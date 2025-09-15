import 'package:flutter/services.dart';
import 'package:characters/characters.dart';

/// Ensures the first visible character is uppercase.
class CapitalizeFirstInputFormatter extends TextInputFormatter {
  const CapitalizeFirstInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final first = text.characters.first;
    final rest = text.characters.skip(1).toString();
    final upperFirst = first.toUpperCase();
    if (first == upperFirst) return newValue;
    final newText = upperFirst + rest;
    // Keep the same selection relative to the end
    final baseOffset = newValue.selection.baseOffset;
    final extentOffset = newValue.selection.extentOffset;
    return newValue.copyWith(
      text: newText,
      selection: TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
      composing: TextRange.empty,
    );
  }
}
