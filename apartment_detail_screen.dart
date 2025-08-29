import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:realtor_app/data/app_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:realtor_app/invoice_generator_screen.dart';
import 'package:realtor_app/contract_form_screen.dart';
import '../utils/custom_snackbar.dart'; // <-- IMPORT THE NEW SNACKBAR HELPER


class ApartmentDetailsScreen extends StatefulWidget {
  Apartment apartment;

  ApartmentDetailsScreen({super.key, required this.apartment});

  @override
  State<ApartmentDetailsScreen> createState() => _ApartmentDetailsScreenState();
}

class _ApartmentDetailsScreenState extends State<ApartmentDetailsScreen>
    with TickerProviderStateMixin {
  // --- UNDO SYSTEM VARIABLES REMOVED ---

  // Existing variables
  int _currentImageIndex = 0;
  late PageController _pageController;
  bool _isOwnerExpanded = false; // State for the new Owner collapsible
  final TextEditingController _deleteConfirmationController =
  TextEditingController();
  bool _isSaving = false;

  // FAB Animation variables
  late AnimationController _animationController;
  late Animation<double> _translateButton;
  bool _isFabMenuOpen = false;
  List<Widget> _fabChildren = [];
  final double _fabHeight = 56.0;
  final double _fabWidth = 56.0;
  final double _fabSpacing = 20.0;

  late List<AnimationController> _fabAnimations;
  late List<Animation<double>> _fabScales;
  late List<Animation<double>> _fabFades;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _translateButton = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() {
            _isFabMenuOpen = false;
          });
        }
      }
    });

    _fabAnimations = [
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 200)),
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 200)),
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 200)),
      AnimationController(
          vsync: this, duration: const Duration(milliseconds: 200)),
    ];

    _fabScales = _fabAnimations
        .map((controller) =>
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Curves.easeOutBack,
          ),
        ))
        .toList();

    _fabFades = _fabAnimations
        .map((controller) =>
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
          ),
        ))
        .toList();

    _fabChildren = [
      _buildFabChild(0, Icons.delete, 'წაშლა', Colors.red,
          _showDeleteConfirmationDialog),
      _buildFabChild(
          1, Icons.edit, 'რედაქტირება', const Color(0xFF004aad), _handleEdit),
      // --- MODIFICATION START ---
      _buildFabChild(2, Icons.assignment, 'ხელშეკრულება', // Changed from Icons.description
          const Color(0xFF004aad), _navigateToContract),
      _buildFabChild(3, Icons.receipt_long, 'ინვოისი', const Color(0xFF004aad), // Changed from Icons.receipt
          _navigateToInvoice),
      // --- MODIFICATION END ---
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _fabAnimations) {
      controller.dispose();
    }
    _pageController.dispose();
    _deleteConfirmationController.dispose();
    // --- UNDO TIMER REMOVED ---
    super.dispose();
  }

  Widget _buildFabChild(
      int index, IconData icon, String tooltip, Color bgColor, VoidCallback onPressed) {
    return ScaleTransition(
      scale: _fabScales[index],
      child: FadeTransition(
        opacity: _fabFades[index],
        child: Container(
          width: 45,
          height: 45,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _isSaving ? Colors.grey : bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, size: 20, color: Colors.white),
            onPressed: _isSaving ? null : onPressed,
            padding: EdgeInsets.zero,
            tooltip: tooltip,
          ),
        ),
      ),
    );
  }

  void _handleEdit() {
    _toggleFabMenu();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditApartmentScreen(apartment: widget.apartment),
      ),
    ).then((result) {
      if (mounted) {
        if (result is Apartment) {
          setState(() {
            widget.apartment = result;
          });
        }
      }
    });
  }

  void _animateFabChildren(bool isOpening) {
    const staggerDuration = Duration(milliseconds: 50);
    if (isOpening) {
      for (int i = _fabAnimations.length - 1; i >= 0; i--) {
        Future.delayed(staggerDuration * (_fabAnimations.length - 1 - i), () {
          if (mounted) {
            _fabAnimations[i].forward();
          }
        });
      }
    } else {
      for (int i = 0; i < _fabAnimations.length; i++) {
        Future.delayed(staggerDuration * i, () {
          if (mounted) {
            _fabAnimations[i].reverse();
          }
        });
      }
    }
  }

  void _toggleFabMenu() {
    if (_isFabMenuOpen) {
      _animationController.reverse();
      _animateFabChildren(false);
    } else {
      setState(() {
        _isFabMenuOpen = true;
        _animationController.forward();
        _animateFabChildren(true);
      });
    }
  }

  void _navigateToInvoice() {
    _toggleFabMenu();
    final apartment = widget.apartment;
    final prefilledData = {
      'apartment': apartment,
      'bookingPrice': apartment.dailyPrice,
      'invoiceType': 'Daily',
      'currency': 'ქართული ლარი',
      'recipient': 'კლიენტი',
      'ownerName': apartment.ownerName,
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceGeneratorScreen(
          prefilledData: prefilledData,
        ),
      ),
    );
  }

  void _navigateToContract() {
    _toggleFabMenu();
    final apartment = widget.apartment;
    final prefilledData = {
      'contractType': 'Monthly',
      'city': apartment.city,
      'currency': 'აშშ დოლარის',
      'price': apartment.monthlyPrice,
      'sqMeters': apartment.squareMeters,
      'geAddress': apartment.geAddress,
      'ruAddress': apartment.ruAddress,
      'ownerNameGe': apartment.ownerName,
      'ownerNameRu': apartment.ownerNameRu,
      'ownerIdNumber': apartment.ownerID,
      'ownerBirthDate': apartment.ownerBD,
      'ownerBankName': apartment.ownerBankName,
      'ownerBankAccount': apartment.ownerBank,
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractFormScreen(
          prefilledData: prefilledData,
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog() async {
    _toggleFabMenu();
    _deleteConfirmationController.clear();
    const String requiredText = 'ბინის წაშლა';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'დასადასტურებლად აკრიფეთ:',
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      requiredText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      autofocus: false,
                      controller: _deleteConfirmationController,
                      decoration: InputDecoration(
                        hintText: requiredText,
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF004aad)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide:
                          BorderSide(color: Color(0xFF004aad), width: 2.0),
                        ),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            backgroundColor: Colors.grey.shade200,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text('გაუქმება'),
                          onPressed: () {
                            _deleteConfirmationController.clear();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text('წაშლა'),
                          onPressed:
                          _deleteConfirmationController.text.trim() ==
                              requiredText
                              ? () async {
                            Navigator.of(context).pop();
                            await _deleteApartmentWithImages();
                          }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- DELETION LOGIC SIMPLIFIED ---
  Future<void> _deleteApartmentWithImages() async {
    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Directly call the service that deletes both Firestore data and Storage images.
      await Provider.of<FirestoreService>(context, listen: false)
          .deleteApartmentWithImages(widget.apartment);

      if (mounted) {
        // --- MODIFIED ---
        CustomSnackBar.show(
          context: context,
          message: 'ბინა წარმატებით წაიშალა',
        );
        // Pop the screen to return to the previous view.
        Navigator.of(context).pop(null);
      }
    } catch (e) {
      if (mounted) {
        // --- MODIFIED ---
        CustomSnackBar.show(
          context: context,
          message: 'ვერ მოხერხდა ბინის წაშლა: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // --- UNDO SYSTEM METHODS REMOVED ---
  // _undoDelete() and _buildUndoWidget() have been removed.

  Widget _buildDetailRow(IconData icon, String label, String value,
      {TextStyle? labelStyle, TextStyle? valueStyle, double iconSize = 24.0}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF004aad), size: iconSize),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: labelStyle ??
                      TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: valueStyle ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityItem(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF004aad), size: 28),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xFF004aad)),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection(Apartment apartment) {
    final availableAmenities = <Widget>[];
    if (apartment.hasAC) {
      availableAmenities
          .add(Expanded(child: _buildAmenityItem(Icons.ac_unit, 'კონდიციონერი')));
    }
    if (apartment.hasElevator) {
      availableAmenities
          .add(Expanded(child: _buildAmenityItem(Icons.elevator, 'ლიფტი')));
    }
    if (apartment.hasWiFi) {
      availableAmenities.add(Expanded(child: _buildAmenityItem(Icons.wifi, 'Wi-Fi')));
    }
    if (apartment.warmWater) {
      availableAmenities
          .add(Expanded(child: _buildAmenityItem(Icons.whatshot, 'ცხელი წყალი')));
    }

    if (availableAmenities.isEmpty) {
      return const SizedBox.shrink();
    }

    while (availableAmenities.length < 4) {
      availableAmenities.add(Expanded(child: Container()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        const Text(
          'კეთილმოწყობა:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: availableAmenities,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isDailyEmphasis = now.month >= 7 && now.month <= 9;
    final apartment = widget.apartment;

    const ownerLabelStyle = TextStyle(color: Color(0xFF616161), fontSize: 11);
    const ownerValueStyle =
    TextStyle(fontSize: 13, fontWeight: FontWeight.w500);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ბინის დეტალები',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF004aad),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 300,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: apartment.imageUrls.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final imageUrl = apartment.imageUrls[index];
                          return Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                      null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                  'ვერმოხერხდა სურათების ჩატვირთვა: $error');
                              return Container(
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.broken_image,
                                        size: 50, color: Colors.grey),
                                    Text('ვერმოხერხდა სურათების ჩატვირთვა',
                                        style:
                                        TextStyle(color: Colors.grey[600])),
                                    Text('URL: ${apartment.imageUrls[index]}',
                                        style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 10)),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      if (apartment.imageUrls.length > 1)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List<Widget>.generate(
                              apartment.imageUrls.length,
                                  (index) => Container(
                                width: 8,
                                height: 8,
                                margin:
                                const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
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
                              apartment.geAddress,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isDailyEmphasis
                                    ? '${NumberFormat('#,##0').format(apartment.dailyPrice)}₾ / დღე'
                                    : '\$${NumberFormat('#,##0').format(apartment.monthlyPrice)} / თვე',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004aad),
                                ),
                              ),
                              Text(
                                isDailyEmphasis
                                    ? '\$${NumberFormat('#,##0').format(apartment.monthlyPrice)} / თვე'
                                    : '${NumberFormat('#,##0').format(apartment.dailyPrice)}₾ / დღე',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: apartment.tags
                              .map((tag) => Container(
                            margin: const EdgeInsets.only(right: 8.0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF004aad)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF004aad)
                                    .withOpacity(0.5),
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
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF004aad).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: const Color(0xFF004aad).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isOwnerExpanded = !_isOwnerExpanded;
                                });
                              },
                              borderRadius: _isOwnerExpanded
                                  ? const BorderRadius.only(
                                topLeft: Radius.circular(12.0),
                                topRight: Radius.circular(12.0),
                              )
                                  : BorderRadius.circular(12.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'მეპატრონე',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: _isOwnerExpanded ? 0.5 : 0.0,
                                      duration:
                                      const Duration(milliseconds: 300),
                                      child: const Icon(
                                        Icons.expand_more,
                                        color: Color(0xFF004aad),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedCrossFade(
                              firstChild: Container(),
                              secondChild: Container(
                                padding: const EdgeInsets.fromLTRB(
                                    16.0, 0, 16.0, 16.0),
                                child: Column(
                                  children: [
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                      Icons.person,
                                      'სახელი',
                                      apartment.ownerName,
                                      labelStyle: ownerLabelStyle,
                                      valueStyle: ownerValueStyle,
                                      iconSize: 20.0,
                                    ),
                                    _buildDetailRow(
                                      Icons.phone,
                                      'ტელეფონის ნომერი',
                                      apartment.ownerNumber.isNotEmpty
                                          ? apartment.ownerNumber
                                          : 'არ არის მითითებული',
                                      labelStyle: ownerLabelStyle,
                                      valueStyle: ownerValueStyle,
                                      iconSize: 20.0,
                                    ),
                                    _buildDetailRow(
                                      Icons.credit_card,
                                      'პირადობის მოწმობა',
                                      apartment.ownerID.isNotEmpty
                                          ? apartment.ownerID
                                          : 'არ არის მითითებული',
                                      labelStyle: ownerLabelStyle,
                                      valueStyle: ownerValueStyle,
                                      iconSize: 20.0,
                                    ),
                                    _buildDetailRow(
                                      Icons.calendar_today,
                                      'დაბადების თარიღი',
                                      apartment.ownerBD.isNotEmpty
                                          ? apartment.ownerBD
                                          : 'არ არის მითითებული',
                                      labelStyle: ownerLabelStyle,
                                      valueStyle: ownerValueStyle,
                                      iconSize: 20.0,
                                    ),
                                    _buildDetailRow(
                                      Icons.account_balance_wallet,
                                      'ბანკი',
                                      apartment.ownerBankName.isNotEmpty
                                          ? apartment.ownerBankName
                                          : 'არ არის მითითებული',
                                      labelStyle: ownerLabelStyle,
                                      valueStyle: ownerValueStyle,
                                      iconSize: 20.0,
                                    ),
                                    _buildDetailRow(
                                      Icons.account_balance,
                                      'ბანკის ანგარიშის ნომერი',
                                      apartment.ownerBank.isNotEmpty
                                          ? apartment.ownerBank
                                          : 'არ არის მითითებული',
                                      labelStyle: ownerLabelStyle,
                                      valueStyle: ownerValueStyle,
                                      iconSize: 20.0,
                                    ),
                                  ],
                                ),
                              ),
                              crossFadeState: _isOwnerExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF004aad).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: const Color(0xFF004aad).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'დეტალები',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            _buildDetailRow(
                              Icons.house,
                              'ოთახი',
                              apartment.geAppRoom,
                            ),
                            if (apartment.geAppBedroom.isNotEmpty &&
                                apartment.geAppBedroom != 'არა')
                              _buildDetailRow(
                                Icons.king_bed,
                                'საძინებელი',
                                apartment.geAppBedroom,
                              ),
                            _buildDetailRow(
                              Icons.square_foot,
                              'კვადრატული მეტრი',
                              '${apartment.squareMeters.toStringAsFixed(0)} m²',
                            ),
                            _buildDetailRow(
                              Icons.people,
                              'მაქს. სტუმრების რაოდენობა',
                              apartment.peopleCapacity.toString(),
                            ),
                            if (apartment.bathrooms.isNotEmpty)
                              _buildDetailRow(
                                Icons.bathtub,
                                'სველი წერტილი',
                                apartment.bathrooms.split(' ').first,
                              ),
                            if (apartment.balcony != 'აივნის გარეშე')
                              _buildDetailRow(
                                Icons.balcony,
                                'აივანი',
                                apartment.balcony.split(' ').first,
                              ),
                            if (apartment.terrace != 'ტერასის გარეშე')
                              _buildDetailRow(
                                Icons.deck,
                                'ტერასა',
                                apartment.terrace.split(' ').first,
                              ),
                            if (apartment.city == 'ბათუმი') ...[
                              if (apartment.seaLine.isNotEmpty &&
                                  apartment.seaLine != 'არა')
                                _buildDetailRow(
                                  Icons.waves,
                                  'ზოლი',
                                  apartment.seaLine,
                                ),
                              _buildDetailRow(
                                Icons.visibility,
                                'ზღვის ხედი',
                                apartment.seaView,
                              ),
                            ],
                            if (apartment.description.isNotEmpty)
                              _buildDetailRow(
                                Icons.description,
                                'აღწერა',
                                apartment.description,
                              ),
                            if (apartment.city == 'თბილისი') ...[
                              if (apartment.district.isNotEmpty)
                                _buildDetailRow(
                                  Icons.location_on,
                                  'რაიონი',
                                  apartment.district,
                                ),
                              if (apartment.microDistrict.isNotEmpty)
                                _buildDetailRow(
                                  Icons.location_city,
                                  'მიკრორაიონი',
                                  apartment.microDistrict,
                                ),
                            ],
                            _buildAmenitiesSection(apartment),
                          ],
                        ),
                      ),
                      if (apartment.successfulBookings > 0) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF004aad).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: const Color(0xFF004aad).withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'სტატისტიკა',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                Icons.event_available,
                                'წარმატებული დაბინავება',
                                apartment.successfulBookings.toString(),
                              ),
                              _buildDetailRow(
                                Icons.attach_money,
                                'მოგება (₾)',
                                '${NumberFormat('#,##0.00').format(apartment.profitLari)} ₾',
                              ),
                              _buildDetailRow(
                                Icons.monetization_on,
                                'მოგება (\$)',
                                '\$${NumberFormat('#,##0.00').format(apartment.profitUSD)}',
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_isFabMenuOpen)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _fabChildren,
                  ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF004aad),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: AnimatedIcon(
                      icon: AnimatedIcons.menu_close,
                      progress: _animationController,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _toggleFabMenu,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          // --- UNDO WIDGET REMOVED FROM STACK ---
        ],
      ),
    );
  }
}

