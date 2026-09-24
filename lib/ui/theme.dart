import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const ink = Color(0xFF13243C);
const muted = Color(0xFF748197);
const blue = Color(0xFF1763F6);
const teal = Color(0xFF009D83);
const mint = Color(0xFFE5F7F0);
const canvas = Color(0xFFF5F7FB);
const line = Color(0xFFE8EDF3);
const violet = Color(0xFF7A5AE8);
const amber = Color(0xFFB56B16);
String money(num value, {bool compact = false}) =>
    compact && value.abs() >= 100000
    ? '₹${(value / 100000).toStringAsFixed(value % 100000 == 0 ? 0 : 2)}L'
    : NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      ).format(value);

ThemeData finTheme() => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: blue,
    primary: blue,
    secondary: teal,
    surface: Colors.white,
  ),
  scaffoldBackgroundColor: canvas,
  fontFamily: 'Arial',
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.1,
      color: ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -.7,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w700,
      letterSpacing: -.35,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: ink),
    bodySmall: TextStyle(fontSize: 12, height: 1.5, color: muted),
  ),
  dividerColor: line,
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF8FAFD),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: blue, width: 1.5),
    ),
    labelStyle: const TextStyle(color: muted, fontSize: 13),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: blue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ink,
      side: const BorderSide(color: line),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    ),
  ),
  sliderTheme: const SliderThemeData(
    activeTrackColor: blue,
    thumbColor: blue,
    inactiveTrackColor: line,
    trackHeight: 5,
  ),
);
