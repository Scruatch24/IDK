// ongoing_booked_apartments.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtor_app/data/app_data.dart';

class OngoingBookedApartmentsScreen extends StatefulWidget {
  const OngoingBookedApartmentsScreen({super.key});

  @override
  State<OngoingBookedApartmentsScreen> createState() => _OngoingBookedApartmentsScreenState();
}

class _OngoingBookedApartmentsScreenState extends State<OngoingBookedApartmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ongoing Bookings'),
        backgroundColor: const Color(0xFF004aad),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.db.collection('ongoingBookings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No ongoing bookings found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final booking = snapshot.data!.docs[index];
              final data = booking.data() as Map<String, dynamic>;
              final startDate = (data['startDate'] as Timestamp).toDate();
              final endDate = (data['endDate'] as Timestamp).toDate();
              final days = data['days'] as int;
              final months = data['months'] as double;
              final totalBasePrice = data['totalBasePrice'] as double;
              final pricingOnTop = data['pricingOnTop'] as double;
              final totalProfit = data['totalProfit'] as double;
              final profitLeft = data['profitLeft'] as double? ?? 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF004aad), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['apartmentAddress'] ?? 'No Address',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Owner: ${data['ownerName']} (${data['ownerNumber']})',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${DateFormat('dd/MM/yy').format(startDate)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text('to'),
                              Text(
                                '${DateFormat('dd/MM/yy').format(endDate)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${days} days (${months.toStringAsFixed(1)} months)',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${data['apartmentId']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildBookingDetailRow(
                        'Base Price:',
                        '${totalBasePrice.toStringAsFixed(0)} ${days < 30 ? '₾' : '\$'}',
                      ),
                      // In the ListView.builder itemBuilder, add this row:
                      _buildBookingDetailRow(
                        'Booking Price:',
                        '${data['bookingPrice']?.toStringAsFixed(0) ?? totalBasePrice.toStringAsFixed(0)} ${days < 30 ? '₾' : '\$'}',
                      ),
                      _buildBookingDetailRow(
                        'Pricing on Top:',
                        '${pricingOnTop.toStringAsFixed(0)} ${days < 30 ? '₾/day' : '\$/month'}',
                      ),
                      _buildBookingDetailRow(
                        'Total Profit:',
                        '${totalProfit.toStringAsFixed(0)} ${days < 30 ? '₾' : '\$'}',
                        isBold: true,
                        color: Colors.green,
                      ),
                      if (profitLeft > 0)
                        _buildBookingDetailRow(
                          'Profit Left:',
                          '${profitLeft.toStringAsFixed(0)} ${days < 30 ? '₾' : '\$'}',
                          color: Colors.orange,
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}