class EditApartmentScreen extends StatefulWidget {
  final Apartment apartment;

  const EditApartmentScreen({super.key, required this.apartment});

  @override
  State<EditApartmentScreen> createState() => _EditApartmentScreenState();
}

class _EditApartmentScreenState extends State<EditApartmentScreen> {
  late String _selectedCity;
  final _formKey = GlobalKey<FormState>();
  final Color primaryColor = const Color(0xFF004aad);
  final _picker = ImagePicker();

  // Bank options
  final List<String> _bankOptions = [
    'საქართველოს ბანკი',
    'თი-ბი-სი ბანკი',
    'ლიბერთი ბანკი',
    'ბაზის ბანკი',
    'ტერა ბანკი'
  ];

  // Dropdown options
  final List<String> _seaLineOptions = [
    'არა',
    'პირველი ზოლი',
    'მეორე ზოლი',
    'მესამე ზოლი',
    'მეოთხე ზოლი',
    'მეხუთე ზოლი'
  ];
  final List<String> _roomOptions = [
    'სტუდიო',
    '2-ოთახიანი',
    '3-ოთახიანი',
    '4-ოთახიანი',
    '5-ოთახიანი',
    '6-ოთახიანი',
    '7-ოთახიანი',
    '8-ოთახიანი'
  ];
  final List<String> _bedroomOptions = [
    'არა',
    '1-საძინებლიანი',
    '2-საძინებლიანი',
    '3-საძინებლიანი',
    '4-საძინებლიანი',
    '5-საძინებლიანი'
  ];
  final List<String> _balconyOptions = [
    'აივნის გარეშე',
    '1 აივანი',
    '2 აივანი',
    '3 აივანი'
  ];
  final List<String> _terraceOptions = [
    'ტერასის გარეშე',
    '1 ტერასა',
    '2 ტერასა',
    '3 ტერასა'
  ];
  final List<String> _bathroomOptions = [
    '1 სველი წერტილი',
    '2 სველი წერტილი',
    '3 სველი წერტილი',
    '4 სველი წერტილი'
  ];

