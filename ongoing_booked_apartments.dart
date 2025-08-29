// ongoing_booked_apartments.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realtor_app/data/app_data.dart';
import 'package:realtor_app/completed_bookings_screen.dart';

class OngoingBookedApartmentsScreen extends StatefulWidget {
  const OngoingBookedApartmentsScreen({super.key});

  @override
  State<OngoingBookedApartmentsScreen> createState() =>
      _OngoingBookedApartmentsScreenState();
}

class _OngoingBookedApartmentsScreenState
    extends State<OngoingBookedApartmentsScreen> {
  // --- STATE FOR SEARCH ---
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  // --- STREAM INITIALIZATION ---
  late final Stream<QuerySnapshot> _bookingsStream;

  // --- RESTORED: LOGIC FOR HOURLY CLEANUP ---
  // Static variable to persist across screen instances within a single app session
  static DateTime? _lastCleanupCheck;

  void _runHourlyCleanup() {
    final now = DateTime.now();

    // Check if it's the first time or if at least 1 hour has passed
    if (_lastCleanupCheck == null ||
        now.difference(_lastCleanupCheck!).inHours >= 1) {
      debugPrint('Hourly check: Running completePastBookings...');

      // Call the function, but don't wait for it to finish.
      // Let it run in the background so it doesn't block the UI.
      final firestoreService =
      Provider.of<FirestoreService>(context, listen: false);
      firestoreService.completePastBookings();

      // Update the timestamp
      _lastCleanupCheck = now;
    } else {
      debugPrint('Hourly check: Less than an hour has passed. Skipping.');
    }
  }
  // --- END OF RESTORED LOGIC ---

  @override
  void initState() {
    super.initState();
    // --- MODIFIED: CALL THE CLEANUP FUNCTION HERE ---
    _runHourlyCleanup();
    // -----------------------------------------------

    // Initialize the stream once to prevent re-fetching on setState
    final firestoreService =
    Provider.of<FirestoreService>(context, listen: false);
    _bookingsStream =
        firestoreService.db.collection('ongoingBookings').snapshots();

    // Add listener to rebuild the list on text change
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
          'მიმდინარე გაქირავებები',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF004aad),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CompletedBookingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- SEARCH UI ---
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _isSearchVisible ? Colors.red : const Color(0xFF004aad),
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
                        prefixIcon: const Icon(Icons.search,
                            color: Color(0xFF004aad)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                          BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF004aad), width: 2),
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10),
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
              stream: _bookingsStream, // Use the initialized stream
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('მიმდინარე ჯავშნები არ მოიძებნა.'));
                }

                // --- FILTERING LOGIC ---
                final allDocs = snapshot.data!.docs;
                final query = _searchController.text.toLowerCase();
                final filteredDocs = query.isEmpty
                    ? allDocs
                    : allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final address =
                      (data['apartmentAddress'] as String?)?.toLowerCase() ??
                          '';
                  final owner =
                      (data['ownerName'] as String?)?.toLowerCase() ?? '';
                  final guest =
                      (data['guestName'] as String?)?.toLowerCase() ?? '';
                  return address.contains(query) ||
                      owner.contains(query) ||
                      guest.contains(query);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('შედეგი ვერ მოიძებნა.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                    filteredDocs[index].data() as Map<String, dynamic>;
                    return OngoingBookingCard(data: data);
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

/// MODIFIED: Converted to a StatefulWidget to manage the expand/collapse state.
class OngoingBookingCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const OngoingBookingCard({super.key, required this.data});

  @override
  State<OngoingBookingCard> createState() => _OngoingBookingCardState();
}

class _OngoingBookingCardState extends State<OngoingBookingCard> {
  bool _isExpanded = false;

  String _formatGeorgianDate(DateTime date) {
    const georgianMonths = [
      'იან', 'თებ', 'მარ', 'აპრ', 'მაი', 'ივნ',
      'ივლ', 'აგვ', 'სექ', 'ოქტ', 'ნოე', 'დეკ'
    ];
    return '${date.day.toString().padLeft(2, '0')}/${georgianMonths[date.month - 1]}/${date.year}';
  }

  String _getDurationDisplay(int days, double months) {
    if (days <= 29) {
      return '$days ღამე';
    } else {
      return '${months.toStringAsFixed(months.truncateToDouble() == months ? 0 : 1)} თვე';
    }
  }

