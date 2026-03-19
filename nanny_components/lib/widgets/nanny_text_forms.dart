import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/styles/text_styles.dart';

class NannyTextForm extends StatefulWidget {
  final InputDecoration? style;
  final String? hintText;
  final String? labelText;
  final String? initialValue;
  final TextInputType? keyType;
  final FocusNode? node;
  final List<TextInputFormatter>? formatters;
  final void Function(String text)? onChanged;
  final VoidCallback? onTap;
  final String? Function(String? text)? validator;
  final bool readOnly;
  final bool enabled;
  final TextEditingController? controller;
  final int? maxLines;
  final int? maxLength;
  final bool isExpanded;
  final Widget? suffixIcon;

  const NannyTextForm({
    super.key,
    this.onChanged,
    this.onTap,
    this.node,
    this.hintText,
    this.labelText,
    this.initialValue,
    this.formatters,
    this.keyType,
    this.validator,
    this.readOnly = false,
    this.enabled = true,
    this.style,
    this.controller,
    this.maxLines,
    this.maxLength,
    this.isExpanded = false,
    this.suffixIcon,
  });

  @override
  State<NannyTextForm> createState() => _NannyTextFormState();
}

class _NannyTextFormState extends State<NannyTextForm> {
  final ValueNotifier<String?> errorText = ValueNotifier<String?>(null);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: errorText,
      builder: (context, error, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: widget.isExpanded ? 75 : null,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 4),
                    blurRadius: 11,
                    color: const Color(0xFF021C3B).withOpacity(.1),
                  ),
                ],
              ),
              child: TextFormField(
                expands: widget.isExpanded,
                minLines: null,
                style:
                    NannyTextStyles.textTheme.bodyMedium?.copyWith(height: 1.5),
                textAlignVertical: TextAlignVertical.center,
                focusNode: widget.node,
                decoration: widget.style?.copyWith(
                      labelText: widget.labelText,
                      hintText: widget.hintText,
                    ) ??
                    InputDecoration(
                      fillColor: Theme.of(context).colorScheme.surface,
                      filled: true,
                      labelText: widget.labelText,
                      labelStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Nanito',
                      ),
                      hintText: widget.hintText,
                      suffixIcon: Padding(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 10, right: 10),
                          child: widget.suffixIcon),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                onTapOutside: (event) =>
                    FocusScope.of(context).requestFocus(FocusNode()),
                inputFormatters: widget.formatters,
                keyboardType: widget.keyType,
                validator: (text) {
                  final error = widget.validator?.call(text);
                  errorText.value = error; // Обновляем ошибку
                  return null; // Возвращаем null, чтобы ошибка не отображалась внутри поля
                },
                initialValue: widget.initialValue,
                readOnly: widget.readOnly,
                enabled: widget.enabled,
                maxLines: widget.isExpanded ? null : widget.maxLines ?? 1,
                maxLength: widget.maxLength,
                onChanged: (value) {
                  // Проксируем внешний колбэк
                  if (widget.onChanged != null) {
                    widget.onChanged!(value);
                  }
                  // Локальная валидация для показа ошибки под полем
                  if (widget.validator != null) {
                    errorText.value = widget.validator!(value);
                  }
                },
                onTap: widget.onTap,
                controller: widget.controller,
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class NannyPasswordForm extends StatefulWidget {
  final String? hintText;
  final String? labelText;
  final TextInputType? keyType;
  final List<TextInputFormatter>? formatters;
  final void Function(String text) onChanged;
  final String? Function(String? text)? validator;
  final bool isExpanded;

  const NannyPasswordForm({
    super.key,
    required this.onChanged,
    this.hintText,
    this.labelText,
    this.formatters,
    this.keyType,
    this.validator,
    this.isExpanded = false,
  });

  @override
  State<NannyPasswordForm> createState() => _NannyPasswordFormState();
}

class _NannyPasswordFormState extends State<NannyPasswordForm> {
  bool obscure = true;
  final ValueNotifier<String?> errorText = ValueNotifier<String?>(null);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: errorText,
      builder: (context, error, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: widget.isExpanded ? 75 : null,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 4),
                    blurRadius: 11,
                    color: const Color(0xFF021C3B).withOpacity(.1),
                  ),
                ],
              ),
              child: TextFormField(
                minLines: null,
                maxLines: 1,
                obscureText: obscure,
                style: NannyTextStyles.textTheme.bodyMedium,
                decoration: InputDecoration(
                  contentPadding: widget.isExpanded
                      ? const EdgeInsets.only(
                          top: 25, bottom: 25, right: 20, left: 20)
                      : null,
                  fillColor: Theme.of(context).colorScheme.surface,
                  filled: true,
                  labelText: widget.labelText,
                  labelStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nanito'),
                  hintText: widget.hintText,
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: IconButton(
                      onPressed: () => setState(
                        () {
                          obscure = !obscure;
                        },
                      ),
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onTapOutside: (event) =>
                    FocusScope.of(context).requestFocus(FocusNode()),
                inputFormatters: widget.formatters,
                keyboardType: widget.keyType,
                validator: (value) {
                  final error = widget.validator?.call(value);
                  errorText.value = error; // Обновляем ошибку
                  return null; // Возвращаем null, чтобы избежать дублирования
                },
                onChanged: (value) {
                  if (widget.validator != null) {
                    errorText.value = widget.validator!(value);
                  }
                  widget.onChanged(value);
                },
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
