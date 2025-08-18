import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:realtor_app/data/app_data.dart';
import 'package:intl/intl.dart';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'add_apartment_screen.dart';
import 'package:realtor_app/apartment_detail_screen.dart';
import 'package:realtor_app/ongoing_booked_apartments.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'invoice_generator_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:realtor_app/contract_form_screen.dart';




class ApartmentListScreen extends StatefulWidget {
  const ApartmentListScreen({super.key});

  @override
  State<ApartmentListScreen> createState() => _ApartmentListScreenState();
}

class _ApartmentListScreenState extends State<ApartmentListScreen> {
  late Stream<List<Apartment>> _apartmentsStream;
  late FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _apartmentsStream = _firestoreService.getAllApartments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'ბინების სია',
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
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddApartmentScreen(),
                ),
              ).then((_) {
                // Refresh the stream when returning from add screen
                setState(() {
                  _apartmentsStream = _firestoreService.getAllApartments();
                });
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Apartment>>(
        stream: _apartmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('შეცდომა: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ბინა ვერ მოიძებნა.'));
          }

          final apartments = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: apartments.length,
            itemBuilder: (context, index) {
              final apartment = apartments[index];
              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 12.0 : 0.0,  // Only add top padding for the first card
                  bottom: 16.0,
                ),
                child: ApartmentCard(
                  key: ValueKey(apartment.id),
                  apartment: apartment,
                  ownerName: apartment.ownerName,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// NO CHANGES BELOW THIS LINE
// The ApartmentCard widget and its state remain the same.

class ApartmentCard extends StatefulWidget {
  final Apartment apartment;
  final String ownerName;

  const ApartmentCard({
    super.key,
    required this.apartment,
    required this.ownerName,
  });

  @override
  State<ApartmentCard> createState() => _ApartmentCardState();
}


// Add this custom painter for half-circle rendering
class _HalfCirclePainter extends CustomPainter {
  final Color leftColor;
  final Color rightColor;

  _HalfCirclePainter({required this.leftColor, required this.rightColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Left half
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width / 2, size.height));
    canvas.drawCircle(center, radius, Paint()..color = leftColor);
    canvas.restore();

    // Right half
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(size.width / 2, 0, size.width, size.height));
    canvas.drawCircle(center, radius, Paint()..color = rightColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HalfCirclePainter oldDelegate) {
    return oldDelegate.leftColor != leftColor || oldDelegate.rightColor != rightColor;
  }
}


class _ApartmentCardState extends State<ApartmentCard> with AutomaticKeepAliveClientMixin {



  late FirestoreService _firestoreService;
  static Future<void>? _georgianLocaleFuture;

  int _getWeeksForMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return ((lastDay.day + firstDay.weekday - 1) / 7).ceil();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(ApartmentCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update if Firestore changes are not from our current booking
    if (!_isLocalUpdate &&
        oldWidget.apartment.bookedDates != widget.apartment.bookedDates) {
      bookedDatesNotifier.value = widget.apartment.bookedDates
          .map((d) => DateTime(d.year, d.month, d.day))
          .toSet();
    }
    _isLocalUpdate = false;
  }

  double _calculateCalendarHeight(int weeksInMonth) {
    const cellHeight = 42.0;
    const headerHeight = 50.0;
    const padding = 16.0;
    return headerHeight + (weeksInMonth * cellHeight) + padding;
  }

  late PageController _pageController;
  bool _isExpanded = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isDisposed = false;
  bool _isLocalUpdate = false;

  // Use ValueNotifier for booked dates
  late ValueNotifier<Set<DateTime>> bookedDatesNotifier;
  int _currentPage = 0;

  List<ImageProvider> _imageProviders = [];
  bool _imagesPrecached = false;

  @override
  void initState() {
    super.initState();
    _georgianLocaleFuture ??= initializeDateFormatting('ka_GE');
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _pageController = PageController();

    _imageProviders = widget.apartment.imageUrls
        .map((url) => NetworkImage(url))
        .toList();

    // Initialize ValueNotifier with booked dates
    bookedDatesNotifier = ValueNotifier<Set<DateTime>>(
        widget.apartment.bookedDates
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet()
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesPrecached) {
      _precacheImages();
      _imagesPrecached = true;
    }
  }

  Future<void> _precacheImages() async {
    for (final provider in _imageProviders) {
      if (_isDisposed) return;
      try {
        await precacheImage(provider, context);
      } catch (e) {
        if (!_isDisposed) {
          debugPrint('ვერ მოხერხდა სურათის ჩატვირთვა: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pageController.dispose();
    // Dispose the ValueNotifier
    bookedDatesNotifier.dispose();
    super.dispose();
  }

// Replace the _bookApartment method in _ApartmentCardState:
  void _bookApartment() async {
    if (_startDate == null || _endDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('გთხოვთ მონიშნოთ დღეები დასაჯავშნათ')),
        );
      }
      return;
    }

    // Calculate days to determine default document type
    // Fixed calculation for booking confirmation
    final days = _endDate!.difference(_startDate!).inDays;
    final defaultDocumentType = days <= 29 ? DocumentType.invoice : DocumentType.contract;

    // Show booking confirmation dialog
    showDialog(
      context: context,
      builder: (context) => BookingConfirmationDialog(
        apartment: widget.apartment,
        startDate: _startDate!,
        endDate: _endDate!,
        firestoreService: _firestoreService,
        bookedDatesNotifier: bookedDatesNotifier,
        onBookingSuccess: () {
          setState(() {
            _startDate = null;
            _endDate = null;
          });
        },
        initialDocumentType: defaultDocumentType,
      ),
    );
  }

  void _editBooking() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a booking to edit.'),
        ),
      );
      return;
    }

    // Find the booking that corresponds to the selected date range
    BookingInfo? targetBooking;
    for (var booking in widget.apartment.bookingInfo) {
      final checkInNormalized = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
      final checkOutNormalized = DateTime(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);

      if (_startDate!.isAtSameMomentAs(checkInNormalized) && _endDate!.isAtSameMomentAs(checkOutNormalized)) {
        targetBooking = booking;
        break;
      }
    }

    if (targetBooking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find the selected booking details.')),
      );
      return;
    }

    // Fetch the full booking data from the 'ongoingBookings' collection
    final bookingData = await _firestoreService.getOngoingBookingByBookingId(targetBooking.id);

    if (bookingData != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => BookingConfirmationDialog(
          apartment: widget.apartment,
          startDate: _startDate!,
          endDate: _endDate!,
          firestoreService: _firestoreService,
          bookedDatesNotifier: bookedDatesNotifier,
          onBookingSuccess: () {
            // This callback resets the calendar selection after the dialog closes
            setState(() {
              _startDate = null;
              _endDate = null;
            });
          },
          // Pass the fetched data to the dialog to enable 'edit mode'
          initialBookingData: bookingData,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load booking details for editing.')),
      );
    }
  }

  void _showBookingSelectionDialog(List<BookingInfo> bookings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('აირჩიეთ ჯავშანი გასაუქმებლად'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: bookings.map((booking) {
              final georgianDateFormat = DateFormat('dd/MMM/yyyy', 'ka_GE');
              return ListTile(
                title: Text(
                    '${booking.guestName.isEmpty ? 'უცნობი სტუმარი' : booking.guestName}'),
                subtitle: Text(
                    '${georgianDateFormat.format(booking.checkIn)} - ${georgianDateFormat.format(booking.checkOut)}'),
                onTap: () {
                  Navigator.of(context).pop();
                  _removeSpecificBooking(booking);
                },
                trailing: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('გაუქმება'),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _removeSpecificBooking(BookingInfo booking) async {
    // Save current state for potential rollback
    final originalBookedDates = Set<DateTime>.from(bookedDatesNotifier.value);

    // Calculate which dates will be removed
    final checkIn = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
    final checkOut = DateTime(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);
    final bookingDates = _getDatesInBookingRange(checkIn, checkOut);

    // Optimistic update - remove dates that won't be used by other bookings
    final newSet = Set<DateTime>.from(bookedDatesNotifier.value);
    for (final dateToRemove in bookingDates) {
      bool isUsedByOtherBooking = false;
      for (final otherBooking in widget.apartment.bookingInfo) {
        if (otherBooking.id == booking.id) continue; // Skip the booking we're removing

        final otherCheckIn = DateTime(otherBooking.checkIn.year, otherBooking.checkIn.month, otherBooking.checkIn.day);
        final otherCheckOut = DateTime(otherBooking.checkOut.year, otherBooking.checkOut.month, otherBooking.checkOut.day);

        if ((dateToRemove.isAtSameMomentAs(otherCheckIn) || dateToRemove.isAfter(otherCheckIn)) &&
            (dateToRemove.isAtSameMomentAs(otherCheckOut) || dateToRemove.isBefore(otherCheckOut))) {
          isUsedByOtherBooking = true;
          break;
        }
      }

      if (!isUsedByOtherBooking) {
        newSet.remove(dateToRemove);
      }
    }

    bookedDatesNotifier.value = newSet;
    _startDate = null;
    _endDate = null;
    _isLocalUpdate = true;

    try {
      await _firestoreService.removeBookingById(
        apartmentId: widget.apartment.id,
        bookingId: booking.id,
      );

      if (mounted) {
        final georgianDateFormat = DateFormat('dd/MMM/yyyy', 'ka_GE');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'ჯავშანი გაუქმდა: ${georgianDateFormat.format(booking.checkIn)} - ${georgianDateFormat.format(booking.checkOut)}'
            ),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        bookedDatesNotifier.value = originalBookedDates;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ვერ მოხერხდა ჯავშნის გაუქმება: $e'),
          ),
        );
      }
    } finally {
      _isLocalUpdate = false;
    }
  }

  List<DateTime> _getDatesInBookingRange(DateTime checkIn, DateTime checkOut) {
    // Include both check-in and check-out dates
    final days = checkOut.difference(checkIn).inDays + 1;
    return List.generate(days, (i) => DateTime(checkIn.year, checkIn.month, checkIn.day + i));
  }

  List<DateTime> _getDatesInRange(DateTime start, DateTime end) {
    // Keep end date as booked for visual purposes (it's checkout day)
    final days = end.difference(start).inDays + 1;
    return List.generate(days, (i) => DateTime(start.year, start.month, start.day + i));
  }

  List<Map<String, dynamic>> _getAvailabilityPeriods(
      Set<DateTime> bookedDatesSet, List<BookingInfo> bookingInfo) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final List<Map<String, dynamic>> periods = [];

    // Helper functions to identify day types (same as in _getNearestAvailabilityStatus)
    bool isCheckInDay(DateTime day) {
      return bookingInfo.any((b) =>
          DateTime(b.checkIn.year, b.checkIn.month, b.checkIn.day).isAtSameMomentAs(day));
    }

    bool isCheckOutDay(DateTime day) {
      return bookingInfo.any((b) =>
          DateTime(b.checkOut.year, b.checkOut.month, b.checkOut.day).isAtSameMomentAs(day));
    }

    bool isCheckInOnlyDay(DateTime day) {
      return isCheckInDay(day) && !isCheckOutDay(day);
    }

    bool isCheckOutOnlyDay(DateTime day) {
      return isCheckOutDay(day) && !isCheckInDay(day);
    }

    bool isTransitionDay(DateTime day) {
      return isCheckInDay(day) && isCheckOutDay(day);
    }

    bool isUnbookedDay(DateTime day) {
      return !bookedDatesSet.contains(day);
    }

    bool isMidBookingDay(DateTime day) {
      return bookedDatesSet.contains(day) && !isCheckInDay(day) && !isCheckOutDay(day);
    }

    // Find all availability periods using the same logic as the status text
    DateTime? currentPeriodStart;
    int consecutiveAvailableDays = 0;

    for (int i = 0; i < 730; i++) { // Loop for the next 2 years
      final checkDate = today.add(Duration(days: i));

      // A day is available if it's unbooked OR it's a check-out only day
      bool isDayAvailable = isUnbookedDay(checkDate) || isCheckOutOnlyDay(checkDate);

      // A day blocks availability if it's a mid-booking day OR a check-in only day OR a transition day
      bool isDayBlocking = isMidBookingDay(checkDate) || isCheckInOnlyDay(checkDate) || isTransitionDay(checkDate);

      if (isDayAvailable && !isDayBlocking) {
        if (currentPeriodStart == null) {
          currentPeriodStart = checkDate;
          consecutiveAvailableDays = 1;
        } else {
          consecutiveAvailableDays++;
        }
      } else if (isDayBlocking) {
        // End the current availability period
        if (currentPeriodStart != null) {
          final periodEnd = checkDate.subtract(const Duration(days: 1));

          // Determine color based on duration
          Color color;
          if (consecutiveAvailableDays <= 3) {
            color = Colors.yellow.shade600; // Short availability
          } else if (consecutiveAvailableDays >= 29) {
            color = Colors.green; // Long availability
          } else {
            color = Colors.green; // Medium availability
          }

          periods.add({
            'start': currentPeriodStart,
            'end': periodEnd,
            'color': color,
            'days': consecutiveAvailableDays,
          });

          currentPeriodStart = null;
          consecutiveAvailableDays = 0;
        }
      }
    }

    // Handle ongoing availability period at the end
    if (currentPeriodStart != null) {
      final periodEnd = today.add(const Duration(days: 729));

      Color color;
      if (consecutiveAvailableDays <= 3) {
        color = Colors.yellow.shade600; // Short availability
      } else if (consecutiveAvailableDays >= 29) {
        color = Colors.green; // Long availability
      } else {
        color = Colors.green; // Medium availability
      }

      periods.add({
        'start': currentPeriodStart,
        'end': periodEnd,
        'color': color,
        'days': consecutiveAvailableDays,
      });
    }

    return periods;
  }

  /// MODIFIED/FIXED FUNCTION
  /// This version corrects the availability text for short-term periods to display
  /// the accurate number of days and uses clearer phrasing.
  Map<String, dynamic> _getNearestAvailabilityStatus(Set<DateTime> bookedDatesSet) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final georgianDateFormat = DateFormat('dd/MMM/yyyy', 'ka_GE');

    // Helper functions to identify day types
    bool isCheckInDay(DateTime day) {
      return widget.apartment.bookingInfo.any((b) =>
          DateTime(b.checkIn.year, b.checkIn.month, b.checkIn.day).isAtSameMomentAs(day));
    }

    bool isCheckOutDay(DateTime day) {
      return widget.apartment.bookingInfo.any((b) =>
          DateTime(b.checkOut.year, b.checkOut.month, b.checkOut.day).isAtSameMomentAs(day));
    }

    bool isCheckInOnlyDay(DateTime day) {
      return isCheckInDay(day) && !isCheckOutDay(day);
    }

    bool isCheckOutOnlyDay(DateTime day) {
      return isCheckOutDay(day) && !isCheckInDay(day);
    }

    bool isTransitionDay(DateTime day) {
      return isCheckInDay(day) && isCheckOutDay(day);
    }

    bool isUnbookedDay(DateTime day) {
      return !bookedDatesSet.contains(day);
    }

    bool isMidBookingDay(DateTime day) {
      return bookedDatesSet.contains(day) && !isCheckInDay(day) && !isCheckOutDay(day);
    }

    // First condition: Check if today is booked/check-in and find nearest check-out followed by available day
    if (bookedDatesSet.contains(today) || isCheckInDay(today)) {
      // Find nearest check-out only day that is followed by unbooked or check-in only day
      for (int i = 1; i < 730; i++) {
        final checkDate = today.add(Duration(days: i));

        if (isCheckOutOnlyDay(checkDate)) {
          final nextDay = checkDate.add(const Duration(days: 1));
          if (isUnbookedDay(nextDay) || isCheckInOnlyDay(nextDay)) {
            if (i >= 29) {
              return {
                'text': 'მიუწვდომელია ${georgianDateFormat.format(checkDate)}-მდე',
                'color': Colors.red,
              };
            }
            // If less than 29 days, continue to other logic below
            break;
          }
        }
      }
    }

    // Second condition: Look for availability periods after transition days OR today
    for (int i = 0; i < 730; i++) {
      final checkDate = today.add(Duration(days: i));

      // Find transition day (both check-in & check-out) OR today
      if (isTransitionDay(checkDate) || checkDate.isAtSameMomentAs(today)) {
        // Find the nearest unbooked or check-out only day after this day
        DateTime? nearestAvailableStart;

        // If checking today, start from today; otherwise start from day after transition
        int startOffset = checkDate.isAtSameMomentAs(today) ? 0 : 1;

        for (int j = startOffset; j < 730; j++) {
          final futureDate = checkDate.add(Duration(days: j));
          if (isUnbookedDay(futureDate) || isCheckOutOnlyDay(futureDate)) {
            nearestAvailableStart = futureDate;
            break;
          }
        }

        if (nearestAvailableStart != null) {
          // Find the nearest check-in only day after the available start
          DateTime? nearestCheckInOnly;

          for (int k = 1; k < 730; k++) {
            final futureDate = nearestAvailableStart.add(Duration(days: k));
            if (isCheckInOnlyDay(futureDate)) {
              nearestCheckInOnly = futureDate;
              break;
            }
          }

          if (nearestCheckInOnly != null) {
            // FIXED: Calculate the actual available days between the start and check-in day
            // If available start is 12th and check-in is 15th, available days are: 12, 13, 14 (3 days)
            final dayDifference = nearestCheckInOnly.difference(nearestAvailableStart).inDays;

            if (dayDifference <= 3) {
              return {
                'text': 'ხელმისაწვდომია ${georgianDateFormat.format(nearestAvailableStart)}-დან ${dayDifference} დღით',
                'color': Colors.yellow.shade600,
              };
            } else if (dayDifference >= 29) {
              // MODIFIED: For periods 29 days or longer, show only start date
              return {
                'text': 'ხელმისაწვდომია ${georgianDateFormat.format(nearestAvailableStart)}-დან',
                'color': Colors.green,
              };
            } else {
              return {
                'text': 'ხელმისაწვდომია ${georgianDateFormat.format(nearestAvailableStart)}-დან ${georgianDateFormat.format(nearestCheckInOnly)}-მდე',
                'color': Colors.green,
              };
            }
          } else {
            // No check-in only day found, show long availability
            return {
              'text': 'ხელმისაწვდომია ${georgianDateFormat.format(nearestAvailableStart)}-დან',
              'color': Colors.green,
            };
          }
        }
      }
    }

    // Fallback: Use the original availability periods logic for other cases
    final periods = _getAvailabilityPeriods(bookedDatesSet, widget.apartment.bookingInfo);

    if (periods.isEmpty) {
      return {
        'text': 'მიუწვდომელია შემდეგი 2 წლით',
        'color': Colors.red,
      };
    }

    final nearestPeriod = periods.firstWhere(
          (p) => p['start'].isAfter(today) || p['start'].isAtSameMomentAs(today),
      orElse: () => {},
    );

    if (nearestPeriod.isEmpty) {
      return {
        'text': 'მიუწვდომელია შემდეგი 2 წლით',
        'color': Colors.red,
      };
    }

    final start = nearestPeriod['start'];
    final end = nearestPeriod['end'];
    final periodColor = nearestPeriod['color'];
    final dayDifference = end.difference(start).inDays + 1;

    String text;
    Color color = periodColor;

    if (start.isAtSameMomentAs(today)) {
      if (dayDifference == 1) {
        text = 'ხელმისაწვდომია მხოლოდ დღეს';
      } else if (dayDifference <= 4) {
        text = 'ხელმისაწვდომია დღეიდან ${dayDifference} დღით';
      } else if (dayDifference >= 29) {
        // MODIFIED: For periods 29 days or longer, show only "from today"
        text = 'ხელმისაწვდომია დღეიდან';
      } else {
        final displayEnd = end.add(const Duration(days: 1));
        text = 'ხელმისაწვდომია დღეიდან — ${georgianDateFormat.format(displayEnd)}-მდე';
      }
    } else {
      if (dayDifference == 1) {
        text = 'ხელმისაწვდომია მხოლოდ ${georgianDateFormat.format(start)}';
      } else if (dayDifference <= 4) {
        text = 'ხელმისაწვდომია ${georgianDateFormat.format(start)}-დან ${dayDifference} დღით';
      } else if (dayDifference >= 29) {
        // MODIFIED: For periods 29 days or longer, show only start date
        text = 'ხელმისაწვდომია ${georgianDateFormat.format(start)}-დან';
      } else {
        final displayStart = start.subtract(const Duration(days: 1));
        final displayEnd = end.add(const Duration(days: 1));
        text = 'ხელმისაწვდომია — ${georgianDateFormat.format(displayStart)}-დან ${georgianDateFormat.format(displayEnd)}-მდე';
      }
    }

    return {
      'text': text,
      'color': color,
    };
  }


  bool _isEntireRangeBooked(Set<DateTime> bookedDatesSet) {
    if (_startDate == null || _endDate == null) return false;

    // Find if a single booking exactly matches the selected start and end dates.
    for (var booking in widget.apartment.bookingInfo) {
      final checkInNormalized = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
      final checkOutNormalized = DateTime(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);

      if (_startDate!.isAtSameMomentAs(checkInNormalized) &&
          _endDate!.isAtSameMomentAs(checkOutNormalized)) {
        // This is a precise match with an existing booking, so it's an "unbooking" scenario.
        return true;
      }
    }

    // If no exact match is found, it's a new booking selection, not an unbooking one.
    return false;
  }


  void _showPriceEditDialog(String priceType) {
    final initialValue = priceType == 'Daily'
        ? widget.apartment.dailyPrice.toStringAsFixed(0)
        : widget.apartment.monthlyPrice.toStringAsFixed(0);

    TextEditingController priceController = TextEditingController(
        text: initialValue);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
            constraints: const BoxConstraints(
              maxWidth: 500, // Maximum width of 500
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  priceType == 'Daily'
                      ? 'დღიური ფასის რედაქტირება'
                      : 'ყოველთვიური ფასის რედაქტირება',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'ახალი ფასი',
                    prefix: Text(priceType == 'Daily' ? '₾' : '\$'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xFF004aad), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'გაუქმება',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final newPrice = double.tryParse(priceController.text);
                            if (newPrice != null && newPrice > 0) {
                              try {
                                final updatedApartment = widget.apartment.copyWith(
                                  dailyPrice: priceType == 'Daily'
                                      ? newPrice
                                      : widget.apartment.dailyPrice,
                                  monthlyPrice: priceType == 'Monthly'
                                      ? newPrice
                                      : widget.apartment.monthlyPrice,
                                );

                                final firestoreService = Provider.of<FirestoreService>(
                                    context, listen: false);

                                await firestoreService.updateApartment(updatedApartment);

                                if (mounted) setState(() {});

                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(priceType == 'Daily'
                                        ? 'დღიური ფასი წარმატებით განახლდა!'
                                        : 'ყოველთვიური ფასი წარმატებით განახლდა!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('ფასის განახლება ვერ მოხერხდა: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('გთხოვთ შეიყვანოთ სწორი ფასი'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004aad),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'შენახვა',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShareOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(
              minWidth: 300,
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ბინის გაზიარება',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 60, // Increased button height
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _shareApartmentDetails(null, withImages: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004aad),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'ფოტოების დაკოპირება',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 60, // Increased button height
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _shareApartmentDetails(null); // Directly share text without guide selection
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004aad),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.text_fields, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'ტექსტის დაკოპირება',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center( // Centered cancel button
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'გაუქმება',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGuideShareDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedGuide = 'არავინ';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Who will be the guide?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          setState(() =>
                          selectedGuide = 'მაია ნაკაიძე'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedGuide == 'მაია ნაკაიძე'
                            ? const Color(0xFF004aad)
                            : Colors.grey[200],
                        foregroundColor: selectedGuide == 'მაია ნაკაიძე'
                            ? Colors.white
                            : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius
                            .circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                          'მაია ნაკაიძე', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          setState(() =>
                          selectedGuide = 'მზია გოგიტიძე'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedGuide == 'მზია გოგიტიძე'
                            ? const Color(0xFF004aad)
                            : Colors.grey[200],
                        foregroundColor: selectedGuide == 'მზია გოგიტიძე'
                            ? Colors.white
                            : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius
                            .circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                          'მზია გოგიტიძე', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => selectedGuide = 'არავინ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedGuide == 'არავინ'
                            ? const Color(0xFF004aad)
                            : Colors.grey[200],
                        foregroundColor: selectedGuide == 'არავინ' ? Colors
                            .white : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius
                            .circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                          'არავინ', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                      'Cancel', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _shareApartmentDetails(selectedGuide);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004aad),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Share', style: TextStyle(fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
    );
  }

// The user wants to modify this function in `apartment_list_screen.dart`
  void _shareApartmentDetails(String? guide, {bool withImages = false}) async {
    final apartment = widget.apartment;

    // Build the message text (this part remains the same)
    final now = DateTime.now();
    final isDailyEmphasis = now.month >= 7 && now.month <= 9;
    final highlightedPrice = isDailyEmphasis
        ? '${NumberFormat('#,##0').format(apartment.dailyPrice)}₾/დღე'
        : '\$${NumberFormat('#,##0').format(apartment.monthlyPrice)}/თვე';

    String message = """
Address: ${apartment.geAddress}
Rooms: ${apartment.geAppRoom.split('-').first}
Bedrooms: ${apartment.geAppBedroom.split('-').first}
Square Meters: ${apartment.squareMeters.toStringAsFixed(0)} m²
Price: $highlightedPrice
""";

    if (guide != null && guide != 'არავინ') {
      message += "\nდაგხვდებათ: $guide";
    }

    // If not sharing with images, just share the text and exit.
    if (!withImages) {
      await Share.share(message);
      return;
    }

    // --- NEW LOGIC FOR SHARING WITH IMAGES ---
    try {
      if (apartment.imageUrls.isEmpty) {
        debugPrint('No images available, falling back to text sharing');
        await Share.share(message);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No images available, shared text only')),
          );
        }
        return;
      }

      debugPrint('Attempting to share with images...');
      final List<XFile> files = [];

      // Download all images into memory
      for (final url in apartment.imageUrls) {
        try {
          debugPrint('Fetching image from $url');
          final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;
            final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

            // Create an XFile from the image data in memory
            // This is the key change that makes it work on web
            files.add(XFile.fromData(
              bytes,
              name: fileName,
              mimeType: 'image/jpeg',
            ));
            debugPrint('Successfully prepared image for sharing.');
          } else {
            debugPrint('Failed to download image: HTTP ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Error downloading or preparing image: $e');
          // Continue to the next image if one fails
        }
      }

      if (files.isNotEmpty) {
        debugPrint('Attempting to share ${files.length} images and text.');
        await Share.shareXFiles(
          files,
          text: message,
          subject: 'Apartment Details',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Shared ${files.length} images and details')),
          );
        }
      } else {
        // This is the fallback if all image downloads fail
        debugPrint('No images were successfully prepared, falling back to text sharing.');
        await Share.share(message);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load images, shared text only.')),
          );
        }
      }
    } catch (e) {
      debugPrint('An error occurred during sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share apartment details')),
        );
      }
    }
  }


