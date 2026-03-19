import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';

class NannyTextFormStyles {
  // Базовая тема для текстовых полей по новому дизайну
  static final InputDecorationTheme defaultFormTheme = InputDecorationTheme(
    filled: true,
    fillColor: NannyTheme.neutral50,
    hintStyle: NannyTextStyles.textTheme.bodyMedium?.copyWith(
      color: NannyTheme.neutral300,
      fontWeight: FontWeight.w500,
    ),
    labelStyle: NannyTextStyles.textTheme.labelLarge?.copyWith(
      color: NannyTheme.neutral400,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: NannyTheme.neutral200, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: NannyTheme.neutral200, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: NannyTheme.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  );

  static const InputDecoration searchForm = InputDecoration(
    fillColor: NannyTheme.neutral100,
    filled: true,
    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
    suffixIcon: Icon(Icons.search_rounded),
    suffixIconColor: NannyTheme.neutral400,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide.none,
    ),
  );
}
