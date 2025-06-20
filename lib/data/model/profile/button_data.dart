
// Clase de datos para representar cada botón
import 'package:flutter/cupertino.dart';

class ButtonData {
  final String text;
  final ShapeBorder shape;
  final int index;

  ButtonData({
    required this.text,
    required this.shape,
    required this.index,
  });
}