  // Controllers
  late TextEditingController _ownerNameController;
  late TextEditingController _ownerNameRuController;
  late TextEditingController _ownerNumberController;
  late TextEditingController _geAddressController;
  late TextEditingController _ruAddressController;
  late TextEditingController _dailyPriceController;
  late TextEditingController _monthlyPriceController;
  late TextEditingController _capacityController;
  late TextEditingController _squareMetersController;
  late TextEditingController _tagsController;
  late TextEditingController _descriptionController;
  late TextEditingController _districtController;
  late TextEditingController _microDistrictController;
  late TextEditingController _districtRuController;
  late TextEditingController _microDistrictRuController;
  late TextEditingController _ownerIDController;
  late TextEditingController _ownerBDController;
  late TextEditingController _ownerBankController;
  late String _selectedBankName;

  DateTime? _ownerBirthDate;

  // FocusNodes and Dominance flags for animated text fields
  final FocusNode _geOwnerNameFocusNode = FocusNode();
  final FocusNode _ruOwnerNameFocusNode = FocusNode();
  bool _isRuOwnerNameDominant = false;

  final FocusNode _geAddressFocusNode = FocusNode();
  final FocusNode _ruAddressFocusNode = FocusNode();
  bool _isRuAddressDominant = false;

  final FocusNode _geDistrictFocusNode = FocusNode();
  final FocusNode _ruDistrictFocusNode = FocusNode();
  bool _isRuDistrictDominant = false;

