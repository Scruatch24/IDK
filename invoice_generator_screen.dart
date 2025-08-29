import 'package:realtor_app/history_screen.dart';
import 'package:realtor_app/history_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:realtor_app/data/app_data.dart'; // Import your app_data.dart
import 'package:dropdown_search/dropdown_search.dart';
import 'dart:ui';
import 'dart:async';


class CopySuccessPopup extends StatelessWidget {
  final String message;
  final Color backgroundColor;

  const CopySuccessPopup({
    super.key,
    required this.message,
    this.backgroundColor = const Color(0xFF004aad),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: const Color(0xFF004aad),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class InvoiceGeneratorScreen extends StatefulWidget {

  final Map<String, dynamic>? prefilledData; // Add this
  final bool showVerificationPopup;
  const InvoiceGeneratorScreen({
    super.key,
    this.prefilledData,
    this.showVerificationPopup = false, // Provide a default value
  });

  @override
  State<InvoiceGeneratorScreen> createState() => _InvoiceGeneratorScreenState();
}

const Color primaryColor = Color(0xFF004aad);
const Color backgroundColor = Colors.white;
const TextStyle headerStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: primaryColor,
);
const TextStyle inputLabelStyle = TextStyle(
  color: primaryColor,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

class _InvoiceGeneratorScreenState extends State<InvoiceGeneratorScreen> {
  // --- State Variables and Controllers ---

  StreamSubscription? _ownersSubscription;
  StreamSubscription? _apartmentsSubscription;

// Replace the existing _showVerificationPopup method with this one.

// Replace the existing _showVerificationPopup method with this one.



  void _showVerificationPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Automatically close the dialog after a few seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        return AlertDialog(
          backgroundColor: Colors.white,
          // The content's size dictates the dialog's size.
          // Wrapping the Column in a Container gives it more space.
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 20.0), // Adds vertical spacing
            child: Column(
              mainAxisSize: MainAxisSize.min, // Keeps the dialog compact vertically
              children: [
                // --- Bigger Icon ---
                Container(
                  width: 64,  // Increased from 48
                  height: 64, // Increased from 48
                  decoration: const BoxDecoration(
                    color: Color(0xFF004aad),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 40,  // Increased from 32
                  ),
                ),
                const SizedBox(height: 24), // Increased spacing

                // --- Bigger Text ---
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18, // Increased from 16
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _selectedCity = 'ბათუმი'; // <-- ADD THIS LINE
  // Invoice Type
  String _invoiceTypeSelection = 'Daily'; // 'Daily' or 'Monthly'
  String _invoiceType = 'ღამე'; // Georgian: ღამე or თვე
  String _invoiceType2 = 'ღამის'; // Georgian: ღამის or თვიური

  // Auto-filled / Selectable Apartment/Owner Data
  Apartment? _selectedApartment;
  Owner? _selectedOwner;
  List<Apartment> _allApartments = []; // All apartments from Firestore
  List<Owner> _allOwners = []; // All owners from Firestore
  List<Apartment> _availableApartmentsForOwner = [];
  String _addOwnerManually = 'არა'; // 'კი' or 'არა'
  final TextEditingController _manualOwnerNameController = TextEditingController();
  final TextEditingController _manualOwnerNameRuController = TextEditingController();

// Add these with other controllers
  final TextEditingController _districtRuController = TextEditingController();
  final TextEditingController _microDistrictRuController = TextEditingController();

  // Add these with other controllers
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _microDistrictController = TextEditingController();

  // Text Controllers for free input fields
  final TextEditingController _geAddressController = TextEditingController();
  final TextEditingController _ruAddressController = TextEditingController();
  int _calculatedPeriod = 0; // New state variable for the calculated period
  String _invoiceRecipient = 'კლიენტი';

  bool get _showClientFields => _invoiceRecipient == 'კლიენტი';
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _prePayedController = TextEditingController();
  final TextEditingController _geNameTakeController = TextEditingController();
  final TextEditingController _ruNameTakeController = TextEditingController();
  final TextEditingController _adultsController = TextEditingController();
  final TextEditingController _childrenController = TextEditingController();
  final TextEditingController _takePhoneNumController = TextEditingController();

  // Dropdown / Selection Values
  String _seaLine = 'პირველი ზოლი'; // Default
  String _seaView = 'არა'; // Default
  String _geAppRoom = '3-ოთახიანი'; // Default
  String _ruAppRoom = '3-комнатная'; // Default equivalent
  String _geAppBedroom = '1-საძინებლიანი'; // Default
  String _ruAppBedroom = '1 спальня'; // Default equivalent
  String _balcony = '1 აივანი'; // Default
  String _terrace = 'ტერასის გარეშე'; // Default (ტერასის გარეშე)
  String _startNegotiated = 'არა'; // Default (არა)
  String _sellingCurrency = 'ქართული ლარი'; // Default

  // Date Variables
  DateTime? _startDate;
  DateTime? _endDate;

  // Guide Person
  String _guidePerson = 'მაკო ნაკაიძე'; // Default
  String _guidePhoneNum = '+995 599 238 685'; // Default phone for Maia Nakaidze

  final TextEditingController _customGuideNameController = TextEditingController();
  final TextEditingController _customGuidePhoneController = TextEditingController();

  // Pets
  String _pets = 'არა'; // Default

  // Calculated Values (will be computed based on inputs)
  double _priceFull = 0.0;
  double _priceLeft = 0.0;
  String _calculateDateNumbers = ''; // This will hold "21, 22, ..., 1"

  String? _storedGeNameTake;
  String? _storedRuNameTake;
  String? _storedTakePhoneNum;
  String? _storedPets;
  String? _storedPrePayed;




  final FocusNode _geAddressFocusNode = FocusNode();
  final FocusNode _ruAddressFocusNode = FocusNode();
  bool _isRuAddressDominant = false;

  final FocusNode _geDistrictFocusNode = FocusNode();
  final FocusNode _ruDistrictFocusNode = FocusNode();
  bool _isRuDistrictDominant = false;

  final FocusNode _geMicroDistrictFocusNode = FocusNode();
  final FocusNode _ruMicroDistrictFocusNode = FocusNode();
  bool _isRuMicroDistrictDominant = false;

  final FocusNode _geNameTakeFocusNode = FocusNode();
  final FocusNode _ruNameTakeFocusNode = FocusNode();
  bool _isRuNameTakeDominant = false;

  // ADD THESE THREE LINES
  final FocusNode _geOwnerNameFocusNode = FocusNode();
  final FocusNode _ruOwnerNameFocusNode = FocusNode();
  bool _isRuOwnerNameDominant = false;

  final FirestoreService _firestoreService = FirestoreService(); // Instance of FirestoreService

  // ADD THESE TWO MAPS HERE
  final Map<int, String> _georgianMonths = {
    1: 'იან', 2: 'თებ', 3: 'მარ', 4: 'აპრ', 5: 'მაი', 6: 'ივნ',
    7: 'ივლ', 8: 'აგვ', 9: 'სექ', 10: 'ოქტ', 11: 'ნოე', 12: 'დეკ',
  };

  final Map<int, String> _russianMonths = {
    1: 'Янв', 2: 'Фев', 3: 'Мар', 4: 'Апр', 5: 'Май', 6: 'Июн',
    7: 'Июл', 8: 'Авг', 9: 'Сен', 10: 'Окт', 11: 'Ноя', 12: 'Дек',
  };

  // --- Utility Maps for Dropdown Translations ---
  final Map<String, String> _seaLineOptions = {
    'არა': '',
    'პირველი ზოლი': 'Первая линия',
    'მეორე ზოლი': 'Вторая линия',
    'მესამე ზოლი': 'Третья линия',
    'მეოთხე ზოლი': 'Четвертая линия',
    'მეხუთე ზოლი': 'Пятая линия',
  };

  final Map<String, String> _seaViewOptions = {
    'არა': 'Нет',
    'კი': 'Да',
  };

  final Map<String, String> _geAppRoomOptions = {
    'სტუდიო': 'Студия',
    '2-ოთახიანი': '2-комнатная',
    '3-ოთახიანი': '3-комнатная',
    '4-ოთახიანი': '4-комнатная',
    '5-ოთახიანი': '5-комнатная',
    '6-ოთახიანი': '6-комнатная',
    '7-ოთახიანი': '7-комнатная',
    '8-ოთახიანი': '8-комнатная',
  };

  final Map<String, String> _geAppBedroomOptions = {
    'არა': '',
    '1-საძინებლიანი': '1 спальня',
    '2-საძინებლიანი': '2 спальни',
    '3-საძინებლიანი': '3 спальни',
    '4-საძინებლიანი': '4 спальни',
    '5-საძინებლიანი': '5 спален',
  };
  final Map<String, String> _balconyOptions = {
    'აივნის გარეშე': '', // Represents empty string for output
    '1 აივანი': '1 балкон',
    '2 აივანი': '2 балкона',
    '3 აივანი': '3 балкона',
  };

  final Map<String, String> _terraceOptions = {
    'ტერასის გარეშე': '', // Represents empty string for output
    '1 ტერასა': '1 терраса',
    '2 ტერასა': '2 террасы',
    '3 ტერასა': '3 террасы',
  };

  final Map<String, String> _startNegotiatedOptions = {
    'არა': ', 13:00 საათზე',
    'კი': ' (შესვლის საათი შეთანხმებით)',
  };
  final Map<String, String> _startNegotiatedOptionsRu = {
    'არა': ' 13:00', // Changed to include "13:00" for Russian
    'კი': '(время заезда в квартиру по согласованию)',
  };

  final Map<String, String> _sellingCurrencyOptions = {
    'ქართული ლარი': 'Грузинских Лари',
    'აშშ დოლარი': 'Долларов США ',
  };

  final Map<String, String> _guidePersonOptions = {
    'მაკო ნაკაიძე': '+995 599 238 685',
    'მზია გოგიტიძე': '+995 555 620 358',
    'სალო ხელაძე': '+995 555 356 069',
    'სხვა': '', // Add "No one" option with an empty phone number
  };
  final Map<String, String> _guidePersonRuNames = {
    'მაკო ნაკაიძე': 'Мако Накаидзе',
    'მზია გოგიტიძე': 'Мзия Гогитидзе',
    'სალო ხელაძე': 'Саломе Хеладзе',
    'სხვა': '', // Add "No one" option with an empty Russian name
  };

  final Map<String, String> _petsOptions = {
    'არა': 'No pets', // Will result in empty string
    'ძაღლით': 'С собакой',
    'კატით': 'С кошкой',
    'ძაღლით და კატით': 'С собакой и кошкой',
    '2 ძაღლით': 'С 2-мя собаками',
    '2 კატით': 'С 2-ма кошками',
  };





// lib/invoice_generator_screen.dart

// ... inside _InvoiceGeneratorScreenState class

  @override
  void initState() {
    super.initState();

    _geAddressController.addListener(() {
      final text = _geAddressController.text;
      final prefix = _selectedCity == 'ბათუმი' ? 'ქ. ბათუმი, ' : 'ქ. თბილისი, ';
      if (!text.startsWith(prefix)) {
        _geAddressController.text = prefix;
        _geAddressController.selection = TextSelection.fromPosition(
          TextPosition(offset: _geAddressController.text.length),
        );
      }
    });

    _ruAddressController.addListener(() {
      final text = _ruAddressController.text;
      final prefix = _selectedCity == 'ბათუმი' ? 'г. Батуми, ' : 'г. Тбилиси, ';
      if (!text.startsWith(prefix)) {
        _ruAddressController.text = prefix;
        _ruAddressController.selection = TextSelection.fromPosition(
          TextPosition(offset: _ruAddressController.text.length),
        );
      }
    });

    if (widget.showVerificationPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showVerificationPopup(context, 'გადაამოწმეთ ინვოისი');
      });
    }

    // Initialize with prefilled data if available
    if (widget.prefilledData != null) {
      final data = widget.prefilledData!;

      // --- NEW: Check if data is from history refill ---
      if (data.containsKey('Invoice Type')) {
        // Invoice Type and Currency
        _invoiceTypeSelection = data['Invoice Type'] as String? ?? 'Daily';
        if (_invoiceTypeSelection == 'Monthly') {
          _invoiceType = "თვე";
          _invoiceType2 = "ყოველთვიური";
        } else {
          _invoiceType = "ღამე";
          _invoiceType2 = "ღამის";
        }
        _sellingCurrency = data['Selling Currency'] as String? ?? 'ქართული ლარი';

        // Address and City
        final geAddress = data['Apartment Address (GE)'] as String? ?? 'ქ. ბათუმი, ';
        _geAddressController.text = geAddress;
        _ruAddressController.text = data['Apartment Address (RU)'] as String? ?? 'г. Батуми, ';
        _selectedCity = geAddress.startsWith('ქ. ბათუმი') ? 'ბათუმი' : 'თბილისი';

        _districtController.text = data['District'] as String? ?? '';
        _microDistrictController.text = data['Microdistrict'] as String? ?? '';
        _districtRuController.text = data['districtRu'] as String? ?? '';
        _microDistrictRuController.text = data['microDistrictRu'] as String? ?? '';

        // Apartment Details
        _seaView = data['Sea View'] as String? ?? 'არა';
        _seaLine = data['Sea Line'] as String? ?? 'არა';
        _geAppRoom = data['Apartment Room (GE)'] as String? ?? '3-ოთახიანი';
        _ruAppRoom = _geAppRoomOptions[_geAppRoom] ?? '3-комнатная';
        _geAppBedroom = data['Apartment Bedroom (GE)'] as String? ?? '1-საძინებლიანი';
        _ruAppBedroom = _geAppBedroomOptions[_geAppBedroom] ?? '1 спальня';
        _balcony = data['Balcony'] as String? ?? '1 აივანი';
        _terrace = data['Terrace'] as String? ?? 'ტერასის გარეშე';

        // Dates
        final startDateString = data['Start Date'] as String?;
        if (startDateString != null) _startDate = DateTime.tryParse(startDateString);
        final endDateString = data['End Date'] as String?;
        if (endDateString != null) _endDate = DateTime.tryParse(endDateString);
        _startNegotiated = data['Start Negotiated'] as String? ?? 'არა';

        // Price
        _priceController.text = data['Price'] as String? ?? '';
        _prePayedController.text = data['Pre-payed'] as String? ?? '';

        // Guide Person
        final guideName = data['Guide Person (GE)'] as String?;
        if (guideName != null && _guidePersonOptions.containsKey(guideName)) {
          _guidePerson = guideName;
          _guidePhoneNum = _guidePersonOptions[guideName]!;
        } else if (guideName != null) {
          _guidePerson = 'სხვა';
          _customGuideNameController.text = guideName;
          _customGuidePhoneController.text = data['Guide Phone Num'] as String? ?? '';
        }

        // Guest Info
        _geNameTakeController.text = data['Guest Name (GE)'] as String? ?? '';
        _ruNameTakeController.text = data['Guest Name (RU)'] as String? ?? '';
        _takePhoneNumController.text = data['Guest Phone Num'] as String? ?? '';
        _adultsController.text = data['Adults'] as String? ?? '';
        _childrenController.text = data['Children'] as String? ?? '';
        _pets = data['Pets'] as String? ?? 'არა';

        // Owner Info & Recipient
        _addOwnerManually = data['Manual Owner Input Enabled'] as String? ?? 'არა';
        _manualOwnerNameController.text = data['Manual Owner Name'] as String? ?? '';
        _manualOwnerNameRuController.text = data['Manual Owner Name (RU)'] as String? ?? '';

        // Infer recipient based on filled data
        if (_geNameTakeController.text.isNotEmpty || _addOwnerManually == 'არა') {
          _invoiceRecipient = 'კლიენტი';
        } else {
          _invoiceRecipient = 'მეპატრონე';
        }

        // Recalculate derived values
        _calculateDatesRange(); // This also calls _updateCalculatedPrices()
      } else {
        // --- EXISTING LOGIC to prefill from somewhere else (e.g., booking) ---
        _selectedApartment = data['apartment'] as Apartment?;
        _startDate = data['startDate'] as DateTime?;
        _endDate = data['endDate'] as DateTime?;

        _invoiceRecipient = data['recipient'] as String? ?? 'კლიენტი';
        _geNameTakeController.text = data['guestName'] as String? ?? '';
        _prePayedController.text = data['prepayment'] as String? ?? '';
        _manualOwnerNameController.text = data['ownerName'] as String? ?? '';

        _invoiceTypeSelection = data['invoiceType'] as String? ?? 'Daily';
        _sellingCurrency = data['currency'] as String? ?? 'ქართული ლარი';
        if (_invoiceTypeSelection == 'Monthly') {
          _invoiceType = "თვე";
          _invoiceType2 = "ყოველთვიური";
        } else {
          _invoiceType = "ღამე";
          _invoiceType2 = "ღამის";
        }

        final prefilledGuide = data['guidePerson'] as String?;
        if (prefilledGuide != null && _guidePersonOptions.containsKey(prefilledGuide)) {
          _guidePerson = prefilledGuide;
          _guidePhoneNum = _guidePersonOptions[prefilledGuide]!;
        }

        if (_selectedApartment != null) {
          _onApartmentSelected(_selectedApartment);
          final bookingPrice = data['bookingPrice'] as double?;
          if (bookingPrice != null) {
            _priceController.text = _formatDouble(bookingPrice);
          }
        }

        if (_startDate != null && _endDate != null) {
          _calculateDatesRange();
        }
      }
    } else {
      // Set default address prefixes if no prefilled data
      _geAddressController.text = 'ქ. ბათუმი, ';
      _ruAddressController.text = 'г. Батуми, ';
    }

    _districtController.addListener(_updateCalculatedPrices);
    _microDistrictController.addListener(_updateCalculatedPrices);
    _priceController.addListener(_updateCalculatedPrices);
    _prePayedController.addListener(_updateCalculatedPrices);
    _manualOwnerNameController.addListener(_updateOwnerBlock);



    _ownersSubscription = _firestoreService.getOwners().listen((owners) { // Capture subscription
      if (!mounted) return; // Add safety check
      setState(() {
        _allOwners = owners;

        if (_selectedApartment != null && (_selectedOwner == null || _selectedOwner!.name == 'Unknown')) {
          final String ownerIdentifier = _selectedApartment!.ownerNumber.isNotEmpty
              ? '${_selectedApartment!.ownerName}-${_selectedApartment!.ownerNumber}'
              : _selectedApartment!.ownerName;

          final foundOwner = _allOwners.firstWhere(
                (owner) => owner.id == ownerIdentifier,
            orElse: () => Owner(id: '', name: 'Unknown', ownerNumber: ''),
          );

          _selectedOwner = foundOwner;

          // Also update the manual owner text fields if visible.
          if (_addOwnerManually == 'კი') {
            _manualOwnerNameController.text = _selectedOwner?.name ?? '';
            _manualOwnerNameRuController.text = _selectedOwner?.nameRu ?? ''; // ADD THIS LINE
          }
        }
      });
    });

    // Load all apartments initially
    _apartmentsSubscription = _firestoreService.getAllApartments().listen((apartments) { // Capture subscription
      if (!mounted) return; // Add safety check
      setState(() {
        _allApartments = apartments;
        _filterAndSortApartments();
      });
    });

    void setupFocusListeners(FocusNode geNode, FocusNode ruNode, Function(bool) updateDominance) {
      geNode.addListener(() {
        if (geNode.hasFocus) setState(() => updateDominance(false));
      });
      ruNode.addListener(() {
        if (ruNode.hasFocus) setState(() => updateDominance(true));
      });
    }

    setupFocusListeners(_geAddressFocusNode, _ruAddressFocusNode, (isRuDominant) => _isRuAddressDominant = isRuDominant);
    setupFocusListeners(_geDistrictFocusNode, _ruDistrictFocusNode, (isRuDominant) => _isRuDistrictDominant = isRuDominant);
    setupFocusListeners(_geMicroDistrictFocusNode, _ruMicroDistrictFocusNode, (isRuDominant) => _isRuMicroDistrictDominant = isRuDominant);
    setupFocusListeners(_geNameTakeFocusNode, _ruNameTakeFocusNode, (isRuDominant) => _isRuNameTakeDominant = isRuDominant);

    setupFocusListeners(_geOwnerNameFocusNode, _ruOwnerNameFocusNode, (isRuDominant) => _isRuOwnerNameDominant = isRuDominant);
// ... existing code
  }

  @override
  void dispose() {
    _ownersSubscription?.cancel();
    _apartmentsSubscription?.cancel();
    _geAddressController.dispose();
    _ruAddressController.dispose();
    _priceController.dispose();
    _prePayedController.dispose();
    _geNameTakeController.dispose();
    _ruNameTakeController.dispose();
    _adultsController.dispose();
    _childrenController.dispose();
    _takePhoneNumController.dispose();
    _manualOwnerNameController.dispose();
    _districtController.dispose();
    _microDistrictController.dispose();
    _districtRuController.dispose();
    _microDistrictRuController.dispose();
    _geAddressFocusNode.dispose();
    _ruAddressFocusNode.dispose();
    _geDistrictFocusNode.dispose();
    _ruDistrictFocusNode.dispose();
    _geMicroDistrictFocusNode.dispose();
    _ruMicroDistrictFocusNode.dispose();
    _geNameTakeFocusNode.dispose();
    _ruNameTakeFocusNode.dispose();

    // ADD THESE TWO LINES
    _geOwnerNameFocusNode.dispose();
    _ruOwnerNameFocusNode.dispose();
    super.dispose();
  }


  void _filterAndSortApartments() {
    if (_selectedOwner == null) {
      // Show all apartments if no owner selected
      _availableApartmentsForOwner = List.from(_allApartments);
    } else {
      // Filter by owner if one is selected
      _availableApartmentsForOwner = _allApartments
          .where((apartment) => apartment.ownerId == _selectedOwner!.id)
          .toList();
    }

    // Sort by profitability
    _availableApartmentsForOwner.sort((a, b) {
      final double profitA = a.profitLari + (a.profitUSD * 2.5);
      final double profitB = b.profitLari + (b.profitUSD * 2.5);
      return profitB.compareTo(profitA);
    });

    // Auto-select first apartment if available and none selected
    if (_selectedOwner != null &&
        _availableApartmentsForOwner.isNotEmpty &&
        _selectedApartment == null) {
      _onApartmentSelected(_availableApartmentsForOwner.first);
    }
  }

  // --- Helper Methods for Auto-fill and Calculations ---

  // lib/invoice_generator_screen.dart -> _InvoiceGeneratorScreenState

  void _updateAddressPrefix() {
    // 1. Define all possible prefixes to be able to remove them
    const gePrefixes = ['ქ. ბათუმი, ', 'ქ. თბილისი, '];
    const ruPrefixes = ['г. Батуми, ', 'г. Тбилиси, '];

    // 2. Get the current text from the controllers
    String cleanGeAddress = _geAddressController.text;
    String cleanRuAddress = _ruAddressController.text;

    // 3. Strip any existing Georgian prefix
    for (var prefix in gePrefixes) {
      if (cleanGeAddress.startsWith(prefix)) {
        cleanGeAddress = cleanGeAddress.substring(prefix.length);
        break; // Exit after finding and stripping a prefix
      }
    }

    // 4. Strip any existing Russian prefix
    for (var prefix in ruPrefixes) {
      if (cleanRuAddress.startsWith(prefix)) {
        cleanRuAddress = cleanRuAddress.substring(prefix.length);
        break; // Exit after finding and stripping a prefix
      }
    }

    // 5. Determine the new prefix based on the selected city
    String gePrefixToAdd = _selectedCity == 'ბათუმი' ? 'ქ. ბათუმი, ' : 'ქ. თბილისი, ';
    String ruPrefixToAdd = _selectedCity == 'ბათუმი' ? 'г. Батуми, ' : 'г. Тбилиси, ';

    // 6. Update the controllers with the new prefix + the clean address
    _geAddressController.text = gePrefixToAdd + cleanGeAddress;
    _ruAddressController.text = ruPrefixToAdd + cleanRuAddress;
  }

// lib/invoice_generator_screen.dart -> _InvoiceGeneratorScreenState

  void _onApartmentSelected(Apartment? apartment) {
    setState(() {
      _selectedApartment = apartment;

      if (apartment != null) {
        // This part is now fixed from the previous step
        final String ownerIdentifier = apartment.ownerNumber.isNotEmpty
            ? '${apartment.ownerName}-${apartment.ownerNumber}'
            : apartment.ownerName;
        _selectedOwner = _allOwners.firstWhere(
              (owner) => owner.id == ownerIdentifier,
          orElse: () => Owner(id: '', name: 'Unknown', ownerNumber: ''),
        );

        _selectedCity = apartment.city;

        // Autofill apartment data
        _geAddressController.text = apartment.geAddress;
        _ruAddressController.text = apartment.ruAddress;
        _seaLine = apartment.seaLine;
        _seaView = apartment.seaView;
        _geAppRoom = apartment.geAppRoom;
        _geAppBedroom = apartment.geAppBedroom;
        _balcony =
        apartment.balcony.isEmpty ? 'აივნის გარეშე' : apartment.balcony;
        _terrace =
        apartment.terrace.isEmpty ? 'ტერასის გარეშე' : apartment.terrace;
        _priceController.text = _invoiceTypeSelection == 'Daily'
            ? apartment.dailyPrice.toStringAsFixed(2)
            : apartment.monthlyPrice.toStringAsFixed(2);

        _updateCalculatedPrices();

        _districtController.text = apartment.district;
        _microDistrictController.text = apartment.microDistrict;

        // If manual owner mode is on, set both Georgian and Russian names
        if (_addOwnerManually == 'კი') {
          _manualOwnerNameController.text = _selectedOwner?.name ?? '';
          _manualOwnerNameRuController.text = _selectedOwner?.nameRu ?? ''; // ADD THIS LINE
        }

        _priceController.text = _invoiceTypeSelection == 'Daily'
            ? _formatDouble(apartment.dailyPrice)
            : _formatDouble(apartment.monthlyPrice);

      } else {
        // This 'else' block remains the same
        _selectedCity = 'ბათუმი';
        _geAddressController.clear();
        _ruAddressController.clear();
        _priceController.clear();
        _seaLine = 'პირველი ზოლი';
        _seaView = "არა";
        _geAppRoom = '3-ოთახიანი';
        _ruAppRoom = '3-комнатная';
        _geAppBedroom = '1-საძინებლიანი';
        _ruAppBedroom = '1 спальня';
        _balcony = '1 აივანი';
        _terrace = 'ტერასის გარეშე';
      }
    });
  }

  void _onOwnerSelected(Owner? owner) {
    setState(() {
      _selectedOwner = owner;
      _selectedApartment = null; // Clear selected apartment when owner changes

      if (owner != null) {
        _availableApartmentsForOwner = _allApartments
            .where((apartment) => apartment.ownerId == owner.id)
            .toList();
        _filterAndSortApartments();
        if (_availableApartmentsForOwner.isNotEmpty) {
          _onApartmentSelected(_availableApartmentsForOwner.first);
        }

        // If manual owner mode is on, set both names
        if (_addOwnerManually == 'კი') {
          _manualOwnerNameController.text = owner.name;
          _manualOwnerNameRuController.text = owner.nameRu; // ADD THIS LINE
        }
      } else {
        // This 'else' block handles deselecting an owner
        _availableApartmentsForOwner = List.from(_allApartments);
        _filterAndSortApartments();
        _geAddressController.clear();
        _ruAddressController.clear();
        _priceController.clear();
        _prePayedController.clear();
        _geNameTakeController.clear();
        _ruNameTakeController.clear();
        _adultsController.clear();
        _childrenController.clear();
        _takePhoneNumController.clear();
        _manualOwnerNameController.clear();
        _manualOwnerNameRuController.clear(); // ADD THIS LINE
        _seaLine = 'პირველი ზოლი';
        _seaView = "არა";
        _geAppRoom = '3-ოთახიანი';
        _ruAppRoom = '3-комнатная';
        _geAppBedroom = '1-საძინებლიანი';
        _ruAppBedroom = '1 спальня';
        _balcony = '1 აივანი';
        _terrace = 'ტერასის გარეშე';
        _startNegotiated = 'არა';
        _sellingCurrency = 'ქართული ლარი';
        _guidePerson = 'მაკო ნაკაიძე';
        _guidePhoneNum = '+995 599 238 685';
        _pets = 'არა';
        _addOwnerManually = 'არა';
        _priceFull = 0.0;
        _priceLeft = 0.0;
        _calculateDateNumbers = '';
        _calculatedPeriod = 0;
      }
    });
  }

  String _formatDouble(double value) {
    if (value.remainder(1) == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  void _updateOwnerBlock() {
    setState(() {
      // This method is primarily used to trigger a rebuild if the manual owner text changes.
      // The actual owner block content is determined in _generateInvoiceText.
    });
  }

  void _autofillApartmentData(Apartment apartment) {
    _geAddressController.text = apartment.geAddress;
    _ruAddressController.text = apartment.ruAddress;
    _seaLine = apartment.seaLine;
    _seaView = apartment.seaView;
    _geAppRoom = apartment.geAppRoom;
    _geAppBedroom = apartment.geAppBedroom;

    _balcony = apartment.balcony.isEmpty ? 'აივნის გარეშე' : apartment.balcony;
    _terrace = apartment.terrace.isEmpty ? 'ტერასის გარეშე' : apartment.terrace;
    _priceController.text = _invoiceTypeSelection == 'Daily'
        ? apartment.dailyPrice.toStringAsFixed(2)
        : apartment.monthlyPrice.toStringAsFixed(2);
    _updateCalculatedPrices();
  }

  void _updateCalculatedPrices() {
    setState(() {
      final double price = double.tryParse(_priceController.text) ?? 0.0;
      // Use the calculated period
      final int period = _calculatedPeriod;
      final double prePayed = double.tryParse(_prePayedController.text) ?? 0.0;

      _priceFull = price * period;
      _priceLeft = _priceFull - prePayed;
    });
  }

  void _calculateDatesRange() {
    if (_startDate == null || _endDate == null) {
      setState(() {
        _calculateDateNumbers = '';
        _calculatedPeriod = 0; // Reset period if dates are not set
      });
      _updateCalculatedPrices(); // Update prices after resetting period
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      setState(() {
        _calculateDateNumbers = 'Invalid date range';
        _calculatedPeriod = 0; // Reset period for invalid range
      });
      _updateCalculatedPrices(); // Update prices after resetting period
      return;
    }

    List<int> days = [];
    DateTime currentDate = DateTime(
        _startDate!.year, _startDate!.month, _startDate!.day);
    DateTime endOfRange = DateTime(
        _endDate!.year, _endDate!.month, _endDate!.day);

    int periodInDays = 0;
    while (currentDate.isBefore(endOfRange)) {
      days.add(currentDate.day);
      periodInDays++;
      currentDate =
          DateTime(currentDate.year, currentDate.month, currentDate.day + 1);
    }

    setState(() {
      _calculateDateNumbers = days.map((e) => e.toString()).join(', ');
      if (_invoiceTypeSelection == 'Daily') {
        _calculatedPeriod = periodInDays;
      } else {
        // For monthly, calculate difference in months. This is a simplified calculation.
        // For more precise month calculation, consider differences in days relative to month lengths.
        int yearDiff = _endDate!.year - _startDate!.year;
        int monthDiff = _endDate!.month - _startDate!.month;
        _calculatedPeriod = yearDiff * 12 + monthDiff;
        if (_calculatedPeriod < 0) _calculatedPeriod = 0; // Ensure non-negative
      }
    });

    _updateCalculatedPrices(); // Call to update prices whenever dates/period change
  }

  // --- Formatting Getters for Invoice Template ---

  String _formatDate(DateTime? date, Map<int, String> monthMap) {
    if (date == null) return '';
    final day = date.day;
    final month = monthMap[date.month];
    final year = date.year;
    return '$day/$month/$year';
  }

  String get _startDateFormattedGe {
    return _formatDate(_startDate, _georgianMonths);
  }

  String get _endDateFormattedGe {
    return _formatDate(_endDate, _georgianMonths);
  }

  String get _startDateFormattedRu {
    return _formatDate(_startDate, _russianMonths);
  }

  String get _endDateFormattedRu {
    return _formatDate(_endDate, _russianMonths);
  }

  String get _startNegotiatedFormattedGe {
    return _startNegotiatedOptions[_startNegotiated] ?? '';
  }

  String get _startNegotiatedFormattedRu {
    return _startNegotiatedOptionsRu[_startNegotiated] ?? '';
  }

  String get _calculateDateFormattedGe {
    return _invoiceTypeSelection == 'Daily' &&
        _calculateDateNumbers.isNotEmpty &&
        _calculateDateNumbers != 'Invalid date range'
        ? 'რიცხვები: $_calculateDateNumbers'
        : '';
  }

  String get _calculateDateFormattedRu {
    return _invoiceTypeSelection == 'Daily' &&
        _calculateDateNumbers.isNotEmpty &&
        _calculateDateNumbers != 'Invalid date range'
        ? 'Числа: $_calculateDateNumbers'
        : '';
  }

  String get _sellingCurrencyFormattedGe {
    return _sellingCurrency; // Already in Georgian
  }

  String get _sellingCurrencyFormattedRu {
    return _sellingCurrencyOptions[_sellingCurrency] ?? '';
  }

  String get _priceFullFormatted {
    return _priceFull.toInt().toString();
  }

  String get _prePayedFormatted {
    return (double.tryParse(_prePayedController.text) ?? 0.0)
        .toInt()
        .toString();
  }

  String get _priceLeftFormatted {
    return _priceLeft.toInt().toString();
  }

  String get _guidePersonGe {
    if (_guidePerson == 'სხვა') {
      return _customGuideNameController.text;
    }
    return _guidePerson;
  }

  String get _guidePersonRu {
    if (_guidePerson == 'სხვა') {
      return ''; // No direct Russian equivalent for custom input
    }
    return _guidePersonRuNames[_guidePerson] ?? '';
  }

  String get _guidePhoneNumFormatted {
    if (_guidePerson == 'სხვა') {
      return _customGuidePhoneController.text;
    }
    return _guidePhoneNum;
  }

  String get _takePhoneNum {
    return _takePhoneNumController.text.isNotEmpty
        ? '- ${_takePhoneNumController.text}'
        : '';
  }

  String get _adultsFormattedGe {
    final int adults = int.tryParse(_adultsController.text) ?? 0;
    return '$adults უფროსი';
  }

  String get _adultsFormattedRu {
    final int adults = int.tryParse(_adultsController.text) ?? 0;
    if (adults == 1) {
      return '1 Взрослый';
    } else {
      return '$adults Взрослых';
    }
  }

  String get _childrenFormattedGe {
    final int children = int.tryParse(_childrenController.text) ?? 0;
    return children == 0 ? '' : ', $children პატარა';
  }

  String get _childrenFormattedRu {
    final int children = int.tryParse(_childrenController.text) ?? 0;
    if (children == 0) {
      return '';
    } else if (children == 1) {
      return ', 1 ребенок';
    } else {
      return ', $children детей';
    }
  }

  String get _petsFormattedGe {
    return _pets == 'არა' ? '' : _pets;
  }

  String get _petsFormattedRu {
    return _pets == 'არა' ? '' : (_petsOptions[_pets] ?? '');
  }

  String get _seaLineFormattedRu {
    final ruValue = _seaLineOptions[_seaLine] ?? ''; // <-- MODIFY THIS
    return ruValue.isNotEmpty ? '\n$ruValue' : '';  // <-- ENTIRE GETTER
  }

  String get _seaViewFormattedRu {
    return _seaView == 'კი' ? '\nВид на море' : '';
  }

  String get _balconyFormattedRu {
    return _balconyOptions[_balcony] ?? '';
  }

  String get _terraceFormattedRu {
    return _terraceOptions[_terrace] ?? '';
  }

  String get _invoiceTypeFormattedRu {
    if (_calculatedPeriod == 1) {
      return _invoiceTypeSelection == 'Daily' ? 'ночь' : 'месяц';
    } else if (_calculatedPeriod >= 2 && _calculatedPeriod <= 4) {
      return _invoiceTypeSelection == 'Daily' ? 'ночи' : 'месяца';
    } else {
      return _invoiceTypeSelection == 'Daily' ? 'ночей' : 'месяцев';
    }
  }

  String get _invoiceType2FormattedRu {
    return _invoiceTypeSelection == 'Daily'
        ? 'сутки'
        : 'месяц'; // 'ღამის' -> 'ночную', 'თვიური' -> 'месячную'
  }


  // --- Invoice Templates (Placeholders will be replaced in _generateInvoiceText) ---
  final String _georgianInvoiceTemplate = """
🏡 ინვოისი

📍 მისამართი:
\${geAddress}\${geDistrictBlock}\${seaView}\${seaLine}

🛏 ბინის მახასიათებლები:
\${geAppRoom}\${geAppBedroom}\${balcony}\${terrace}
კონდიციონერი
ინტერნეტი / Wi-Fi
ცხელი წყალი
ლიფტი

📅 დაჯავშნის პერიოდი:
შესვლა: \${startDateFormattedGe}\${startNegotiatedFormattedGe}
\${calculateDateFormattedGe}
გასვლა: \${endDateFormattedGe}, 12:00 საათზე
სულ: \${calculatedPeriod} \${invoiceType}

💵 ფასი და გადახდა:
\${invoiceType2} ფასი: \${price} \${sellingCurrencyFormattedGe}
ჯამური ღირებულება: \${priceFullFormatted} \${sellingCurrencyFormattedGe}\${GE_PREPAYMENT_BLOCK}\${GE_REMAINING_PAYMENT_BLOCK}
\${GE_GUIDE_BLOCK}
👩🏻‍💼 თქვენი აგენტი:
სოფია – +995 574 533 353

👤 სტუმარი:
\${geNameTake} \${takePhoneNum}\${GE_ADULTCHILDREN_BLOCK}
\${petsFormattedGe}\${GE_OWNER_BLOCK}""";


  final String _russianInvoiceTemplate = """
🏡 Инвойс

📍 Адрес:
\${ruAddress}\${ruDistrictBlock}\${seaViewFormattedRu}\${seaLineFormattedRu}

🛏 Описание квартиры:
\${ruAppRoom}\${ruAppBedroom}\${balconyFormattedRu}\${terraceFormattedRu}
Кондиционер
Интернет / Wi-Fi
Горячая вода
Лифт

📅 Даты проживания:
Заезд: \${startDateFormattedRu}\${startNegotiatedFormattedRu}
\${calculateDateFormattedRu}
Выезд: \${endDateFormattedRu} 12:00
Всего: \${calculatedPeriod} \${invoiceTypeFormattedRu}

💵 Стоимость и оплата:
Цена за \${invoiceType2FormattedRu}: \${price} \${sellingCurrencyFormattedRu}
Общая сумма: \${priceFullFormatted} \${sellingCurrencyFormattedRu}\${RU_PREPAYMENT_BLOCK}\${RU_REMAINING_PAYMENT_BLOCK}
\${RU_GUIDE_BLOCK}
🧑‍💼 Ваш агент:
София – +995 574 533 353

👤 Гость:
\${ruNameTake} \${takePhoneNum}\${RU_ADULTCHILDREN_BLOCK}
\${petsFormattedRu}\${RU_OWNER_BLOCK}""";



  String _generateInvoiceText(String template) {
    String generatedText = template;

    // Build guide blocks
    String geGuideBlockContent;
    String ruGuideBlockContent;

    // Build owner blocks
    String geOwnerBlock = '';
    String ruOwnerBlock = '';

    // Build district blocks
    String geDistrictBlock = '';
    if (_districtController.text.isNotEmpty) {
      geDistrictBlock += '\n${_districtController.text}';
    }
    if (_microDistrictController.text.isNotEmpty) {
      geDistrictBlock += '\n${_microDistrictController.text}';
    }

    String ruDistrictBlock = '';
    if (_districtRuController.text.isNotEmpty) {
      ruDistrictBlock += '\n${_districtRuController.text}';
    }
    if (_microDistrictRuController.text.isNotEmpty) {
      ruDistrictBlock += '\n${_microDistrictRuController.text}';
    }

    // Build adult/children blocks
    String geAdultChildrenBlock = '';
    String ruAdultChildrenBlock = '';

    // Handle guest name/phone
    if (_invoiceRecipient == 'კლიენტი') {
      generatedText = generatedText.replaceAll(
          '\${geNameTake} \${takePhoneNum}',
          '${_geNameTakeController.text} ${_takePhoneNum}'
      );
      generatedText = generatedText.replaceAll(
          '\${ruNameTake} \${takePhoneNum}',
          '${_ruNameTakeController.text} ${_takePhoneNum}'
      );
    } else {
      generatedText = generatedText.replaceAll('\${geNameTake} \${takePhoneNum}', '');
      generatedText = generatedText.replaceAll('\${ruNameTake} \${takePhoneNum}', '');
    }

    // Handle owner block based on recipient and manual input
    if (_invoiceRecipient == 'მეპატრონე') {
      if (_addOwnerManually == 'კი') {
        final geName = _manualOwnerNameController.text;
        final ruName = _manualOwnerNameRuController.text;

        if (geName.isNotEmpty) {
          geOwnerBlock = '\n👤 მეპატრონე:\n$geName';
        }
        // Use Russian name if provided, otherwise fallback to Georgian name
        if (ruName.isNotEmpty) {
          ruOwnerBlock = '\n👤 Владелец:\n$ruName';
        } else if (geName.isNotEmpty) {
          ruOwnerBlock = '\n👤 Владелец:\n$geName';
        }
      } else if (_selectedOwner != null) {
        geOwnerBlock = '\n👤 მეპატრონე:\n${_selectedOwner!.name} - ${_selectedOwner!.ownerNumber}';
        ruOwnerBlock = '\n👤 Владелец:\n${_selectedOwner!.name} - ${_selectedOwner!.ownerNumber}';
      }
    }

    // Build adult/children blocks
    if (_geNameTakeController.text != '' || _takePhoneNum != '') {
      geAdultChildrenBlock = '\n${_adultsFormattedGe}${_childrenFormattedGe}';
      ruAdultChildrenBlock = '\n${_adultsFormattedRu}${_childrenFormattedRu}';
    } else {
      geAdultChildrenBlock = '${_adultsFormattedGe}${_childrenFormattedGe}';
      ruAdultChildrenBlock = '${_adultsFormattedRu}${_childrenFormattedRu}';
    }

    // Handle bedrooms
    String formattedGeBedroom = '';
    String formattedRuBedroom = '';
    if (_geAppBedroom != 'არა') {
      formattedGeBedroom = '\n$_geAppBedroom';
      formattedRuBedroom = '\n${_ruAppBedroom}';
    }

    // Handle guide block
    if (_guidePerson == 'სხვა') {
      final customName = _customGuideNameController.text;
      final customPhone = _customGuidePhoneController.text;
      geGuideBlockContent = """
    
📞 თქვენ დაგხვდებათ:
$customName – $customPhone
""";
      ruGuideBlockContent = """
    
📞 Вас встретит:
$customName – $customPhone
""";
    } else {
      geGuideBlockContent = """
    
📞 თქვენ დაგხვდებათ:
${_guidePersonGe} – ${_guidePhoneNum}
""";
      ruGuideBlockContent = """
    
📞 Вас встретит:
${_guidePersonRu} – ${_guidePhoneNum}
""";
    }

    // Handle balcony and terrace
    String formattedGeBalcony = '';
    String formattedRuBalcony = '';
    if (_balcony != 'აივნის გარეშე') {
      formattedGeBalcony = '\n$_balcony';
      formattedRuBalcony = '\n${_balconyOptions[_balcony] ?? ''}';
    }

    String formattedGeTerrace = '';
    String formattedRuTerrace = '';
    if (_terrace != 'ტერასის გარეშე') {
      formattedGeTerrace = '\n$_terrace';
      formattedRuTerrace = '\n${_terraceOptions[_terrace] ?? ''}';
    }

    // Handle prepayment blocks
    String formattedGePrePayed = '';
    String formattedRuPrePayed = '';
    final double prePayedAmount = double.tryParse(_prePayedController.text) ?? 0.0;

    if (prePayedAmount > 0 && _invoiceRecipient == 'კლიენტი') {
      formattedGePrePayed = '\nწინასწარი გადახდა (ჯავშნის თანხა): ${_prePayedFormatted} ${_sellingCurrencyFormattedGe}';
      formattedRuPrePayed = '\nПредоплата (бронь): ${_prePayedFormatted} ${_sellingCurrencyFormattedRu}';
    }

    // Build remaining payment blocks
    String geRemainingPaymentBlock = '';
    String ruRemainingPaymentBlock = '';

    if (_invoiceRecipient == 'კლიენტი') {
      geRemainingPaymentBlock = '\nდარჩენილი გადასახდელი თანხა: ${_priceLeftFormatted} ${_sellingCurrencyFormattedGe} (ბინაში შესვლის დროს)';
      ruRemainingPaymentBlock = '\nОставшая сумма оплаты: ${_priceLeftFormatted} ${_sellingCurrencyFormattedRu} (При заезде в квартиру)';
    }



    // Replace all placeholders
    generatedText = generatedText.replaceAll('\${geDistrictBlock}', geDistrictBlock);
    generatedText = generatedText.replaceAll('\${ruDistrictBlock}', ruDistrictBlock);
    generatedText = generatedText.replaceAll('\${geAddress}', _geAddressController.text);
    generatedText = generatedText.replaceAll('\${ruAddress}', _ruAddressController.text);
    generatedText = generatedText.replaceAll('\${seaLine}', _seaLine != 'არა' ? '\n$_seaLine' : '');
    generatedText = generatedText.replaceAll('\${seaView}', _seaView == 'კი' ? '\nზღვის ხედი' : '');
    generatedText = generatedText.replaceAll('\${geAppRoom}', _geAppRoom);
    generatedText = generatedText.replaceAll('\${ruAppRoom}', _ruAppRoom);
    generatedText = generatedText.replaceAll('\${geAppBedroom}', formattedGeBedroom);
    generatedText = generatedText.replaceAll('\${ruAppBedroom}', formattedRuBedroom);
    generatedText = generatedText.replaceAll('\${balcony}', formattedGeBalcony);
    generatedText = generatedText.replaceAll('\${terrace}', formattedGeTerrace);

    generatedText = generatedText.replaceAll('\${startDateFormattedGe}', _startDateFormattedGe);
    generatedText = generatedText.replaceAll('\${endDateFormattedGe}', _endDateFormattedGe);
    generatedText = generatedText.replaceAll('\${startDateFormattedRu}', _startDateFormattedRu);
    generatedText = generatedText.replaceAll('\${endDateFormattedRu}', _endDateFormattedRu);

    generatedText = generatedText.replaceAll('\${startNegotiatedFormattedGe}', _startNegotiatedFormattedGe);
    generatedText = generatedText.replaceAll('\${startNegotiatedFormattedRu}', _startNegotiatedFormattedRu);
    generatedText = generatedText.replaceAll('\${calculateDateFormattedGe}', _calculateDateFormattedGe);
    generatedText = generatedText.replaceAll('\${calculateDateFormattedRu}', _calculateDateFormattedRu);

    generatedText = generatedText.replaceAll('\${calculatedPeriod}', _calculatedPeriod.toString());
    generatedText = generatedText.replaceAll('\${invoiceType}', _invoiceType);
    generatedText = generatedText.replaceAll('\${invoiceType2}', _invoiceType2);
    generatedText = generatedText.replaceAll('\${invoiceTypeFormattedRu}', _invoiceTypeFormattedRu);
    generatedText = generatedText.replaceAll('\${invoiceType2FormattedRu}', _invoiceType2FormattedRu);
    generatedText = generatedText.replaceAll('\${price}', _priceController.text);
    generatedText = generatedText.replaceAll('\${sellingCurrencyFormattedGe}', _sellingCurrencyFormattedGe);
    generatedText = generatedText.replaceAll('\${sellingCurrencyFormattedRu}', _sellingCurrencyFormattedRu);
    generatedText = generatedText.replaceAll('\${priceFullFormatted}', _priceFullFormatted);
    generatedText = generatedText.replaceAll('\${priceLeftFormatted}', _priceLeftFormatted);
    generatedText = generatedText.replaceAll('\${guidePersonGe}', _guidePersonGe);
    generatedText = generatedText.replaceAll('\${guidePersonRu}', _guidePersonRu);
    generatedText = generatedText.replaceAll('\${guidePhoneNum}', _guidePhoneNumFormatted);
    generatedText = generatedText.replaceAll('\${adultsFormattedGe}', _adultsFormattedGe);
    generatedText = generatedText.replaceAll('\${adultsFormattedRu}', _adultsFormattedRu);
    generatedText = generatedText.replaceAll('\${childrenFormattedGe}', _childrenFormattedGe);
    generatedText = generatedText.replaceAll('\${childrenFormattedRu}', _childrenFormattedRu);
    generatedText = generatedText.replaceAll('\${petsFormattedGe}', _petsFormattedGe);
    generatedText = generatedText.replaceAll('\${petsFormattedRu}', _petsFormattedRu);
    generatedText = generatedText.replaceAll('\${GE_GUIDE_BLOCK}', geGuideBlockContent);
    generatedText = generatedText.replaceAll('\${RU_GUIDE_BLOCK}', ruGuideBlockContent);
    generatedText = generatedText.replaceAll('\${RU_ADULTCHILDREN_BLOCK}', ruAdultChildrenBlock);
    generatedText = generatedText.replaceAll('\${GE_ADULTCHILDREN_BLOCK}', geAdultChildrenBlock);
    generatedText = generatedText.replaceAll('\${GE_OWNER_BLOCK}', geOwnerBlock);
    generatedText = generatedText.replaceAll('\${RU_OWNER_BLOCK}', ruOwnerBlock);
    generatedText = generatedText.replaceAll('\${seaLineFormattedRu}', _seaLineFormattedRu);
    generatedText = generatedText.replaceAll('\${seaViewFormattedRu}', _seaViewFormattedRu);
    generatedText = generatedText.replaceAll('\${balconyFormattedRu}', formattedRuBalcony);
    generatedText = generatedText.replaceAll('\${terraceFormattedRu}', formattedRuTerrace);
    generatedText = generatedText.replaceAll('\${GE_PREPAYMENT_BLOCK}', formattedGePrePayed);
    generatedText = generatedText.replaceAll('\${RU_PREPAYMENT_BLOCK}', formattedRuPrePayed);
    generatedText = generatedText.replaceAll('\${GE_REMAINING_PAYMENT_BLOCK}', geRemainingPaymentBlock);
    generatedText = generatedText.replaceAll('\${RU_REMAINING_PAYMENT_BLOCK}', ruRemainingPaymentBlock);

    // Clean up any empty lines
    generatedText = generatedText.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return generatedText;
  }

// --- UI Building ---

// Define colors and text styles at the top of your class or in a separate constants file
// Make sure these are defined in your InvoiceGeneratorScreenState class or accessible globally.
  final Color primaryColor = const Color(0xFF004aad);
  final Color backgroundColor = Colors.white;
  final TextStyle headerStyle = const TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87);



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'ინვოისის შედგენა',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(type: 'Invoice'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // This is the sticky header
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildRecipientButton(
                    label: 'კლიენტისთვის',
                    isActive: _invoiceRecipient == 'კლიენტი',
                    onTap: () {
                      setState(() {
                        if (_invoiceRecipient == 'მეპატრონე') {
                          // Restore client values if they exist
                          _geNameTakeController.text = _storedGeNameTake ?? '';
                          _ruNameTakeController.text = _storedRuNameTake ?? '';
                          _takePhoneNumController.text =
                              _storedTakePhoneNum ?? '';
                          _pets = _storedPets ?? 'არა';
                          _prePayedController.text = _storedPrePayed ?? '';
                        }
                        _invoiceRecipient = 'კლიენტი';
                      });
                    },
                  ),
                  _buildRecipientButton(
                    label: 'მეპატრონესთვის',
                    isActive: _invoiceRecipient == 'მეპატრონე',
                    onTap: () {
                      setState(() {
                        if (_invoiceRecipient == 'კლიენტი') {
                          // Store current client values
                          _storedGeNameTake = _geNameTakeController.text;
                          _storedRuNameTake = _ruNameTakeController.text;
                          _storedTakePhoneNum =
                              _takePhoneNumController.text;
                          _storedPets = _pets;
                          _storedPrePayed = _prePayedController.text;

                          // Clear client fields
                          _geNameTakeController.clear();
                          _ruNameTakeController.clear();
                          _takePhoneNumController.clear();
                          _pets = 'არა';
                          _prePayedController.clear();
                        }
                        _invoiceRecipient = 'მეპატრონე';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // This is the scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 24),

                  // Invoice type section
                  _buildSectionHeader('ინვოისის ტიპი:'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeToggle(
                          label: 'დღიური',
                          isActive: _invoiceTypeSelection == 'Daily',
                          onTap: () {
                            setState(() {
                              _invoiceTypeSelection = 'Daily';
                              _invoiceType = "ღამე";
                              _invoiceType2 = "ღამის";
                              _calculateDatesRange();
                              if (_selectedApartment != null) {
                                _priceController.text = _selectedApartment!
                                    .dailyPrice
                                    .toStringAsFixed(2);
                                _updateCalculatedPrices();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeToggle(
                          label: 'ყოველთვიური',
                          isActive: _invoiceTypeSelection == 'Monthly',
                          onTap: () {
                            setState(() {
                              _invoiceTypeSelection = 'Monthly';
                              _invoiceType = "თვე";
                              _invoiceType2 = "ყოველთვიური";
                              _calculateDateNumbers = '';
                              if (_selectedApartment != null) {
                                _priceController.text = _selectedApartment!
                                    .monthlyPrice
                                    .toStringAsFixed(2);
                                _updateCalculatedPrices();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Currency dropdown
                  _buildSectionHeader('ვალუტა:'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeToggle(
                          label: 'ქართული ლარი',
                          isActive: _sellingCurrency == 'ქართული ლარი',
                          onTap: () {
                            setState(() {
                              _sellingCurrency = 'ქართული ლარი';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeToggle(
                          label: 'აშშ დოლარი',
                          isActive: _sellingCurrency == 'აშშ დოლარი',
                          onTap: () {
                            setState(() {
                              _sellingCurrency = 'აშშ დოლარი';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader('ქალაქი:'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeToggle(
                          label: 'ბათუმი',
                          isActive: _selectedCity == 'ბათუმი',
                          onTap: () {
                            setState(() {
                              _selectedCity = 'ბათუმი';
                              // Add these four lines to clear the fields
                              _districtController.clear();
                              _microDistrictController.clear();
                              _districtRuController.clear();
                              _microDistrictRuController.clear();
                              _updateAddressPrefix(); // Update prefix on change
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeToggle(
                          label: 'თბილისი',
                          isActive: _selectedCity == 'თბილისი',
                          onTap: () {
                            setState(() {
                              _selectedCity = 'თბილისი';
                              _seaView = 'არა'; // Add this line
                              _seaLine = 'არა'; // Add this line
                              _updateAddressPrefix(); // Update prefix on change
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Address fields
                  _buildSectionHeader('ბინის მისამართი:'),
                  const SizedBox(height: 12),
                  _buildAnimatedTextFieldRow(
                    geController: _geAddressController,
                    ruController: _ruAddressController,
                    geLabel: 'მისამართი (ქართულად)',
                    ruLabel: '(რუს./ინგ.)',
                    geFocusNode: _geAddressFocusNode,
                    ruFocusNode: _ruAddressFocusNode,
                    isRuDominant: _isRuAddressDominant,
                  ),
                  if (_selectedCity == 'თბილისი') const SizedBox(height: 16),
                  if (_selectedCity == 'თბილისი')
                    _buildAnimatedTextFieldRow(
                      geController: _districtController,
                      ruController: _districtRuController,
                      geLabel: 'რაიონი (ქართულად)',
                      ruLabel: '(რუს./ინგ).',
                      geFocusNode: _geDistrictFocusNode,
                      ruFocusNode: _ruDistrictFocusNode,
                      isRuDominant: _isRuDistrictDominant,
                    ),
                  if (_selectedCity == 'თბილისი') const SizedBox(height: 16),
                  if (_selectedCity == 'თბილისი')
                    _buildAnimatedTextFieldRow(
                      geController: _microDistrictController,
                      ruController: _microDistrictRuController,
                      geLabel: 'მიკრორაიონი (ქართულად)',
                      ruLabel: '(რუს./ინგ.)',
                      geFocusNode: _geMicroDistrictFocusNode,
                      ruFocusNode: _ruMicroDistrictFocusNode,
                      isRuDominant: _isRuMicroDistrictDominant,
                    ),
                  const SizedBox(height: 24),

                  // Apartment details section
                  _buildSectionHeader('ბინის დეტალები:'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (_selectedCity == 'ბათუმი')
                        _buildModernDropdown<String>(
                          label: 'ზღვის ხედი',
                          value: _seaView,
                          items: _seaViewOptions.keys.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value,
                                  style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _seaView = newValue!;
                            });
                          },
                        ),
                      if (_selectedCity == 'ბათუმი')
                        _buildModernDropdown<String>(
                          label: 'რომელი ზოლი',
                          value: _seaLine,
                          items: _seaLineOptions.keys.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value,
                                  style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _seaLine = newValue!;
                            });
                          },
                        ),
                      _buildModernDropdown<String>(
                        label: 'რამდენ ოთახიანი ბინაა',
                        value: _geAppRoom,
                        items: _geAppRoomOptions.keys.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child:
                            Text(value, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _geAppRoom = newValue!;
                            _ruAppRoom = _geAppRoomOptions[_geAppRoom]!;

                            // Automatically set bedrooms to "არა" when "სტუდიო" is selected
                            if (_geAppRoom == 'სტუდიო') {
                              _geAppBedroom = 'არა';
                              _ruAppBedroom = _geAppBedroomOptions['არა']!;
                            }
                          });
                        },
                      ),
                      _buildModernDropdown<String>(
                        label: 'რამდენ საძინებლიანი ბინაა',
                        value: _geAppBedroom,
                        items: _geAppBedroomOptions.keys.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child:
                            Text(value, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _geAppBedroom = newValue!;
                            _ruAppBedroom =
                            _geAppBedroomOptions[_geAppBedroom]!; // Update Russian equivalent
                          });
                        },
                      ),
                      _buildModernDropdown<String>(
                        label: 'რამდენი აივანი',
                        value: _balcony,
                        items: _balconyOptions.keys.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child:
                            Text(value, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _balcony = newValue!;
                          });
                        },
                      ),
                      _buildModernDropdown<String>(
                        label: 'რამდენი ტერასა',
                        value: _terrace,
                        items: _terraceOptions.keys.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child:
                            Text(value, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _terrace = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Date section
                  _buildSectionHeader('თარიღები:'),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      // Date Picker (100% width)
                      _buildModernDatePicker(
                        label: 'შესვლა',
                        selectedDate: _startDate,
                        onDateSelected: (date) {
                          setState(() {
                            _startDate = date;
                            _calculateDatesRange();
                          });
                        },
                      ),
                      const SizedBox(height: 16), // Spacing between widgets
                      // Dropdown (100% width)
                      _buildModernDropdown<String>(
                        label: 'შესვლის დრო შეთანხმებით',
                        value: _startNegotiated,
                        items: _startNegotiatedOptions.keys.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child:
                            Text(value, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _startNegotiated = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildModernDatePicker(
                    label: 'გამოსვლა',
                    selectedDate: _endDate,
                    onDateSelected: (date) {
                      setState(() {
                        _endDate = date;
                        _calculateDatesRange();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'სულ: $_calculatedPeriod ${_invoiceTypeSelection == 'Daily' ? 'ღამე' : 'თვე'}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                          ),
                        ),
                        if (_invoiceTypeSelection == 'Daily')
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'რიცხვები: ${_calculateDateNumbers.isEmpty ? '...' : _calculateDateNumbers}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Price section
                  _buildSectionHeader('ფასი და გადახდა:'),
                  const SizedBox(height: 12),
                  _buildModernTextField(
                    controller: _priceController,
                    label: _invoiceTypeSelection == 'Daily'
                        ? 'დღიური ფასი'
                        : 'ყოველთვიური ფასი',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                  if (_showClientFields) ...[
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: _prePayedController,
                      label: 'ჯავშანი',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildPriceInfoCard(
                    label: 'ჯამური ღირებულება',
                    value:
                    '${_formatDouble(_priceFull)} $_sellingCurrency',
                  ),
                  const SizedBox(height: 8),
                  if (_showClientFields)
                    _buildPriceInfoCard(
                      label: 'დარჩ. გადასახდელი',
                      value:
                      '${_formatDouble(_priceLeft)} $_sellingCurrency',
                    ),
                  const SizedBox(height: 24),

// In the build method, replace the existing guide person dropdown section with:
                  _buildSectionHeader('დახვდება:'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeToggle(
                          label: 'მაკო',
                          isActive: _guidePerson == 'მაკო ნაკაიძე',
                          onTap: () {
                            setState(() {
                              _guidePerson = 'მაკო ნაკაიძე';
                              _guidePhoneNum = '+995 599 238 685';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeToggle(
                          label: 'მზია',
                          isActive: _guidePerson == 'მზია გოგიტიძე',
                          onTap: () {
                            setState(() {
                              _guidePerson = 'მზია გოგიტიძე';
                              _guidePhoneNum = '+995 555 620 358';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeToggle(
                          label: 'სალო',
                          isActive: _guidePerson == 'სალო ხელაძე',
                          onTap: () {
                            setState(() {
                              _guidePerson = 'სალო ხელაძე';
                              _guidePhoneNum = '+995 555 356 069';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeToggle(
                          label: 'სხვა',
                          isActive: _guidePerson == 'სხვა',
                          onTap: () {
                            setState(() {
                              _guidePerson = 'სხვა';
                              _guidePhoneNum = '';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_guidePerson == 'სხვა') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernTextField(
                            controller: _customGuideNameController,
                            label: 'სახელი ვინ დახვდება',
                            keyboardType: TextInputType.text,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModernTextField(
                            controller: _customGuidePhoneController,
                            label: 'ტელეფონის ნომერი ვინ დახვდება',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Guest information
                  _buildSectionHeader('სტუმრის ინფორმაცია:'),
                  if (_showClientFields) ...[
                    const SizedBox(height: 12),
                    _buildAnimatedTextFieldRow(
                      geController: _geNameTakeController,
                      ruController: _ruNameTakeController,
                      geLabel: 'სახელი (ქართულად)',
                      ruLabel: '(რუს./ინგ.)',
                      geFocusNode: _geNameTakeFocusNode,
                      ruFocusNode: _ruNameTakeFocusNode,
                      isRuDominant: _isRuNameTakeDominant,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      controller: _takePhoneNumController,
                      label: 'ტელეფონის ნომერი',
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernTextField(
                          controller: _adultsController,
                          label: 'უფროსები',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernTextField(
                          controller: _childrenController,
                          label: 'პატარები',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildModernDropdown<String>(
                    label: 'ცხოველები',
                    value: _pets,
                    items: _petsOptions.keys.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _pets = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Owner section (conditionally shown)
                  if (_invoiceRecipient == 'მეპატრონე') ...[
                    _buildSectionHeader('მეპატრონის დამატება:'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRadioOption(
                            label: 'არა',
                            value: 'არა',
                            groupValue: _addOwnerManually,
                            onChanged: (value) {
                              setState(() {
                                _addOwnerManually = value!;
                                _manualOwnerNameController.clear();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRadioOption(
                            label: 'კი',
                            value: 'კი',
                            groupValue: _addOwnerManually,
                            onChanged: (value) {
                              setState(() {
                                _addOwnerManually = value!;
                                if (_addOwnerManually == 'კი' &&
                                    _selectedOwner != null) {
                                  _manualOwnerNameController.text =
                                      _selectedOwner!.name;
                                  _manualOwnerNameRuController.text =
                                      _selectedOwner!.nameRu;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_addOwnerManually == 'კი') ...[
                      const SizedBox(height: 16),
                      _buildAnimatedTextFieldRow(
                        geController: _manualOwnerNameController,
                        ruController: _manualOwnerNameRuController,
                        geLabel: 'სახელი (ქართულად)',
                        ruLabel: '(რუს./ინგ.)',
                        geFocusNode: _geOwnerNameFocusNode,
                        ruFocusNode: _ruOwnerNameFocusNode,
                        isRuDominant: _isRuOwnerNameDominant,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],

                  // Copy buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: 'ინვოისის\nდაკოპირება\n(GE)',
                          onPressed: () async {
                            final String georgianInvoice =
                            _generateInvoiceText(_georgianInvoiceTemplate);
                            Clipboard.setData(
                                ClipboardData(text: georgianInvoice));

                            // Show animated popup
                            OverlayEntry? overlayEntry;
                            overlayEntry = OverlayEntry(
                              builder: (context) => Stack(
                                children: [
                                  // Dimmed background
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ),
                                  // Popup content
                                  Positioned(
                                    top: MediaQuery.of(context).size.height *
                                        0.4,
                                    left:
                                    MediaQuery.of(context).size.width * 0.2,
                                    right:
                                    MediaQuery.of(context).size.width * 0.2,
                                    child: AnimatedOpacity(
                                      opacity: 1,
                                      duration:
                                      const Duration(milliseconds: 300),
                                      child: CopySuccessPopup(
                                        message: 'დაკოპირებულია (GE)',
                                        backgroundColor: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            Overlay.of(context).insert(overlayEntry);

                            // Remove the overlay after 2 seconds
                            Future.delayed(const Duration(seconds: 2), () {
                              overlayEntry?.remove();
                            });

                            // --- History Saving Block (GEORGIAN) ---
                            final Map<String, dynamic> placeholders = {
                              'isGeorgian':
                              true, // Add this to distinguish language
                              'Invoice Type': _invoiceTypeSelection,
                              'Apartment Address (GE)':
                              _geAddressController.text,
                              'Apartment Address (RU)':
                              _ruAddressController.text,
                              'District': _districtController.text,
                              'Microdistrict': _microDistrictController.text,
                              'districtRu': _districtRuController.text,
                              'microDistrictRu':
                              _microDistrictRuController.text,
                              'Sea View': _seaView,
                              'Sea Line': _seaLine,
                              'Apartment Room (GE)': _geAppRoom,
                              'Apartment Bedroom (GE)': _geAppBedroom,
                              'Balcony': _balcony,
                              'Terrace': _terrace,
                              'Start Date': _startDate?.toIso8601String(),
                              'End Date': _endDate?.toIso8601String(),
                              'Start Negotiated': _startNegotiated,
                              'Calculated Period': _calculatedPeriod.toString(),
                              'Price': _priceController.text,
                              'Pre-payed': _prePayedController.text,
                              'Price Full': _priceFull.toStringAsFixed(2),
                              'Price Left': _priceLeft.toStringAsFixed(2),
                              'Selling Currency': _sellingCurrency,
                              'Guide Person (GE)': _guidePerson,
                              'Guide Phone Num': _guidePhoneNumFormatted,
                              'Guest Name (GE)': _geNameTakeController.text,
                              'Guest Name (RU)': _ruNameTakeController.text,
                              'Guest Phone Num':
                              _takePhoneNumController.text,
                              'Adults': _adultsController.text,
                              'Children': _childrenController.text,
                              'Pets': _pets,
                              'Selected Owner': _selectedOwner?.name,
                              'Selected Apartment ID': _selectedApartment?.id,
                              'Manual Owner Input Enabled':
                              _addOwnerManually,
                              'Manual Owner Name':
                              _manualOwnerNameController.text,
                              'Manual Owner Name (RU)': _manualOwnerNameRuController.text,
                            };

                            final historyItem = DocumentHistoryItem(
                              type: 'Invoice',
                              generatedText: georgianInvoice,
                              timestamp: DateTime.now(),
                              placeholders: placeholders,
                            );
                            await DocumentHistoryManager.addHistoryItem(
                                historyItem);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          label: 'Скопировать\nинвойс\n(RU)',
                          onPressed: () async {
                            final String russianInvoice =
                            _generateInvoiceText(_russianInvoiceTemplate);
                            Clipboard.setData(
                                ClipboardData(text: russianInvoice));

                            // Show animated popup
                            OverlayEntry? overlayEntry;
                            overlayEntry = OverlayEntry(
                              builder: (context) => Stack(
                                children: [
                                  // Dimmed background
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ),
                                  // Popup content
                                  Positioned(
                                    top: MediaQuery.of(context).size.height *
                                        0.4,
                                    left:
                                    MediaQuery.of(context).size.width * 0.2,
                                    right:
                                    MediaQuery.of(context).size.width * 0.2,
                                    child: AnimatedOpacity(
                                      opacity: 1,
                                      duration:
                                      const Duration(milliseconds: 300),
                                      child: CopySuccessPopup(
                                        message: 'Скопировано (RU)',
                                        backgroundColor: primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            Overlay.of(context).insert(overlayEntry);

                            // Remove the overlay after 2 seconds
                            Future.delayed(const Duration(seconds: 2), () {
                              overlayEntry?.remove();
                            });

                            // --- History Saving Block (RUSSIAN) ---
                            final Map<String, dynamic> placeholders = {
                              'isGeorgian':
                              false, // Add this to distinguish language
                              'Invoice Type': _invoiceTypeSelection,
                              'Apartment Address (GE)':
                              _geAddressController.text,
                              'Apartment Address (RU)':
                              _ruAddressController.text,
                              'District': _districtController.text,
                              'Microdistrict': _microDistrictController.text,
                              'districtRu': _districtRuController.text,
                              'microDistrictRu':
                              _microDistrictRuController.text,
                              'Sea View': _seaView,
                              'Sea Line': _seaLine,
                              'Apartment Room (GE)': _geAppRoom,
                              'Apartment Bedroom (GE)': _geAppBedroom,
                              'Balcony': _balcony,
                              'Terrace': _terrace,
                              'Start Date': _startDate?.toIso8601String(),
                              'End Date': _endDate?.toIso8601String(),
                              'Start Negotiated': _startNegotiated,
                              'Calculated Period': _calculatedPeriod.toString(),
                              'Price': _priceController.text,
                              'Pre-payed': _prePayedController.text,
                              'Price Full': _priceFull.toStringAsFixed(2),
                              'Price Left': _priceLeft.toStringAsFixed(2),
                              'Selling Currency': _sellingCurrency,
                              'Guide Person (GE)': _guidePerson,
                              'Guide Phone Num': _guidePhoneNumFormatted,
                              'Guest Name (GE)': _geNameTakeController.text,
                              'Guest Name (RU)': _ruNameTakeController.text,
                              'Guest Phone Num':
                              _takePhoneNumController.text,
                              'Adults': _adultsController.text,
                              'Children': _childrenController.text,
                              'Pets': _pets,
                              'Selected Owner': _selectedOwner?.name,
                              'Selected Apartment ID': _selectedApartment?.id,
                              'Manual Owner Input Enabled':
                              _addOwnerManually,
                              'Manual Owner Name':
                              _manualOwnerNameController.text,
                              'Manual Owner Name (RU)': _manualOwnerNameRuController.text,
                            };

                            final historyItem = DocumentHistoryItem(
                              type: 'Invoice',
                              generatedText: russianInvoice,
                              timestamp: DateTime.now(),
                              placeholders: placeholders,
                            );
                            await DocumentHistoryManager.addHistoryItem(
                                historyItem);
                            // --- END HISTORY BLOCK ---
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// --- Reusable Widget Builders (from the new code) ---

  Widget _buildAnimatedTextFieldRow({
    required TextEditingController geController,
    required TextEditingController ruController,
    required String geLabel,
    required String ruLabel,
    required FocusNode geFocusNode,
    required FocusNode ruFocusNode,
    required bool isRuDominant,
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
            // 'lerp' stands for Linear Interpolation. It smoothly transitions
            // between two values.
            final geWidth = lerpDouble(largeWidth, smallWidth, value)!;
            final ruWidth = lerpDouble(smallWidth, largeWidth, value)!;

            return Row(
              children: [
                SizedBox(
                  width: geWidth,
                  child: _buildModernTextField( // Using your existing text field builder!
                    controller: geController,
                    label: geLabel,
                    focusNode: geFocusNode,
                  ),
                ),
                const SizedBox(width: spacing),
                SizedBox(
                  width: ruWidth,
                  child: _buildModernTextField( // Using your existing text field builder!
                    controller: ruController,
                    label: ruLabel,
                    focusNode: ruFocusNode,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: headerStyle,
    );
  }

  Widget _buildRecipientButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? primaryColor : backgroundColor,
            border: Border.all(
              color: isActive ? primaryColor : primaryColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center, // Add this line
              style: TextStyle(
                color: isActive ? Colors.white : primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: inputLabelStyle,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF004aad), width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF004aad)),
      dropdownColor: backgroundColor,
      borderRadius: BorderRadius.circular(8),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: inputLabelStyle,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF004aad), width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      style: const TextStyle(fontSize: 14),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
          // 1. ADD THIS LINE to set Georgian as the calendar's language
          locale: const Locale('ka', 'GE'),
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
          builder: (context, child) {
            return Transform.scale(
              scale: 1.2, // 👈 Adjust this value to make it bigger or smaller
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: primaryColor,
                    onPrimary: Colors.white,
                    onSurface: Colors.black87,
                  ),
                  dialogBackgroundColor: Colors.white,
                ),
                child: child!,
              ),
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
          labelStyle: inputLabelStyle,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF004aad), width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.grey.shade50,
          suffixIcon:
          const Icon(Icons.calendar_today, color: Color(0xFF004aad), size: 20),
        ),
        child: Text(
          selectedDate != null
              ? _formatDate(selectedDate, _georgianMonths)
              : 'აირჩიეთ თარიღი',
          style: TextStyle(
            fontSize: 14,
            color: selectedDate == null ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
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
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfoCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF004aad),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: groupValue == value ? primaryColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: groupValue == value ? primaryColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: groupValue == value ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center, // Add this line
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}