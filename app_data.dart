import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';


class BookingInfo {
  final String id;
  final DateTime checkIn;
  final DateTime checkOut;
  final String guestName;

  BookingInfo({
    required this.id,
    required this.checkIn,
    required this.checkOut,
    this.guestName = '',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'checkIn': Timestamp.fromDate(checkIn),
      'checkOut': Timestamp.fromDate(checkOut),
      'guestName': guestName,
    };
  }

  factory BookingInfo.fromFirestore(Map<String, dynamic> data) {
    return BookingInfo(
      id: data['id'] ?? '',
      checkIn: (data['checkIn'] as Timestamp).toDate(),
      checkOut: (data['checkOut'] as Timestamp).toDate(),
      guestName: data['guestName'] ?? '',
    );
  }
}


class Apartment {
  final String id;
  final String ownerId;
  final String ownerName;
  final String city;
  String geAddress;
  String ruAddress;
  String district;
  String microDistrict;
  String districtRu;
  String microDistrictRu;
  String seaView;
  String seaLine;
  String geAppRoom;
  String geAppBedroom;
  String balcony;
  String terrace;
  int successfulBookings;
  double profitLari;
  double profitUSD;
  String bathrooms;
  List<String> tags;
  int peopleCapacity;
  double dailyPrice;
  double monthlyPrice;
  bool hasAC;
  bool hasElevator;
  bool hasInternet;
  bool hasWiFi;
  bool warmWater;
  double squareMeters;
  List<String> imageUrls;
  String ownerNumber;
  String ownerNameRu;
  final String description;
  String ownerID;
  String ownerBD;
  String ownerBank;
  String ownerBankName;
  List<DateTime> bookedDates;
  List<BookingInfo> bookingInfo;
  final bool isPinned;
  final Timestamp? pinnedTimestamp; // <-- NEW: To sort by pin date

  Apartment({
    required this.id,
    required this.ownerId,
    required this.description,
    required this.ownerName,
    this.city = 'ბათუმი',
    required this.geAddress,
    required this.ruAddress,
    required this.microDistrictRu,
    required this.districtRu,
    required this.microDistrict,
    required this.district,
    required this.seaView,
    required this.seaLine,
    required this.geAppRoom,
    required this.geAppBedroom,
    required this.balcony,
    required this.terrace,
    this.successfulBookings = 0,
    this.profitLari = 0.0,
    this.profitUSD = 0.0,
    this.bathrooms = '1 სველი წერტილი',
    this.tags = const [],
    this.peopleCapacity = 1,
    this.dailyPrice = 0.0,
    this.monthlyPrice = 0.0,
    this.hasAC = false,
    this.hasElevator = false,
    this.hasInternet = false,
    this.hasWiFi = false,
    this.warmWater = false,
    this.squareMeters = 0.0,
    this.imageUrls = const [],
    this.ownerNumber = '',
    this.ownerNameRu = '',
    this.ownerID = '',
    this.ownerBD = '',
    this.ownerBank = '',
    this.ownerBankName = '',
    this.bookedDates = const [],
    this.bookingInfo = const [],
    this.isPinned = false,
    this.pinnedTimestamp, // <-- NEW
  });

  factory Apartment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final ownerName = data['ownerName'] ??
        data['ownerNameRu'] ??
        'No Owner';