  String _getPricePerUnitDisplay(
      int days, double totalBasePrice, double months) {
    if (days <= 29) {
      if (days == 0) return '0₾/დღე';
      final dailyPrice = totalBasePrice / days;
      return '${dailyPrice.toStringAsFixed(0)}₾/დღე';
    } else {
      if (months == 0) return '\$0/თვე';
      final monthlyPrice = totalBasePrice / months;
      return '\$${monthlyPrice.toStringAsFixed(0)}/თვე';
    }
  }

  Widget _buildReadOnlyField(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 15,
                color: valueColor ?? Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MODIFIED: Added separate color properties for label and value
  Widget _buildPricingRow(String label, String value,
      {bool isBold = false,
        Color? labelColor,
        Color? valueColor,
        double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: labelColor ?? Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Extracted the collapsible content into its own builder method for clarity.
  Widget _buildCollapsibleContent() {
    final data = widget.data;
    // Extracting data with defaults
    final days = data['days'] as int? ?? 0;
    final months = data['months'] as double? ?? 0.0;
    final totalBasePrice = data['totalBasePrice'] as double? ?? 0.0;
    final pricingOnTop = data['pricingOnTop'] as double? ?? 0.0;
    final totalProfit = data['totalProfit'] as double? ?? 0.0;
    final prepayment = data['prepayment'] as double? ?? 0.0;
    final profitFromPrepayment = data['profitFromPrepayment'] as double? ?? 0.0;
    final cleanerFee = data['cleanerFee'] as double? ?? 0.0;
    final profitLeftToPay = data['profitLeftToPay'] as double? ?? 0.0;
    final prepaymentLeft = data['prepaymentLeft'] as double? ?? 0.0;
    final guestName = data['guestName'] as String? ?? 'N/A';
    final documentTypeStr =
        (data['documentType'] as String?)?.split('.').last ?? 'none';
    final selectedPartner =
        data['selectedNameForPartnerProfit'] as String? ?? 'მაკოს';

    final documentDisplay = documentTypeStr == 'invoice'
        ? 'ინვოისი'
        : documentTypeStr == 'contract'
        ? 'ხელშეკრულება'
        : 'არცერთი';

    final currencySymbol = days <= 29 ? '₾' : '\$';
    final onTopUnit = days <= 29 ? '(დღე)' : '(თვე)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30, thickness: 1.5),
        _buildReadOnlyField(
          'ფასი ზემოდან $onTopUnit',
          '$currencySymbol${pricingOnTop.toStringAsFixed(0)}',
        ),
        _buildReadOnlyField(
          'ჯავშანი',
          '$currencySymbol${prepayment.toStringAsFixed(0)}',
        ),
        _buildReadOnlyField(
          'ჯავშნიდან ავიღე',
          '$currencySymbol${profitFromPrepayment.toStringAsFixed(0)}',
        ),
        _buildReadOnlyField(
          'დამლაგებლის თანხა',
          '$currencySymbol${cleanerFee.toStringAsFixed(0)}',
        ),
        _buildReadOnlyField(
          'მოგებიდან დარჩ. მოსაცემი',
          '$currencySymbol${profitLeftToPay.toStringAsFixed(0)}',
          valueColor: Colors.green.shade700,
        ),
        _buildReadOnlyField(
          'მოგებიდან დარჩ. მისაცემი',
          '$currencySymbol${prepaymentLeft.toStringAsFixed(0)}',
          valueColor: Colors.red.shade700,
        ),
        const SizedBox(height: 10),
        _buildProfitDistribution(
          days,
          totalBasePrice,
          totalProfit,
          prepayment,
          profitFromPrepayment,
          cleanerFee,
          profitLeftToPay,
          prepaymentLeft,
          selectedPartner,
        ),
        const Divider(height: 30, thickness: 1.5),
        _buildReadOnlyField(
          'დოკუმენტის შედგენა',
          documentDisplay,
        ),
        _buildReadOnlyField(
          'სტუმრის სახელი',
          guestName.isEmpty ? 'მითითებული არ არის' : guestName,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF004aad);
    final data = widget.data;

    // Extract data needed for the header
    final startDate = (data['startDate'] as Timestamp).toDate();
    final endDate = (data['endDate'] as Timestamp).toDate();
    final days = data['days'] as int? ?? 0;
    final months = data['months'] as double? ?? 0.0;
    final totalBasePrice = data['totalBasePrice'] as double? ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: accentColor, width: 2),
      ),
      clipBehavior: Clip.antiAlias, // Ensures the InkWell ripple is clipped
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ALWAYS VISIBLE HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['apartmentAddress'] ?? 'No Address',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'მეპატრონე: ${data['ownerName'] ?? ''} - ${data['ownerNumber'] ?? ''}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              // MODIFIED: Using new color properties
              _buildPricingRow(
                'შესვლა — გამოსვლა:',
                '${_formatGeorgianDate(startDate)} — ${_formatGeorgianDate(endDate)}',
                isBold: true,
                labelColor: Colors.black,
                valueColor: accentColor,
              ),
              _buildPricingRow(
                'ხანგრძლივობა:',
                _getDurationDisplay(days, months),
                isBold: true,
                labelColor: Colors.black,
                valueColor: accentColor,
              ),
              _buildPricingRow(
                'ფასი:',
                _getPricePerUnitDisplay(days, totalBasePrice, months),
                isBold: true,
                labelColor: Colors.black,
                valueColor: accentColor,
              ),
              // --- ANIMATED COLLAPSIBLE CONTENT ---
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                child: _isExpanded
                    ? _buildCollapsibleContent()
                    : const SizedBox.shrink(),
              )
            ],
          ),
        ),
      ),
    );
  }

  // This widget contains the complex profit calculation and display logic.
  // It is unchanged but placed here for completeness within the State class.
  Widget _buildProfitDistribution(
      int days,
      double totalBasePrice,
      double totalProfit,
      double prepayment,
      double profitFromPrepayment,
      double cleanerFee,
      double profitLeftToPay,
      double prepaymentLeft,
      String selectedNameForPartnerProfit,
      ) {
    final currency = days <= 29 ? '₾' : '\$';
    final isLari = currency == '₾';

    final profitLeft = totalProfit - profitFromPrepayment;
    final myShare = profitLeft / 2 - profitFromPrepayment / 2;
    final partnerShare = profitLeft / 2 + profitFromPrepayment / 2;
    final myFinalAmount = myShare - profitLeftToPay;
    final partnerFinalAmount = partnerShare - prepaymentLeft;

    final ownerNetShare = totalBasePrice - totalProfit - cleanerFee;
    Widget ownerValueWidget;

    if (cleanerFee > 0) {
      ownerValueWidget = RichText(
        textAlign: TextAlign.end,
        text: TextSpan(
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'FiraGO'),
          children: [
            TextSpan(
              text: isLari
                  ? '${ownerNetShare.toStringAsFixed(0)}$currency'
                  : '$currency${ownerNetShare.toStringAsFixed(0)}',
            ),
            TextSpan(
              text: isLari
                  ? ' + ${cleanerFee.toStringAsFixed(0)}$currency დამლაგებლის'
                  : ' + $currency${cleanerFee.toStringAsFixed(0)} დამლაგებლის',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
      );
    } else {
      ownerValueWidget = Text(
        isLari
            ? '${(totalBasePrice - totalProfit).toStringAsFixed(0)}$currency'
            : '$currency${(totalBasePrice - totalProfit).toStringAsFixed(0)}',
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPricingRow(
          'ჯამური ფასი:',
          isLari
              ? '${totalBasePrice.toStringAsFixed(0)}$currency'
              : '$currency${totalBasePrice.toStringAsFixed(0)}',
          isBold: true,
          labelColor: Colors.black,
          valueColor: Colors.black,
          fontSize: 20,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('მეპატრონეს:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(child: ownerValueWidget),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildPricingRow(
          'მოგება:',
          isLari
              ? '${totalProfit.toStringAsFixed(0)}$currency'
              : '$currency${totalProfit.toStringAsFixed(0)}',
          isBold: true,
          labelColor: const Color(0xFF004aad),
          valueColor: const Color(0xFF004aad),
          fontSize: 18,
        ),
        const SizedBox(height: 8),
        _buildPricingRow(
          'ჯავშანი:',
          isLari
              ? '${prepayment.toStringAsFixed(0)}$currency'
              : '$currency${prepayment.toStringAsFixed(0)}',
          isBold: true,
          labelColor: const Color(0xFF004aad),
          valueColor: const Color(0xFF004aad),
          fontSize: 16,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            children: [
              _buildPricingRow(
                'ავიღე:',
                isLari
                    ? '${profitFromPrepayment.toStringAsFixed(0)}$currency'
                    : '$currency${profitFromPrepayment.toStringAsFixed(0)}',
                labelColor: Colors.blue,
                valueColor: Colors.blue,
                fontSize: 14,
              ),
              _buildPricingRow(
                'მივეცი:',
                isLari
                    ? '${(prepayment - profitFromPrepayment).toStringAsFixed(0)}$currency'
                    : '$currency${(prepayment - profitFromPrepayment).toStringAsFixed(0)}',
                labelColor: Colors.blue,
                valueColor: Colors.blue,
                fontSize: 14,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildPricingRow(
          'დარჩ. ასაღები:',
          isLari
              ? '${profitLeft.toStringAsFixed(0)}$currency'
              : '$currency${profitLeft.toStringAsFixed(0)}',
          isBold: true,
          labelColor: const Color(0xFF004aad),
          valueColor: const Color(0xFF004aad),
          fontSize: 16,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ჩემი:',
                      style: TextStyle(fontSize: 14, color: Colors.blue)),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontFamily: 'FiraGO'),
                      children: [
                        TextSpan(
                          text: isLari
                              ? '${myFinalAmount.toStringAsFixed(0)}$currency'
                              : '$currency${myFinalAmount.toStringAsFixed(0)}',
                        ),
                        if (profitLeftToPay > 0)
                          TextSpan(
                            text: isLari
                                ? ' + ${profitLeftToPay.toStringAsFixed(0)}$currency მოსაცემი'
                                : ' + $currency${profitLeftToPay.toStringAsFixed(0)} მოსაცემი',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.green),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$selectedNameForPartnerProfit:',
                      style: const TextStyle(fontSize: 14, color: Colors.blue)),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontFamily: 'FiraGO'),
                      children: [
                        TextSpan(
                          text: isLari
                              ? '${partnerFinalAmount.toStringAsFixed(0)}$currency'
                              : '$currency${partnerFinalAmount.toStringAsFixed(0)}',
                        ),
                        if (prepaymentLeft > 0)
                          TextSpan(
                            text: isLari
                                ? ' + ${prepaymentLeft.toStringAsFixed(0)}$currency მისაცემი'
                                : ' + $currency${prepaymentLeft.toStringAsFixed(0)} მისაცემი',
                            style:
                            const TextStyle(fontSize: 14, color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CompletedBookingCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const CompletedBookingCard({super.key, required this.data});

  @override
  State<CompletedBookingCard> createState() => _CompletedBookingCardState();
}

class _CompletedBookingCardState extends State<CompletedBookingCard> {
  bool _isExpanded = false;

  String _formatGeorgianDate(DateTime date) {
    const georgianMonths = [
      'იან', 'თებ', 'მარ', 'აპრ', 'მაი', 'ივნ',
      'ივლ', 'აგვ', 'სექ', 'ოქტ', 'ნოე', 'დეკ'
    ];
    return '${date.day.toString().padLeft(2, '0')}/${georgianMonths[date.month - 1]}/${date.year}';
  }

  String _getDurationDisplay(int days, double months) {
    if (days <= 29) {
      return '$days ღამე';
    } else {
      return '${months.toStringAsFixed(months.truncateToDouble() == months ? 0 : 1)} თვე';
    }
  }

  String _getPricePerUnitDisplay(
      int days, double totalBasePrice, double months) {
    if (days <= 29) {
      if (days == 0) return '0₾/დღე';
      final dailyPrice = totalBasePrice / days;
      return '${dailyPrice.toStringAsFixed(0)}₾/დღე';
    } else {
      if (months == 0) return '\$0/თვე';
      final monthlyPrice = totalBasePrice / months;
      return '\$${monthlyPrice.toStringAsFixed(0)}/თვე';
    }
  }

  Widget _buildReadOnlyField(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 15,
                color: valueColor ?? Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String label, String value,
      {bool isBold = false,
        Color? labelColor,
        Color? valueColor,
        double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: labelColor ?? Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleContent() {
    final data = widget.data;
    final days = data['days'] as int? ?? 0;
    final months = data['months'] as double? ?? 0.0;
    final totalBasePrice = data['totalBasePrice'] as double? ?? 0.0;
    final pricingOnTop = data['pricingOnTop'] as double? ?? 0.0;
    final totalProfit = data['totalProfit'] as double? ?? 0.0;
    final prepayment = data['prepayment'] as double? ?? 0.0;
    final profitFromPrepayment = data['profitFromPrepayment'] as double? ?? 0.0;
    final cleanerFee = data['cleanerFee'] as double? ?? 0.0;
    final profitLeftToPay = data['profitLeftToPay'] as double? ?? 0.0;
    final prepaymentLeft = data['prepaymentLeft'] as double? ?? 0.0;
    final guestName = data['guestName'] as String? ?? 'N/A';
    final documentTypeStr =
        (data['documentType'] as String?)?.split('.').last ?? 'none';
    final selectedPartner =
        data['selectedNameForPartnerProfit'] as String? ?? 'მაკოს';

    final documentDisplay = documentTypeStr == 'invoice'
        ? 'ინვოისი'
        : documentTypeStr == 'contract'
        ? 'ხელშეკრულება'
        : 'არცერთი';
    final currencySymbol = days <= 29 ? '₾' : '\$';
    final onTopUnit = days <= 29 ? '(დღე)' : '(თვე)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30, thickness: 1.5),
        _buildReadOnlyField(
          'ფასი ზემოდან $onTopUnit',
          '$currencySymbol${pricingOnTop.toStringAsFixed(0)}',
        ),
        _buildReadOnlyField(
          'ჯავშანი',
          '$currencySymbol${prepayment.toStringAsFixed(0)}',
        ),
        _buildReadOnlyField(
          'ჯავშნიდან ავიღე',
          '$currencySymbol${profitFromPrepayment.toStringAsFixed(0)}',
        ),
        _buildReadOnlyField(
          'დამლაგებლის თანხა',
          '$currencySymbol${cleanerFee.toStringAsFixed(0)}',
        ),
        _buildReadOnlyField(
          'მოგებიდან დარჩ. მოსაცემი',
          '$currencySymbol${profitLeftToPay.toStringAsFixed(0)}',
          valueColor: Colors.green.shade700,
        ),
        _buildReadOnlyField(
          'მოგებიდან დარჩ. მისაცემი',
          '$currencySymbol${prepaymentLeft.toStringAsFixed(0)}',
          valueColor: Colors.red.shade700,
        ),
        const SizedBox(height: 10),
        _buildProfitDistribution(
          days,
          totalBasePrice,
          totalProfit,
          prepayment,
          profitFromPrepayment,
          cleanerFee,
          profitLeftToPay,
          prepaymentLeft,
          selectedPartner,
        ),
        const Divider(height: 30, thickness: 1.5),
        _buildReadOnlyField(
          'დოკუმენტის შედგენა',
          documentDisplay,
        ),
        _buildReadOnlyField(
          'სტუმრის სახელი',
          guestName.isEmpty ? 'მითითებული არ არის' : guestName,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF004aad);
    final data = widget.data;

    final startDate = (data['startDate'] as Timestamp).toDate();
    final endDate = (data['endDate'] as Timestamp).toDate();
    final days = data['days'] as int? ?? 0;
    final months = data['months'] as double? ?? 0.0;
    final totalBasePrice = data['totalBasePrice'] as double? ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: accentColor, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- NEW: "Completed" Tag ---
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'დასრულებული',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // --- Card Content ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['apartmentAddress'] ?? 'No Address',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'მეპატრონე: ${data['ownerName'] ?? ''} - ${data['ownerNumber'] ?? ''}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              _buildPricingRow(
                'შესვლა — გამოსვლა:',
                '${_formatGeorgianDate(startDate)} — ${_formatGeorgianDate(endDate)}',
                isBold: true,
                labelColor: Colors.black,
                valueColor: accentColor,
              ),
              _buildPricingRow(
                'ხანგრძლივობა:',
                _getDurationDisplay(days, months),
                isBold: true,
                labelColor: Colors.black,
                valueColor: accentColor,
              ),
              _buildPricingRow(
                'ფასი:',
                _getPricePerUnitDisplay(days, totalBasePrice, months),
                isBold: true,
                labelColor: Colors.black,
                valueColor: accentColor,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                child: _isExpanded
                    ? _buildCollapsibleContent()
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Profit distribution logic from the original card
  Widget _buildProfitDistribution(
      int days,
      double totalBasePrice,
      double totalProfit,
      double prepayment,
      double profitFromPrepayment,
      double cleanerFee,
      double profitLeftToPay,
      double prepaymentLeft,
      String selectedNameForPartnerProfit,
      ) {
    final currency = days <= 29 ? '₾' : '\$';
    final isLari = currency == '₾';

    final profitLeft = totalProfit - profitFromPrepayment;
    final myShare = profitLeft / 2 - profitFromPrepayment / 2;
    final partnerShare = profitLeft / 2 + profitFromPrepayment / 2;
    final myFinalAmount = myShare - profitLeftToPay;
    final partnerFinalAmount = partnerShare - prepaymentLeft;

    final ownerNetShare = totalBasePrice - totalProfit - cleanerFee;
    Widget ownerValueWidget;

    if (cleanerFee > 0) {
      ownerValueWidget = RichText(
        textAlign: TextAlign.end,
        text: TextSpan(
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'FiraGO'),
          children: [
            TextSpan(
              text: isLari
                  ? '${ownerNetShare.toStringAsFixed(0)}$currency'
                  : '$currency${ownerNetShare.toStringAsFixed(0)}',
            ),
            TextSpan(
              text: isLari
                  ? ' + ${cleanerFee.toStringAsFixed(0)}$currency დამლაგებლის'
                  : ' + $currency${cleanerFee.toStringAsFixed(0)} დამლაგებლის',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
      );
    } else {
      ownerValueWidget = Text(
        isLari
            ? '${(totalBasePrice - totalProfit).toStringAsFixed(0)}$currency'
            : '$currency${(totalBasePrice - totalProfit).toStringAsFixed(0)}',
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPricingRow(
          'ჯამური ფასი:',
          isLari
              ? '${totalBasePrice.toStringAsFixed(0)}$currency'
              : '$currency${totalBasePrice.toStringAsFixed(0)}',
          isBold: true,
          labelColor: Colors.black,
          valueColor: Colors.black,
          fontSize: 20,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('მეპატრონეს:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(child: ownerValueWidget),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildPricingRow(
          'მოგება:',
          isLari
              ? '${totalProfit.toStringAsFixed(0)}$currency'
              : '$currency${totalProfit.toStringAsFixed(0)}',
          isBold: true,
          labelColor: const Color(0xFF004aad),
          valueColor: const Color(0xFF004aad),
          fontSize: 18,
        ),
        const SizedBox(height: 8),
        _buildPricingRow(
          'ჯავშანი:',
          isLari
              ? '${prepayment.toStringAsFixed(0)}$currency'
              : '$currency${prepayment.toStringAsFixed(0)}',
          isBold: true,
          labelColor: const Color(0xFF004aad),
          valueColor: const Color(0xFF004aad),
          fontSize: 16,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            children: [
              _buildPricingRow(
                'ავიღე:',
                isLari
                    ? '${profitFromPrepayment.toStringAsFixed(0)}$currency'
                    : '$currency${profitFromPrepayment.toStringAsFixed(0)}',
                labelColor: Colors.blue,
                valueColor: Colors.blue,
                fontSize: 14,
              ),
              _buildPricingRow(
                'მივეცი:',
                isLari
                    ? '${(prepayment - profitFromPrepayment).toStringAsFixed(0)}$currency'
                    : '$currency${(prepayment - profitFromPrepayment).toStringAsFixed(0)}',
                labelColor: Colors.blue,
                valueColor: Colors.blue,
                fontSize: 14,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildPricingRow(
          'დარჩ. ასაღები:',
          isLari
              ? '${profitLeft.toStringAsFixed(0)}$currency'
              : '$currency${profitLeft.toStringAsFixed(0)}',
          isBold: true,
          labelColor: const Color(0xFF004aad),
          valueColor: const Color(0xFF004aad),
          fontSize: 16,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ჩემი:',
                      style: TextStyle(fontSize: 14, color: Colors.blue)),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontFamily: 'FiraGO'),
                      children: [
                        TextSpan(
                          text: isLari
                              ? '${myFinalAmount.toStringAsFixed(0)}$currency'
                              : '$currency${myFinalAmount.toStringAsFixed(0)}',
                        ),
                        if (profitLeftToPay > 0)
                          TextSpan(
                            text: isLari
                                ? ' + ${profitLeftToPay.toStringAsFixed(0)}$currency მოსაცემი'
                                : ' + $currency${profitLeftToPay.toStringAsFixed(0)} მოსაცემი',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.green),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$selectedNameForPartnerProfit:',
                      style: const TextStyle(fontSize: 14, color: Colors.blue)),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontFamily: 'FiraGO'),
                      children: [
                        TextSpan(
                          text: isLari
                              ? '${partnerFinalAmount.toStringAsFixed(0)}$currency'
                              : '$currency${partnerFinalAmount.toStringAsFixed(0)}',
                        ),
                        if (prepaymentLeft > 0)
                          TextSpan(
                            text: isLari
                                ? ' + ${prepaymentLeft.toStringAsFixed(0)}$currency მისაცემი'
                                : ' + $currency${prepaymentLeft.toStringAsFixed(0)} მისაცემი',
                            style:
                            const TextStyle(fontSize: 14, color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}