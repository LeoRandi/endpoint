import "_imports.dart";

class TextWidget extends StatelessWidget {
  final String text;
  final TextStyle style;

  const TextWidget(this.text, this.style, {super.key});

  static TextWidget small(String text){
    return TextWidget(text, textSmall);
  }

  static TextWidget medium(String text){
    return TextWidget(text, textMedium);
  }

  static TextWidget large(String text){
    return TextWidget(text, textLarge);
  }

  static TextWidget extraLarge(String text){
    return TextWidget(text, textExtraLarge);
  }

  @override
  Widget build(context){
    return Text(
      text,
      style: style,
    );
  }
}