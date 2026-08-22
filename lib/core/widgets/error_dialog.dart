import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cms/core/theme/app_colors.dart';

void showErrorDialog(BuildContext context, String title, dynamic error) {
  final fullErrorText = error.toString();
  
  // Parse clean, user-friendly message
  String cleanMessage = fullErrorText;
  if (cleanMessage.startsWith('Exception: ')) {
    cleanMessage = cleanMessage.replaceFirst('Exception: ', '');
  }
  
  // Extract main exception message if it contains "ValidationException:" or similar
  final validationMatch = RegExp(r'(?:ValidationException|ServerException):\s*([^\n]+)').firstMatch(cleanMessage);
  if (validationMatch != null) {
    cleanMessage = validationMatch.group(1)!.trim();
  }
  
  // Check for nested exception block in JSON/String format
  if (cleanMessage.contains('exception:') || cleanMessage.contains('"exception":')) {
    final excRegex = RegExp(r'"exception":\s*"([^"]+)"');
    final match = excRegex.firstMatch(cleanMessage);
    if (match != null) {
      cleanMessage = match.group(1)!;
    } else {
      final splitIndex = cleanMessage.indexOf('Errors:');
      if (splitIndex != -1) {
        cleanMessage = cleanMessage.substring(0, splitIndex).trim();
      }
    }
  }

  // Final clean up of HTML tags or JSON structures
  cleanMessage = cleanMessage
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\"', '"')
      .trim();

  if (cleanMessage.isEmpty) {
    cleanMessage = 'An unexpected error occurred.';
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 28),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cleanMessage,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: fullErrorText));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error details copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.copy, size: 16, color: Color(0xFF4A8B5F)),
          label: const Text(
            'Copy Details',
            style: TextStyle(
              color: Color(0xFF4A8B5F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}
