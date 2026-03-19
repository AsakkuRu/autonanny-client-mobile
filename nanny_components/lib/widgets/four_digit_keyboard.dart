import 'package:flutter/material.dart';
import 'package:nanny_components/nanny_components.dart';

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
  List<String> digits = ["", "", "", ""];
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AdaptBuilder(
      builder: (context, size) => NannyBottomSheet(
        // height: size.height * .8,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.topChild != null) widget.topChild!,
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: digitBox(digits[0], size)),
                  const SizedBox(width: 8),
                  Expanded(child: digitBox(digits[1], size)),
                  const SizedBox(width: 8),
                  Expanded(child: digitBox(digits[2], size)),
                  const SizedBox(width: 8),
                  Expanded(child: digitBox(digits[3], size)),
                ],
              ),
              if (widget.bottomChild != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: widget.bottomChild!,
                ),
              Expanded(
                child: Center(
                  child: GridView(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.2
                            // mainAxisExtent: size.height * .1,
                            ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      numButton("1", size),
                      numButton("2", size),
                      numButton("3", size),
                      numButton("4", size),
                      numButton("5", size),
                      numButton("6", size),
                      numButton("7", size),
                      numButton("8", size),
                      numButton("9", size),
                      const SizedBox(),
                      numButton("0", size),
                      deleteButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget digitBox(String value, Size size) {
    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 0,
      child: Container(
        height: size.width * .23,
        decoration: BoxDecoration(
            color: value.isNotEmpty
                ? NannyTheme.lightGreen
                : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              value.isNotEmpty
                  ? BoxShadow(
                      offset: const Offset(0, 5),
                      blurRadius: 11,
                      spreadRadius: -6,
                      color: const Color(0xFF0D5118).withOpacity(.5),
                    )
                  : BoxShadow(
                      offset: const Offset(0, 10),
                      blurRadius: 14,
                      spreadRadius: -9,
                      color: const Color(0xFF021C3B).withOpacity(.25),
                    ),
            ]),
        child: Center(
          child: Text(value, textScaleFactor: 2),
        ),
      ),
    );
  }

  Widget numButton(String setValue, Size size) {
    return ElevatedButton(
        onPressed: () => setDigit(setValue),
        style: NannyButtonStyles.transparent,
        child: Text(setValue, textScaleFactor: 2));
  }

  Widget deleteButton() {
    return ElevatedButton(
        onPressed: deleteDigit,
        style: NannyButtonStyles.transparent,
        child: const Icon(Icons.backspace_outlined));
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
