import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_core/models/from_api/transaction.dart';
import 'package:nanny_core/nanny_core.dart';

/// FE-MVP-023: ViewModel для истории транзакций
class TransactionsHistoryVM extends ViewModelBase {
  TransactionsHistoryVM({
    required super.context,
    required super.update,
    this.initialTransactionType,
    this.initialSearchQuery,
  }) {
    filter = TransactionFilter(
      types: initialTransactionType == null ? null : [initialTransactionType!],
      searchQuery: initialSearchQuery == null || initialSearchQuery!.isEmpty
          ? null
          : initialSearchQuery,
    );
    if (filter.searchQuery case final query? when query.isNotEmpty) {
      searchController.text = query;
    }
  }

  final String? initialTransactionType;
  final String? initialSearchQuery;

  final TextEditingController searchController = TextEditingController();

  List<Transaction> allTransactions = [];
  List<Transaction> filteredTransactions = [];
  TransactionFilter filter = TransactionFilter();

  bool isLoadError = false;
  bool isExporting = false;

  bool get hasActiveFilters {
    return filter.startDate != null ||
        filter.endDate != null ||
        (filter.types != null && filter.types!.isNotEmpty) ||
        filter.minAmount != null ||
        filter.maxAmount != null ||
        (filter.searchQuery != null && filter.searchQuery!.isNotEmpty);
  }

  String get activeFiltersSummary {
    final parts = <String>[];
    if (filter.startDate != null || filter.endDate != null) {
      final start =
          filter.startDate != null ? _formatDate(filter.startDate!) : '...';
      final end = filter.endDate != null ? _formatDate(filter.endDate!) : '...';
      parts.add('Период: $start - $end');
    }
    if (filter.types != null && filter.types!.isNotEmpty) {
      parts.add('Тип: ${_typeLabel(filter.types!.first)}');
    }
    if (filter.minAmount != null || filter.maxAmount != null) {
      final min = filter.minAmount != null
          ? NumberFormat('#,##0', 'ru_RU').format(filter.minAmount)
          : '0';
      final max = filter.maxAmount != null
          ? NumberFormat('#,##0', 'ru_RU').format(filter.maxAmount)
          : '...';
      parts.add('Сумма: $min-$max ₽');
    }
    if (filter.searchQuery case final query? when query.isNotEmpty) {
      parts.add('Поиск: "$query"');
    }
    return parts.join(' • ');
  }

  @override
  Future<bool> loadPage() async {
    isLoadError = false;
    final result = await NannyUsersApi.getTransactions(perPage: 100);
    if (!result.success || result.response == null) {
      isLoadError = true;
      return false;
    }
    allTransactions = result.response!.transactions;
    applyFilters();
    return true;
  }

  void applyFilters() {
    filteredTransactions =
        allTransactions.where((t) => filter.matches(t)).toList();
    filteredTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    update(() {});
  }

  void onSearchChanged(String query) {
    filter = TransactionFilter(
      startDate: filter.startDate,
      endDate: filter.endDate,
      types: filter.types,
      minAmount: filter.minAmount,
      maxAmount: filter.maxAmount,
      searchQuery: query.isEmpty ? null : query,
    );
    applyFilters();
  }

  void clearSearch() {
    searchController.clear();
    onSearchChanged('');
  }

  void clearFilters() {
    filter = TransactionFilter();
    searchController.clear();
    applyFilters();
  }

  Future<void> refresh() async {
    await reloadPage();
  }

