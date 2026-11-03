import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact numeric input used throughout the calculator.
class NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? prefix;
  final String? suffix;
  final bool integer;
  final bool autofocus;
  final ValueChanged<String> onChanged;

  const NumField({
    super.key,
    required this.controller,
    required this.label,
    required this.onChanged,
    this.hint,
    this.prefix,
    this.suffix,
    this.integer = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            integer ? RegExp(r'[0-9]') : RegExp(r'[0-9.]')),
        if (!integer) _SingleDotFormatter(),
      ],
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        suffixText: suffix,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class _SingleDotFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      '.'.allMatches(newValue.text).length > 1 ? oldValue : newValue;
}

/// The "×" / "=" glyph between fields.
class OpGlyph extends StatelessWidget {
  final String glyph;
  const OpGlyph(this.glyph, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        glyph,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