    return Apartment(
      id: doc.id,
      ownerId: data['ownerId']?.toString() ?? '',
      ownerName: ownerName.toString(),
      geAddress: data['geAddress']?.toString() ?? '',
      ruAddress: data['ruAddress']?.toString() ?? '',
      district: data['district']?.toString() ?? '',
      microDistrict: data['microDistrict']?.toString() ?? '',
      districtRu: data['district']?.toString() ?? '',
      microDistrictRu: data['microDistrict']?.toString() ?? '',
      seaView: data['seaView']?.toString() ?? '',
      seaLine: data['seaLine']?.toString() ?? 'პირველი ზოლი',
      geAppRoom: data['geAppRoom']?.toString() ?? '1-ოთახიანი',
      geAppBedroom: data['geAppBedroom']?.toString() ?? '1-საძინებლიანი',
      balcony: data['balcony']?.toString() ?? 'აივნის გარეშე',
      terrace: data['terrace']?.toString() ?? 'ტერასის გარეშე',
      successfulBookings: (data['successfulBookings'] as int?) ?? 0,
      profitLari: (data['profitLari'] as num?)?.toDouble() ?? 0.0,
      profitUSD: (data['profitUSD'] as num?)?.toDouble() ?? 0.0,
      bathrooms: data['bathrooms']?.toString() ?? '1 სველი წერტილი',
      tags: List<String>.from(data['tags'] ?? []),
      peopleCapacity: (data['peopleCapacity'] as int?) ?? 1,
      dailyPrice: (data['dailyPrice'] as num?)?.toDouble() ?? 0.0,
      monthlyPrice: (data['monthlyPrice'] as num?)?.toDouble() ?? 0.0,
      hasAC: (data['hasAC'] as bool?) ?? false,
      hasElevator: (data['hasElevator'] as bool?) ?? false,
      hasInternet: (data['hasInternet'] as bool?) ?? false,
      hasWiFi: (data['hasWiFi'] as bool?) ?? false,
      warmWater: (data['warmWater'] as bool?) ?? false,
      squareMeters: (data['squareMeters'] as num?)?.toDouble() ?? 0.0,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      ownerNumber: data['ownerNumber']?.toString() ?? '',
      ownerNameRu: data['ownerNameRu']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      ownerID: data['ownerID']?.toString() ?? '',
      ownerBD: data['ownerBD']?.toString() ?? '',
      ownerBank: data['ownerBank']?.toString() ?? '',
      ownerBankName: data['ownerBankName']?.toString() ?? '',
      bookedDates: (data['bookedDates'] as List?)?.map((e) =>
          (e as Timestamp).toDate()).toList() ?? [],
      bookingInfo: (data['bookingInfo'] as List?)?.map((e) =>
          BookingInfo.fromFirestore(e as Map<String, dynamic>)).toList() ?? [],
      city: data['city']?.toString() ?? 'ბათუმი',
      isPinned: (data['isPinned'] as bool?) ?? false,
      pinnedTimestamp: data['pinnedTimestamp'] as Timestamp?, // <-- NEW
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'description': description,
      'geAddress': geAddress,
      'ruAddress': ruAddress,
      'districtRu': districtRu,
      'microDistrictRu': microDistrictRu,
      'district': district,
      'microDistrict': microDistrict,
      'seaView': seaView,
      'seaLine': seaLine,
      'geAppRoom': geAppRoom,
      'geAppBedroom': geAppBedroom,
      'balcony': balcony,
      'terrace': terrace,
      'successfulBookings': successfulBookings,
      'profitLari': profitLari,
      'profitUSD': profitUSD,
      'bathrooms': bathrooms,
      'tags': tags,
      'peopleCapacity': peopleCapacity,
      'dailyPrice': dailyPrice,
      'monthlyPrice': monthlyPrice,
      'hasAC': hasAC,
      'hasElevator': hasElevator,
      'hasInternet': hasInternet,
      'hasWiFi': hasWiFi,
      'warmWater': warmWater,
      'squareMeters': squareMeters,
      'imageUrls': imageUrls,
      'ownerNumber': ownerNumber,
      'ownerNameRu': ownerNameRu,
      'ownerID': ownerID,
      'ownerBD': ownerBD,
      'ownerBank': ownerBank,
      'ownerBankName': ownerBankName,
      'bookedDates': bookedDates.map((date) =>
          Timestamp.fromDate(date)).toList(),
      'bookingInfo': bookingInfo.map((booking) => booking.toFirestore()).toList(),
      'city': city,
      'isPinned': isPinned,
      'pinnedTimestamp': pinnedTimestamp, // <-- NEW
    };
  }

  Apartment copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? city,
    String? geAddress,
    String? ruAddress,
    String? districtRu,
    String? microDistrictRu,
    String? district,
    String? microDistrict,
    String? seaView,
    String? seaLine,
    String? geAppRoom,
    String? geAppBedroom,
    String? balcony,
    String? terrace,
    int? successfulBookings,
    double? profitLari,
    double? profitUSD,
    String? bathrooms,
    List<String>? tags,
    int? peopleCapacity,
    double? dailyPrice,
    double? monthlyPrice,
    bool? hasAC,
    bool? hasElevator,
    bool? hasInternet,
    bool? hasWiFi,
    bool? warmWater,
    double? squareMeters,
    List<String>? imageUrls,
    String? ownerNumber,
    String? ownerNameRu,
    String? description,
    String? ownerID,
    String? ownerBD,
    String? ownerBank,
    String? ownerBankName,
    List<DateTime>? bookedDates,
    List<BookingInfo>? bookingInfo,
    bool? isPinned,
    ValueGetter<Timestamp?>? pinnedTimestamp, // <-- MODIFIED to handle null
  }) {
    return Apartment(
      id: id ?? this.id,
      city: city ?? this.city,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      description: description ?? this.description,
      geAddress: geAddress ?? this.geAddress,
      ruAddress: ruAddress ?? this.ruAddress,
      microDistrictRu: microDistrictRu ?? this.microDistrictRu,
      districtRu: districtRu ?? this.districtRu,
      microDistrict: microDistrict ?? this.microDistrict,
      district: district ?? this.district,
      seaView: seaView ?? this.seaView,
      seaLine: seaLine ?? this.seaLine,
      geAppRoom: geAppRoom ?? this.geAppRoom,
      geAppBedroom: geAppBedroom ?? this.geAppBedroom,
      balcony: balcony ?? this.balcony,
      terrace: terrace ?? this.terrace,
      successfulBookings: successfulBookings ?? this.successfulBookings,
      profitLari: profitLari ?? this.profitLari,
      profitUSD: profitUSD ?? this.profitUSD,
      bathrooms: bathrooms ?? this.bathrooms,
      tags: tags ?? this.tags,
      peopleCapacity: peopleCapacity ?? this.peopleCapacity,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      hasAC: hasAC ?? this.hasAC,
      hasElevator: hasElevator ?? this.hasElevator,
      hasInternet: hasInternet ?? this.hasInternet,
      hasWiFi: hasWiFi ?? this.hasWiFi,
      warmWater: warmWater ?? this.warmWater,
      squareMeters: squareMeters ?? this.squareMeters,
      imageUrls: imageUrls ?? this.imageUrls,
      ownerNumber: ownerNumber ?? this.ownerNumber,
      ownerNameRu: ownerNameRu ?? this.ownerNameRu,
      ownerID: ownerID ?? this.ownerID,
      ownerBD: ownerBD ?? this.ownerBD,
      ownerBank: ownerBank ?? this.ownerBank,
      ownerBankName: ownerBankName ?? this.ownerBankName,
      bookedDates: bookedDates ?? this.bookedDates,
      bookingInfo: bookingInfo ?? this.bookingInfo,
      isPinned: isPinned ?? this.isPinned,
      pinnedTimestamp: pinnedTimestamp != null ? pinnedTimestamp() : this.pinnedTimestamp, // <-- MODIFIED to handle null
    );
  }
}

// ... Rest of the file remains unchanged ...
class Owner {
  final String id;
  final String name;
  final String nameRu;
  String ownerNumber;
  int totalSuccessfulBookings;
  double totalProfitLari;
  double totalProfitUSD;
  List<String> apartmentIds;
  String ownerID;  // Add this
  String ownerBD;  // Add this
  String ownerBank;  // Add this
  String ownerBankName;  // Add this

  Owner({
    required this.id,
    required this.name,
    this.nameRu = '',
    this.ownerNumber = '',
    this.totalSuccessfulBookings = 0,
    this.totalProfitLari = 0.0,
    this.totalProfitUSD = 0.0,
    this.apartmentIds = const [],
    this.ownerID = '',  // Add this with default value
    this.ownerBD = '',  // Add this with default value
    this.ownerBank = '',  // Add this with default value
    this.ownerBankName = '',  // Add this with default value
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'nameRu': nameRu,
      'ownerNumber': ownerNumber,

      'totalSuccessfulBookings': totalSuccessfulBookings,
      'totalProfitLari': totalProfitLari,
      'totalProfitUSD': totalProfitUSD,
      'apartmentIds': apartmentIds,
      'ownerID': ownerID,  // Add this
      'ownerBD': ownerBD,  // Add this
      'ownerBank': ownerBank,  // Add this
      'ownerBankName': ownerBankName,  // Add this
    };
  }

  factory Owner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Owner(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      nameRu: data['nameRu']?.toString() ?? '',
      ownerNumber: data['ownerNumber']?.toString() ?? '',
      totalSuccessfulBookings: (data['totalSuccessfulBookings'] as int?) ?? 0,
      totalProfitLari: (data['totalProfitLari'] as num?)?.toDouble() ?? 0.0,
      totalProfitUSD: (data['totalProfitUSD'] as num?)?.toDouble() ?? 0.0,
      apartmentIds: List<String>.from(data['apartmentIds'] ?? []),
      ownerID: data['ownerID']?.toString() ?? '',  // Add this
      ownerBD: data['ownerBD']?.toString() ?? '',  // Add this
      ownerBank: data['ownerBank']?.toString() ?? '',  // Add this
      ownerBankName: data['ownerBankName']?.toString() ?? '',  // Add this
    );
  }

  Owner copyWith({
    String? id,
    String? name,
    String? nameRu,
    String? ownerNumber,
    int? totalSuccessfulBookings,
    double? totalProfitLari,
    double? totalProfitUSD,
    String? ownerID,  // Add this
    String? ownerBD,  // Add this
    String? ownerBank,  // Add this
    String? ownerBankName,  // Add this
  }) {
    return Owner(
      id: id ?? this.id,
      name: name ?? this.name,
      nameRu: nameRu ?? this.nameRu,
      ownerNumber: ownerNumber ?? this.ownerNumber,
      totalSuccessfulBookings: totalSuccessfulBookings ?? this.totalSuccessfulBookings,
      totalProfitLari: totalProfitLari ?? this.totalProfitLari,
      totalProfitUSD: totalProfitUSD ?? this.totalProfitUSD,
      ownerID: ownerID ?? this.ownerID,  // Add this
      ownerBD: ownerBD ?? this.ownerBD,  // Add this
      ownerBank: ownerBank ?? this.ownerBank,  // Add this
      ownerBankName: ownerBankName ?? this.ownerBankName,  // Add this
    );
  }
}

