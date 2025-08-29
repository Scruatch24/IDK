import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    bool isError = false,
  }) {
    // Hide any existing snackbars
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Define colors and icons based on the type
    final Color backgroundColor = isError
        ? const Color(0xFFD32F2F) // A standard shade of red for errors
        : const Color(0xFF004aad); // Your primary blue color for success
    final IconData icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    // Create the SnackBar widget
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating, // Makes the snackbar float
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.all(16.0), // Margin from the screen edges
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      elevation: 4.0,
      duration: const Duration(seconds: 3),
    );

    // Show the SnackBar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}