  final FocusNode _geMicroDistrictFocusNode = FocusNode();
  final FocusNode _ruMicroDistrictFocusNode = FocusNode();
  bool _isRuMicroDistrictDominant = false;

  // State variables
  late String _seaView;
  late String _selectedSeaLine;
  late String _selectedRooms;
  late String _selectedBedrooms;
  late String _selectedBalcony;
  late String _selectedTerrace;
  late String _selectedBathroom;
  late bool _hasAC;
  late bool _hasElevator;
  late bool _hasInternet;
  late bool _hasWiFi;
  late bool _warmWater;
  late List<String> _tags;

  // Image management
  List<String> _currentImageUrls = [];
  List<XFile> _newImages = [];
  List<String> _imagesToDelete = [];
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    _currentImageUrls = List.from(widget.apartment.imageUrls);
    _selectedCity = widget.apartment.city;
    _ownerNameController =
        TextEditingController(text: widget.apartment.ownerName);
    _ownerNameRuController =
        TextEditingController(text: widget.apartment.ownerNameRu);
    _ownerNumberController =
        TextEditingController(text: widget.apartment.ownerNumber);
    _geAddressController =
        TextEditingController(text: widget.apartment.geAddress);
    _ruAddressController =
        TextEditingController(text: widget.apartment.ruAddress);
    _dailyPriceController =
        TextEditingController(text: widget.apartment.dailyPrice.toString());
    _monthlyPriceController =
        TextEditingController(text: widget.apartment.monthlyPrice.toString());
    _capacityController =
        TextEditingController(text: widget.apartment.peopleCapacity.toString());
    _squareMetersController =
        TextEditingController(text: widget.apartment.squareMeters.toString());
    _tagsController =
        TextEditingController(text: widget.apartment.tags.join(', '));
    _descriptionController =
        TextEditingController(text: widget.apartment.description);
    _ownerIDController = TextEditingController(text: widget.apartment.ownerID);
    _ownerBDController = TextEditingController(text: widget.apartment.ownerBD);
    _ownerBankController =
        TextEditingController(text: widget.apartment.ownerBank);
    _selectedBankName = widget.apartment.ownerBankName.isNotEmpty
        ? widget.apartment.ownerBankName
        : _bankOptions[0];
    _districtRuController =
        TextEditingController(text: widget.apartment.districtRu);
    _microDistrictRuController =
        TextEditingController(text: widget.apartment.microDistrictRu);
    _districtController =
        TextEditingController(text: widget.apartment.district);
    _microDistrictController =
        TextEditingController(text: widget.apartment.microDistrict);

    _seaView = widget.apartment.seaView;
    _selectedSeaLine = widget.apartment.seaLine;
    _selectedRooms = widget.apartment.geAppRoom;
    _selectedBedrooms = widget.apartment.geAppBedroom;
    _selectedBalcony = widget.apartment.balcony;
    _selectedTerrace = widget.apartment.terrace;
    _selectedBathroom = widget.apartment.bathrooms;
    _hasAC = widget.apartment.hasAC;
    _hasElevator = widget.apartment.hasElevator;
    _hasInternet = widget.apartment.hasInternet;
    _hasWiFi = widget.apartment.hasWiFi;
    _warmWater = widget.apartment.warmWater;
    _tags = List.from(widget.apartment.tags);

    if (widget.apartment.ownerBD.isNotEmpty) {
      try {
        _ownerBirthDate =
            DateFormat('dd/MMM/yyyy', 'ka_GE').parse(widget.apartment.ownerBD);
      } catch (e) {
        _ownerBirthDate = null;
      }
    }

    if (_selectedRooms == 'სტუდიო' &&
        !_bedroomOptions.contains(_selectedBedrooms)) {
      _selectedBedrooms = 'არა';
    }

    void setupFocusListeners(
        FocusNode geNode, FocusNode ruNode, Function(bool) updateDominance) {
      geNode.addListener(() {
        if (geNode.hasFocus) setState(() => updateDominance(false));
      });
      ruNode.addListener(() {
        if (ruNode.hasFocus) setState(() => updateDominance(true));
      });
    }