  Future<void> showFilterDialog() async {
    final result = await showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _TransactionFilterSheet(
          initialFilter: filter,
        ),
      ),
    );

    if (result == null) return;

    filter = TransactionFilter(
      startDate: result.startDate,
      endDate: result.endDate,
      types: result.types,
      minAmount: result.minAmount,
      maxAmount: result.maxAmount,
      searchQuery: filter.searchQuery,
    );
    applyFilters();
  }

  Future<void> exportTransactions() async {
    if (filteredTransactions.isEmpty) {
      await NannyDialogs.showResultSheet(
        context,
        title: 'Нет данных для экспорта',
        message: 'Измените фильтры или дождитесь появления операций.',
        tone: AutonannyBannerTone.warning,
        leading: const AutonannyIcon(AutonannyIcons.warning),
      );
      return;
    }

    update(() => isExporting = true);

    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final incomeTotal = filteredTransactions
          .where((transaction) => transaction.isIncome)
          .fold<double>(
              0, (sum, transaction) => sum + transaction.amount.abs());
      final expenseTotal = filteredTransactions
          .where((transaction) => transaction.isExpense)
          .fold<double>(
              0, (sum, transaction) => sum + transaction.amount.abs());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'История операций — АвтоНяня',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Период: ${_buildExportPeriodText()}',
                style:
                    const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
              if (hasActiveFilters)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    'Фильтры: $activeFiltersSummary',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              pw.Divider(),
            ],
          ),
          footer: (ctx) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Сформировано: ${DateFormat('dd.MM.yyyy HH:mm').format(now)}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              ),
              pw.Text(
                'Стр. ${ctx.pageNumber} из ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              ),
            ],
          ),
          build: (_) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _pdfStat('Операций', '${filteredTransactions.length}'),
                _pdfStat('Пополнения', _formatCurrency(incomeTotal)),
                _pdfStat('Списания', _formatCurrency(expenseTotal)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellHeight: 28,
              columnWidths: {
                0: const pw.FixedColumnWidth(74),
                1: const pw.FixedColumnWidth(68),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FixedColumnWidth(70),
                4: const pw.FixedColumnWidth(58),
              },
              headers: ['Дата', 'Тип', 'Описание', 'Сумма', 'Статус'],
              data: filteredTransactions
                  .map(
                    (transaction) => [
                      DateFormat('dd.MM.yyyy').format(transaction.createdAt),
                      transaction.typeText,
                      transaction.description.isEmpty
                          ? '—'
                          : transaction.description,
                      '${transaction.isIncome ? '+' : '-'}${_formatCurrency(transaction.amount.abs())}',
                      transaction.statusText.isEmpty
                          ? 'Завершено'
                          : transaction.statusText,
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'transactions_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf',
      );
    } catch (error) {
      if (context.mounted) {
        await NannyDialogs.showResultSheet(
          context,
          title: 'Не удалось экспортировать историю',
          message: '$error',
          tone: AutonannyBannerTone.danger,
          leading: const AutonannyIcon(AutonannyIcons.warning),
        );
      }
    }

    update(() => isExporting = false);
  }

  @override
  void dispose() {
    searchController.dispose();
  }

  String _formatDate(DateTime value) => DateFormat('dd.MM.yyyy').format(value);

  String _typeLabel(String type) {
    return switch (type) {
      'deposit' => 'Пополнение',
      'withdrawal' => 'Вывод',
      'payment' => 'Оплата',
      'refund' => 'Возврат',
      'commission' => 'Комиссия',
      'earning' => 'Заработок',
      _ => type,
    };
  }

  String _buildExportPeriodText() {
    if (filter.startDate != null && filter.endDate != null) {
      return '${_formatDate(filter.startDate!)} - ${_formatDate(filter.endDate!)}';
    }
    if (filter.startDate != null) {
      return 'с ${_formatDate(filter.startDate!)}';
    }
    if (filter.endDate != null) {
      return 'по ${_formatDate(filter.endDate!)}';
    }
    return 'За все время';
  }

  String _formatCurrency(double value) {
    return '${NumberFormat('#,##0.00', 'ru_RU').format(value)} ₽';
  }

  pw.Widget _pdfStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }
}

class _TransactionFilterSheet extends StatefulWidget {
  const _TransactionFilterSheet({
    required this.initialFilter,
  });

  final TransactionFilter initialFilter;

