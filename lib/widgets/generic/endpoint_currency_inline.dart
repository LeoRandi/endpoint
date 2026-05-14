import '../_imports.dart';

class EndpointCurrencyInline extends StatelessWidget {
  final int value;
  final Color iconColor;
  final Color textColor;
  final TextStyle? textStyle;
  final double iconSize;
  final double spacing;

  const EndpointCurrencyInline({
    super.key,
    required this.value,
    required this.iconColor,
    required this.textColor,
    this.textStyle,
    this.iconSize = 14,
    this.spacing = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.monetization_on_rounded,
          size: iconSize,
          color: iconColor,
        ),
        SizedBox(width: spacing),
        EndpointText(
          '$value',
          style: (textStyle ??
                  textSmallNumericBold.copyWith(
                    letterSpacing: 1.1,
                  ))
              .copyWith(color: textColor),
        ),
      ],
    );
  }
}