    setupFocusListeners(_geOwnerNameFocusNode, _ruOwnerNameFocusNode,
            (isRuDominant) => _isRuOwnerNameDominant = isRuDominant);
    setupFocusListeners(_geAddressFocusNode, _ruAddressFocusNode,
            (isRuDominant) => _isRuAddressDominant = isRuDominant);
    setupFocusListeners(_geDistrictFocusNode, _ruDistrictFocusNode,
            (isRuDominant) => _isRuDistrictDominant = isRuDominant);
    setupFocusListeners(_geMicroDistrictFocusNode, _ruMicroDistrictFocusNode,
            (isRuDominant) => _isRuMicroDistrictDominant = isRuDominant);

    _geAddressController.addListener(() {
      final text = _geAddressController.text;
      final prefix =
      _selectedCity == 'ბათუმი' ? 'ქ. ბათუმი, ' : 'ქ. თბილისი, ';
      if (!text.startsWith(prefix)) {
        _geAddressController.text = prefix;
        _geAddressController.selection = TextSelection.fromPosition(
          TextPosition(offset: _geAddressController.text.length),
        );
      }
    });

    _ruAddressController.addListener(() {
      final text = _ruAddressController.text;
      final prefix =
      _selectedCity == 'ბათუმი' ? 'г. Батуми, ' : 'г. Тбилиси, ';
      if (!text.startsWith(prefix)) {
        _ruAddressController.text = prefix;
        _ruAddressController.selection = TextSelection.fromPosition(
          TextPosition(offset: _ruAddressController.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerNameRuController.dispose();
    _ownerNumberController.dispose();
    _geAddressController.dispose();
    _ruAddressController.dispose();
    _dailyPriceController.dispose();
    _monthlyPriceController.dispose();
    _capacityController.dispose();
    _squareMetersController.dispose();
    _tagsController.dispose();
    _descriptionController.dispose();
    _districtController.dispose();
    _microDistrictController.dispose();
    _districtRuController.dispose();
    _microDistrictRuController.dispose();
    _ownerIDController.dispose();
    _ownerBDController.dispose();
    _ownerBankController.dispose();
    _geOwnerNameFocusNode.dispose();
    _ruOwnerNameFocusNode.dispose();
    _geAddressFocusNode.dispose();
    _ruAddressFocusNode.dispose();
    _geDistrictFocusNode.dispose();
    _ruDistrictFocusNode.dispose();
    _geMicroDistrictFocusNode.dispose();
    _ruMicroDistrictFocusNode.dispose();
    super.dispose();
  }

  void _updateAddressPrefix() {
    const gePrefixes = ['ქ. ბათუმი, ', 'ქ. თბილისი, '];
    const ruPrefixes = ['г. Батуми, ', 'г. Тбилиси, '];

    String cleanGeAddress = _geAddressController.text;
    String cleanRuAddress = _ruAddressController.text;

    for (var prefix in gePrefixes) {
      if (cleanGeAddress.startsWith(prefix)) {
        cleanGeAddress = cleanGeAddress.substring(prefix.length);
        break;
      }
    }

    for (var prefix in ruPrefixes) {
      if (cleanRuAddress.startsWith(prefix)) {
        cleanRuAddress = cleanRuAddress.substring(prefix.length);
        break;
      }
    }

    String gePrefixToAdd =
    _selectedCity == 'ბათუმი' ? 'ქ. ბათუმი, ' : 'ქ. თბილისი, ';
    String ruPrefixToAdd =
    _selectedCity == 'ბათუმი' ? 'г. Батуми, ' : 'г. Тбилиси, ';

    _geAddressController.text = gePrefixToAdd + cleanGeAddress;
    _ruAddressController.text = ruPrefixToAdd + cleanRuAddress;
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _newImages.addAll(pickedFiles);
        });
      }
    } catch (e) {
      if (mounted) {
        // --- MODIFIED ---
        CustomSnackBar.show(
          context: context,
          message: 'სურათი ვერ აირჩა: $e',
          isError: true,
        );
      }
    }
  }

  void _removeImage(int index, bool isExisting) {
    if ((_currentImageUrls.length + _newImages.length) <= 1) {
      // --- MODIFIED ---
      CustomSnackBar.show(
        context: context,
        message: 'საჭიროებს 1 სურათი მაინც',
        isError: true,
      );
      return;
    }

    setState(() {
      if (isExisting) {
        _imagesToDelete.add(_currentImageUrls.removeAt(index));
      } else {
        _newImages.removeAt(index - _currentImageUrls.length);
      }
    });
  }