class FirestoreService with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseFirestore get db => _db;

  // Get stream of all owners
  Stream<List<Owner>> getOwners() {
    return _db.collection('owners').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Owner.fromFirestore(doc)).toList());
  }

  // Get stream of all apartments (from main collection)
  Stream<List<Apartment>> getAllApartments() {
    return _db.collection('apartments').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Apartment.fromFirestore(doc)).toList());
  }

  // Get apartments for specific owner
  Stream<List<Apartment>> getApartmentsForOwner(String ownerId) {
    return _db.collection('apartments')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) =>
        Apartment.fromFirestore(doc)).toList());
  }

  Future<void> saveApartment(Apartment apartment) async {
    final apartmentDocId = apartment.geAddress.replaceAll(RegExp(r'[\/]'), '-');

    final exists = await _db.collection('apartments').doc(apartmentDocId).get().then((doc) => doc.exists);

    if (exists) {
      await updateApartment(apartment);
    } else {
      await createApartment(apartment);
    }
  }

  Future<Apartment?> getApartmentById(String id) async {
    final doc = await _db.collection('apartments').doc(id).get();
    return doc.exists ? Apartment.fromFirestore(doc) : null;
  }

  Future<void> createApartment(Apartment apartment) async {
    try {
      final apartmentDocId = apartment.geAddress.replaceAll(RegExp(r'[\/]'), '-');
      final mainRef = _db.collection('apartments').doc(apartmentDocId);

      await mainRef.set(apartment.toFirestore());
      await _updateOwnerDocument(apartment);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to create apartment: $e');
    }
  }

