import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/driver_info_vm.dart';
import 'package:nanny_components/base_views/views/video_view.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule_responses_data.dart';
import 'package:nanny_core/nanny_core.dart';

/// Единый экран профиля водителя для клиентского приложения.
///
/// Если [viewingOrder] == true, то [scheduleData] должен быть передан:
/// из этой поверхности можно сразу принять или отклонить отклик на контракт.
class DriverInfoView extends StatefulWidget {
  final int id;
  final bool hasPaymentButtons;
  final bool franchiseView;
  final bool viewingOrder;
  final ScheduleResponsesData? scheduleData;
  final VoidCallback? onOpenRating;

  const DriverInfoView({
    super.key,
    required this.id,
    this.hasPaymentButtons = false,
    this.franchiseView = false,
    this.viewingOrder = false,
    this.scheduleData,
    this.onOpenRating,
  });

  @override
  State<DriverInfoView> createState() => _DriverInfoViewState();
}

class _DriverInfoViewState extends State<DriverInfoView> {
  static const List<String> _questionnaireLabels = [
    'Опыт с детьми',
    'Нестандартные ситуации',
    'Почему выбрали эту работу',
    'Дополнительная информация',
    'Сильные стороны',
    'Ограничения',
    'Комментарии',
  ];

  late final DriverInfoVM vm;

