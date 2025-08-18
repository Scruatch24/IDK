// lib/history_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:intl/intl.dart';
import 'package:realtor_app/history_manager.dart';
import 'package:open_filex/open_filex.dart'; // Import for opening files/URLs
import 'package:url_launcher/url_launcher.dart'; // Import for launching URLs

class HistoryDetailScreen extends StatelessWidget {
  final DocumentHistoryItem item;

  const HistoryDetailScreen({super.key, required this.item});

  // Function to launch URL
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('ვერ მოხერხდა გაშვება $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.type == 'Contract' ? 'ხელ.-ის დეტალები' : 'ინვოისის დეტალები',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF004aad), // primaryColor from contract_form_screen.dart
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (item.generatedText != null)
            IconButton(
              icon: const Icon(Icons.copy),
              color: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: item.generatedText!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('დაკოპირებულია!')),
                );
              },
            ),
          if (item.pdfUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              color: Colors.white,
              onPressed: () async {
                if (item.pdfUrl != null) {
                  await _launchUrl(item.pdfUrl!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF-ი არ არსებობს')),
                  );
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'შექმნილია ${DateFormat('dd-MM-yyyy HH:mm').format(item.timestamp)}-ზე',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF004aad), // primaryColor
              ),
            ),
            const SizedBox(height: 20),

            // Conditional display for generated content
            if (item.type == 'Invoice' && item.generatedText != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ინვოისი:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF004aad), // primaryColor
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    width: double.infinity,
                    child: SelectableText(
                      item.generatedText!,
                      style: const TextStyle(fontSize: 15, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              )
            else if (item.type == 'Contract' && item.pdfUrl != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PDF კონტრაქტი:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF004aad), // primaryColor
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _launchUrl(item.pdfUrl!),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      width: double.infinity,
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Color(0xFF004aad)), // primaryColor
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PDF კონტრაქტი (დააჭირეთ გასახსნელად)',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF004aad),
                                decoration: TextDecoration.underline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              const Text(
                'დოკუმენტი არ არსებობს',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}