// Also update the _getAvailabilityColorForDay helper method to handle edge cases better:
  Color? _getAvailabilityColorForDay(DateTime day, List<Map<String, dynamic>> allAvailabilityPeriods) {
    for (var period in allAvailabilityPeriods) {
      if ((day.isAtSameMomentAs(period['start']) || day.isAfter(period['start'])) &&
          (day.isAtSameMomentAs(period['end']) || day.isBefore(period['end']))) {
        return period['color'];
      }
    }

    // Fallback: if no availability period found, check if it's a checkout-only day
    // and return a default availability color
    bool isCheckOutDay = widget.apartment.bookingInfo.any((b) =>
        DateTime(b.checkOut.year, b.checkOut.month, b.checkOut.day).isAtSameMomentAs(day));
    bool isCheckInDay = widget.apartment.bookingInfo.any((b) =>
        DateTime(b.checkIn.year, b.checkIn.month, b.checkIn.day).isAtSameMomentAs(day));

    if (isCheckOutDay && !isCheckInDay) {
      // This is a checkout-only day, so it should have some availability color
      return Colors.green.shade700; // Default to green for consistency
    }

    return null;
  }


  Widget _buildCalendar(Set<DateTime> bookedDatesSet, List<Map<String, dynamic>> allAvailabilityPeriods) {
    // Define a text style with a shadow for better visibility
    final shadowStyle = [
      Shadow(
        color: Colors.black.withOpacity(0.6),
        blurRadius: 2,
        offset: const Offset(0, 1),
      )
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 425,
          child: CalendarCarousel(
            locale: 'ka_GE',
            weekdayTextStyle: const TextStyle(
                color: Color(0xFF004aad), fontWeight: FontWeight.bold),
            customGridViewPhysics: const NeverScrollableScrollPhysics(),
            onDayPressed: (DateTime date, List events) {
              setState(() {
                final normalizedDay = DateTime(date.year, date.month, date.day);

                // --- Helper logic to identify date types for the PRESSED day ---
                BookingInfo? pressedDayCheckInBooking;
                BookingInfo? pressedDayCheckOutBooking;
                bool isMidBookingDay = false;
                bool isPressedDayBooked = bookedDatesSet.contains(normalizedDay);

                for (var booking in widget.apartment.bookingInfo) {
                  final checkIn = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
                  final checkOut = DateTime(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);

                  if (normalizedDay.isAtSameMomentAs(checkIn)) {
                    pressedDayCheckInBooking = booking;
                  }
                  if (normalizedDay.isAtSameMomentAs(checkOut)) {
                    pressedDayCheckOutBooking = booking;
                  }
                  if (normalizedDay.isAfter(checkIn) && normalizedDay.isBefore(checkOut)) {
                    isMidBookingDay = true;
                  }
                }

                /// MODIFIED/FIXED: Block selection of past dates unless they are a check-in day.
                final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                if (normalizedDay.isBefore(today)) {
                  if (pressedDayCheckInBooking == null) {
                    // This is a past day that is NOT a check-in. Block it.
                    return;
                  }
                  // Otherwise, it's a past check-in day, so allow the logic to continue.
                }

                final isPressedDayCheckoutOnly = pressedDayCheckOutBooking != null && pressedDayCheckInBooking == null;
                final isPressedDayCheckInOnly = pressedDayCheckInBooking != null && pressedDayCheckOutBooking == null;
                final isPressedDayUnbooked = !isPressedDayBooked;

                // --- Check if the current selection is a full booking range ---
                bool isCurrentSelectionAnExistingBooking = false;
                if (_startDate != null && _endDate != null && !_startDate!.isAtSameMomentAs(_endDate!)) {
                  for (final booking in widget.apartment.bookingInfo) {
                    final checkIn = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
                    final checkOut = DateTime(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);
                    if (_startDate!.isAtSameMomentAs(checkIn) && _endDate!.isAtSameMomentAs(checkOut)) {
                      isCurrentSelectionAnExistingBooking = true;
                      break;
                    }
                  }
                }

                // --- Main Selection Logic (Order of rules is important) ---

                // RULE 0: If a full booking was selected and user now clicks an unbooked day, reset selection.
                if (isCurrentSelectionAnExistingBooking && isPressedDayUnbooked) {
                  _startDate = normalizedDay;
                  _endDate = normalizedDay;
                  return;
                }

                // --- Context-aware checks: Analyze the state of the CURRENT selection ---
                bool selectionStartedOnNonCheckInDay = false;
                bool selectionStartedOnTransitionDay = false;
                if (_startDate != null) {
                  BookingInfo? startDateCheckIn;
                  BookingInfo? startDateCheckOut;
                  for (var booking in widget.apartment.bookingInfo) {
                    final checkIn = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
                    final checkOut = DateTime(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);
                    if (_startDate!.isAtSameMomentAs(checkIn)) startDateCheckIn = booking;
                    if (_startDate!.isAtSameMomentAs(checkOut)) startDateCheckOut = booking;
                  }
                  if (startDateCheckIn == null) selectionStartedOnNonCheckInDay = true;
                  if (startDateCheckIn != null && startDateCheckOut != null) selectionStartedOnTransitionDay = true;
                }

                if (selectionStartedOnTransitionDay && isPressedDayUnbooked) {
                  _startDate = normalizedDay;
                  _endDate = normalizedDay;
                  return;
                }

                // RULE 1: Handle clicks on "Check-In" days for auto-selection.
                if (pressedDayCheckInBooking != null) {
                  bool shouldSuppressAutoSelect = selectionStartedOnNonCheckInDay && isPressedDayCheckInOnly;
                  if (!shouldSuppressAutoSelect) {
                    final bookingEndDate = DateTime(
                        pressedDayCheckInBooking.checkOut.year,
                        pressedDayCheckInBooking.checkOut.month,
                        pressedDayCheckInBooking.checkOut.day);

                    if (_startDate != null && _startDate!.isAtSameMomentAs(normalizedDay) &&
                        _endDate != null && _endDate!.isAtSameMomentAs(bookingEndDate)) {
                      _startDate = null;
                      _endDate = null;
                    } else {
                      _startDate = normalizedDay;
                      _endDate = bookingEndDate;
                    }
                    return;
                  }
                }

                // RULE 2: Handle clicks on "Check-Out Only" days.
                if (isPressedDayCheckoutOnly) {
                  if (_startDate != null && _startDate!.isAtSameMomentAs(normalizedDay) && _endDate!.isAtSameMomentAs(normalizedDay)) {
                    _startDate = null;
                    _endDate = null;
                  } else {
                    _startDate = normalizedDay;
                    _endDate = normalizedDay;
                  }
                  return;
                }

                // RULE 3: Ignore clicks on mid-booking days.
                if (isMidBookingDay) {
                  return;
                }

                // RULE 4: Handle creation/modification of new booking ranges with fixes for edge cases.
                if (_startDate == null) {
                  _startDate = normalizedDay;
                  _endDate = normalizedDay;
                  return;
                } else {
                  // Case: User clicks a day BEFORE the current start date.
                  if (normalizedDay.isBefore(_startDate!)) {
                    // FIX for Scenario 1: If this past day is a check-in day, auto-select its range.
                    if (pressedDayCheckInBooking != null) {
                      final bookingEndDate = DateTime(
                          pressedDayCheckInBooking.checkOut.year,
                          pressedDayCheckInBooking.checkOut.month,
                          pressedDayCheckInBooking.checkOut.day);
                      _startDate = normalizedDay;
                      _endDate = bookingEndDate;
                    } else {
                      // Otherwise, it's a normal unbooked day, so just reset the selection to this day.
                      _startDate = normalizedDay;
                      _endDate = normalizedDay;
                    }
                    return;
                  }

                  // Case: User re-clicks the same single day to deselect it.
                  if (normalizedDay.isAtSameMomentAs(_startDate!) && _startDate == _endDate) {
                    _startDate = null;
                    _endDate = null;
                    return;
                  }

                  // Case: User re-clicks the start or end of an existing date range.
                  if (normalizedDay.isAtSameMomentAs(_startDate!) || normalizedDay.isAtSameMomentAs(_endDate!)) {
                    // FIX for Scenario 2: If re-clicking the END of a range AND it's a check-in day, auto-select.
                    if (_startDate != _endDate && normalizedDay.isAtSameMomentAs(_endDate!) && pressedDayCheckInBooking != null) {
                      final bookingEndDate = DateTime(
                          pressedDayCheckInBooking.checkOut.year,
                          pressedDayCheckInBooking.checkOut.month,
                          pressedDayCheckInBooking.checkOut.day);
                      _startDate = normalizedDay;
                      _endDate = bookingEndDate;
                    } else {
                      // Otherwise, collapse the selection to the clicked day.
                      _startDate = normalizedDay;
                      _endDate = normalizedDay;
                    }
                    return;
                  }

                  // NEW RULE: Prevent selection past the next check-in day.
                  // Check the type of the start day of the current selection.
                  bool isStartDayCheckIn = false;
                  if (_startDate != null) {
                    for (var booking in widget.apartment.bookingInfo) {
                      final checkIn = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
                      if (_startDate!.isAtSameMomentAs(checkIn)) {
                        isStartDayCheckIn = true;
                        break;
                      }
                    }
                  }

                  // The constraint applies if the selection started on a day that was NOT a check-in day.
                  if (_startDate != null && !isStartDayCheckIn) {
                    // Find the nearest future check-in day which acts as a boundary.
                    DateTime? boundary;
                    final futureCheckIns = widget.apartment.bookingInfo
                        .map((b) => DateTime(b.checkIn.year, b.checkIn.month, b.checkIn.day))
                        .where((d) => d.isAfter(_startDate!))
                        .toList();

                    if (futureCheckIns.isNotEmpty) {
                      futureCheckIns.sort((a, b) => a.compareTo(b));
                      boundary = futureCheckIns.first;
                    }

                    // If a boundary exists and the user selected a day after it...
                    if (boundary != null && normalizedDay.isAfter(boundary)) {
                      // ...then the selection is invalid. Reset the start of selection to this new day.
                      _startDate = normalizedDay;
                      _endDate = normalizedDay;
                    } else {
                      // Otherwise, the selection is valid. Extend the range normally.
                      _endDate = normalizedDay;
                    }
                  } else {
                    // If the selection started on a check-in day, the constraint doesn't apply.
                    _endDate = normalizedDay;
                  }
                }
              });
            },
            weekendTextStyle: const TextStyle(color: Colors.red),
            daysHaveCircularBorder: true,
            todayButtonColor: const Color(0xFFE0E7FF),
            todayBorderColor: const Color(0xFF004aad),
            todayTextStyle: const TextStyle(
              color: Color(0xFF004aad),
              fontWeight: FontWeight.bold,
            ),
            markedDateCustomTextStyle: const TextStyle(color: Colors.black),
            maxSelectedDate: DateTime.now().add(const Duration(days: 730)),
            headerTextStyle: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            leftButtonIcon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF004aad),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Colors.white,
                size: 20,
              ),
            ),
            rightButtonIcon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF004aad),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 20,
              ),
            ),
            customDayBuilder: (bool isSelectable,
                int index,
                bool isSelectedDay,
                bool isToday,
                bool isPrevMonthDay,
                TextStyle textStyle,
                bool isNextMonthDay,
                bool isThisMonthDay,
                DateTime day,) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              bool isBooked = bookedDatesSet.contains(normalizedDay);
              bool isStart = _startDate != null &&
                  normalizedDay.isAtSameMomentAs(_startDate!);
              bool isEnd = _endDate != null &&
                  normalizedDay.isAtSameMomentAs(_endDate!);
              bool isBetween = _startDate != null && _endDate != null &&
                  normalizedDay.isAfter(_startDate!) &&
                  normalizedDay.isBefore(_endDate!);

              // NEW LOGIC: Get booking information for this specific day
              List<BookingInfo> dayBookings = [];
              bool isCheckIn = false;
              bool isCheckOut = false;

              if (isBooked) {
                // Find all bookings that include this day
                for (var booking in widget.apartment.bookingInfo) {
                  final checkInNormalized = DateTime(booking.checkIn.year, booking.checkIn.month, booking.checkIn.day);
                  final checkOutNormalized = DateTime(booking.checkOut.year, booking.checkOut.month, booking.checkOut.day);

                  // Check if this day falls within any booking period (inclusive of both check-in and check-out)
                  if ((normalizedDay.isAtSameMomentAs(checkInNormalized) || normalizedDay.isAfter(checkInNormalized)) &&
                      (normalizedDay.isAtSameMomentAs(checkOutNormalized) || normalizedDay.isBefore(checkOutNormalized))) {
                    dayBookings.add(booking);

                    // Check if this day is a check-in for this booking
                    if (normalizedDay.isAtSameMomentAs(checkInNormalized)) {
                      isCheckIn = true;
                    }

                    // Check if this day is a check-out for this booking
                    if (normalizedDay.isAtSameMomentAs(checkOutNormalized)) {
                      isCheckOut = true;
                    }
                  }
                }
              }

              /// MODIFIED/FIXED `buildDots` LOGIC
              Widget buildDots(bool showWhiteDot, bool showBlackDot) {
                if (!showWhiteDot && !showBlackDot) return const SizedBox.shrink();

                return Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left side for black dot (check-out)
                      Expanded(
                        child: showBlackDot
                            ? Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Container(
                              width: 8,   // Made smaller
                              height: 8,  // Made smaller
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 0.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.7),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                            : const SizedBox.shrink(),
                      ),
                      // Center space
                      const Expanded(child: SizedBox.shrink()),
                      // Right side for white dot (check-in)
                      Expanded(
                        child: showWhiteDot
                            ? Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 1), // Adjusted padding
                            child: Container(
                              width: 10,  // Made bigger
                              height: 10, // Made bigger
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 0.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.7),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              }

              // Helper to get the darker, consistent shade for availability colors
              Color getConsistentAvailabilityColor(Color? baseColor) {
                if (baseColor == Colors.green) {
                  return Colors.green.shade700;
                } else if (baseColor == Colors.yellow.shade600) {
                  return Colors.yellow.shade700;
                }
                return baseColor ?? Colors.transparent;
              }

              // MODIFIED/FIXED: Handle start and end selection with corrected half-circle logic
              if (isStart || isEnd) {
                bool isSingleDaySelection = isStart && isEnd;
                bool isCheckoutOnly = isCheckOut && !isCheckIn;

                // Handle the special case of a single-day selection on a checkout-only day
                if (isSingleDaySelection && isCheckoutOnly) {
                  return CustomPaint(
                    painter: _HalfCirclePainter(
                      leftColor: Colors.red, // End of previous booking
                      rightColor: const Color(0xFF004aad), // Newly selected half
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: shadowStyle),
                          ),
                        ),
                        buildDots(isCheckIn, isCheckOut),
                      ],
                    ),
                  );
                }

                // Handle the start of a multi-day selection
                if (isStart && !isSingleDaySelection) {
                  Color rightColor = const Color(0xFF004aad); // Selected half
                  Color leftColor;

                  if (isCheckOut) {
                    // The day before is booked, so the left half is red.
                    leftColor = Colors.red;
                  } else {
                    // The day before is an availability period, so get its color.
                    leftColor = getConsistentAvailabilityColor(
                        _getAvailabilityColorForDay(day.subtract(const Duration(days: 1)), allAvailabilityPeriods)
                    );
                  }

                  return CustomPaint(
                    painter: _HalfCirclePainter(leftColor: leftColor, rightColor: rightColor),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: shadowStyle),
                          ),
                        ),
                        buildDots(isCheckIn, isCheckOut),
                      ],
                    ),
                  );
                }

                // Handle the end of a multi-day selection
                if (isEnd && !isSingleDaySelection) {
                  Color leftColor = const Color(0xFF004aad); // Selected half
                  Color rightColor;

                  if (isCheckIn) {
                    // The day after is booked, so the right half is red.
                    rightColor = Colors.red;
                  } else {
                    // The day after starts a new availability period, so get its color.
                    rightColor = getConsistentAvailabilityColor(
                        _getAvailabilityColorForDay(day, allAvailabilityPeriods)
                    );
                  }

                  return CustomPaint(
                    painter: _HalfCirclePainter(leftColor: leftColor, rightColor: rightColor),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: shadowStyle),
                          ),
                        ),
                        buildDots(isCheckIn, isCheckOut),
                      ],
                    ),
                  );
                }

                // Fallback for all other single-day selections.
                // This renders a full blue circle.
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: const Color(0xFF004aad),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          day.day.toString(),
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: shadowStyle),
                        ),
                      ),
                      if (isBooked) buildDots(isCheckIn, isCheckOut),
                    ],
                  ),
                );
              }


              // FIXED: Handle between dates for both booking and unbooking scenarios
              if (isBetween) {
                // Check if we're in an unbooking scenario (selected range is entirely booked)
                bool isUnbookingScenario = _startDate != null && _endDate != null &&
                    _isEntireRangeBooked(bookedDatesSet);

                if (isUnbookingScenario) {
                  // For unbooking, show selected style even for booked days in between
                  Color backgroundColor = const Color(0xFF5A9FFF); // Better light blue for white text visibility

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF004aad),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: shadowStyle,
                            ),
                          ),
                        ),
                        if (isBooked)
                          buildDots(isCheckIn, isCheckOut),
                      ],
                    ),
                  );
                } else {
                  // Original logic for new bookings
                  if (isBooked) {
                    // This case handles a booked day within a new selection range.
                    // It should visually appear as unavailable.
                    Color leftColor = Colors.red;
                    Color rightColor = Colors.red;

                    return CustomPaint(
                      painter: _HalfCirclePainter(leftColor: leftColor, rightColor: rightColor),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              day.day.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: shadowStyle,
                              ),
                            ),
                          ),
                          buildDots(isCheckIn, isCheckOut),
                        ],
                      ),
                    );
                  } else {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5A9FFF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF004aad),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          day.day.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: shadowStyle,
                          ),
                        ),
                      ),
                    );
                  }
                }
              }

              if (isBooked) {
                Color leftColor;
                Color rightColor;

                if (isCheckIn && isCheckOut) {
                  // This is a transition day (e.g., one guest checks out, another checks in). Render as full red.
                  leftColor = Colors.red;
                  rightColor = Colors.red;
                } else if (isCheckOut) {
                  // This is an "only check-out" day.
                  // The left half is red (end of the booked period).
                  // The right half shows the color of the new availability period that starts today.
                  leftColor = Colors.red;
                  rightColor = getConsistentAvailabilityColor(
                      _getAvailabilityColorForDay(day, allAvailabilityPeriods)
                  );
                } else if (isCheckIn) {
                  // This is an "only check-in" day.
                  // The left half shows the color of the previous day's availability.
                  // The right half is red (start of the booked period).
                  leftColor = getConsistentAvailabilityColor(
                      _getAvailabilityColorForDay(day.subtract(const Duration(days: 1)), allAvailabilityPeriods)
                  );
                  rightColor = Colors.red;
                } else {
                  // This is a day in the middle of a booking. Render as full red.
                  leftColor = Colors.red;
                  rightColor = Colors.red;
                }


                return CustomPaint(
                  painter: _HalfCirclePainter(leftColor: leftColor, rightColor: rightColor),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          day.day.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: shadowStyle,
                          ),
                        ),
                      ),
                      buildDots(isCheckIn, isCheckOut),
                    ],
                  ),
                );
              }


              // Rest of the method remains the same for availability periods...
              for (var period in allAvailabilityPeriods) {
                if ((normalizedDay.isAfter(period['start']) ||
                    normalizedDay.isAtSameMomentAs(period['start'])) &&
                    (normalizedDay.isBefore(period['end']) ||
                        normalizedDay.isAtSameMomentAs(period['end']))) {
                  Color borderColor = isToday ? const Color(0xFF004aad) : Colors.transparent;
                  double borderWidth = isToday ? 2.0 : 0.0;
                  Color fillColor = (period['color'] as Color);

                  if (fillColor == Colors.green) {
                    fillColor = Colors.green.shade700;
                  } else if (fillColor == Colors.yellow.shade600) {
                    fillColor = Colors.yellow.shade700;
                  }


                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: fillColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: borderWidth),
                    ),
                    child: Center(
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: shadowStyle,
                        ),
                      ),
                    ),
                  );
                }
              }

              if (isToday) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF004aad), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      day.day.toString(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }

              return null;
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final now = DateTime.now();
    final isDailyEmphasis = now.month >= 7 && now.month <= 9;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            spreadRadius: 3,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          onLongPress: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ApartmentDetailsScreen(apartment: widget.apartment),
              ),
            );

            if (mounted) {
              if (result == null) {
                // Apartment was deleted - refresh the list
                setState(() {});
              } else if (result is Apartment) {
                // Apartment was updated - update the list
                setState(() {});
              }
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: const Color(0xFF004aad),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: SizedBox(
                      height: 200,
                      child: Stack(
                        children: [
// Replace the PageView.builder in the ApartmentCard with this:
                          PageView.builder(
                            controller: _pageController,
                            itemCount: widget.apartment.imageUrls.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onHorizontalDragStart: (details) {
                                  _pageController.position.hold(() {});
                                },
                                onHorizontalDragUpdate: (details) {
                                  _pageController.position.moveTo(
                                    _pageController.position.pixels -
                                        details.primaryDelta!,
                                    duration: Duration.zero,
                                  );
                                },
                                onHorizontalDragEnd: (details) {
                                  _pageController.position.animateTo(
                                    _pageController.position.pixels -
                                        details.primaryVelocity! * 0.1,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                },
                                child: Image.network(
                                  widget.apartment.imageUrls[index],
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child,
                                      loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                            .expectedTotalBytes != null
                                            ? loadingProgress
                                            .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('Error loading image: $error');
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center,
                                        children: [
                                          const Icon(Icons.broken_image, size: 50,
                                              color: Colors.grey),
                                          Text('Failed to load image',
                                              style: TextStyle(
                                                  color: Colors.grey[600])),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            onPageChanged: (int page) {
                              setState(() {
                                _currentPage = page;
                              });
                            },
                          ),
                          if (widget.apartment.imageUrls.length > 1)
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List<Widget>.generate(
                                  widget.apartment.imageUrls.length,
                                      (index) =>
                                      GestureDetector(
                                        onTap: () {
                                          _pageController.animateToPage(
                                            index,
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _currentPage == index
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.5),
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.apartment.geAddress,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Color(0xFF004aad)),
                          onPressed: _showShareOptionsDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.apartment.ownerNumber.isNotEmpty
                          ? 'მეპატრონე: \n${widget.ownerName} — ${widget.apartment
                          .ownerNumber}'
                          : 'მეპატრონე: \n${widget.ownerName}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.apartment.tags
                            .map((tag) =>
                            Container(
                              margin: const EdgeInsets.only(right: 8.0),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF004aad).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF004aad).withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  color: Color(0xFF004aad),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onLongPress: () => _showPriceEditDialog('Daily'),
                          child: _buildPriceLabel(
                            price: widget.apartment.dailyPrice,
                            unit: '₾/დღე',
                            isPrimary: isDailyEmphasis,
                          ),
                        ),
                        GestureDetector(
                          onLongPress: () => _showPriceEditDialog('Monthly'),
                          child: _buildPriceLabel(
                            price: widget.apartment.monthlyPrice,
                            unit: '\$/თვე',
                            isPrimary: !isDailyEmphasis,
                            isUSD: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      rooms: widget.apartment.geAppRoom,
                      bedrooms: widget.apartment.geAppBedroom,
                      squareMeters: widget.apartment.squareMeters,
                      peopleCapacity: widget.apartment.peopleCapacity,
                    ),
                    const SizedBox(height: 8),
                    // Use ValueListenableBuilder for dynamic content
                    ValueListenableBuilder<Set<DateTime>>(
                      valueListenable: bookedDatesNotifier,
                      builder: (context, bookedDatesSet, child) {
                        final nearestAvailabilityStatus = _getNearestAvailabilityStatus(
                            bookedDatesSet);
                        final allAvailabilityPeriods = _getAvailabilityPeriods(
                            bookedDatesSet, widget.apartment.bookingInfo);
                        final bool isUnbooking = _startDate != null &&
                            _endDate != null &&
                            _isEntireRangeBooked(bookedDatesSet);

                        return Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: nearestAvailabilityStatus['color'] == Colors.red
                                      ? Colors.red
                                      : nearestAvailabilityStatus['color'] == Colors.green
                                      ? Colors.green
                                      : Colors.yellow.shade700,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: nearestAvailabilityStatus['color'],
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  nearestAvailabilityStatus['text'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.6),
                                        blurRadius: 1.5,
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: _isExpanded
                                  ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(
                                    color: const Color(0xFF004aad).withOpacity(
                                        0.5),
                                    thickness: 1.5,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildCalendar(
                                      bookedDatesSet, allAvailabilityPeriods),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          // MODIFIED: Enable button only if an existing booking is selected OR the new range is at least 2 days.
                                          onPressed: (_startDate != null && _endDate != null) && (isUnbooking || _endDate!.isAfter(_startDate!))
                                              ? () {
                                            // Decide which action to perform
                                            if (isUnbooking) {
                                              _editBooking(); // An existing booking is selected, so we edit
                                            } else {
                                              _bookApartment(); // A new range is selected, so we book
                                            }
                                          }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            // Use different colors for "Edit" and "Book" modes
                                            backgroundColor: isUnbooking
                                                ? const Color(0xFF5A9FFF) // Edit button color
                                                : const Color(0xFF004aad), // Book button color
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                          ),
                                          child: Text(
                                            isUnbooking ? 'დეტალები' : 'დაჯავშნა', // Change text based on mode
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              // Add shadow for better readability
                                              shadows: <Shadow>[
                                                Shadow(
                                                  offset: Offset(1.0, 1.0),
                                                  blurRadius: 2.0,
                                                  color: Color.fromARGB(128, 0, 0, 0),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        );
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceLabel({
    required double price,
    required String unit,
    required bool isPrimary,
    bool isUSD = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isUSD ? '\$${NumberFormat('#,##0').format(price)}' : '${NumberFormat(
              '#,##0').format(price)}₾',
          style: TextStyle(
            fontSize: isPrimary ? 24 : 16,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            color: isPrimary ? const Color(0xFF004aad) : Colors.grey[600],
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required String rooms,
    required String bedrooms,
    required double squareMeters,
    required int peopleCapacity,
  }) {
    return Row(
      children: [
        const Icon(Icons.house, color: Color(0xFF004aad), size: 18),
        const SizedBox(width: 4),
        Text(
          rooms
              .split('-')
              .first,
          style: const TextStyle(color: Color(0xFF004aad)),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.king_bed, color: Color(0xFF004aad), size: 18),
        const SizedBox(width: 4),
        Text(
          bedrooms
              .split('-')
              .first,
          style: const TextStyle(color: Color(0xFF004aad)),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.people, color: Color(0xFF004aad), size: 18),
        const SizedBox(width: 4),
        Text(
          peopleCapacity.toString(),
          style: const TextStyle(color: Color(0xFF004aad)),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.square_foot, color: Color(0xFF004aad), size: 18),
        const SizedBox(width: 4),
        Text(
          '${squareMeters.toStringAsFixed(0)} m²',
          style: const TextStyle(color: Color(0xFF004aad)),
        ),
      ],
    );
  }
}


// You can replace your entire BookingConfirmationDialog class with this updated version.

// You can replace your entire BookingConfirmationDialog class with this updated version.

enum DocumentType {
  none,
  invoice,
  contract,
}

class BookingConfirmationDialog extends StatefulWidget {
  final Apartment apartment;
  final DateTime startDate;
  final DateTime endDate;
  final FirestoreService firestoreService;
  final ValueNotifier<Set<DateTime>> bookedDatesNotifier;
  final Function() onBookingSuccess;
  final DocumentType initialDocumentType;
  final Map<String, dynamic>? initialBookingData;

  const BookingConfirmationDialog({
    super.key,
    required this.apartment,
    required this.startDate,
    required this.endDate,
    required this.firestoreService,
    required this.bookedDatesNotifier,
    required this.onBookingSuccess,
    this.initialDocumentType = DocumentType.invoice,
    this.initialBookingData,
  });

  @override
  State<BookingConfirmationDialog> createState() =>
      _BookingConfirmationDialogState();
}

class _BookingConfirmationDialogState extends State<BookingConfirmationDialog> {
  late bool _isEditMode;

  // This map will hold the initial state of the form to check for changes.
  Map<String, dynamic> _initialFormState = {};

  late DocumentType _selectedDocumentType;
  final TextEditingController _prepaymentController = TextEditingController();
  final TextEditingController _prepaymentLeftController = TextEditingController();
  final TextEditingController _profitFromPrepaymentController =
  TextEditingController();
  final TextEditingController _profitLeftToPayController =
  TextEditingController();
  final TextEditingController _pricingOnTopController = TextEditingController();
  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _deleteConfirmationController =
  TextEditingController();

  String _selectedNameForMyProfit = 'მაკოს';
  String _selectedNameForPartnerProfit = 'მაკოს';

  late int _days;
  late double _months;
  late double _basePricePerUnit;
  late double _totalBasePrice;
  late double _pricingOnTop;
  late double _totalProfit;
  late double _profitLeft;
  int _currentImagePage = 0;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.initialBookingData != null;
    _calculateDurationAndPrice();

    if (_isEditMode) {
      _populateFieldsForEdit();
      _captureInitialFormState(); // Capture the state after populating
    } else {
      _initializeFieldsForCreate();
    }
  }

  // A new getter to check if the form data has changed from its initial state.
  bool get _isFormDirty {
    if (!_isEditMode) return false; // Not relevant in create mode.

    return _initialFormState['pricingOnTop'] != _pricingOnTopController.text ||
        _initialFormState['prepayment'] != _prepaymentController.text ||
        _initialFormState['prepaymentLeft'] != _prepaymentLeftController.text ||
        _initialFormState['profitFromPrepayment'] !=
            _profitFromPrepaymentController.text ||
        _initialFormState['profitLeftToPay'] !=
            _profitLeftToPayController.text ||
        _initialFormState['guestName'] != _guestNameController.text ||
        _initialFormState['selectedNameForPartnerProfit'] !=
            _selectedNameForPartnerProfit;
  }

  void _captureInitialFormState() {
    _initialFormState = {
      'pricingOnTop': _pricingOnTopController.text,
      'prepayment': _prepaymentController.text,
      'prepaymentLeft': _prepaymentLeftController.text,
      'profitFromPrepayment': _profitFromPrepaymentController.text,
      'profitLeftToPay': _profitLeftToPayController.text,
      'guestName': _guestNameController.text,
      'selectedNameForPartnerProfit': _selectedNameForPartnerProfit,
    };
  }

  void _populateFieldsForEdit() {
    final data = widget.initialBookingData!;
    _pricingOnTop = data['pricingOnTop'] as double? ?? 0.0;

    _pricingOnTopController.text = _pricingOnTop.toStringAsFixed(0);
    _prepaymentController.text =
        (data['prepayment'] as double? ?? 0.0).toStringAsFixed(0);
    _prepaymentLeftController.text =
        (data['prepaymentLeft'] as double? ?? 0.0).toStringAsFixed(0);
    _profitFromPrepaymentController.text =
        (data['profitFromPrepayment'] as double? ?? 0.0).toStringAsFixed(0);
    _profitLeftToPayController.text =
        (data['profitLeftToPay'] as double? ?? 0.0).toStringAsFixed(0);
    _guestNameController.text = data['guestName'] as String? ?? '';
    _selectedNameForMyProfit =
        data['selectedNameForMyProfit'] as String? ?? 'მაკოს';
    _selectedNameForPartnerProfit =
        data['selectedNameForPartnerProfit'] as String? ?? 'მაკოს';

    _calculateProfit();
  }

  void _initializeFieldsForCreate() {
    _selectedDocumentType = widget.initialDocumentType;
    _pricingOnTop = 0.0;
    _pricingOnTopController.text = _pricingOnTop.toStringAsFixed(0);
    _prepaymentController.text = "0";
    _prepaymentLeftController.text = "0";
    _profitFromPrepaymentController.text = "0";
    _profitLeftToPayController.text = "0";
    _calculateProfit();
  }

  @override
  void dispose() {
    // Dispose all controllers
    _prepaymentController.dispose();
    _prepaymentLeftController.dispose();
    _profitFromPrepaymentController.dispose();
    _profitLeftToPayController.dispose();
    _pricingOnTopController.dispose();
    _guestNameController.dispose();
    _deleteConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteConfirmationDialog() {
    _deleteConfirmationController.clear();
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            const requiredText = "ჯავშნის წაშლა";
            final bool canDelete =
                _deleteConfirmationController.text == requiredText;

            return AlertDialog(
              title: const Text('Delete Booking Confirmation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'To delete this booking, please type the following exactly:'),
                  const SizedBox(height: 8),
                  const Text(
                    requiredText,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _deleteConfirmationController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Type here to confirm',
                    ),
                    onChanged: (value) {
                      setDialogState(
                              () {}); // Re-build dialog to check button state
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: canDelete ? _deleteBooking : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm Deletion'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteBooking() async {
    final docId = widget.initialBookingData?['docId'] as String?;
    final bookingId = widget.initialBookingData?['bookingId'] as String?;
    final apartmentId = widget.apartment.id;

    if (docId == null || bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: Could not identify booking to delete.')),
      );
      return;
    }

    try {
      await widget.firestoreService.deleteOngoingBooking(
        docId: docId,
        apartmentId: apartmentId,
        bookingId: bookingId,
      );

      if (!mounted) return;
      // Close both dialogs
      Navigator.of(context).pop(); // Close delete confirmation
      Navigator.of(context).pop(); // Close edit dialog

      widget.onBookingSuccess(); // This resets the calendar selection

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking successfully deleted.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete booking: $e')),
      );
    }
  }

  /// MODIFIED/FIXED: `_updateBooking` now shows a custom success dialog instead of a SnackBar.
  Future<void> _updateBooking() async {
    final docId = widget.initialBookingData?['docId'] as String?;
    if (docId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Booking ID not found.')),
        );
      }
      return;
    }

    final updatedData = {
      'startDate': widget.startDate,
      'endDate': widget.endDate,
      'days': _days,
      'months': _months,
      'totalBasePrice': _totalBasePrice,
      'pricingOnTop': _pricingOnTop,
      'totalProfit': _totalProfit,
      'profitLeft': _profitLeft,
      'prepayment': double.tryParse(_prepaymentController.text) ?? 0.0,
      'prepaymentLeft': double.tryParse(_prepaymentLeftController.text) ?? 0.0,
      'profitFromPrepayment':
      double.tryParse(_profitFromPrepaymentController.text) ?? 0.0,
      'profitLeftToPay':
      double.tryParse(_profitLeftToPayController.text) ?? 0.0,
      'guestName': _guestNameController.text,
      'selectedNameForMyProfit': _selectedNameForMyProfit,
      'selectedNameForPartnerProfit': _selectedNameForPartnerProfit,
    };

    try {
      await widget.firestoreService.updateOngoingBooking(docId, updatedData);
      if (mounted) {
        Navigator.pop(context); // Close the main dialog
        widget.onBookingSuccess();

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            Future.delayed(const Duration(seconds: 2), () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
            return const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF004aad), size: 48),
                  SizedBox(height: 16),
                  Text('ცვლილებები შეინახა', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update booking: $e')),
        );
      }
    }
  }

  String _formatGeorgianDate(DateTime date) {
    const georgianMonths = [
      'იან', 'თებ', 'მარ', 'აპრ', 'მაი', 'ივნ',
      'ივლ', 'აგვ', 'სექ', 'ოქტ', 'ნოე', 'დეკ'
    ];

    return '${date.day.toString().padLeft(2, '0')}/${georgianMonths[date.month - 1]}/${date.year}';
  }

  void _calculateDurationAndPrice() {
    _days = widget.endDate.difference(widget.startDate).inDays;

    if (_days <= 29) {
      _months = 0;
      _basePricePerUnit = widget.apartment.dailyPrice;
      _totalBasePrice = _days * _basePricePerUnit;
    } else {
      final exactMonths = _days / 30;
      final fullMonths = exactMonths.floor();
      final remainder = exactMonths - fullMonths;

      if (remainder < 0.25) {
        _months = fullMonths.toDouble();
      } else if (remainder < 0.75) {
        _months = fullMonths + 0.5;
      } else {
        _months = fullMonths + 1.0;
      }

      _basePricePerUnit = widget.apartment.monthlyPrice;
      _totalBasePrice = _months * _basePricePerUnit;
    }
  }

  void _calculateProfit() {
    if (_days <= 29) {
      _totalProfit = _days * _pricingOnTop;
      _profitLeft = _totalProfit -
          (double.tryParse(_profitFromPrepaymentController.text) ?? 0.0);
    } else {
      _totalProfit = _months * _pricingOnTop;
      _profitLeft = _totalProfit -
          (double.tryParse(_profitFromPrepaymentController.text) ?? 0.0);
    }
  }

  Widget _buildNameSelectionButtons(
      String selectedName, Function(String) onNameSelected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNameButton(
            'მაკოს', selectedName == 'მაკოს', () => onNameSelected('მაკოს')),
        const SizedBox(width: 4),
        _buildNameButton(
            'მზიას', selectedName == 'მზიას', () => onNameSelected('მზიას')),
        const SizedBox(width: 4),
        _buildNameButton(
            'სალოს', selectedName == 'სალოს', () => onNameSelected('სალოს')),
      ],
    );
  }

  Widget _buildNameButton(String name, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
        setState(() {
          _selectedNameForPartnerProfit = name;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF004aad) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF004aad) : Colors.grey.shade400,
            width: 1,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildProfitDistribution() {
    final profitFromPrepayment =
        double.tryParse(_profitFromPrepaymentController.text) ?? 0.0;
    final prepayment = double.tryParse(_prepaymentController.text) ?? 0.0;
    final prepaymentLeft =
        double.tryParse(_prepaymentLeftController.text) ?? 0.0;
    final profitLeftToPay =
        double.tryParse(_profitLeftToPayController.text) ?? 0.0;

    final myShare = _profitLeft / 2 - profitFromPrepayment / 2;
    final partnerShare = _profitLeft / 2 + profitFromPrepayment / 2;

    final myFinalAmount = myShare - profitLeftToPay;
    final partnerFinalAmount = partnerShare - prepaymentLeft;

    final currency = _days <= 29 ? '₾' : '\$';
    final isLari = currency == '₾';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPricingRow(
          'ჯამური ფასი:',
          isLari
              ? '${_totalBasePrice.toStringAsFixed(0)}$currency'
              : '$currency${_totalBasePrice.toStringAsFixed(0)}',
          isBold: true,
          fontSize: 20,
        ),
        const SizedBox(height: 8),
        _buildPricingRow(
          'მეპატრონეს:',
          isLari
              ? '${(_totalBasePrice - _totalProfit).toStringAsFixed(0)}$currency'
              : '$currency${(_totalBasePrice - _totalProfit).toStringAsFixed(0)}',
          isBold: true,
          fontSize: 18,
        ),
        const SizedBox(height: 8),
        _buildPricingRow(
          'მოგება:',
          isLari
              ? '${_totalProfit.toStringAsFixed(0)}$currency'
              : '$currency${_totalProfit.toStringAsFixed(0)}',
          isBold: true,
          color: const Color(0xFF004aad),
          fontSize: 18,
        ),
        const SizedBox(height: 8),
        _buildPricingRow(
          'ჯავშანი:',
          isLari
              ? '${prepayment.toStringAsFixed(0)}$currency'
              : '$currency${prepayment.toStringAsFixed(0)}',
          isBold: true,
          color: const Color(0xFF004aad),
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
                color: Colors.blue,
                fontSize: 14,
              ),
              _buildPricingRow(
                'მივეცი:',
                isLari
                    ? '${(prepayment - profitFromPrepayment).toStringAsFixed(0)}$currency'
                    : '$currency${(prepayment - profitFromPrepayment).toStringAsFixed(0)}',
                color: Colors.blue,
                fontSize: 14,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildPricingRow(
          'დარჩ. ასაღები:',
          isLari
              ? '${(_totalProfit - profitFromPrepayment).toStringAsFixed(0)}$currency'
              : '$currency${(_totalProfit - profitFromPrepayment).toStringAsFixed(0)}',
          isBold: true,
          color: const Color(0xFF004aad),
          fontSize: 16,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ჩემი:',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: isLari
                              ? '${myFinalAmount.toStringAsFixed(0)}$currency'
                              : '$currency${myFinalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 14, color: Colors.blue),
                        ),
                        if (profitLeftToPay > 0)
                          TextSpan(
                            text: isLari
                                ? ' + ${profitLeftToPay.toStringAsFixed(0)}$currency ჩემთვის მოსაცემი $_selectedNameForPartnerProfit'
                                : ' + $currency${profitLeftToPay.toStringAsFixed(0)} ჩემთვის მოსაცემი $_selectedNameForPartnerProfit',
                            style: const TextStyle(fontSize: 14, color: Colors.green),
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
                  Text(
                    '$_selectedNameForPartnerProfit:',
                    style: const TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: isLari
                              ? '${partnerFinalAmount.toStringAsFixed(0)}$currency'
                              : '$currency${partnerFinalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 14, color: Colors.blue),
                        ),
                        if (prepaymentLeft > 0)
                          TextSpan(
                            text: isLari
                                ? ' + ${prepaymentLeft.toStringAsFixed(0)}$currency ჩემგან მისაცემი $_selectedNameForPartnerProfit'
                                : ' + $currency${prepaymentLeft.toStringAsFixed(0)} ჩემგან მისაცემი $_selectedNameForPartnerProfit',
                            style: const TextStyle(fontSize: 14, color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            children: [
              _buildNameSelectionButtons(_selectedNameForPartnerProfit, (name) {
                setState(() {
                  _selectedNameForPartnerProfit = name;
                });
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _getDurationDisplay() {
    if (_days <= 29) {
      return '$_days ღამე';
    } else {
      return '${_months.toInt()} თვე';
    }
  }

  String _getPricePerUnitDisplay() {
    if (_days <= 29) {
      return '${widget.apartment.dailyPrice}₾/დღე';
    } else {
      return '\$${widget.apartment.monthlyPrice}/თვე';
    }
  }

  Future<void> _confirmBooking() async {
    final dates = _getDatesInRange(widget.startDate, widget.endDate);
    final newSet = Set<DateTime>.from(widget.bookedDatesNotifier.value)
      ..addAll(dates);
    widget.bookedDatesNotifier.value = newSet;

    try {
      final apartment =
      await widget.firestoreService.getApartmentById(widget.apartment.id);
      if (apartment == null) throw Exception('Apartment not found');

      final bookingId =
          '${apartment.id}_${widget.startDate.millisecondsSinceEpoch}';

      await widget.firestoreService.addOngoingBooking(
        apartment: apartment,
        bookingData: {
          'bookingId': bookingId,
          'startDate': widget.startDate,
          'endDate': widget.endDate,
          'days': _days,
          'months': _months,
          'totalBasePrice': _totalBasePrice,
          'pricingOnTop': _pricingOnTop,
          'totalProfit': _totalProfit,
          'profitLeft': _profitLeft,
          'prepayment': double.tryParse(_prepaymentController.text) ?? 0.0,
          'prepaymentLeft':
          double.tryParse(_prepaymentLeftController.text) ?? 0.0,
          'profitFromPrepayment':
          double.tryParse(_profitFromPrepaymentController.text) ?? 0.0,
          'profitLeftToPay':
          double.tryParse(_profitLeftToPayController.text) ?? 0.0,
          'documentType': _selectedDocumentType.toString(),
          'guestName': _guestNameController.text,
          'selectedNameForMyProfit': _selectedNameForMyProfit,
          'selectedNameForPartnerProfit': _selectedNameForPartnerProfit,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully booked')),
        );
        widget.onBookingSuccess();
        Navigator.pop(context);

        if (_selectedDocumentType == DocumentType.invoice) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceGeneratorScreen(
                prefilledData: {
                  'apartment': apartment,
                  'startDate': widget.startDate,
                  'endDate': widget.endDate,
                  'totalPrice': _totalBasePrice,
                  'invoiceType': _days <= 29 ? 'Daily' : 'Monthly',
                  'recipient': _guestNameController.text.isNotEmpty
                      ? _guestNameController.text
                      : 'კლიენტი',
                },
              ),
            ),
          );
        } else if (_selectedDocumentType == DocumentType.contract) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OngoingBookedApartmentsScreen(),
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully booked')),
        );
        widget.onBookingSuccess();
        Navigator.pop(context); // Closes the booking dialog

        if (_selectedDocumentType == DocumentType.invoice) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceGeneratorScreen(
                // Add this parameter to trigger the popup
                showVerificationPopup: true,
                prefilledData: {
                  'apartment': apartment,
                  'startDate': widget.startDate,
                  'endDate': widget.endDate,
                  'totalPrice': _totalBasePrice,
                  'invoiceType': _days <= 29 ? 'Daily' : 'Monthly',
                  'recipient': _guestNameController.text.isNotEmpty
                      ? _guestNameController.text
                      : 'კლიენტი',
                },
              ),
            ),
          );
        } else if (_selectedDocumentType == DocumentType.contract) {
          Navigator.push(
            context,
            MaterialPageRoute(
              // Add this parameter to trigger the popup
              builder: (context) => const ContractFormScreen(showVerificationPopup: true),
            ),
          );
        }
      }

    } catch (e) {
      if (mounted) {
        widget.bookedDatesNotifier.value =
        Set<DateTime>.from(widget.bookedDatesNotifier.value)
          ..removeAll(dates);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    }
  }

  List<DateTime> _getDatesInRange(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    return List.generate(
        days, (i) => DateTime(start.year, start.month, start.day + i));
  }

  Widget _buildPricingRow(String label, String value,
      {bool isBold = false, Color? color, double fontSize = 14}) {
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
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeOption({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    double width = double.infinity,
  }) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF004aad) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
              isActive ? const Color(0xFF004aad) : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'დოკუმენტის შედგენა:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDocumentTypeOption(
                label: 'ინვოისი',
                isActive: _selectedDocumentType == DocumentType.invoice,
                onTap: () =>
                    setState(() => _selectedDocumentType = DocumentType.invoice),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDocumentTypeOption(
                label: 'ხელშეკრულება',
                isActive: _selectedDocumentType == DocumentType.contract,
                onTap: () =>
                    setState(() => _selectedDocumentType = DocumentType.contract),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageCarousel() {
    final images = widget.apartment.imageUrls;
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _currentImagePage = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child:
                          Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            images.length,
                (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentImagePage
                    ? const Color(0xFF004aad)
                    : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    /// MODIFIED/FIXED: Added constants for reused styles
    const accentColor = Color(0xFF004aad);
    const labelTextStyle = TextStyle(color: accentColor);
    const focusedBorderStyle = OutlineInputBorder(
      borderSide: BorderSide(color: accentColor, width: 2.0),
    );

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: accentColor, width: 2.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 600,
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditMode)
                      const SizedBox(width: 44)
                    else
                      const SizedBox.shrink(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _isEditMode
                              ? 'ჯავშნის რედაქტირება'
                              : 'ჯავშნის დადასტურება',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ),
                    if (_isEditMode)
                      IconButton(
                        splashRadius: 24,
                        icon: const Icon(Icons.delete_forever,
                            color: Colors.red, size: 30),
                        onPressed: _showDeleteConfirmationDialog,
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
                const SizedBox(height: 16),
                _buildImageCarousel(),
                Text(
                  widget.apartment.geAddress,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.apartment.ownerNumber.isNotEmpty
                      ? 'მეპატრონე: ${widget.apartment.ownerName} - ${widget.apartment.ownerNumber}'
                      : 'მეპატრონე: ${widget.apartment.ownerName}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                // --- MODIFICATION START ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('შესვლა — გამოსვლა:',
                          style:
                          TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.bold)),
                      Text(
                          '${_formatGeorgianDate(widget.startDate)} — ${_formatGeorgianDate(widget.endDate)}',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ხანგრძლივობა:',
                          style:
                          TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.bold)),
                      Text(_getDurationDisplay(),
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ფასი:',
                          style:
                          TextStyle(fontSize: 14, color: accentColor, fontWeight: FontWeight.bold)),
                      Text(_getPricePerUnitDisplay(),
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                // --- MODIFICATION END ---

                const Divider(height: 30, thickness: 1.5),

                /// MODIFIED/FIXED: Applied new styles to all TextFields
                TextField(
                  controller: _pricingOnTopController,
                  decoration: InputDecoration(
                    labelText:
                    'ფასი ზემოდან ${_days <= 29 ? '(დღე)' : '(თვე)'} ${_days <= 29 ? '₾' : '\$'}',
                    border: const OutlineInputBorder(),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    labelStyle: labelTextStyle,
                    focusedBorder: focusedBorderStyle,
                  ),
                  style: const TextStyle(fontSize: 16),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _pricingOnTop = double.tryParse(value) ?? 0.0;
                      _calculateProfit();
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _prepaymentController,
                  decoration: InputDecoration(
                    labelText: 'ჯავშანი (${_days <= 29 ? '₾' : '\$'})',
                    border: const OutlineInputBorder(),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    labelStyle: labelTextStyle,
                    focusedBorder: focusedBorderStyle,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _profitFromPrepaymentController,
                  decoration: InputDecoration(
                    labelText:
                    'ჯავშნიდან ავიღე: (${_days <= 29 ? '₾' : '\$'})',
                    border: const OutlineInputBorder(),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    labelStyle: labelTextStyle,
                    focusedBorder: focusedBorderStyle,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _calculateProfit();
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _profitLeftToPayController,
                  decoration: InputDecoration(
                    labelText:
                    'მოგებიდან დარჩ. მოსაცემი თანხა (${_days <= 29 ? '₾' : '\$'})',
                    border: const OutlineInputBorder(),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    labelStyle: labelTextStyle,
                    focusedBorder: focusedBorderStyle,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _prepaymentLeftController,
                  decoration: InputDecoration(
                    labelText:
                    'მოგებიდან დარჩ. მისაცემი თანხა (${_days <= 29 ? '₾' : '\$'})',
                    border: const OutlineInputBorder(),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    labelStyle: labelTextStyle,
                    focusedBorder: focusedBorderStyle,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                _buildProfitDistribution(),
                const SizedBox(height: 16),
                if (!_isEditMode) ...[
                  _buildDocumentTypeSelector(),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _guestNameController,
                  decoration: InputDecoration(
                    labelText: 'სტუმრის სახელი',
                    border: const OutlineInputBorder(),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    labelStyle: labelTextStyle,
                    focusedBorder: focusedBorderStyle,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'გაუქმება',
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isEditMode
                              ? (_isFormDirty ? _updateBooking : null)
                              : _confirmBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _isEditMode ? 'შენახვა' : 'დადასტურება',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}