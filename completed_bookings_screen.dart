// completed_bookings_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtor_app/data/app_data.dart';
import 'package:realtor_app/ongoing_booked_apartments.dart'; // We will reuse the card widget

class CompletedBookingsScreen extends StatefulWidget {
  const CompletedBookingsScreen({super.key});

  @override
  State<CompletedBookingsScreen> createState() => _CompletedBookingsScreenState();
}

class _CompletedBookingsScreenState extends State<CompletedBookingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  late final Stream<QuerySnapshot> _bookingsStream;

  @override
  void initState() {
    super.initState();
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _bookingsStream = firestoreService.db.collection('completedBookings').snapshots();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'დასრულებული გაქირავებები',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF004aad),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isSearchVisible = !_isSearchVisible;
                      if (!_isSearchVisible) {
                        _searchController.clear();
                      }
                    });
                  },
                  icon: Icon(
                    _isSearchVisible ? Icons.close : Icons.search,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isSearchVisible ? 'ძიების დახურვა' : 'ძიება',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSearchVisible ? Colors.red : const Color(0xFF004aad),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isSearchVisible
                      ? Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'მეპატრონე, სტუმარი, ბინის მისამართი...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF004aad)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF004aad), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _bookingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('დასრულებული ჯავშნები არ მოიძებნა.'));
                }

                final allDocs = snapshot.data!.docs;
                final query = _searchController.text.toLowerCase();
                final filteredDocs = query.isEmpty
                    ? allDocs
                    : allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final address = (data['apartmentAddress'] as String?)?.toLowerCase() ?? '';
                  final owner = (data['ownerName'] as String?)?.toLowerCase() ?? '';
                  final guest = (data['guestName'] as String?)?.toLowerCase() ?? '';
                  return address.contains(query) || owner.contains(query) || guest.contains(query);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('შედეგი ვერ მოიძებნა.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    return CompletedBookingCard(data: data); // Use the new card widget
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}