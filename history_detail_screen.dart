// lib/history_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:intl/intl.dart';
import 'package:realtor_app/history_manager.dart';
import 'package:url_launcher/url_launcher.dart'; // Import for launching URLs
import '../utils/custom_snackbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:realtor_app/utils/pdf_download_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:realtor_app/contract_form_screen.dart';
import 'package:realtor_app/invoice_generator_screen.dart'; // <-- IMPORT THE INVOICE SCREEN

class HistoryDetailScreen extends StatefulWidget {
  final DocumentHistoryItem item;

  const HistoryDetailScreen({super.key, required this.item});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  // Function to share or open PDF
  Future<void> _shareOrOpenPdf(String url) async {
    try {
      if (kIsWeb) {
        String filename;
        final invalidChars = RegExp(r'[\\/*?:"<>|]');

        if (widget.item.type == 'Contract') {
          final parts = widget.item.id.split(' - ');
          final names = parts.take(2).join(' - ').replaceAll(invalidChars, '_');
          filename = 'ხელშეკრულება - $names.pdf'; // Use Georgian naming format
        } else {
          final name = widget.item.id.split(' - ').first.replaceAll(invalidChars, '_');
          filename = 'ინვოისი - $name.pdf'; // Use Georgian naming for invoices
        }

        // Use the helper which handles both sharing and downloading
        await PdfDownloadHelper.shareOrDownloadPdf(url: url, filename: filename);
      } else {
        // For native iOS/Android, url_launcher remains the correct tool.
        final uri = Uri.parse(url);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          throw Exception('Could not launch $url');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'ფაილის გახსნა/გაზიარება ვერ მოხერხდა',
          isError: true,
        );
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text(
            'წაშლის დადასტურება',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF004aad),
            ),
          ),
          content: const Text('დარწმუნებული ხართ, რომ გსურთ ამ ჩანაწერის წაშლა?'),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: <Widget>[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF004aad),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('გაუქმება'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('წაშლა'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _deleteItem();
    }
  }

  void _deleteItem() async {
    try {
      await DocumentHistoryManager.deleteHistoryItem(widget.item.id, widget.item.type);

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'ჩანაწერი წარმატებით წაიშალა',
        );
        Navigator.of(context).pop(); // Go back to the list screen
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'წაშლა ვერ მოხერხდა: $e',
          isError: true,
        );
      }
    }
  }

  // --- HELPER WIDGET FOR ACTION BUTTONS ---
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF004aad),
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item.type == 'Contract' ? 'ხელ.-ის დეტალები' : 'ინვოისის დეტალები',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF004aad), // primaryColor
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.item.generatedText != null)
            IconButton(
              icon: const Icon(CupertinoIcons.doc_on_doc),
              color: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.item.generatedText!));
                CustomSnackBar.show(
                  context: context,
                  message: 'დაკოპირებულია!',
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make children stretch
          children: [
            Text(
              'შექმნილია ${DateFormat('dd-MM-yyyy HH:mm').format(widget.item.timestamp)}-ზე',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF004aad),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // --- REFILL BUTTON FOR CONTRACT ---
            if (widget.item.type == 'Contract') ...[
              _buildActionButton(
                icon: Icons.edit_document,
                label: 'ინფორმაციის ხელახლა შევსება',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContractFormScreen(
                        prefilledData: widget.item.placeholders,
                        showVerificationPopup: true,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // --- NEW: REFILL BUTTON FOR INVOICE ---
            if (widget.item.type == 'Invoice') ...[
              _buildActionButton(
                icon: Icons.edit_document,
                label: 'ინფორმაციის ხელახლა შევსება',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InvoiceGeneratorScreen(
                        prefilledData: widget.item.placeholders,
                        showVerificationPopup: true,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            if (widget.item.type == 'Invoice' && widget.item.generatedText != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ინვოისი:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF004aad),
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
                      widget.item.generatedText!,
                      style: const TextStyle(fontSize: 15, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              )
            else if (widget.item.type == 'Contract' && widget.item.pdfUrl != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PDF ხელშეკრულება:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF004aad),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _shareOrOpenPdf(widget.item.pdfUrl!),
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
                          const Icon(Icons.assignment, color: Color(0xFF004aad)),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'PDF-ის გახსნა / გაზიარება',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF004aad),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.open_in_new, color: Colors.grey),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showDeleteConfirmationDialog,
        backgroundColor: Colors.red.shade600,
        tooltip: 'ჩანაწერის წაშლა',
        shape: const CircleBorder(),
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
    );
  }
}