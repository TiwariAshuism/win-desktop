import 'package:flutter/material.dart';

class Logger {
  static info(dynamic message) {
    debugPrint("======================");
    debugPrint(message.toString());
    debugPrint("======================");
  }
}