  Future<String> _uploadImage(XFile imageFile, String apartmentAddress) async {
    try {
      final cleanAddress = apartmentAddress.replaceAll(RegExp(r'[\/]'), '-');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('Apartments')
          .child(cleanAddress)
          .child(fileName);

      final imageData = await imageFile.readAsBytes();
      final uploadTask = ref.putData(imageData);

      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  Future<void> _deleteOldImages() async {
    if (_imagesToDelete.isEmpty) return;

    final storage = FirebaseStorage.instance;
    final deleteTasks = <Future>[];

    for (final url in _imagesToDelete) {
      try {
        deleteTasks.add(storage.refFromURL(url).delete());
      } catch (e) {
        debugPrint('Error deleting image: $e');
      }
    }

    await Future.wait(deleteTasks);
    _imagesToDelete.clear();
  }

  Future<void> _saveChanges() async {

    if (!_formKey.currentState!.validate() || _isSaving) return;
    if (_currentImageUrls.isEmpty && _newImages.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'გთხოვთ დაამატოთ 1 სურათი მაინც',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _isUploading = true;
    });

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      // Use the *original* apartment's address to check for the document's existence.
      final originalDocId = widget.apartment.geAddress.replaceAll(RegExp(r'[\/]'), '-');
      final doc = await firestoreService.db.collection('apartments').doc(originalDocId).get();

      if (!doc.exists) {
        if (mounted) {
          CustomSnackBar.show(
            context: context,
            message: 'ეს ბინა წაიშალა სხვა ადგილიდან',
            isError: true,
          );
          // Exit the edit screen since the apartment is gone.
          Navigator.of(context).pop(null);
        }
        return; // Abort the save.
      }
    } catch(e) {
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'ვერ მოხერხდა ბინის სტატუსის ვერიფიცირება: ${e.toString()}',
          isError: true,
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    try {
      final String newAddress = _geAddressController.text.trim();
      final String oldAddress = widget.apartment.geAddress;
      final bool addressChanged = newAddress != oldAddress;
      final String cleanOldAddress =
      oldAddress.replaceAll(RegExp(r'[\/]'), '-');
      final String cleanNewAddress =
      newAddress.replaceAll(RegExp(r'[\/]'), '-');

      List<String> finalImageUrls = [];
      if (addressChanged && _currentImageUrls.isNotEmpty) {
        finalImageUrls = await _copyImagesToNewAddress(
            _currentImageUrls, cleanOldAddress, cleanNewAddress);
        _imagesToDelete.addAll(_currentImageUrls);
      } else {
        finalImageUrls = List.from(_currentImageUrls);
      }

      final List<String> uploadedUrls = [];
      for (final imageFile in _newImages) {
        final url = await _uploadImage(
          imageFile,
          addressChanged ? cleanNewAddress : cleanOldAddress,
        );
        uploadedUrls.add(url);
      }

      await _deleteOldImages();

      final updatedApartment = widget.apartment.copyWith(
        city: _selectedCity,
        ownerName: _ownerNameController.text.trim(),
        ownerNameRu: _ownerNameRuController.text.trim(),
        ownerNumber: _ownerNumberController.text.trim(),
        ownerID: _ownerIDController.text.trim(),
        ownerBD: _ownerBDController.text.trim(),
        ownerBank: _ownerBankController.text.trim(),
        ownerBankName: _selectedBankName,
        geAddress: _geAddressController.text.trim(),
        ruAddress: _ruAddressController.text.trim(),
        seaView: _seaView,
        seaLine: _selectedSeaLine,
        geAppRoom: _selectedRooms,
        geAppBedroom: _selectedBedrooms,
        balcony: _selectedBalcony,
        terrace: _selectedTerrace,
        bathrooms: _selectedBathroom,
        dailyPrice: double.tryParse(_dailyPriceController.text) ?? 0,
        monthlyPrice: double.tryParse(_monthlyPriceController.text) ?? 0,
        peopleCapacity: int.tryParse(_capacityController.text) ?? 1,
        squareMeters: double.tryParse(_squareMetersController.text) ?? 0,
        description: _descriptionController.text.trim(),
        hasAC: _hasAC,
        hasElevator: _hasElevator,
        hasInternet: _hasInternet,
        hasWiFi: _hasWiFi,
        warmWater: _warmWater,
        tags: _tagsController.text.split(',').map((e) => e.trim()).toList(),
        imageUrls: [...finalImageUrls, ...uploadedUrls],
        district: _districtController.text.trim(),
        microDistrict: _microDistrictController.text.trim(),
        districtRu: _districtRuController.text.trim(),
        microDistrictRu: _microDistrictRuController.text.trim(),
      );

      // --- THIS IS THE CRUCIAL FIX ---
      // 1. Calculate the new Document ID based on the potentially new address.
      final newDocId = updatedApartment.geAddress.replaceAll(RegExp(r'[\/]'), '-');
      // 2. Create a final, definitive apartment object with the correct ID.
      final finalApartment = updatedApartment.copyWith(id: newDocId);
      // --- END OF FIX ---

      await Provider.of<FirestoreService>(context, listen: false)
          .updateApartmentWithOwnerHandling(
        originalApartment: widget.apartment,
        updatedApartment: finalApartment,
      );

      if (addressChanged) {
        await _tryDeleteOldFolder(cleanOldAddress);
      }

      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'ბინა წარმატებით განახლდა!',
        );
        Navigator.of(context).pop(finalApartment); // <-- Return the object with the correct ID
      }
    } catch (e) {
      if (mounted) {
        // --- MODIFIED ---
        CustomSnackBar.show(
          context: context,
          message: 'წარუმატებელი განახლება: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploading = false;
        });
      }
    }
  }

  Future<List<String>> _copyImagesToNewAddress(
      List<String> imageUrls,
      String oldAddress,
      String newAddress,
      ) async {
    final List<String> copiedUrls = [];
    final storage = FirebaseStorage.instance;

    for (final url in imageUrls) {
      try {
        final fileName = url.split('/').last.split('?').first;
        final oldRef = storage.refFromURL(url);
        final newRef = storage
            .ref()
            .child('Apartments')
            .child(newAddress)
            .child(fileName);
        final Uint8List? imageData = await oldRef.getData();
        if (imageData == null) {
          throw Exception('Failed to download image data');
        }
        final uploadTask = newRef.putData(imageData);
        final snapshot = await uploadTask.whenComplete(() {});
        final newUrl = await snapshot.ref.getDownloadURL();
        copiedUrls.add(newUrl);
      } catch (e) {
        debugPrint('Failed to copy image: $e');
        copiedUrls.add(url);
      }
    }

    return copiedUrls;
  }

  Future<void> _tryDeleteOldFolder(String oldAddress) async {
    try {
      final folderRef =
      FirebaseStorage.instance.ref().child('Apartments').child(oldAddress);

      final listResult = await folderRef.listAll();

      if (listResult.items.isEmpty && listResult.prefixes.isEmpty) {
        // This part is problematic as Firebase Storage doesn't support direct folder deletion.
      }
    } catch (e) {
      debugPrint('Error during old folder cleanup check: $e');
    }
  }

  Widget _buildImageManagementGrid() {
    final allImages = [
      ..._currentImageUrls.map((url) => _ImageItem(url: url, isFile: false)),
      ..._newImages.map((file) => _ImageItem(file: file, isFile: true)),
    ];

    if (allImages.isEmpty && !_isUploading) {
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate, size: 40, color: Colors.black54),
              SizedBox(height: 8),
              Text('ფოტოების დამატება', style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allImages.length + (_isUploading ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isUploading && index == allImages.length) {
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border:
                    Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              final item = allImages[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: item.isFile
                          ? FutureBuilder<Uint8List>(
                        future: item.file!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Image.memory(snapshot.data!,
                                fit: BoxFit.cover);
                          }
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                      )
                          : Image.network(item.url!, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => _removeImage(
                          index,
                          index < _currentImageUrls.length,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add),
            label: const Text('მეტი ფოტოს დამატება'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }

  Widget _buildAnimatedTextFieldRow({
    required TextEditingController geController,
    required TextEditingController ruController,
    required String geLabel,
    required String ruLabel,
    required FocusNode geFocusNode,
    required FocusNode ruFocusNode,
    required bool isRuDominant,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const spacing = 12.0;
        final availableWidth = totalWidth - spacing;
        final largeWidth = availableWidth * 0.6;
        final smallWidth = availableWidth * 0.4;

        return TweenAnimationBuilder<double>(
          tween: Tween(end: isRuDominant ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          builder: (context, value, child) {
            final geWidth = lerpDouble(largeWidth, smallWidth, value)!;
            final ruWidth = lerpDouble(smallWidth, largeWidth, value)!;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: geWidth,
                  child: _buildModernTextField(
                    controller: geController,
                    labelText: geLabel,
                    focusNode: geFocusNode,
                    validator: validator,
                    keyboardType: keyboardType ?? TextInputType.text,
                  ),
                ),
                const SizedBox(width: spacing),
                SizedBox(
                  width: ruWidth,
                  child: _buildModernTextField(
                    controller: ruController,
                    labelText: ruLabel,
                    focusNode: ruFocusNode,
                    keyboardType: keyboardType ?? TextInputType.text,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLines = 1,
    int? minLines,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      minLines: minLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(
            color: primaryColor, fontSize: 14, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildModernDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: primaryColor, fontSize: 14, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      icon: Icon(Icons.arrow_drop_down, color: primaryColor),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(8),
    );
  }

  Widget _buildTypeToggle({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? primaryColor : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                  color: isActive ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernDatePicker({
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          locale: const Locale('ka', 'GE'),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  onSurface: Colors.black87,
                ),
                dialogBackgroundColor: Colors.white,
              ),
              child: Transform.scale(scale: 1.2, child: child!),
            );
          },
        );
        if (picked != null && picked != selectedDate) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: primaryColor, fontSize: 14, fontWeight: FontWeight.w500),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.grey.shade50,
          suffixIcon:
          Icon(Icons.calendar_today, color: primaryColor, size: 20),
        ),
        child: Text(
          selectedDate != null
              ? DateFormat('dd/MMM/yyyy', 'ka_GE').format(selectedDate)
              : 'აირჩიეთ თარიღი',
          style: TextStyle(
            fontSize: 14,
            color:
            selectedDate == null ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildCircularCheckbox({
    required String title,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? primaryColor : Colors.transparent,
                border: Border.all(
                  color: value ? primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child:
              value ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'ბინის რედაქტირება',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveChanges,
          ),
        ],
      ),
      body: _isSaving
          ? Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 16),
                const Text("შენახვა...")
              ]))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildSectionHeader('მეპატრონის ინფორმაცია'),
              _buildAnimatedTextFieldRow(
                  geController: _ownerNameController,
                  ruController: _ownerNameRuController,
                  geLabel: 'სახელი (ქართულად)',
                  ruLabel: '(რუს./ინგ.)',
                  geFocusNode: _geOwnerNameFocusNode,
                  ruFocusNode: _ruOwnerNameFocusNode,
                  isRuDominant: _isRuOwnerNameDominant,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'გთხოვთ შეიყვანოთ მეპატრონის სახელი';
                    }
                    return null;
                  }),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _ownerNumberController,
                labelText: 'ტელეფონის ნომერი',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'გთხოვთ შეიყვანოთ ტელეფონის ნომერი';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _ownerIDController,
                labelText: 'პირადი ნომერი',
              ),
              const SizedBox(height: 16),
              _buildModernDatePicker(
                label: 'დაბადების თარიღი',
                selectedDate: _ownerBirthDate,
                onDateSelected: (date) {
                  setState(() {
                    _ownerBirthDate = date;
                    _ownerBDController.text =
                        DateFormat('dd/MMM/yyyy', 'ka_GE').format(date);
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildModernDropdown<String>(
                label: 'ბანკი',
                items: _bankOptions
                    .map((option) =>
                    DropdownMenuItem(value: option, child: Text(option)))
                    .toList(),
                value: _selectedBankName,
                onChanged: (value) {
                  setState(() {
                    _selectedBankName = value ?? _bankOptions[0];
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _ownerBankController,
                labelText: 'ბანკის ანგარიში ნომერი',
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('ბინის ფოტოები'),
              _buildImageManagementGrid(),
              const SizedBox(height: 24),

              _buildSectionHeader('ბინის მისამართი'),
              Row(
                children: [
                  _buildTypeToggle(
                    label: 'ბათუმი',
                    isActive: _selectedCity == 'ბათუმი',
                    onTap: () => setState(() {
                      _selectedCity = 'ბათუმი';
                      _districtController.clear();
                      _microDistrictController.clear();
                      _districtRuController.clear();
                      _microDistrictRuController.clear();
                      _updateAddressPrefix();
                    }),
                  ),
                  const SizedBox(width: 12),
                  _buildTypeToggle(
                    label: 'თბილისი',
                    isActive: _selectedCity == 'თბილისი',
                    onTap: () => setState(() {
                      _selectedCity = 'თბილისი';
                      _seaView = 'არა';
                      _selectedSeaLine = 'არა';
                      _updateAddressPrefix();
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAnimatedTextFieldRow(
                geController: _geAddressController,
                ruController: _ruAddressController,
                geLabel: 'მისამართი (ქართულად)',
                ruLabel: '(რუს./ინგ.)',
                geFocusNode: _geAddressFocusNode,
                ruFocusNode: _ruAddressFocusNode,
                isRuDominant: _isRuAddressDominant,
                validator: (value) {
                  if (value == null || value.trim().length <= 11) {
                    return 'გთხოვთ შეიყვანოთ სრული მისამართი';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_selectedCity == 'თბილისი') ...[
                _buildAnimatedTextFieldRow(
                  geController: _districtController,
                  ruController: _districtRuController,
                  geLabel: 'რაიონი (ქართულად)',
                  ruLabel: '(რუს./ინგ.)',
                  geFocusNode: _geDistrictFocusNode,
                  ruFocusNode: _ruDistrictFocusNode,
                  isRuDominant: _isRuDistrictDominant,
                  validator: (value) {
                    if (_selectedCity == 'თბილისი' &&
                        (value == null || value.isEmpty)) {
                      return 'გთხოვთ შეიყვანოთ რაიონი';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildAnimatedTextFieldRow(
                  geController: _microDistrictController,
                  ruController: _microDistrictRuController,
                  geLabel: 'მიკრორაიონი (ქართულად)',
                  ruLabel: '(რუს./ინგ.)',
                  geFocusNode: _geMicroDistrictFocusNode,
                  ruFocusNode: _ruMicroDistrictFocusNode,
                  isRuDominant: _isRuMicroDistrictDominant,
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 8),

              _buildSectionHeader('ბინის მახასიათებლები'),
              if (_selectedCity == 'ბათუმი') ...[
                _buildModernDropdown<String>(
                  label: 'ზღვის ზოლი',
                  items: _seaLineOptions
                      .map((option) => DropdownMenuItem(
                      value: option, child: Text(option)))
                      .toList(),
                  value: _selectedSeaLine,
                  onChanged: (value) => setState(
                          () => _selectedSeaLine = value ?? _seaLineOptions[0]),
                ),
                const SizedBox(height: 16),
                _buildModernDropdown<String>(
                  label: 'ზღვის ხედი',
                  value: _seaView,
                  items: ['კი', 'არა'].map((String value) {
                    return DropdownMenuItem<String>(
                        value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _seaView = newValue ?? 'არა';
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              _buildModernDropdown<String>(
                label: 'ოთახი',
                items: _roomOptions
                    .map((option) =>
                    DropdownMenuItem(value: option, child: Text(option)))
                    .toList(),
                value: _selectedRooms,
                onChanged: (value) {
                  setState(() {
                    _selectedRooms = value ?? 'სტუდიო';
                    if (_selectedRooms == 'სტუდიო') {
                      _selectedBedrooms = 'არა';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildModernDropdown<String>(
                label: 'საძინებელი',
                items: _bedroomOptions
                    .map((option) =>
                    DropdownMenuItem(value: option, child: Text(option)))
                    .toList(),
                value: _selectedBedrooms,
                onChanged: _selectedRooms == 'სტუდიო'
                    ? null
                    : (value) => setState(
                        () => _selectedBedrooms = value ?? '1-საძინებლიანი'),
              ),
              const SizedBox(height: 16),
              _buildModernDropdown<String>(
                label: 'სველი წერტილი',
                items: _bathroomOptions
                    .map((option) =>
                    DropdownMenuItem(value: option, child: Text(option)))
                    .toList(),
                value: _selectedBathroom,
                onChanged: (value) => setState(
                        () => _selectedBathroom = value ?? _bathroomOptions[0]),
              ),
              const SizedBox(height: 16),
              _buildModernDropdown<String>(
                label: 'აივანი',
                items: _balconyOptions
                    .map((option) =>
                    DropdownMenuItem(value: option, child: Text(option)))
                    .toList(),
                value: _selectedBalcony,
                onChanged: (value) => setState(
                        () => _selectedBalcony = value ?? _balconyOptions[0]),
              ),
              const SizedBox(height: 16),
              _buildModernDropdown<String>(
                label: 'ტერასა',
                items: _terraceOptions
                    .map((option) =>
                    DropdownMenuItem(value: option, child: Text(option)))
                    .toList(),
                value: _selectedTerrace,
                onChanged: (value) => setState(
                        () => _selectedTerrace = value ?? _terraceOptions[0]),
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _squareMetersController,
                labelText: 'კვადრატული მეტრი',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'გთხოვთ შეიყვანოთ კვადრატული მეტრი';
                  if (double.tryParse(value) == null)
                    return 'გთხოვთ შეიყვანოთ კორექტული რიცხვი';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _capacityController,
                labelText: 'მაქს. სტუმრების რაოდენობა',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'გთხოვთ შეიყვანოთ მაქს. სტუმრების რაოდენობა';
                  if (int.tryParse(value) == null)
                    return 'გთხოვთ შეიყვანოთ კორექტული რიცხვი';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCircularCheckbox(
                      title: 'კონდიციონერი',
                      value: _hasAC,
                      onChanged: (value) =>
                          setState(() => _hasAC = value ?? false),
                    ),
                  ),
                  Expanded(
                    child: _buildCircularCheckbox(
                      title: 'ლიფტი',
                      value: _hasElevator,
                      onChanged: (value) =>
                          setState(() => _hasElevator = value ?? false),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildCircularCheckbox(
                      title: 'ცხელი წყალი',
                      value: _warmWater,
                      onChanged: (value) =>
                          setState(() => _warmWater = value ?? false),
                    ),
                  ),
                  Expanded(
                    child: _buildCircularCheckbox(
                      title: 'Wi-Fi',
                      value: _hasWiFi,
                      onChanged: (value) {
                        setState(() {
                          _hasWiFi = value ?? false;
                          _hasInternet = value ?? false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('ფასი'),
              _buildModernTextField(
                controller: _dailyPriceController,
                labelText: 'დღიური ფასი (₾)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'გთხოვთ შეიყვანოთ დღიური ფასი';
                  if (double.tryParse(value) == null)
                    return 'გთხოვთ შეიყვანოთ კორექტული რიცხვი';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _monthlyPriceController,
                labelText: 'თვიური ფასი (\$)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'გთხოვთ შეიყვანოთ თვიური ფასი';
                  if (double.tryParse(value) == null)
                    return 'გთხოვთ შეიყვანოთ კორექტული რიცხვი';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('დამატებითი ინფორმაცია'),
              _buildModernTextField(
                controller: _descriptionController,
                labelText: 'აღწერა',
                hintText: 'შეიყვანეთ ბინის აღწერა...',
                maxLines: 4,
                minLines: 2,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _tagsController,
                labelText: 'თეგები (გამოყავით მძიმით)',
                hintText: 'ზღვისპირა, თანამედროვე, ლუქსი',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageItem {
  final String? url;
  final XFile? file;
  final bool isFile;

  _ImageItem({
    this.url,
    this.file,
    required this.isFile,
  }) : assert((url != null && !isFile) || (file != null && isFile));
}