  @override
  void initState() {
    super.initState();
    vm = DriverInfoVM(
      context: context,
      update: setState,
      id: widget.id,
      viewingOrder: widget.viewingOrder,
      scheduleData: widget.scheduleData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AutonannyAppBar(
        title: 'Профиль водителя',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      bottomNavigationBar:
          widget.viewingOrder ? _buildResponseActionsBar() : null,
      body: RequestLoader(
        request: vm.getDriver,
        completeView: (context, driverData) {
          if (driverData == null) {
            return const AutonannyErrorState(
              title: 'Профиль водителя недоступен',
              description:
                  'Не удалось загрузить данные водителя. Попробуйте открыть профиль ещё раз.',
            );
          }

          final data = driverData;
          final userData = data.userData.asDriver();
          final driverRoleData = userData.roleData;
          final questionnaireAnswers =
              _buildQuestionnaireAnswers(driverRoleData?.answers);
          final experienceYears = driverRoleData?.experienceYears;
          final driverInitials = [
            if (userData.name.trim().isNotEmpty)
              userData.name.trim().characters.first,
            if (userData.surname.trim().isNotEmpty)
              userData.surname.trim().characters.first,
          ].join().toUpperCase();
          final driverPhotoUrl = NannyConsts.buildFileUrl(userData.photoPath);
          final driverVideoUrl = NannyConsts.buildFileUrl(userData.videoPath) ??
              userData.videoPath;

          return ListView(
            padding: const EdgeInsets.all(AutonannySpacing.lg),
            children: [
              _buildHeroCard(
                name: '${userData.name} ${userData.surname}'.trim(),
                initials: driverInitials.isEmpty ? 'В' : driverInitials,
                photoUrl: driverPhotoUrl,
                experienceYears: experienceYears,
                hasVideo: driverVideoUrl.trim().isNotEmpty,
                videoUrl: driverVideoUrl,
                onOpenVideo: driverVideoUrl.trim().isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => VideoView(url: driverVideoUrl),
                          ),
                        ),
                onOpenRating: widget.onOpenRating,
              ),
              if (widget.viewingOrder) ...[
                const SizedBox(height: AutonannySpacing.lg),
                const AutonannyInlineBanner(
                  title: 'Отклик на контракт',
                  message:
                      'Проверьте профиль водителя и при необходимости сразу примите или отклоните отклик ниже.',
                  tone: AutonannyBannerTone.info,
                  leading: AutonannyIcon(AutonannyIcons.info),
                ),
              ],
              const SizedBox(height: AutonannySpacing.lg),
              _buildStatsRow(experienceYears: experienceYears),
              const SizedBox(height: AutonannySpacing.lg),
              if (questionnaireAnswers.isNotEmpty)
                _buildQuestionnaireSection(questionnaireAnswers),
              if (questionnaireAnswers.isNotEmpty)
                const SizedBox(height: AutonannySpacing.lg),
              _buildCarSection(data.carDataText),
              const SizedBox(height: AutonannySpacing.lg),
              if (widget.viewingOrder)
                _buildPriceSection(
                  tripsCount: widget.scheduleData?.data.length ?? 0,
                ),
              if (widget.viewingOrder)
                const SizedBox(height: AutonannySpacing.lg),
              _buildAvailabilitySection(
                hasVideo: driverVideoUrl.trim().isNotEmpty,
                hasQuestionnaire: questionnaireAnswers.isNotEmpty,
              ),
              if (!widget.viewingOrder)
                const SizedBox(height: AutonannySpacing.xl),
            ],
          );
        },
        errorView: (context, error) => ErrorView(errorText: error.toString()),
      ),
    );
  }

  Widget _buildHeroCard({
    required String name,
    required String initials,
    required String? photoUrl,
    required int? experienceYears,
    required bool hasVideo,
    required String videoUrl,
    required VoidCallback? onOpenVideo,
    required VoidCallback? onOpenRating,
  }) {
    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.xl),
      decoration: const BoxDecoration(
        gradient: AutonannyGradients.hero,
        borderRadius: AutonannyRadii.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutonannyAvatar(
                imageUrl: photoUrl,
                initials: initials,
                size: 92,
                borderRadius: BorderRadius.circular(46),
              ),
              const SizedBox(width: AutonannySpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Водитель' : name,
                      style: AutonannyTypography.h2(color: Colors.white),
                    ),
                    const SizedBox(height: AutonannySpacing.sm),
                    Text(
                      'Проверенный профиль водителя со сведениями об опыте, анкете и автомобиле.',
                      style: AutonannyTypography.bodyS(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                    if (experienceYears != null) ...[
                      const SizedBox(height: AutonannySpacing.md),
                      _buildMetaBadge(
                        icon: AutonannyIcons.verified,
                        label:
                            'Опыт: $experienceYears ${_yearWord(experienceYears)}',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AutonannySpacing.lg),
          if (hasVideo)
            GestureDetector(
              onTap: onOpenVideo,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AutonannySpacing.md),
                  DriverVideoPreview(
                    videoUrl: videoUrl,
                    height: 180,
                  ),
                  const SizedBox(height: AutonannySpacing.sm),
                ],
              ),
            )
          else
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: AutonannyRadii.brLg,
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AutonannyIcon(
                      AutonannyIcons.video,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: AutonannySpacing.sm),
                    Flexible(
                      child: Text(
                        'Водитель пока не загрузил видео о себе',
                        textAlign: TextAlign.center,
                        style: AutonannyTypography.bodyS(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Wrap(
            spacing: AutonannySpacing.sm,
            runSpacing: AutonannySpacing.sm,
            children: [
              if (onOpenRating != null)
                _buildActionChip(
                  icon: AutonannyIcons.star,
                  label: 'Отзывы и рейтинг',
                  onTap: onOpenRating,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionnaireSection(
    List<MapEntry<String, String>> questionnaireAnswers,
  ) {
    return AutonannySectionContainer(
      title: 'Ключевая информация',
      subtitle: 'Ответы водителя на анкету и важные детали по опыту.',
      child: Column(
        children: [
          for (var i = 0; i < questionnaireAnswers.length; i++) ...[
            _questionAnswerPlate(
              title: questionnaireAnswers[i].key,
              value: questionnaireAnswers[i].value,
            ),
            if (i != questionnaireAnswers.length - 1)
              const SizedBox(height: AutonannySpacing.md),
          ],
        ],
      ),
    );
  }

  Widget _buildCarSection(CarDataText carData) {
    return AutonannySectionContainer(
      title: 'Автомобиль',
      subtitle: 'Данные автомобиля, на котором водитель выполняет поездки.',
      child: Column(
        children: [
          _detailRow('Марка', _displayValue(carData.autoMark)),
          const SizedBox(height: AutonannySpacing.md),
          _detailRow('Модель', _displayValue(carData.autoModel)),
          const SizedBox(height: AutonannySpacing.md),
          _detailRow('Цвет', _displayValue(carData.autoColor)),
          const SizedBox(height: AutonannySpacing.md),
          _detailRow(
            'Год выпуска',
            carData.releaseYear > 0 ? carData.releaseYear.toString() : '—',
          ),
          const SizedBox(height: AutonannySpacing.md),
          _detailRow('Гос. номер', _displayValue(carData.stateNumber)),
          const SizedBox(height: AutonannySpacing.md),
          _detailRow('СТС', _displayValue(carData.ctc)),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection({
    required bool hasVideo,
    required bool hasQuestionnaire,
  }) {
    if (hasVideo && hasQuestionnaire) {
      return const SizedBox.shrink();
    }

    final missing = <String>[];
    if (!hasVideo) {
      missing.add('видео-визитка');
    }
    if (!hasQuestionnaire) {
      missing.add('ответы анкеты');
    }

    return AutonannyInlineBanner(
      title: 'Профиль заполнен частично',
      message:
          'Сейчас недоступны: ${missing.join(', ')}. Остальная информация о водителе загружена и доступна для просмотра.',
      tone: AutonannyBannerTone.info,
      leading: const AutonannyIcon(AutonannyIcons.info),
    );
  }

  Widget _buildPriceSection({required int tripsCount}) {
    return AutonannySectionContainer(
      title: 'Стоимость поездки',
      subtitle: 'Итоговая цена фиксируется в контракте после выбора водителя.',
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$tripsCount ${_tripWord(tripsCount)} в отклике',
              style: AutonannyTypography.bodyM(
                color: const Color(0xFF4B5563),
              ),
            ),
          ),
          Text(
            '188 ₽',
            style: AutonannyTypography.h2(
              color: const Color(0xFF5B4FCF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseActionsBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AutonannySpacing.lg,
          AutonannySpacing.sm,
          AutonannySpacing.lg,
          AutonannySpacing.lg,
        ),
        child: Row(
          children: [
            Expanded(
              child: AutonannyButton(
                label: 'Отклонить',
                variant: AutonannyButtonVariant.secondary,
                onPressed: () => vm.answerSchedule(confirm: false),
              ),
            ),
            const SizedBox(width: AutonannySpacing.md),
            Expanded(
              child: AutonannyButton(
                label: 'Выбрать этого водителя',
                onPressed: () => vm.answerSchedule(confirm: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaBadge({
    required AutonannyIconAsset icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AutonannySpacing.md,
        vertical: AutonannySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: AutonannyRadii.brFull,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AutonannyIcon(
            AutonannyIcons.verified,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: AutonannySpacing.xs),
          Flexible(
            child: Text(
              label,
              style: AutonannyTypography.labelM(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow({required int? experienceYears}) {
    final cards = <MapEntry<String, String>>[
      MapEntry(
        '${widget.scheduleData?.data.length ?? 0}',
        'маршрутов\nв отклике',
      ),
      MapEntry(
        '${experienceYears ?? 0}',
        'лет\nстажа',
      ),
      const MapEntry('Профи', 'проверенный\nводитель'),
    ];

    return Row(
      children: cards
          .map(
            (item) => Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: cards.last == item ? 0 : AutonannySpacing.xs,
                ),
                padding: const EdgeInsets.all(AutonannySpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AutonannyRadii.brLg,
                  border: Border.all(color: const Color(0xFFE4E9F5)),
                ),
                child: Column(
                  children: [
                    Text(
                      item.key,
                      style: AutonannyTypography.h3(
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      item.value,
                      textAlign: TextAlign.center,
                      style: AutonannyTypography.caption(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildActionChip({
    required AutonannyIconAsset icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AutonannyRadii.brFull,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AutonannySpacing.md,
          vertical: AutonannySpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: AutonannyRadii.brFull,
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AutonannyIcon(icon, color: Colors.white, size: 16),
            const SizedBox(width: AutonannySpacing.xs),
            Text(
              label,
              style: AutonannyTypography.labelM(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AutonannySpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: AutonannyRadii.brLg,
        border: Border.all(color: const Color(0xFFE4E9F5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: AutonannyTypography.bodyS(
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: AutonannySpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AutonannyTypography.bodyM(
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, String>> _buildQuestionnaireAnswers(Answers? answers) {
    if (answers == null) {
      return const [];
    }

    final values = <String?>[
      answers.first,
      answers.second,
      answers.third,
      answers.fourth,
      answers.fifth,
      answers.sixth,
      answers.seventh,
    ];

    final result = <MapEntry<String, String>>[];
    for (var i = 0; i < values.length; i++) {
      final value = values[i]?.trim() ?? '';
      if (value.isEmpty) {
        continue;
      }
      result.add(MapEntry(_questionnaireLabels[i], value));
    }
    return result;
  }

  Widget _questionAnswerPlate({
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AutonannySpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: AutonannyRadii.brLg,
        border: Border.all(color: const Color(0xFFE4E9F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AutonannyTypography.labelL(
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: AutonannySpacing.sm),
          Text(
            value,
            style: AutonannyTypography.bodyM(
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  String _displayValue(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? '—' : normalized;
  }

  String _yearWord(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) {
      return 'год';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'года';
    }
    return 'лет';
  }

  String _tripWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'поездка';
    }
    if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'поездки';
    }
    return 'поездок';
  }
}
