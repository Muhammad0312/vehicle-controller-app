import 'package:flutter/services.dart';

class IpAddressInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Filter out spaces and non-digits/dots
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');

    // Prevent starting with a dot
    if (newText.startsWith('.')) {
      newText = newText.substring(1);
    }

    // 2. Split into octets
    List<String> octets = newText.split('.');

    // 3. Validation and formatting

    // Limit to 4 octets
    if (octets.length > 4) {
      octets = octets.sublist(0, 4);
      // Reconstruct text to stop adding more dots
      newText = octets.join('.');
    }

    // Process each octet
    for (int i = 0; i < octets.length; i++) {
      String octet = octets[i];

      // Limit to 3 digits per octet
      if (octet.length > 3) {
        octet = octet.substring(0, 3);
        octets[i] = octet;
      }

      // Check range 0-255
      if (octet.isNotEmpty) {
        int? value = int.tryParse(octet);
        if (value != null && value > 255) {
          // If valid previous numeric, keep that, otherwise truncate current to 255 or clamp
          // Better UX: prevent typing the digit that makes it > 255
          // Simple approach: clamp to 255
          octets[i] = '255';
        }
      }
    }

    // Auto-append dot logic
    // We strictly reconstruct the string from valid octets
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < octets.length; i++) {
      buffer.write(octets[i]);
      // Add dot if:
      // 1. We are not the last allowed octet (index 3)
      // 2. AND (User typed a dot explicitly OR we hit 3 chars)
      // BUT we need to distinguish if user Just Typed 3 chars vs backspacing.
      // The split logic destroys the "trailing dot" info if it's empty.
    }

    // simpler approach: iterate and rebuild based on cursor position logic is hard.
    // Let's stick to the Plan: simple regex + range check + auto-dot.

    // Re-implementation with simple cleaning
    String cleanText = newValue.text
        .replaceAll(' ', '')
        .replaceAll(',', '.'); // replace space/comma

    // Allow only digits and dots
    cleanText = cleanText.replaceAll(RegExp(r'[^0-9.]'), '');

    // Handle double dots
    while (cleanText.contains('..')) {
      cleanText = cleanText.replaceAll('..', '.');
    }

    List<String> parts = cleanText.split('.');
    if (parts.length > 4) {
      // Drop extra parts
      parts = parts.sublist(0, 4);
      cleanText = parts.join('.');
    }

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].length > 3) {
        // If user keeps typing, move to next octet if possible, or truncate
        // Basic truncated for now
        String chunk = parts[i].substring(0, 3);
        parts[i] = chunk;
        // If we are not at the last octet, enabling auto-dot usually means check if text length grew
      }
      if (parts[i].isNotEmpty) {
        int? val = int.tryParse(parts[i]);
        if (val != null && val > 255) {
          parts[i] = '255';
        }
      }
    }

    // Auto-add dot if 3 digits typed in current octet and we aren't at end
    // We need to detect if we are adding characters, not deleting.
    if (newValue.text.length > oldValue.text.length) {
      // User is typing

      // Find which octet we are in
      // It's brittle to calculate exact index.
      // Let's rely on the simple rule: if a part has 3 digits and no following dot, add one.

      // Improve: Reconstruct cleanText from parts
      // But we need to preserve trailing dot if user typed it.
    }

    // Final logic implementation that is robust:
    String text = newValue.text;

    // 1. Remove spaces (fix for keyboard issue)
    text = text.replaceAll(' ', '');

    // 2. Allow only digits and dots
    text = text.replaceAll(RegExp(r'[^0-9.]'), '');

    // 3. Split
    List<String> split = text.split('.');

    // 4. Validate parts
    for (int i = 0; i < split.length; i++) {
      if (split[i].length > 3) {
        split[i] = split[i].substring(0, 3);
      }
      if (split[i].isNotEmpty && int.parse(split[i]) > 255) {
        split[i] = '255';
      }
    }

    // 5. Limit to 4 octets
    if (split.length > 4) {
      split = split.sublist(0, 4);
    }

    // 6. smart dot insertion
    // If the last part has 3 digits and we strictly added text and there are less than 4 parts
    if (text.length > oldValue.text.length && split.length < 4) {
      if (split.last.length == 3 && !text.endsWith('.')) {
        // Check if we are editing the end
        if (newValue.selection.end == text.length) {
          text = '${split.join('.')}.';
          // reconstruct split to be safe
          split = text.split('.');
        }
      }
    } else {
      // Just join
      text = split.join('.');

      // If the original text ended with a dot (and it wasn't a double dot pruned above),
      // we should try to preserve it if valid
      if (newValue.text.endsWith('.') && !text.endsWith('.')) {
        if (split.length < 4) {
          text = '$text.';
        }
      }
    }

    // 7. Update selection to end (simplification, robust cursor is hard)
    // If we changed the text, move cursor to end is safest for this simple formatter
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
