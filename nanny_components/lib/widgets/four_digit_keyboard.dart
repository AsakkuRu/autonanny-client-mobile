import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/styles/new_design_auth.dart';

class FourDigitKeyboard extends StatefulWidget {
  final Widget? topChild;
  final Widget? bottomChild;
  final void Function(String code) onCodeChanged;

  const FourDigitKeyboard({
    super.key,
    required this.onCodeChanged,
    this.topChild,
    this.bottomChild,
  });

  @override
  State<FourDigitKeyboard> createState() => _FourDigitKeyboardState();
}

class _FourDigitKeyboardState extends State<FourDigitKeyboard> {
  static const _keyboardRows = [
    ["1", "2", "3"],
    ["4", "5", "6"],
    ["7", "8", "9"],
    ["", "0", "delete"],
  ];

  List<String> digits = ["", "", "", ""];
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptBuilder(
      builder: (context, size) {
        final compact = size.height < 700 || size.width < 360;
        final extraCompact = size.height < 620;
        final digitHeight = (size.width * .21)
            .clamp(extraCompact ? 56.0 : 60.0, compact ? 72.0 : 88.0)
            .toDouble();
        final keyHeight = extraCompact ? 54.0 : (compact ? 60.0 : 68.0);
        final sectionSpacing = extraCompact ? 16.0 : 20.0;
        final rowSpacing = extraCompact ? 8.0 : 10.0;

        return NannyBottomSheet(
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                extraCompact ? 16 : 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.topChild != null) ...[
                    widget.topChild!,
                    SizedBox(height: sectionSpacing),
                  ],
                  Row(
                    children: [
                      Expanded(child: digitBox(digits[0], digitHeight)),
                      const SizedBox(width: 8),
                      Expanded(child: digitBox(digits[1], digitHeight)),
                      const SizedBox(width: 8),
                      Expanded(child: digitBox(digits[2], digitHeight)),
                      const SizedBox(width: 8),
                      Expanded(child: digitBox(digits[3], digitHeight)),
                    ],
                  ),
                  if (widget.bottomChild != null) ...[
                    SizedBox(height: sectionSpacing),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: widget.bottomChild!,
                    ),
                  ],
                  SizedBox(height: sectionSpacing),
                  Column(
                    children: [
                      for (var i = 0; i < _keyboardRows.length; i++) ...[
                        _keyboardRow(
                          _keyboardRows[i],
                          keyHeight: keyHeight,
                        ),
                        if (i != _keyboardRows.length - 1)
                          SizedBox(height: rowSpacing),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget digitBox(String value, double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: value.isNotEmpty ? NewDesignAuthTokens.primary100 : Colors.white,
        borderRadius: NewDesignAuthTokens.radiusMd,
        border: Border.all(
          color: value.isNotEmpty
              ? NewDesignAuthTokens.primary
              : NewDesignAuthTokens.neutral200,
          width: value.isNotEmpty ? 1.8 : 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 15, 30, 0.06),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: NewDesignAuthTokens.titleXL.copyWith(
            color: NewDesignAuthTokens.neutral900,
            fontSize: 28,
            height: 1,
            letterSpacing: 0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _keyboardRow(
    List<String> values, {
    required double keyHeight,
  }) {
    return Row(
      children: [
        for (var i = 0; i < values.length; i++) ...[
          Expanded(
            child: SizedBox(
              height: keyHeight,
              child: values[i].isEmpty
                  ? const SizedBox.shrink()
                  : values[i] == "delete"
                      ? deleteButton()
                      : numButton(values[i]),
            ),
          ),
          if (i != values.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget numButton(String setValue) {
    return ElevatedButton(
      onPressed: () => setDigit(setValue),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        foregroundColor: NewDesignAuthTokens.neutral900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: NewDesignAuthTokens.neutral200,
          ),
        ),
      ),
      child: Text(
        setValue,
        textAlign: TextAlign.center,
        style: NewDesignAuthTokens.titleM.copyWith(
          fontSize: 26,
          height: 1,
          letterSpacing: 0,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget deleteButton() {
    return ElevatedButton(
      onPressed: deleteDigit,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        foregroundColor: NewDesignAuthTokens.neutral700,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: NewDesignAuthTokens.neutral200,
          ),
        ),
      ),
      child: const Icon(Icons.backspace_outlined),
    );
  }

  void setDigit(String value) {
    setState(() => digits[currentIndex] = value);

    if (currentIndex < 3) currentIndex++;
    widget.onCodeChanged(digits.join());

    if (digits[3].isNotEmpty) {
      currentIndex = 0;
      setState(() => digits = ["", "", "", ""]);
    }
  }

  void deleteDigit() {
    if (currentIndex - 1 < 0) return;

    currentIndex--;
    setState(() => digits[currentIndex] = "");
    widget.onCodeChanged(digits.join());
  }
}