// lib/data/app_data.dart

  Future<void> completePastBookings() async {
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 1));

    debugPrint('Running scheduled task to complete bookings ending on or before $yesterday');

    final bookingsToComplete = await _db
        .collection('ongoingBookings')
        .where('endDate', isLessThanOrEqualTo: yesterday)
        .get();

    if (bookingsToComplete.docs.isEmpty) {
      debugPrint('No past bookings found to complete.');
      return;
    }

    final batch = _db.batch();

    for (final doc in bookingsToComplete.docs) {
      final bookingData = doc.data();
      final apartmentId = bookingData['apartmentId'] as String;

      final apartmentRef = _db.collection('apartments').doc(apartmentId);
      final apartmentDoc = await apartmentRef.get();

      if (!apartmentDoc.exists) {
        debugPrint('Apartment $apartmentId not found for booking ${doc.id}. This booking is orphaned and will be deleted.');
        batch.delete(doc.reference); // Clean up orphaned booking
        continue;
      }

      debugPrint('Processing booking: ${doc.id} for apartment: $apartmentId');

      // 1. Prepare data for the 'completedBookings' collection.
      final finalBookingData = {
        ...bookingData,
        'completedAt': FieldValue.serverTimestamp(),
      };
      final completedDocId = '${doc.id} (Completed)';

      // 2. Schedule deletion from 'ongoingBookings' and creation in 'completedBookings'.
      batch.delete(doc.reference);
      batch.set(_db.collection('completedBookings').doc(completedDocId), finalBookingData);

      // 3. Update Apartment and Owner stats.
      final totalBasePrice = (bookingData['totalBasePrice'] as num).toDouble();
      final days = bookingData['days'] as int;
      final ownerDocId = (bookingData['ownerNumber'] as String).isNotEmpty ? '${bookingData['ownerName']}-${bookingData['ownerNumber']}' : (bookingData['ownerName'] as String);
      final ownerRef = _db.collection('owners').doc(ownerDocId);

      final Map<String, dynamic> apartmentUpdateData = {
        'successfulBookings': FieldValue.increment(1),
      };

      if (days <= 29) { // Daily booking -> GEL
        apartmentUpdateData['profitLari'] = FieldValue.increment(totalBasePrice);
      } else { // Monthly booking -> USD
        apartmentUpdateData['profitUSD'] = FieldValue.increment(totalBasePrice);
      }
      batch.update(apartmentRef, apartmentUpdateData);

      final Map<String, dynamic> ownerUpdateData = {
        'totalSuccessfulBookings': FieldValue.increment(1),
      };
      if (days <= 29) { // Daily booking -> GEL
        ownerUpdateData['totalProfitLari'] = FieldValue.increment(totalBasePrice);
      } else { // Monthly booking -> USD
        ownerUpdateData['totalProfitUSD'] = FieldValue.increment(totalBasePrice);
      }
      batch.update(ownerRef, ownerUpdateData);

      // 4. Clean up the calendar data in the apartment document.
      final bookingId = bookingData['bookingId'] as String;
      final apartmentToUpdate = Apartment.fromFirestore(apartmentDoc);

      final updatedBookingInfo = apartmentToUpdate.bookingInfo
          .where((booking) => booking.id != bookingId)
          .toList();

      final updatedBookedDates = _recalculateBookedDates(updatedBookingInfo);

      batch.update(apartmentRef, {
        'bookingInfo': updatedBookingInfo.map((b) => b.toFirestore()).toList(),
        'bookedDates': updatedBookedDates.map((d) => Timestamp.fromDate(d)).toList(),
      });
    }

    try {
      await batch.commit();
      debugPrint('Successfully completed and moved ${bookingsToComplete.docs.length} bookings.');
      notifyListeners();
    } catch (e) {
      debugPrint('Error committing batch for booking completion: $e');
      throw Exception('Failed to complete past bookings: $e');
    }
  }

  /// Helper to recalculate booked dates based on the remaining bookingInfo list.
  List<DateTime> _recalculateBookedDates(List<BookingInfo> bookingInfo) {
    final Set<DateTime> dates = {};
    for (final booking in bookingInfo) {
      final days = booking.checkOut.difference(booking.checkIn).inDays + 1;
      for (int i = 0; i < days; i++) {
        dates.add(DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day + i));
      }
    }
    return dates.toList();
  }

  Future<void> updateApartment(Apartment apartment) async {
    try {
      final apartmentDocId = apartment.geAddress.replaceAll(RegExp(r'[\/]'), '-');
      final mainRef = _db.collection('apartments').doc(apartmentDocId);

      await mainRef.update(apartment.toFirestore());
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update apartment: $e');
    }
  }


  Future<void> deleteApartmentWithImages(Apartment apartment) async {
    debugPrint("--- [DELETION PROCESS STARTED] for apartment ID: ${apartment.id} ---");
    final batch = _db.batch();

    try {
      final String apartmentDocId = apartment.geAddress.replaceAll(RegExp(r'[\/]'), '-');
      final String ownerDocId = apartment.ownerNumber.isNotEmpty
          ? '${apartment.ownerName}-${apartment.ownerNumber}'
          : apartment.ownerName;

      debugPrint("Apartment Doc ID to be deleted: $apartmentDocId");
      debugPrint("Associated Owner Doc ID: $ownerDocId");

      // --- 1. Find all associated bookings to delete from the single source of truth ---
      final List<QuerySnapshot> bookingSnapshots = await Future.wait([
        _db.collection('ongoingBookings').where('apartmentId', isEqualTo: apartment.id).get(),
        _db.collection('completedBookings').where('apartmentId', isEqualTo: apartment.id).get(),
      ]);

      int bookingCount = 0;
      for (final snapshot in bookingSnapshots) {
        for (final doc in snapshot.docs) {
          debugPrint("Scheduling deletion for booking: ${doc.reference.path}");
          batch.delete(doc.reference); // Delete from the top-level collection
          bookingCount++;
        }
      }
      debugPrint("Found and scheduled deletion for $bookingCount total bookings.");


      // --- 2. Schedule deletion for the apartment document ---
      debugPrint("Scheduling deletion for main apartment doc: apartments/$apartmentDocId");
      batch.delete(_db.collection('apartments').doc(apartmentDocId));

      // --- 3. Schedule update for the parent owner document ---
      debugPrint("Scheduling update for owner doc: owners/$ownerDocId to remove apartment reference and decrement stats.");
      final ownerRef = _db.collection('owners').doc(ownerDocId);
      batch.update(ownerRef, {
        'apartmentIds': FieldValue.arrayRemove([apartmentDocId]),
        'totalSuccessfulBookings': FieldValue.increment(-apartment.successfulBookings),
        'totalProfitLari': FieldValue.increment(-apartment.profitLari),
        'totalProfitUSD': FieldValue.increment(-apartment.profitUSD),
      });

      // --- 4. Commit all Firestore writes ---
      debugPrint("Committing atomic batch...");
      await batch.commit();
      debugPrint("--- [BATCH COMMIT SUCCESSFUL] ---");

      // --- 5. Clean up non-transactional resources AFTER successful commit ---
      unawaited(_deleteApartmentImages(apartment));
      await _cleanUpOwnerIfEmpty(ownerDocId);

      notifyListeners();

    } catch (e) {
      debugPrint("--- [DELETION PROCESS FAILED] ---");
      debugPrint("A critical error occurred during the deletion batch commit: $e");
      throw Exception('Failed to delete apartment and its related data: $e');
    }
  }

  Future<void> _updateOwnerApartmentReferences({
    required String oldOwnerId,
    required String newOwnerId,
    required String apartmentId,
  }) async {
    try {
      final batch = _db.batch();

      // 1. Remove apartment reference from old owner
      if (oldOwnerId != newOwnerId) {
        final oldOwnerRef = _db.collection('owners').doc(oldOwnerId);

        // First check if old owner exists to avoid errors
        final oldOwnerDoc = await oldOwnerRef.get();
        if (oldOwnerDoc.exists) {
          batch.update(oldOwnerRef, {
            'apartmentIds': FieldValue.arrayRemove([apartmentId])
          });
        }
      }

      // 2. Add apartment reference to new owner
      final newOwnerRef = _db.collection('owners').doc(newOwnerId);
      final newOwnerData = {
        'apartmentIds': FieldValue.arrayUnion([apartmentId]),
        'id': newOwnerId, // Ensure ID field is set
      };

      // Check if new owner exists to decide between set/update
      final newOwnerDoc = await newOwnerRef.get();
      if (newOwnerDoc.exists) {
        batch.update(newOwnerRef, {
          'apartmentIds': FieldValue.arrayUnion([apartmentId])
        });
      } else {
        // If new owner doesn't exist, create with basic info
        // (Name and number will be updated in the main apartment update)
        batch.set(newOwnerRef, newOwnerData, SetOptions(merge: true));
      }

      await batch.commit();

      // 3. Verify and clean up old owner if needed
      if (oldOwnerId != newOwnerId) {
        await _cleanUpOwnerIfEmpty(oldOwnerId);
      }
    } catch (e) {
      debugPrint('Error updating owner references: $e');
      rethrow;
    }
  }

  Future<void> _deleteApartmentImages(Apartment apartment) async {
    try {
      // Delete individual images first
      await _deleteAllImagesInFolder(apartment.imageUrls);

      // Then try to delete the entire folder
      final folderRef = _storage.ref().child('Apartments/${apartment.geAddress.replaceAll(RegExp(r'[\/]'), '-')}');
      await _deleteFolderRecursively(folderRef);
    } catch (e) {
      debugPrint('Storage deletion error: $e');
      // Continue even if storage deletion fails
    }
  }

  Future<void> updateApartmentWithOwnerHandling({
    required Apartment originalApartment,
    required Apartment updatedApartment,
  }) async {
    try {
      final batch = _db.batch();

      // --- Determine IDs ---
      final originalDocId = originalApartment.geAddress.replaceAll(RegExp(r'[\/]'), '-');
      final updatedDocId = updatedApartment.id;
      final originalOwnerId = originalApartment.ownerNumber.isNotEmpty
          ? '${originalApartment.ownerName}-${originalApartment.ownerNumber}'
          : originalApartment.ownerName;
      final updatedOwnerId = updatedApartment.ownerNumber.isNotEmpty
          ? '${updatedApartment.ownerName}-${updatedApartment.ownerNumber}'
          : updatedApartment.ownerName;

      final bool addressChanged = originalDocId != updatedDocId;
      final bool ownerChanged = originalOwnerId != updatedOwnerId;

      // --- Perform necessary reads BEFORE scheduling writes ---
      DocumentSnapshot? originalOwnerDoc;
      if (ownerChanged) {
        // We only need to read the old owner's doc to see if it exists
        originalOwnerDoc = await _db.collection('owners').doc(originalOwnerId).get();
      }

      // --- Schedule All Writes Atomically ---

      // 1. Sync new owner's profile data (name, bank info, etc.)
      await _syncOwnerDataFromApartment(
        batch: batch,
        apartment: updatedApartment,
        ownerId: updatedOwnerId,
      );

      // 2. Migrate any ongoing bookings to reflect new owner/address
      await _migrateOrSyncBookingsOnUpdate(
        batch: batch,
        originalApartment: originalApartment,
        updatedApartment: updatedApartment,
      );

      // 3. Handle Owner References and Stats
      if (ownerChanged) {
        // Only interact with the original owner if we confirmed it exists
        if (originalOwnerDoc != null && originalOwnerDoc.exists) {
          // A. Move apartment ID from old owner to new owner
          _updateOwnerReferences( // No 'await' needed as it just adds to batch
            batch: batch,
            oldOwnerId: originalOwnerId,
            newOwnerId: updatedOwnerId,
            apartmentIdToRemove: originalDocId,
            apartmentIdToAdd: updatedDocId,
          );
          // B. Transfer financial stats from old owner to new owner
          _transferOwnerStats( // No 'await' needed
            batch: batch, // <-- FIXED: Pass the main batch
            fromOwnerId: originalOwnerId,
            toOwnerId: updatedOwnerId,
            apartment: updatedApartment,
          );
        }
      } else if (addressChanged) {
        // Owner is the same, but address changed. Update the apartment ID in the owner's list.
        final ownerRef = _db.collection('owners').doc(originalOwnerId);
        batch.update(ownerRef, {
          'apartmentIds': FieldValue.arrayRemove([originalDocId]),
        });
        batch.update(ownerRef, {
          'apartmentIds': FieldValue.arrayUnion([updatedDocId]),
        });
      }

      // 4. Handle the Apartment document itself (delete old, create new)
      if (addressChanged) {
        batch.delete(_db.collection('apartments').doc(originalDocId));
      }
      batch.set(_db.collection('apartments').doc(updatedDocId), updatedApartment.toFirestore());

      // --- Commit the entire transaction ---
      await batch.commit();
      notifyListeners();

      // --- Post-Transaction Cleanup ---
      if (ownerChanged) {
        await _cleanUpOwnerIfEmpty(originalOwnerId);
      }
    } catch (e) {
      debugPrint("A critical error occurred during the update batch commit: $e");
      throw Exception('Failed to update apartment with owner handling: $e');
    }
  }

  /// MODIFIED/FIXED: This function now correctly and efficiently updates booking documents.
  Future<void> _migrateOrSyncBookingsOnUpdate({
    required WriteBatch batch,
    required Apartment originalApartment,
    required Apartment updatedApartment,
  }) async {
    // Find all bookings linked to the ORIGINAL apartment ID.
    final bookingsSnapshot = await _db
        .collection('ongoingBookings')
        .where('apartmentId', isEqualTo: originalApartment.id)
        .get();

    if (bookingsSnapshot.docs.isEmpty) {
      return; // No bookings to update.
    }

    final updatedDocId = updatedApartment.id;

    // Iterate through each found booking and schedule an update in the batch.
    for (final doc in bookingsSnapshot.docs) {
      // Prepare a map of all fields that need to be changed.
      final Map<String, dynamic> updates = {
        'apartmentId': updatedDocId, // CRITICAL FIX: Update the foreign key.
        'apartmentAddress': updatedApartment.geAddress,
        'ownerId': updatedApartment.ownerId,
        'ownerName': updatedApartment.ownerName,
        'ownerNumber': updatedApartment.ownerNumber,
      };

      // Add the update operation to the batch.
      batch.update(doc.reference, updates);
    }
  }


  Future<String> _generateUniqueDocId({
    required CollectionReference collectionRef,
    required String baseId,
  }) async {
    var finalId = baseId;
    var counter = 2;

    while (true) {
      final docSnapshot = await collectionRef.doc(finalId).get();
      if (!docSnapshot.exists) {
        return finalId;
      }
      finalId = '$baseId($counter)';
      counter++;
    }
  }

  Future<void> _updateOwnerReferences({
    required WriteBatch batch,
    required String oldOwnerId,
    required String newOwnerId,
    required String apartmentIdToRemove, // <-- MODIFIED
    required String apartmentIdToAdd,    // <-- MODIFIED
  }) async {
    final oldOwnerRef = _db.collection('owners').doc(oldOwnerId);
    batch.update(oldOwnerRef, {
      'apartmentIds': FieldValue.arrayRemove([apartmentIdToRemove]) // <-- FIXED
    });

    final newOwnerRef = _db.collection('owners').doc(newOwnerId);
    batch.set(newOwnerRef, {
      'apartmentIds': FieldValue.arrayUnion([apartmentIdToAdd]), // <-- FIXED
      'id': newOwnerId,
    }, SetOptions(merge: true));
  }

  Future<void> _cleanUpOwnerIfEmpty(String ownerId) async {
    debugPrint("--- [Owner Cleanup Check] for owner ID: $ownerId ---");
    final ownerDocRef = _db.collection('owners').doc(ownerId);
    final ownerDoc = await ownerDocRef.get();

    if (!ownerDoc.exists) {
      debugPrint("Owner doc $ownerId no longer exists. No cleanup needed.");
      return;
    }

    final data = ownerDoc.data() as Map<String, dynamic>? ?? {};
    final apartmentIds = data['apartmentIds'] as List<dynamic>? ?? [];

    debugPrint("Owner $ownerId has ${apartmentIds.length} apartments remaining in their list.");

    if (apartmentIds.isEmpty) {
      debugPrint("Apartment ID list is empty. Deleting owner document $ownerId...");
      await ownerDocRef.delete();
      debugPrint("Owner document $ownerId deleted successfully.");
    } else {
      debugPrint("Owner document $ownerId will NOT be deleted as they have other properties.");
    }
    debugPrint("--- [Owner Cleanup Check Finished] ---");
  }


  Future<void> _transferOwnerStats({
    required WriteBatch batch, // <-- MODIFIED: Accepts the main batch
    required String fromOwnerId,
    required String toOwnerId,
    required Apartment apartment,
  }) async { // <-- MODIFIED: No longer async, as it doesn't 'await' anything
    final fromOwnerRef = _db.collection('owners').doc(fromOwnerId);
    final toOwnerRef = _db.collection('owners').doc(toOwnerId);

    // Schedule a decrement from the old owner
    batch.update(fromOwnerRef, {
      'totalSuccessfulBookings': FieldValue.increment(-apartment.successfulBookings),
      'totalProfitLari': FieldValue.increment(-apartment.profitLari),
      'totalProfitUSD': FieldValue.increment(-apartment.profitUSD),
    });

    // Schedule an increment/set for the new owner.
    // Using set with merge handles both creating a new owner and updating an existing one.
    batch.set(toOwnerRef, {
      'totalSuccessfulBookings': FieldValue.increment(apartment.successfulBookings),
      'totalProfitLari': FieldValue.increment(apartment.profitLari),
      'totalProfitUSD': FieldValue.increment(apartment.profitUSD),
      'id': toOwnerId,
      'name': apartment.ownerName,
      'nameRu': apartment.ownerNameRu,
      'ownerNumber': apartment.ownerNumber,
      // NOTE: Other owner fields like bank info are handled by _syncOwnerDataFromApartment
    }, SetOptions(merge: true));
  }

  Future<void> _deleteAllImagesInFolder(List<String> imageUrls) async {
    final storage = FirebaseStorage.instance;
    await Future.wait(imageUrls.map((url) async {
      try {
        await storage.refFromURL(url).delete();
        debugPrint('Deleted image: $url');
      } catch (e) {
        debugPrint('Error deleting image $url: $e');
      }
    }));
  }

  Future<void> updateBookedDatesWithBookingInfo({
    required String apartmentId,
    required List<DateTime> dates,
    required bool isBooking,
    BookingInfo? bookingInfo,
  }) async {
    try {
      DocumentReference apartmentDoc = _db.collection('apartments').doc(apartmentId);
      DocumentSnapshot apartmentSnapshot = await apartmentDoc.get();

      if (!apartmentSnapshot.exists) {
        final query = await _db.collection('apartments')
            .where('id', isEqualTo: apartmentId)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          throw Exception('Apartment not found');
        }

        apartmentDoc = _db.collection('apartments').doc(query.docs.first.id);
        apartmentSnapshot = await apartmentDoc.get();
      }

      final data = apartmentSnapshot.data() as Map<String, dynamic>? ?? {};

      List<DateTime> newBookedDates = [];
      final existingDates = data['bookedDates'] as List<dynamic>? ?? [];
      newBookedDates = existingDates.map((d) => (d as Timestamp).toDate()).toList();

      List<BookingInfo> newBookingInfo = [];
      final existingBookingInfo = data['bookingInfo'] as List<dynamic>? ?? [];
      newBookingInfo = existingBookingInfo
          .map((e) => BookingInfo.fromFirestore(e as Map<String, dynamic>))
          .toList();

      if (isBooking) {
        newBookedDates.addAll(dates);
        if (bookingInfo != null) {
          newBookingInfo.add(bookingInfo);
        }
      } else {
        if (bookingInfo != null) {
          newBookingInfo.removeWhere((booking) => booking.id == bookingInfo.id);

          final checkIn = DateTime(bookingInfo.checkIn.year, bookingInfo.checkIn.month, bookingInfo.checkIn.day);
          final checkOut = DateTime(bookingInfo.checkOut.year, bookingInfo.checkOut.month, bookingInfo.checkOut.day);
          final bookingDates = _getDatesInBookingRange(checkIn, checkOut);

          for (final dateToRemove in bookingDates) {
            bool isUsedByOtherBooking = false;
            for (final otherBooking in newBookingInfo) {
              final otherCheckIn = DateTime(otherBooking.checkIn.year, otherBooking.checkIn.month, otherBooking.checkIn.day);
              final otherCheckOut = DateTime(otherBooking.checkOut.year, otherBooking.checkOut.month, otherBooking.checkOut.day);

              if ((dateToRemove.isAtSameMomentAs(otherCheckIn) || dateToRemove.isAfter(otherCheckIn)) &&
                  (dateToRemove.isAtSameMomentAs(otherCheckOut) || dateToRemove.isBefore(otherCheckOut))) {
                isUsedByOtherBooking = true;
                break;
              }
            }

            if (!isUsedByOtherBooking) {
              newBookedDates.removeWhere((date) =>
              dateToRemove.year == date.year &&
                  dateToRemove.month == date.month &&
                  dateToRemove.day == date.day);
            }
          }
        } else {
          newBookedDates.removeWhere((date) =>
              dates.any((d) =>
              d.year == date.year &&
                  d.month == date.month &&
                  d.day == date.day));
        }
      }

      newBookedDates = newBookedDates.toSet().toList();

      await apartmentDoc.update({
        'bookedDates': newBookedDates.map((d) => Timestamp.fromDate(d)).toList(),
        'bookingInfo': newBookingInfo.map((booking) => booking.toFirestore()).toList(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating booked dates with booking info: $e');
      throw Exception('Failed to update booked dates: $e');
    }
  }

  List<DateTime> _getDatesInBookingRange(DateTime checkIn, DateTime checkOut) {
    final days = checkOut.difference(checkIn).inDays + 1;
    return List.generate(days, (i) => DateTime(checkIn.year, checkIn.month, checkIn.day + i));
  }


  Future<void> _deleteFolderRecursively(Reference ref) async {
    try {
      try {
        final listResult = await ref.listAll();
        await Future.wait(listResult.items.map((item) => item.delete()));
        debugPrint('Deleted all files in folder: ${ref.fullPath}');
      } catch (e) {
        debugPrint('Error listing/deleting folder contents ${ref.fullPath}: $e');
      }

      try {
        await ref.delete();
        debugPrint('Successfully deleted folder: ${ref.fullPath}');
      } catch (e) {
        debugPrint('Error deleting folder ${ref.fullPath}: $e');
      }
    } catch (e) {
      debugPrint('Complete folder deletion failed for ${ref.fullPath}: $e');
    }
  }

  Future<void> _syncOwnerDataFromApartment({
    required WriteBatch batch,
    required Apartment apartment,
    required String ownerId,
  }) async {
    final ownerRef = _db.collection('owners').doc(ownerId);
    final ownerData = {
      'id': ownerId,
      'name': apartment.ownerName,
      'nameRu': apartment.ownerNameRu,
      'ownerNumber': apartment.ownerNumber,
      'ownerID': apartment.ownerID,
      'ownerBD': apartment.ownerBD,
      'ownerBank': apartment.ownerBank,
      'ownerBankName': apartment.ownerBankName,
    };
    batch.set(ownerRef, ownerData, SetOptions(merge: true));
  }

  Future<void> _updateStatsOnBookingChange({
    required WriteBatch batch,
    required Apartment apartment,
    required double totalBasePrice,
    required int days,
    required bool isDeletion,
  }) async {
    final increment = isDeletion ? -1 : 1;
    final priceChange = isDeletion ? -totalBasePrice : totalBasePrice;

    final apartmentRef = _db.collection('apartments').doc(apartment.id);
    final Map<String, dynamic> apartmentUpdateData = {
      'successfulBookings': FieldValue.increment(increment),
    };
    if (days <= 29) {
      apartmentUpdateData['profitLari'] = FieldValue.increment(priceChange);
    } else {
      apartmentUpdateData['profitUSD'] = FieldValue.increment(priceChange);
    }
    batch.update(apartmentRef, apartmentUpdateData);

    final ownerDocId = apartment.ownerNumber.isNotEmpty
        ? '${apartment.ownerName}-${apartment.ownerNumber}'
        : apartment.ownerName;
    final ownerRef = _db.collection('owners').doc(ownerDocId);
    final Map<String, dynamic> ownerUpdateData = {
      'totalSuccessfulBookings': FieldValue.increment(increment),
    };
    if (days <= 29) {
      ownerUpdateData['totalProfitLari'] = FieldValue.increment(priceChange);
    } else {
      ownerUpdateData['totalProfitUSD'] = FieldValue.increment(priceChange);
    }
    batch.update(ownerRef, ownerUpdateData);
  }

  Future<void> _verifyFolderDeletion(Reference ref) async {
    try {
      await ref.listAll();
      debugPrint('WARNING: Folder still exists after deletion: ${ref.fullPath}');
    } catch (e) {
      if (e.toString().contains('not found')) {
        debugPrint('Successfully verified folder deletion: ${ref.fullPath}');
      } else {
        debugPrint('Error verifying folder deletion: ${ref.fullPath} - $e');
      }
    }
  }

  Future<void> deleteApartment(Apartment apartment) async {
    try {
      final apartmentDocId = apartment.geAddress.replaceAll(RegExp(r'[\/]'), '-');
      final mainRef = _db.collection('apartments').doc(apartmentDocId);

      await mainRef.delete();
      await _cleanUpOwnerDocument(apartment);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete apartment: $e');
    }
  }

  Future<void> _cleanUpOwnerDocument(Apartment apartment) async {
    final ownerId = apartment.ownerNumber.isNotEmpty
        ? '${apartment.ownerName}-${apartment.ownerNumber}'
        : apartment.ownerName;

    final ownerDocRef = _db.collection('owners').doc(ownerId);
    final ownerDoc = await ownerDocRef.get();

    if (ownerDoc.exists) {
      final data = ownerDoc.data() as Map<String, dynamic>? ?? {};
      final apartmentIds = (data['apartmentIds'] as List<dynamic>? ?? []).cast<String>();

      final apartmentDocId = apartment.geAddress.replaceAll(RegExp(r'[\/]'), '-');
      apartmentIds.remove(apartmentDocId);

      if (apartmentIds.isEmpty) {
        await ownerDocRef.delete();
      } else {
        await ownerDocRef.update({'apartmentIds': apartmentIds});
      }
    }
  }

  void _clearImageCache(List<String> imageUrls) {
    for (final url in imageUrls) {
      final provider = NetworkImage(url);
      provider.evict().catchError((_) {});
    }
  }

  Future<Apartment?> getApartmentByAddress(String address) async {
    try {
      final doc = await _db.collection('apartments').doc(address).get();
      return doc.exists ? Apartment.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Failed to get apartment: $e');
    }
  }

  Stream<List<Apartment>> searchApartments({
    String? seaLine,
    int? minRooms,
    double? maxPrice,
    List<String>? tags,
  }) {
    Query query = _db.collection('apartments');

    if (seaLine != null) {
      query = query.where('seaLine', isEqualTo: seaLine);
    }
    if (minRooms != null) {
      query = query.where('geAppRoom', isGreaterThanOrEqualTo: '$minRooms-ოთახიანი');
    }
    if (maxPrice != null) {
      query = query.where('dailyPrice', isLessThanOrEqualTo: maxPrice);
    }
    if (tags != null && tags.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tags);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Apartment.fromFirestore(doc)).toList());
  }

  Future<void> updateOwnerStats({
    required String ownerName,
    required String ownerNumber,
    required double profitLari,
    required double profitUSD,
  }) async {
    try {
      final ownerDocId = ownerNumber.isNotEmpty
          ? '$ownerName-$ownerNumber'
          : ownerName;

      await _db.collection('owners').doc(ownerDocId).update({
        'totalSuccessfulBookings': FieldValue.increment(1),
        'totalProfitLari': FieldValue.increment(profitLari),
        'totalProfitUSD': FieldValue.increment(profitUSD),
      });
    } catch (e) {
      throw Exception('Failed to update owner stats: $e');
    }
  }

  Future<void> _updateOwnerDocument(Apartment apartment) async {
    final ownerId = apartment.ownerNumber.isNotEmpty
        ? '${apartment.ownerName}-${apartment.ownerNumber}'
        : apartment.ownerName;
    final apartmentId = apartment.geAddress.replaceAll(RegExp(r'[\/]'), '-');

    final ownerRef = _db.collection('owners').doc(ownerId);
    final ownerDoc = await ownerRef.get();

    final ownerData = {
      'id': ownerId,
      'name': apartment.ownerName,
      'nameRu': apartment.ownerNameRu,
      'ownerNumber': apartment.ownerNumber,
      'apartmentIds': FieldValue.arrayUnion([apartmentId]),
      'ownerID': apartment.ownerID,
      'ownerBD': apartment.ownerBD,
      'ownerBank': apartment.ownerBank,
      'ownerBankName': apartment.ownerBankName,
    };

    if (!ownerDoc.exists) {
      ownerData.addAll({
        'totalSuccessfulBookings': apartment.successfulBookings,
        'totalProfitLari': apartment.profitLari,
        'totalProfitUSD': apartment.profitUSD,
      });
    }

    await ownerRef.set(ownerData, SetOptions(merge: true));
  }

  Future<void> addOngoingBooking({
    required Apartment apartment,
    required Map<String, dynamic> bookingData,
  }) async {
    final batch = _db.batch();

    try {
      final startDate = bookingData['startDate'] as DateTime;
      final guestName = bookingData['guestName'] as String? ?? '';

      // --- 1. Generate unique Document ID ---
      final cleanAddress = apartment.geAddress.replaceAll(RegExp(r'[\/]'), '-');
      final cleanGuestName = guestName.isNotEmpty ? guestName.replaceAll(RegExp(r'[\s\/]'), '_') : 'Guest';
      final docId = await _generateUniqueDocId(
        collectionRef: _db.collection('ongoingBookings'),
        baseId: '$cleanAddress-$cleanGuestName',
      );

      // --- 2. Prepare booking data ---
      final bookingId = '${apartment.id}_${startDate.millisecondsSinceEpoch}';
      final bookingInfo = BookingInfo(
        id: bookingId,
        checkIn: startDate,
        checkOut: (bookingData['endDate'] as DateTime),
        guestName: guestName,
      );
      final finalBookingData = {
        ...bookingData,
        'bookingId': bookingId,
        'docId': docId, // Store its own document ID for easy reference
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(bookingData['endDate'] as DateTime),
        'createdAt': FieldValue.serverTimestamp(),
        'apartmentId': apartment.id,
        'apartmentAddress': apartment.geAddress,
        'ownerName': apartment.ownerName,
        'ownerNumber': apartment.ownerNumber,
      };

      // --- 3. Add booking document write to the batch ---
      batch.set(_db.collection('ongoingBookings').doc(docId), finalBookingData);

      // --- 4. Add calendar update to the batch ---
      final apartmentRef = _db.collection('apartments').doc(apartment.id);
      final dates = _getDatesInBookingRange(startDate, bookingData['endDate'] as DateTime);
      final currentApartment = await getApartmentById(apartment.id);
      final newBookingInfo = [...(currentApartment?.bookingInfo ?? []), bookingInfo];
      final newBookedDates = (currentApartment?.bookedDates.toSet() ?? <DateTime>{})
        ..addAll(dates);

      batch.update(apartmentRef, {
        'bookedDates': newBookedDates.map((d) => Timestamp.fromDate(d)).toList(),
        'bookingInfo': newBookingInfo.map((b) => b.toFirestore()).toList(),
      });

      // --- 5. Add stats update to the batch ---
      _updateStatsOnBookingChange(
        batch: batch,
        apartment: apartment,
        totalBasePrice: (bookingData['totalBasePrice'] as double),
        days: (bookingData['days'] as int),
        isDeletion: false,
      );

      // --- 6. Commit all changes at once ---
      await batch.commit();

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding ongoing booking: $e');
      throw Exception('Failed to create ongoing booking: $e');
    }
  }

  Future<void> removeBookingById({
    required String apartmentId,
    required String bookingId,
  }) async {
    try {
      final apartmentDoc = await _db.collection('apartments').doc(apartmentId).get();
      if (!apartmentDoc.exists) throw Exception('Apartment not found');

      final data = apartmentDoc.data() as Map<String, dynamic>? ?? {};
      final existingBookingInfo = data['bookingInfo'] as List<dynamic>? ?? [];
      final bookingInfoList = existingBookingInfo
          .map((e) => BookingInfo.fromFirestore(e as Map<String, dynamic>))
          .toList();

      final bookingToRemove = bookingInfoList.firstWhere(
            (booking) => booking.id == bookingId,
        orElse: () => throw Exception('Booking not found'),
      );

      final dates = _getDatesInBookingRange(bookingToRemove.checkIn, bookingToRemove.checkOut);

      await updateBookedDatesWithBookingInfo(
        apartmentId: apartmentId,
        dates: dates,
        isBooking: false,
        bookingInfo: bookingToRemove,
      );

    } catch (e) {
      debugPrint('Error removing booking: $e');
      throw Exception('Failed to remove booking: $e');
    }
  }


  Future<Map<String, dynamic>?> getOngoingBookingByBookingId(String bookingId) async {
    final querySnapshot = await _db
        .collection('ongoingBookings')
        .where('bookingId', isEqualTo: bookingId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      return {...doc.data(), 'docId': doc.id};
    }
    return null;
  }


  Future<void> updateOngoingBooking({
    required Map<String, dynamic> initialData,
    required Map<String, dynamic> updatedData,
  }) async {
    final oldGuestName = initialData['guestName'] as String? ?? '';
    final newGuestName = updatedData['guestName'] as String? ?? '';

    // If guest name hasn't changed, do a simple update.
    if (oldGuestName == newGuestName) {
      try {
        final docId = initialData['docId'] as String;
        await _db.collection('ongoingBookings').doc(docId).update(updatedData);
        notifyListeners();
      } catch (e) {
        debugPrint('Error updating ongoing booking fields: $e');
        throw Exception('Failed to update booking fields: $e');
      }
      return;
    }

    // If guest name HAS changed, we must migrate the document to a new ID.
    try {
      final batch = _db.batch();
      final oldDocId = initialData['docId'] as String;

      // 1. Generate a NEW unique ID based on the new guest name.
      final cleanAddress = (initialData['apartmentAddress'] as String).replaceAll(RegExp(r'[\/]'), '-');
      final cleanNewGuestName = newGuestName.isNotEmpty ? newGuestName.replaceAll(RegExp(r'[\s\/]'), '_') : 'Guest';
      final newDocId = await _generateUniqueDocId(
          collectionRef: _db.collection('ongoingBookings'),
          baseId: '$cleanAddress-$cleanNewGuestName');

      // 2. Prepare the final data for the new document.
      final finalUpdatedData = {
        ...initialData,
        ...updatedData,
        'docId': newDocId, // Update the internal docId reference
      };

      // 3. Schedule the deletion of the old document and creation of the new one.
      batch.delete(_db.collection('ongoingBookings').doc(oldDocId));
      batch.set(_db.collection('ongoingBookings').doc(newDocId), finalUpdatedData);

      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Error migrating ongoing booking: $e');
      throw Exception('Failed to migrate booking: $e');
    }
  }

  Future<void> deleteOngoingBooking({
    required Map<String, dynamic> bookingData,
  }) async {
    final batch = _db.batch();

    try {
      final docId = bookingData['docId'] as String?;
      final apartmentId = bookingData['apartmentId'] as String;
      final bookingId = bookingData['bookingId'] as String;

      if (docId == null) {
        throw Exception('Booking data is missing required document ID for deletion.');
      }

      // --- 1. Schedule DELETE for the single booking document ---
      batch.delete(_db.collection('ongoingBookings').doc(docId));

      // --- 2. Attempt to update the associated Apartment document ---
      final apartment = await getApartmentById(apartmentId);
      if (apartment != null) {
        // Update stats
        _updateStatsOnBookingChange(
          batch: batch,
          apartment: apartment,
          totalBasePrice: (bookingData['totalBasePrice'] as num).toDouble(),
          days: (bookingData['days'] as int),
          isDeletion: true,
        );

        // Update calendar
        final updatedBookingInfo = apartment.bookingInfo.where((b) => b.id != bookingId).toList();
        final updatedBookedDates = _recalculateBookedDates(updatedBookingInfo);

        batch.update(_db.collection('apartments').doc(apartment.id), {
          'bookingInfo': updatedBookingInfo.map((b) => b.toFirestore()).toList(),
          'bookedDates': updatedBookedDates.map((d) => Timestamp.fromDate(d)).toList(),
        });
      } else {
        debugPrint('Warning: Could not find apartment [$apartmentId] to update calendar during booking deletion.');
      }

      // --- 3. Commit all batched changes ---
      await batch.commit();
      notifyListeners();

    } catch (e) {
      debugPrint('Error deleting ongoing booking: $e');
      throw Exception('Failed to delete booking: $e');
    }
  }

  Future<void> updateBookedDates({
    required String apartmentId,
    required List<DateTime> dates,
    required bool isBooking,
  }) async {
    try {
      DocumentReference apartmentDoc = _db.collection('apartments').doc(apartmentId);
      DocumentSnapshot apartmentSnapshot = await apartmentDoc.get();

      if (!apartmentSnapshot.exists) {
        final query = await _db.collection('apartments')
            .where('id', isEqualTo: apartmentId)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          throw Exception('Apartment not found');
        }

        apartmentDoc = _db.collection('apartments').doc(query.docs.first.id);
        apartmentSnapshot = await apartmentDoc.get();
      }

      List<DateTime> newBookedDates = [];
      final existingDates = (apartmentSnapshot.data() as Map<String, dynamic>?)?['bookedDates'] as List<dynamic>? ?? [];

      newBookedDates = existingDates
          .map((d) => (d as Timestamp).toDate())
          .toList();

      if (isBooking) {
        newBookedDates.addAll(dates);
      } else {
        newBookedDates.removeWhere((date) =>
            dates.any((d) =>
            d.year == date.year &&
                d.month == date.month &&
                d.day == date.day));
      }

      newBookedDates = newBookedDates.toSet().toList();

      await apartmentDoc.update({
        'bookedDates': newBookedDates.map((d) => Timestamp.fromDate(d)).toList(),
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating booked dates: $e');
      throw Exception('Failed to update booked dates: $e');
    }
  }
}