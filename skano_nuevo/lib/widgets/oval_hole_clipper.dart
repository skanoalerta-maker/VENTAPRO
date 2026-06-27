import 'package:flutter/material.dart';

class OvalHoleClipper extends CustomClipper<Path> {
  final double widthFactor;
  final double heightFactor;

  OvalHoleClipper({
    this.widthFactor = 0.75,
    this.heightFactor = 0.55,
  });

  @override
  Path getClip(Size size) {
    final background = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final holeRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * widthFactor,
      height: size.height * heightFactor,
    );

    final holePath = Path()..addOval(holeRect);

    return Path.combine(
      PathOperation.difference,
      background,
      holePath,
    );
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
