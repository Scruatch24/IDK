// lib/history_manager.dart
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class DocumentHistoryItem {
  final String id;
  final String type;
  final String? generatedText;
  final String? pdfUrl;
  final String? textFileUrl;
  final DateTime timestamp;
  final Map<String, dynamic> placeholders;

  DocumentHistoryItem({
    this.id = '',
    required this.type,
    this.generatedText,
    this.pdfUrl,
    this.textFileUrl,
    required this.timestamp,
    required this.placeholders,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'generatedText': generatedText,
      'pdfUrl': pdfUrl,
      'textFileUrl': textFileUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'placeholders': placeholders,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory DocumentHistoryItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DocumentHistoryItem(
      id: doc.id,
      type: data['type'] ?? 'Unknown',
      generatedText: data['generatedText'],
      pdfUrl: data['pdfUrl'],
      textFileUrl: data['textFileUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      placeholders: data['placeholders'] as Map<String, dynamic>? ?? {},
    );
  }

  String get formattedTimestamp => DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
}

class DocumentHistoryManager {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> _getCurrentUserUid() async {
    User? user = _auth.currentUser;
    if (user == null) {
      try {
        UserCredential userCredential = await _auth.signInAnonymously();
        user = userCredential.user;
        print("Signed in anonymously with UID: ${user?.uid}");
      } catch (e) {
        print("Error signing in anonymously: $e");
        return null;
      }
    }
    return user?.uid;
  }

  static Future<Map<String, String>?> uploadContractFiles({
    required Uint8List pdfBytes,
    required String textContent, // textContent is no longer used but kept for signature consistency
    required String geNameGive,
    required String geNameTake,
  }) async {
    String? uid = await _getCurrentUserUid();
    if (uid == null) return null;

    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final folderName = '$geNameGive - $geNameTake - $timestamp';
    final basePath = 'Contracts/$uid/$geNameGive/$folderName';

    try {
      // Upload PDF
      final pdfPath = '$basePath/contract.pdf';
      final pdfUploadTask = _storage.ref().child(pdfPath).putData(pdfBytes);
      final pdfSnapshot = await pdfUploadTask;
      final pdfUrl = await pdfSnapshot.ref.getDownloadURL();

      // --- The TXT file upload has been removed. ---

      return {
        'pdfUrl': pdfUrl,
        'storagePath': basePath,
      };
    } catch (e) {
      print("Error uploading contract files: $e");
      return null;
    }
  }

  static Future<String?> uploadInvoiceFiles({
    required File pdfFile,
    required String textContent,
    required String address,
  }) async {
    String? uid = await _getCurrentUserUid();
    if (uid == null) return null;

    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final baseName = '$address - $timestamp';

    try {
      // Upload PDF
      final pdfPath = 'Invoices/$uid/$baseName.pdf';
      final pdfUploadTask = _storage.ref().child(pdfPath).putFile(pdfFile);
      final pdfSnapshot = await pdfUploadTask;
      final pdfUrl = await pdfSnapshot.ref.getDownloadURL();

      // Upload TXT
      final txtPath = 'Invoices/$uid/$baseName.txt';
      final txtData = Uint8List.fromList(utf8.encode(textContent));
      final txtUploadTask = _storage.ref().child(txtPath).putData(txtData);
      final txtSnapshot = await txtUploadTask;
      final txtUrl = await txtSnapshot.ref.getDownloadURL();

      return txtUrl;
    } catch (e) {
      print("Error uploading invoice files: $e");
      return null;
    }
  }

  static Future<void> addHistoryItem(DocumentHistoryItem item) async {
    String? uid = await _getCurrentUserUid();
    if (uid == null) return;

    String collectionPath;
    String documentName;
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(item.timestamp);

    if (item.type == 'Invoice') {
      collectionPath = 'invoices_history';
      final isGeorgian = item.placeholders['isGeorgian'] == true;
      final address = isGeorgian
          ? item.placeholders['Apartment Address (GE)']
          : item.placeholders['Apartment Address (RU)'];
      documentName = '$address - $timestamp';
    } else if (item.type == 'Contract') {
      collectionPath = 'contracts_history';

      // --- THIS IS THE FIX ---
      // The keys are updated to match what is being saved in contract_form_screen.dart
      final geNameGive = (item.placeholders['ownerNameGe'] as String? ?? 'UnknownOwner').replaceAll('/', '_');
      final geNameTake = (item.placeholders['guestNameGe'] as String? ?? 'UnknownGuest').replaceAll('/', '_');
      // --- END OF FIX ---

      documentName = '$geNameGive - $geNameTake - $timestamp';
    } else {
      print("Error: Unknown document type.");
      return;
    }

    try {
      await _db.collection('generated')
          .doc('contracts and invoices')
          .collection(collectionPath)
          .doc(documentName)
          .set(item.toFirestore());
    } catch (e) {
      print("Error adding history item: $e");
    }
  }

  // THIS IS THE EXISTING METHOD that returns a Future
  static Future<List<DocumentHistoryItem>> getHistory(String type) async {
    String? uid = await _getCurrentUserUid();
    if (uid == null) return [];

    String collectionPath = type == 'Invoice'
        ? 'invoices_history'
        : 'contracts_history';

    try {
      QuerySnapshot snapshot = await _db
          .collection('generated')
          .doc('contracts and invoices')
          .collection(collectionPath)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => DocumentHistoryItem.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error getting history: $e");
      return [];
    }
  }

  // --- ADD THIS NEW METHOD to provide a real-time stream ---
  static Stream<List<DocumentHistoryItem>> getHistoryStream(String type) {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      // Return an empty stream if the user is somehow not logged in
      return Stream.value([]);
    }

    String collectionPath = type == 'Invoice'
        ? 'invoices_history'
        : 'contracts_history';

    try {
      return _db
          .collection('generated')
          .doc('contracts and invoices')
          .collection(collectionPath)
          .orderBy('createdAt', descending: true)
          .snapshots() // Use snapshots() instead of get() for real-time updates
          .map((snapshot) => snapshot.docs
          .map((doc) => DocumentHistoryItem.fromFirestore(doc))
          .toList());
    } catch (e) {
      print("Error getting history stream: $e");
      return Stream.value([]);
    }
  }

  /// Deletes a single history item and its associated files from Firebase.
  static Future<void> deleteHistoryItem(String id, String type) async {
    String? uid = await _getCurrentUserUid();
    if (uid == null) return;

    String collectionPath = type == 'Invoice'
        ? 'invoices_history'
        : 'contracts_history';

    try {
      // Get the reference to the document to be deleted
      DocumentReference docRef = _db
          .collection('generated')
          .doc('contracts and invoices')
          .collection(collectionPath)
          .doc(id);

      // Get the document to access its data before deleting
      DocumentSnapshot docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        print("Error: Document with ID $id not found.");
        return;
      }

      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

      // Concurrently delete associated files from Firebase Storage
      List<Future<void>> deleteFutures = [];
      if (data['pdfUrl'] != null) {
        try {
          deleteFutures.add(_storage.refFromURL(data['pdfUrl']).delete());
        } catch (e) {
          print("Error deleting PDF file: $e");
        }
      }

      if (data['textFileUrl'] != null) {
        try {
          deleteFutures.add(_storage.refFromURL(data['textFileUrl']).delete());
        } catch (e) {
          print("Error deleting text file: $e");
        }
      }

      await Future.wait(deleteFutures);

      // Finally, delete the Firestore document
      await docRef.delete();
    } catch (e) {
      print("Error deleting history item: $e");
      throw Exception('Failed to delete history item.');
    }
  }

  static Future<void> clearHistory(String type) async {
    String? uid = await _getCurrentUserUid();
    if (uid == null) return;

    String collectionPath = type == 'Invoice'
        ? 'invoices_history'
        : 'contracts_history';

    try {
      QuerySnapshot snapshot = await _db
          .collection('generated')
          .doc('contracts and invoices')
          .collection(collectionPath)
          .get();

      WriteBatch batch = _db.batch();
      List<Future<void>> deleteFutures = [];

      for (DocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['pdfUrl'] != null) {
          deleteFutures.add(_storage.refFromURL(data['pdfUrl']).delete());
        }

        if (data['textFileUrl'] != null) {
          deleteFutures.add(_storage.refFromURL(data['textFileUrl']).delete());
        }
      }

      await batch.commit();
      await Future.wait(deleteFutures);
    } catch (e) {
      print("Error clearing history: $e");
    }
  }
}