  @override
  State<_TransactionFilterSheet> createState() =>
      _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<_TransactionFilterSheet> {
  static const _typeOptions = <_TransactionTypeOption>[
    _TransactionTypeOption(value: null, label: 'Все типы'),
    _TransactionTypeOption(value: 'deposit', label: 'Пополнение'),
    _TransactionTypeOption(value: 'payment', label: 'Оплата'),
    _TransactionTypeOption(value: 'refund', label: 'Возврат'),
    _TransactionTypeOption(value: 'withdrawal', label: 'Вывод'),
    _TransactionTypeOption(value: 'commission', label: 'Комиссия'),
    _TransactionTypeOption(value: 'earning', label: 'Заработок'),
  ];

  late DateTime? _startDate = widget.initialFilter.startDate;
  late DateTime? _endDate = widget.initialFilter.endDate;
  late String? _selectedType = widget.initialFilter.types?.firstOrNull;
  late final TextEditingController _minAmountController = TextEditingController(
    text: widget.initialFilter.minAmount?.toStringAsFixed(0) ?? '',
  );
  late final TextEditingController _maxAmountController = TextEditingController(
    text: widget.initialFilter.maxAmount?.toStringAsFixed(0) ?? '',
  );

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return AutonannyBottomSheetShell(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Фильтры операций',
                        style: AutonannyTypography.h2(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AutonannySpacing.xs),
                      Text(
                        'Период, тип и диапазон суммы для истории кошелька.',
                        style: AutonannyTypography.bodyS(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AutonannySpacing.md),
                AutonannyIconButton(
                  icon: const AutonannyIcon(AutonannyIcons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  variant: AutonannyIconButtonVariant.ghost,
                ),
              ],
            ),
            const SizedBox(height: AutonannySpacing.xl),
            AutonannySectionContainer(
              title: 'Период',
              subtitle:
                  'Можно выбрать только начало, только конец или обе даты.',
              child: Column(
                children: [
                  _DateField(
                    label: 'От',
                    value: _startDate,
                    onTap: () => _pickDate(isStart: true),
                    onClear: _startDate == null
                        ? null
                        : () => setState(() => _startDate = null),
                  ),
                  const SizedBox(height: AutonannySpacing.md),
                  _DateField(
                    label: 'До',
                    value: _endDate,
                    onTap: () => _pickDate(isStart: false),
                    onClear: _endDate == null
                        ? null
                        : () => setState(() => _endDate = null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AutonannySpacing.lg),
            AutonannySectionContainer(
              title: 'Тип операции',
              subtitle: 'Один тип за раз, чтобы быстрее сузить список.',
              child: Column(
                children: _typeOptions
                    .map(
                      (option) => AutonannyListRow(
                        title: option.label,
                        subtitle: option.value == null
                            ? 'Без ограничения по типу'
                            : null,
                        onTap: () => setState(() {
                          _selectedType = option.value;
                        }),
                        trailing: Icon(
                          _selectedType == option.value
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: _selectedType == option.value
                              ? colors.actionPrimary
                              : colors.textTertiary,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: AutonannySpacing.lg),
            AutonannySectionContainer(
              title: 'Сумма операции',
              subtitle: 'По абсолютному значению операции, без знака.',
              child: Column(
                children: [
                  AutonannyTextField(
                    controller: _minAmountController,
                    labelText: 'Минимум, ₽',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: AutonannySpacing.md),
                  AutonannyTextField(
                    controller: _maxAmountController,
                    labelText: 'Максимум, ₽',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AutonannySpacing.lg),
            const AutonannyInlineBanner(
              title: 'Поиск по тексту не теряется',
              message:
                  'Если у вас уже введен поиск на экране, он останется активным после применения фильтров.',
              tone: AutonannyBannerTone.info,
            ),
            const SizedBox(height: AutonannySpacing.xl),
            Row(
              children: [
                Expanded(
                  child: AutonannyButton(
                    label: 'Сбросить',
                    variant: AutonannyButtonVariant.secondary,
                    onPressed: _reset,
                  ),
                ),
                const SizedBox(width: AutonannySpacing.md),
                Expanded(
                  child: AutonannyButton(
                    label: 'Применить',
                    onPressed: _apply,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      initialDate: initialDate,
      locale: const Locale('ru'),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = DateTime(picked.year, picked.month, picked.day);
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        );
        if (_startDate != null && _startDate!.isAfter(_endDate!)) {
          _startDate = DateTime(picked.year, picked.month, picked.day);
        }
      }
    });
  }

  void _reset() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedType = null;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      TransactionFilter(
        startDate: _startDate,
        endDate: _endDate,
        types: _selectedType == null ? null : [_selectedType!],
        minAmount: _parseAmount(_minAmountController.text),
        maxAmount: _parseAmount(_maxAmountController.text),
      ),
    );
  }

  double? _parseAmount(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }
}

class _DateField extends StatefulWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncText();
  }

  @override
  void didUpdateWidget(covariant _DateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _syncText();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncText() {
    _controller.text = widget.value == null
        ? ''
        : DateFormat('dd.MM.yyyy').format(widget.value!);
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyTextField(
      labelText: widget.label,
      readOnly: true,
      hintText: 'Выберите дату',
      controller: _controller,
      onTap: widget.onTap,
      suffix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onClear != null)
            IconButton(
              onPressed: widget.onClear,
              icon: const AutonannyIcon(AutonannyIcons.close),
            ),
          const Padding(
            padding: EdgeInsets.only(right: AutonannySpacing.md),
            child: AutonannyIcon(AutonannyIcons.calendar),
          ),
        ],
      ),
    );
  }
}

class _TransactionTypeOption {
  const _TransactionTypeOption({
    required this.value,
    required this.label,
  });

  final String? value;
  final String label;
}
