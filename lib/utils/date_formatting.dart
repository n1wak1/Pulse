import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Краткая дата по локали (например, ru: 02.04.2026).
String formatShortDate(DateTime date, Locale locale) {
  return DateFormat.yMd(locale.toString()).format(date);
}
