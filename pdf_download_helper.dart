// lib/utils/pdf_download_helper.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

class PdfDownloadHelper {
  /// Tries to share a PDF using the Web Share API. If sharing is not supported,
  /// it uses an intelligent fallback based on the user's operating system.
  static Future<void> shareOrDownloadPdf({
    required String url,
    required String filename,
  }) async {
    if (!kIsWeb) return;

    try {
      // 1. Fetch the PDF data from the URL.
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch PDF: ${response.statusCode}');
      }
      final bytes = response.bodyBytes;
      final file = html.File([bytes], filename, {'type': 'application/pdf'});

      try {
        // 2. Attempt to use the Web Share API to share the actual file.
        // This is the best experience for mobile users.
        final shareData = {'files': [file]};
        await html.window.navigator.share(shareData);
      } catch (e) {
        // 3. If sharing the file fails, determine the best fallback.
        debugPrint('Web Share API for files failed: $e. Determining fallback.');

        final userAgent = html.window.navigator.userAgent.toLowerCase();
        final isIOS = userAgent.contains('iphone') || userAgent.contains('ipad') || userAgent.contains('ipod');

        if (isIOS) {
          // FIX: On iOS, blob downloads open a problematic viewer.
          // A better fallback is to open the direct URL in a new tab.
          // The user can then use the native viewer's share options, which will share a valid link.
          debugPrint('iOS detected. Falling back to opening URL in a new tab.');
          await _standardWebDownload(url, filename);
        } else {
          // For other platforms (Android, Desktop), a direct download from blob is the best fallback.
          debugPrint('Non-iOS detected. Falling back to direct download.');
          await _downloadBytes(bytes, filename);
        }
      }
    } catch (e) {
      debugPrint('Error in shareOrDownloadPdf (outer catch): $e');
      // Ultimate fallback is to try and open the URL in a new tab.
      await _standardWebDownload(url, filename);
    }
  }

  /// Helper to trigger a download from a list of bytes.
  static Future<void> _downloadBytes(Uint8List bytes, String filename) async {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  /// Standard web download that opens the file's direct URL in a new tab.
  static Future<void> _standardWebDownload(String url, String filename) async {
    final anchor = html.AnchorElement(href: url)
    // The 'download' attribute is a suggestion to the browser.
      ..setAttribute('download', filename)
    // '_blank' opens it in a new tab.
      ..setAttribute('target', '_blank')
      ..style.display = 'none';

    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
  }
}