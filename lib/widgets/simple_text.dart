import 'package:flutter/material.dart';

class SimpleText extends StatelessWidget {
  final String? text;

  final int? lines;

  final double? fontSize;

  final FontWeight? fontWeight;

  final Color? textColor;

  final FontStyle? style;

  final TextAlign? align;

  final bool? autoFitWidth;

  final TextDecoration? decoration;

  final double? decorationHeight;

  final TextOverflow? overflow;

  final Function? onTap;
  const SimpleText({
    super.key,
    this.text,
    this.fontSize,
    this.fontWeight,
    this.textColor,
    this.lines,
    this.style,
    this.align,
    this.decoration = TextDecoration.none,
    this.autoFitWidth,
    this.onTap,
    this.overflow = TextOverflow.ellipsis,
    this.decorationHeight,
  });

  @override
  Widget build(BuildContext context) {
    Widget textWidget = Text(
      (text ?? "").isEmpty ? (text ?? "") : (text ?? ""),
      softWrap: true,
      maxLines: lines ?? 999,
      overflow: overflow,
      textAlign: align,
      style: TextStyle(
        decoration: decoration,
        decorationColor: textColor,
        decorationThickness: decorationHeight,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: textColor,
        fontStyle: style,
      ),
    );

    if (onTap != null) {
      textWidget = InkWell(
        child: textWidget,
        onTap: () {
          if (onTap != null) {
            onTap!();
          }
        },
      );
    }

    if (autoFitWidth ?? false) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: textWidget,
      );
    } else {
      return textWidget;
    }
  }
}
