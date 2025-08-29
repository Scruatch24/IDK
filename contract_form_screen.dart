import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:realtor_app/home_screen.dart';
import 'package:realtor_app/history_screen.dart';
import 'package:realtor_app/history_manager.dart';
import 'package:realtor_app/data/app_data.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:realtor_app/utils/pdf_download_helper.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:ui';
import '../utils/custom_snackbar.dart'; // <-- IMPORT THE NEW SNACKBAR HELPER


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realtor Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}

class ContractFormScreen extends StatefulWidget {
  final Map<String, dynamic>? prefilledData;

  final bool showVerificationPopup; // Add this parameter
  const ContractFormScreen({
    super.key,
    this.prefilledData,
    this.showVerificationPopup = false, // Provide a default value
  });

  @override
  State<ContractFormScreen> createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends State<ContractFormScreen> {
  // State variables for placeholders
  String _paymentMethod = 'გადარიცხვა';
  String _contractType = 'Monthly';
  String _geCity = 'ბათუმი';
  String _sellingCurrency = 'აშშ დოლარის';
  String _price = '';
  DateTime? _startDate;
  String _period = '';
  String _periodDays = ''; // ADD THIS FOR EXTRA DAYS
  String _summerMonthOption = 'არ იხდის';
  // MODIFIED: This is now controlled by the checkboxes
  String _numSummerMonths = '1';
  DateTime? _summerStartDate;
  DateTime? _summerEndDate;
  String _priceSummer = '';
  // REMOVED: No longer needed
  // String _pricePeriod = '';
  String _manualPrepaidAmount = ''; // ADDED: For manual input
  String _gePricePeriodDet = 'და ბოლო';
  String _ruPricePeriodDet = 'и последний';
  String _gePets = 'ცხოველებისა და ფრინველების გარეშე';
  String _petsPayed = '0';
  String _cleaningPrice = '';
  String _prePayedCurrency = 'აშშ დოლარის';
  String _prePayed = '0';
  String _sqMeter = '';
  String _geAddress = '';
  String _ruAddress = '';
  String _geNameGive = '';
  String _ruNameGive = '';
  String _pnGive = '';
  DateTime? _bdGive;
  String _geNameTake = '';
  String _ruNameTake = '';
  String _idTakeType = 'პასპორტი';
  String _idTakeNum = '';
  DateTime? _bdTake;
  String _geCityTake = '';
  String _ruCityTake = '';
  String _geCountryTake = '';
  String _ruCountryTake = '';
  String _gePersons = 'მარტო';
  String _bank = '';
  String _geBankName = 'საქართველოს ბანკი';
  String _trPersonOption = 'არა';
  String _trPersonGe = '';
  // ADD THIS to control the conditional summer price field
  bool _showConditionalSummerPriceField = false;

  // ADDED: State for summer month checkboxes
  final Map<String, bool> _selectedSummerMonths = {
    'ივნისი': true,
    'ივლისი': false,
    'აგვისტო': false,
  };


  // ADDED: State for additional utility checkboxes
  final Map<String, bool> _additionalUtilities = {
    'ფასიანი ტელევიზია': true, // Checked by default
    'დომოფონი': false,
    'დაცვა': false,
  };

  // Controllers for text fields
  final _priceController = TextEditingController();
  final _periodController = TextEditingController();
  final _periodDaysController = TextEditingController();
  // REMOVED: Controller no longer needed for UI
  // final _numSummerMonthsController = TextEditingController();
  final _priceSummerController = TextEditingController();
  // FIX: ADD A DEDICATED CONTROLLER FOR THE SECOND FIELD
  final _priceSummerConditionalController = TextEditingController();
  // REMOVED: Replaced with manual amount controller
  // final _pricePeriodController = TextEditingController();
  final _manualPrepaidAmountController = TextEditingController(); // ADDED
  final _gePricePeriodDetController = TextEditingController(text: 'და ბოლო');
  final _ruPricePeriodDetController = TextEditingController(
      text: 'и последний');
  final _petsPayedController = TextEditingController();
  final _cleaningPriceController = TextEditingController();
  final _prePayedController = TextEditingController();
  final _sqMeterController = TextEditingController();
  final _geAddressController = TextEditingController();
  final _ruAddressController = TextEditingController();
  final _geNameGiveController = TextEditingController();
  final _ruNameGiveController = TextEditingController();
  final _pnGiveController = TextEditingController();
  final _geNameTakeController = TextEditingController();
  final _ruNameTakeController = TextEditingController();
  final _idTakeNumController = TextEditingController();
  final _geCityTakeController = TextEditingController();
  final _ruCityTakeController = TextEditingController();
  final _geCountryTakeController = TextEditingController();
  final _ruCountryTakeController = TextEditingController();
  final _bankController = TextEditingController();


  String _formatPrefilledNumber(dynamic numberValue) {
    if (numberValue == null) {
      return '';
    }

    // Try to parse the value into a number (double).
    final double? number = double.tryParse(numberValue.toString());

    // If parsing fails (e.g., it's not a number), return the original string.
    if (number == null) {
      return numberValue.toString();
    }

    // This is the key part:
    // The modulo operator (%) returns the remainder of a division.
    // For a whole number like 50.0, (50.0 % 1) is 0.
    // For a decimal number like 50.1, (50.1 % 1) is 0.1.
    if (number % 1 == 0) {
      // If there's no remainder, it's a whole number.
      return number.toInt().toString(); // Display as an integer (e.g., "50")
    } else {
      // Otherwise, it has a decimal part.
      return number.toString(); // Display with decimals (e.g., "50.1")
    }
  }

  // --- State Variables for Animated Text Fields ---

// For Owner (Give) Name
  final FocusNode _geNameGiveFocusNode = FocusNode();
  final FocusNode _ruNameGiveFocusNode = FocusNode();
  bool _isRuNameGiveDominant = false;

// For Guest (Take) Name
  final FocusNode _geNameTakeFocusNode = FocusNode();
  final FocusNode _ruNameTakeFocusNode = FocusNode();
  bool _isRuNameTakeDominant = false;

// For Guest (Take) City
  final FocusNode _geCityTakeFocusNode = FocusNode();
  final FocusNode _ruCityTakeFocusNode = FocusNode();
  bool _isRuCityTakeDominant = false;

// For Guest (Take) Country
  final FocusNode _geCountryTakeFocusNode = FocusNode();
  final FocusNode _ruCountryTakeFocusNode = FocusNode();
  bool _isRuCountryTakeDominant = false;

// Replace the existing _showVerificationPopup method with this one.

// Replace the existing _showVerificationPopup method with this one.

  void _updateAddressPrefix() {
    const gePrefixes = ['ქ. ბათუმი, ', 'ქ. თბილისი, '];
    const ruPrefixes = ['г. Батуми, ', 'г. Тбилиси, '];

    String cleanGeAddress = _geAddressController.text;
    String cleanRuAddress = _ruAddressController.text;

    for (var prefix in gePrefixes) {
      if (cleanGeAddress.startsWith(prefix)) {
        cleanGeAddress = cleanGeAddress.substring(prefix.length);
      }
    }
    for (var prefix in ruPrefixes) {
      if (cleanRuAddress.startsWith(prefix)) {
        cleanRuAddress = cleanRuAddress.substring(prefix.length);
      }
    }

    String gePrefixToAdd = _geCity == 'ბათუმი' ? 'ქ. ბათუმი, ' : 'ქ. თბილისი, ';
    String ruPrefixToAdd = _geCity == 'ბათუმი' ? 'г. Батуми, ' : 'г. Тбилиси, ';

    _geAddressController.text = gePrefixToAdd + cleanGeAddress;
    _ruAddressController.text = ruPrefixToAdd + cleanRuAddress;
  }

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

// lib/contract_form_screen.dart

// ... inside _ContractFormScreenState class

  @override
  void initState() {
    super.initState();

    // --- Process Prefilled Data FIRST ---
    if (widget.prefilledData != null) {
      final data = widget.prefilledData!;

      // Set simple string values and controller texts
      _contractType = data['contractType'] ?? 'Monthly';
      _geCity = data['city'] ?? 'ბათუმი';
      _sellingCurrency = data['currency'] ?? 'აშშ დოლარის';
      _priceController.text = _formatPrefilledNumber(data['price']);
      _periodController.text = data['period']?.toString() ?? '';
      _periodDaysController.text = data['periodDays']?.toString() ?? '';
      _prePayedController.text = _formatPrefilledNumber(data['prepayment']) ?? '0';
      _sqMeterController.text = _formatPrefilledNumber(data['sqMeters']);
      _geAddressController.text = data['geAddress'] ?? '';
      _ruAddressController.text = data['ruAddress'] ?? '';
      _geNameGiveController.text = data['ownerNameGe'] ?? '';
      _ruNameGiveController.text = data['ownerNameRu'] ?? '';
      _pnGiveController.text = data['ownerIdNumber'] ?? '';
      _bankController.text = data['ownerBankAccount'] ?? '';
      _geNameTakeController.text = data['guestNameGe'] ?? '';
      _ruNameTakeController.text = data['guestNameRu'] ?? '';

      // --- NEWLY ADDED PRE-FILLS FOR FULL FUNCTIONALITY ---
      _summerMonthOption = data['summerMonthOption'] ?? 'არ იხდის';
      _priceSummerController.text = _formatPrefilledNumber(data['priceSummer']);
      _manualPrepaidAmountController.text = _formatPrefilledNumber(data['manualPrepaidAmount']);
      _gePricePeriodDetController.text = data['gePricePeriodDet'] ?? 'და ბოლო';
      _ruPricePeriodDetController.text = data['ruPricePeriodDet'] ?? 'и последний';
      _prePayedCurrency = data['prePayedCurrency'] ?? 'აშშ დოლარის';
      _gePets = data['gePets'] ?? 'ცხოველებისა და ფრინველების გარეშე';
      _petsPayedController.text = _formatPrefilledNumber(data['petsPayed']);
      _cleaningPriceController.text = _formatPrefilledNumber(data['cleaningPrice']);
      _idTakeType = data['idTakeType'] ?? 'პასპორტი';
      _idTakeNumController.text = data['idTakeNum'] ?? '';
      _geCityTakeController.text = data['guestCityGe'] ?? '';
      _ruCityTakeController.text = data['guestCityRu'] ?? '';
      _geCountryTakeController.text = data['guestCountryGe'] ?? '';
      _ruCountryTakeController.text = data['guestCountryRu'] ?? '';
      _gePersons = data['gePersons'] ?? 'მარტო';
      _paymentMethod = data['paymentMethod'] ?? 'გადარიცხვა';
      _trPersonOption = data['trPersonOption'] ?? 'არა';
      _trPersonGe = data['trPersonGe'] ?? '';

      // Set bank name (with a fallback)
      final String? ownerBankName = data['ownerBankName'];
      _geBankName = (ownerBankName != null && ownerBankName.isNotEmpty)
          ? ownerBankName
          : 'საქართველოს ბანკი';

      // Set dates from ISO 8601 strings
      _startDate = data['startDate'] != null ? DateTime.tryParse(data['startDate']) : null;
      _summerStartDate = data['summerStartDate'] != null ? DateTime.tryParse(data['summerStartDate']) : null;
      _summerEndDate = data['summerEndDate'] != null ? DateTime.tryParse(data['summerEndDate']) : null;
      _bdTake = data['guestBirthDate'] != null ? DateTime.tryParse(data['guestBirthDate']) : null;

      // Handle owner's birth date (which is saved in a different format)
      final ownerBirthDateString = data['ownerBirthDate'] as String?;
      if (ownerBirthDateString != null && ownerBirthDateString.isNotEmpty) {
        try {
          _bdGive = DateFormat('dd/MMM/yyyy', 'ka_GE').parse(ownerBirthDateString);
        } catch (e) {
          debugPrint("Error parsing owner birth date '$ownerBirthDateString': $e");
          _bdGive = null;
        }
      }

      // Restore checkbox maps
      if (data['selectedSummerMonths'] is Map) {
        final Map<String, dynamic> summerMonthsFromDb = data['selectedSummerMonths'];
        _selectedSummerMonths.forEach((key, value) {
          _selectedSummerMonths[key] = summerMonthsFromDb[key] ?? false;
        });
      }
      if (data['additionalUtilities'] is Map) {
        final Map<String, dynamic> utilitiesFromDb = data['additionalUtilities'];
        _additionalUtilities.forEach((key, value) {
          _additionalUtilities[key] = utilitiesFromDb[key] ?? false;
        });
      }

      // Update state variables from controllers to ensure UI consistency
      _price = _priceController.text;
      _period = _periodController.text;
      _periodDays = _periodDaysController.text;
      _prePayed = _prePayedController.text;
      _sqMeter = _sqMeterController.text;
      _geAddress = _geAddressController.text;
      _ruAddress = _ruAddressController.text;
      _geNameGive = _geNameGiveController.text;
      _ruNameGive = _ruNameGiveController.text;
      _pnGive = _pnGiveController.text;
      _bank = _bankController.text;
      _geNameTake = _geNameTakeController.text;
      _ruNameTake = _ruNameTakeController.text;
    }

    // --- Set up Listeners ---
    _geAddressController.addListener(() {
      final text = _geAddressController.text;
      final prefix = _geCity == 'ბათუმი' ? 'ქ. ბათუმი, ' : 'ქ. თბილისი, ';
      if (!text.startsWith(prefix)) {
        _geAddressController.text = prefix;
        _geAddressController.selection = TextSelection.fromPosition(
          TextPosition(offset: _geAddressController.text.length),
        );
      }
    });

    _ruAddressController.addListener(() {
      final text = _ruAddressController.text;
      final prefix = _geCity == 'ბათუმი' ? 'г. Батуми, ' : 'г. Тбилиси, ';
      if (!text.startsWith(prefix)) {
        _ruAddressController.text = prefix;
        _ruAddressController.selection = TextSelection.fromPosition(
          TextPosition(offset: _ruAddressController.text.length),
        );
      }
    });

    _priceController.addListener(_updateCalculations);
    _periodController.addListener(_updateCalculations);
    _periodDaysController.addListener(_updateCalculations);

    // FIX: Implement two-way synchronization for the summer price fields
    _priceSummerController.addListener(() {
      // When the main field changes, update the conditional field if the text is different
      if (_priceSummerController.text != _priceSummerConditionalController.text) {
        _priceSummerConditionalController.text = _priceSummerController.text;
      }
      _updateCalculations(); // Also trigger a general recalculation
    });
    _priceSummerConditionalController.addListener(() {
      // When the conditional field changes, update the main field if the text is different
      if (_priceSummerConditionalController.text != _priceSummerController.text) {
        _priceSummerController.text = _priceSummerConditionalController.text;
      }
      _updateCalculations(); // Also trigger a general recalculation
    });

    _gePricePeriodDetController.addListener(() {
      setState(() {
        _gePricePeriodDet = _gePricePeriodDetController.text;
      });
    });
    _ruPricePeriodDetController.addListener(() {
      setState(() {
        _ruPricePeriodDet = _ruPricePeriodDetController.text;
      });
    });
    // ADDED: Listener for the new manual prepaid amount field
    _manualPrepaidAmountController.addListener(() {
      setState(() {
        _manualPrepaidAmount = _manualPrepaidAmountController.text;
      });
    });

    _cleaningPriceController.addListener(() {
      setState(() {
        _cleaningPrice = _cleaningPriceController.text;
      });
    });


    // --- Set Default Values ONLY IF no data was prefilled ---
    if (widget.prefilledData == null) {
      _geAddressController.text = 'ქ. ბათუმი, ';
      _ruAddressController.text = 'г. Батуми, ';
    }

    if (widget.showVerificationPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showVerificationPopup(context, 'გადაამოწმეთ ხელშეკრულება');
      });
    }

    void setupFocusListeners(FocusNode geNode, FocusNode ruNode, Function(bool) updateDominance) {
      geNode.addListener(() {
        if (geNode.hasFocus) setState(() => updateDominance(false));
      });
      ruNode.addListener(() {
        if (ruNode.hasFocus) setState(() => updateDominance(true));
      });
    }

    // Set up listeners for each pair
    setupFocusListeners(_geNameGiveFocusNode, _ruNameGiveFocusNode, (isRuDominant) => _isRuNameGiveDominant = isRuDominant);
    setupFocusListeners(_geNameTakeFocusNode, _ruNameTakeFocusNode, (isRuDominant) => _isRuNameTakeDominant = isRuDominant);
    setupFocusListeners(_geCityTakeFocusNode, _ruCityTakeFocusNode, (isRuDominant) => _isRuCityTakeDominant = isRuDominant);
    setupFocusListeners(_geCountryTakeFocusNode, _ruCountryTakeFocusNode, (isRuDominant) => _isRuCountryTakeDominant = isRuDominant);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _periodController.dispose();
    _periodDaysController.dispose();
    _priceSummerController.dispose();
    _priceSummerConditionalController.dispose(); // FIX: Dispose the new controller
    _manualPrepaidAmountController.dispose();
    _gePricePeriodDetController.dispose();
    _ruPricePeriodDetController.dispose();
    _petsPayedController.dispose();
    _cleaningPriceController.dispose();
    _prePayedController.dispose();
    _sqMeterController.dispose();
    _geAddressController.dispose();
    _ruAddressController.dispose();
    _geNameGiveController.dispose();
    _ruNameGiveController.dispose();
    _pnGiveController.dispose();
    _geNameTakeController.dispose();
    _ruNameTakeController.dispose();
    _idTakeNumController.dispose();
    _geCityTakeController.dispose();
    _ruCityTakeController.dispose();
    _geCountryTakeController.dispose();
    _ruCountryTakeController.dispose();
    _bankController.dispose();

    _geNameGiveFocusNode.dispose();
    _ruNameGiveFocusNode.dispose();
    _geNameTakeFocusNode.dispose();
    _ruNameTakeFocusNode.dispose();
    _geCityTakeFocusNode.dispose();
    _ruCityTakeFocusNode.dispose();
    _geCountryTakeFocusNode.dispose();
    _ruCountryTakeFocusNode.dispose();

    super.dispose();
  }

  final Map<String, String> _trPersonOptionsMap = {
    'სოფიო ქათამაძეს': 'სოფიო ქათამაძე',
    'მაკო ნაკაიძეს': 'მაკო ნაკაიძე',
  };

  // ADD THIS ENTIRE METHOD
  void _updateCalculations() {
    setState(() {
      // Update state from controllers
      _price = _priceController.text;
      _period = _periodController.text;
      _periodDays = _periodDaysController.text;
      // The summer price state is now updated via the synchronized controllers' listeners
      _priceSummer = _priceSummerController.text;

      // Logic to determine if the conditional summer price field should be visible
      bool shouldShowConditionalField = false;
      final months = int.tryParse(_period) ?? 0;
      final days = int.tryParse(_periodDays) ?? 0;

      // Check if any extra days fall into a summer month
      bool extraDaysInSummer = false;
      if (days > 0 && _startDate != null) {
        final startOfExtraDays = DateTime(_startDate!.year, _startDate!.month + months, _startDate!.day);
        for (int i = 0; i < days; i++) {
          final currentDay = startOfExtraDays.add(Duration(days: i));
          // Summer is June (6), July (7), August (8)
          if (currentDay.month >= 6 && currentDay.month <= 8) {
            extraDaysInSummer = true;
            break;
          }
        }
      }

      // The conditional field should show if extra days fall in summer
      // for both Monthly and Yearly contracts.
      if ((_contractType == 'Monthly' || _contractType == 'Yearly') && extraDaysInSummer) {
        shouldShowConditionalField = true;
      }

      _showConditionalSummerPriceField = shouldShowConditionalField;
    });
  }

  String get _ruSellingCurrency {
    if (_sellingCurrency == 'აშშ დოლარის') return 'Долларов США';
    if (_sellingCurrency == 'ქართული ლარის') return 'Грузинских Лари';
    return '';
  }

  String get _ruPrePayedCurrency {
    if (_prePayedCurrency == 'აშშ დოლარის') return 'Долларов США';
    if (_prePayedCurrency == 'ქართული ლარის') return 'Грузинских Лари';
    return '';
  }

  // Derived properties using getters
  String get _ruCity {
    if (_geCity == 'ბათუმი') return 'Батуми';
    if (_geCity == 'თბილისი') return 'Тбилиси';
    return 'Батуми';
  }

  String get _ruPets {
    switch (_gePets) {
      case 'ცხოველებისა და ფრინველების გარეშე':
        return 'без домашних питомцев';
      case 'ძაღლით':
        return 'с собакой';
      case 'კატით':
        return 'с кошкой';
      case 'ძაღლით და კატით':
        return 'с собакой и кошкой';
      case '2 ძაღლით':
        return '2-мя собаками';
      case '2 კატით':
        return '2-ма кошками';
      default:
        return 'без домашних питомцев';
    }
  }

  String get _ruPersons {
    switch (_gePersons) {
      case 'მარტო':
        return 'один';
      case 'ერთ პერსონასთან ერთად':
        return 'с одной персоной (кроме себя)';
      case 'ორ პერსონასთან ერთად':
        return 'с двумя персонами (кроме себя)';
      case 'სამ პერსონასთან ერთად':
        return 'с тремя персонами (кроме себя)';
      case 'ოთხ პერსონასთან ერთად':
        return 'с четырьмя персонами (кроме себя)';
      case 'ხუთ პერსონასთან ერთად':
        return 'с пятью персонами (кроме себя)';
      case 'ექვს პერსონასთან ერთად':
        return 'с шестью персонами (кроме себя)';
      case 'შვიდ პერსონასთან ერთად':
        return 'с семью персонами (кроме себя)';
      case 'რვა პერსონასთან ერთად':
        return 'с восьмью персонами (кроме себя)';
      default:
        return 'один';
    }
  }

  String get _ruBankName {
    switch (_geBankName) {
      case 'საქართველოს ბანკი':
        return 'Банк Сакартвело';
      case 'თი-ბი-სი ბანკი':
        return 'Банк Ти-Би-Си';
      case 'ლიბერთი ბანკი':
        return 'Банк Либерти';
      case 'ბაზის ბანკი':
        return 'Базис Банк';
      case 'ტერა ბანკი':
        return 'Тера Банк';
      default:
        return 'Банк Сакартвело';
    }
  }

  String get _trPersonRu {
    if (_trPersonOption != 'კი') return '';
    if (_trPersonGe == 'სოფიო ქათამაძეს') return 'Софио Катамадзе';
    if (_trPersonGe == 'მაკო ნაკაიძეს') return 'Мако Накаидзе';
    return '';
  }

  String get _trPPn {
    if (_trPersonOption != 'კი') return '';
    if (_trPersonGe == 'სოფიო ქათამაძეს') return '61003006137';
    if (_trPersonGe == 'მაკო ნაკაიძეს') return '33001011248';
    return '';
  }

  String get _endDate {
    if (_startDate == null) return '';

    // Handle Daily contracts separately
    if (_contractType == 'Daily') {
      final durationDays = int.tryParse(_period) ?? 0;
      if (durationDays <= 0) return '';
      final endDateValue = _startDate!.add(Duration(days: durationDays));
      return _formatDateGeorgian(endDateValue);
    }

    // Handle Monthly and Yearly contracts
    final months = int.tryParse(_period) ?? 0;
    final days = int.tryParse(_periodDays) ?? 0;
    if (months <= 0 && days <= 0) return '';

    try {
      // Add the full months first
      DateTime tempDate = DateTime(
        _startDate!.year,
        _startDate!.month + months,
        _startDate!.day,
      );
      // Then add the remaining days
      final endDateValue = tempDate.add(Duration(days: days));
      return _formatDateGeorgian(endDateValue);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String get _effectivePriceSummer {
    if (_priceSummer.isNotEmpty) return _priceSummer;
    final priceValue = double.tryParse(_price) ?? 0.0;
    return priceValue.toStringAsFixed(0); // Changed from (priceValue + 100)
  }

  String get _priceFull {
    try {
      final price = double.tryParse(_price) ?? 0.0;

      // Handle Daily contracts (no changes to its logic)
      if (_contractType == 'Daily') {
        final durationDays = double.tryParse(_period) ?? 0.0;
        return (durationDays * price).toStringAsFixed(2);
      }

      // --- Logic for Monthly & Yearly ---
      final months = int.tryParse(_period) ?? 0;
      final days = int.tryParse(_periodDays) ?? 0;
      double totalPrice = 0;

      // 1. Calculate price for FULL MONTHS
      if (_contractType == 'Yearly') {
        final numSummerMonths = _selectedSummerMonths.values.where((v) => v).length;
        final priceSummer = double.tryParse(_effectivePriceSummer) ?? 0.0;
        totalPrice += ((months - numSummerMonths) * price) + (numSummerMonths * priceSummer);
      } else { // Monthly
        totalPrice += months * price;
      }

      // 2. Calculate price for EXTRA DAYS
      if (days > 0 && _startDate != null) {
        final startOfExtraDays = DateTime(_startDate!.year, _startDate!.month + months, _startDate!.day);
        int summerDaysCount = 0;

        for (int i = 0; i < days; i++) {
          final currentDay = startOfExtraDays.add(Duration(days: i));
          // Check for Summer months (June, July, August)
          if (currentDay.month >= 6 && currentDay.month <= 8) {
            summerDaysCount++;
          }
        }

        final regularDaysCount = days - summerDaysCount;
        final dailyPrice = price / 30.0;
        final dailySummerPrice = (double.tryParse(_effectivePriceSummer) ?? 0.0) / 30.0;

        totalPrice += (regularDaysCount * dailyPrice) + (summerDaysCount * dailySummerPrice);
      }

      return totalPrice.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  String _getCurrencySymbol(String currency) {
    if (currency == 'აშშ დოლარის') return '\$';
    if (currency == 'ქართული ლარის') return '₾';
    return '';
  }

  // --- Reusable Widget Builders (from Invoice Generator) ---

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0), // Increased bottom padding
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black, // Changed to black
        ),
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
            // 'lerp' stands for Linear Interpolation.
            final geWidth = lerpDouble(largeWidth, smallWidth, value)!;
            final ruWidth = lerpDouble(smallWidth, largeWidth, value)!;

            return Row(
              children: [
                SizedBox(
                  width: geWidth,
                  child: _buildModernTextField(
                    controller: geController,
                    label: geLabel,
                    focusNode: geFocusNode,
                  ),
                ),
                const SizedBox(width: spacing),
                SizedBox(
                  width: ruWidth,
                  child: _buildModernTextField(
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

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    FocusNode? focusNode,
    bool enabled = true, // USE 'enabled' INSTEAD
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      focusNode: focusNode,
      enabled: enabled, // PASS 'enabled' HERE
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF004aad),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        // This ensures the border also looks disabled
        disabledBorder: OutlineInputBorder(
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
        // The color now correctly depends on the 'enabled' state
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
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
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(1900),
          lastDate: lastDate ?? DateTime(2101),
          builder: (context, child) {
            // Added Transform.scale to make the calendar pop-up bigger
            return Transform.scale(
              scale: 1.2,
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF004aad),
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
          labelStyle: const TextStyle(
            color: Color(0xFF004aad),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.grey.shade50,
          suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF004aad),
              size: 20),
        ),
        child: Text(
          selectedDate != null
          // CORRECTED: Use 'MMM' and the 'ka_GE' locale for Georgian month names
              ? DateFormat('dd/MMM/yyyy', 'ka_GE').format(selectedDate)
              : 'აირჩიეთ თარიღი',
          style: TextStyle(
            fontSize: 14,
            color: selectedDate == null ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ADD THIS ENTIRE METHOD
  void _updateTrustedPersonBankDetails(String personKey) {
    if (personKey == 'სოფიო ქათამაძეს') {
      _geBankName = 'საქართველოს ბანკი';
      _bankController.text = 'GE29BG0000000101213289';
    } else if (personKey == 'მაკო ნაკაიძეს') {
      _geBankName = 'თი-ბი-სი ბანკი';
      _bankController.text = 'GE85TB7046745066300001';
    }
    // Make sure the underlying state variable is also updated
    _bank = _bankController.text;
  }

  Widget _buildModernDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    bool enabled = true, // ADD THIS
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      // Conditionally disable the dropdown
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF004aad),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
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
        // Change color when disabled
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
      ),
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF004aad)),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(8),
    );
  }

  Widget _buildTypeToggle({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool enabled = true, // ADD THIS PARAMETER
  }) {
    final Color activeColor = const Color(0xFF004aad);
    final Color disabledColor = Colors.grey.shade200;
    final Color inactiveColor = Colors.grey.shade50;
    final Color disabledTextColor = Colors.grey.shade500;

    return Expanded(
      child: GestureDetector(
        // Conditionally disable the tap functionality
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // Change color based on enabled/active state
            color: !enabled
                ? disabledColor
                : isActive
                ? activeColor
                : inactiveColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive && enabled ? activeColor : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                // Change text color based on enabled/active state
                color: !enabled
                    ? disabledTextColor
                    : isActive
                    ? Colors.white
                    : Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ADDED: A reusable widget for the month checkboxes
  Widget _buildStyledCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF004aad).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value ? const Color(0xFF004aad) : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF004aad),
                visualDensity: VisualDensity.compact,
              ),
              Text(title, style: const TextStyle(fontSize: 14)),
            ],
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

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF004aad),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF004aad);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Center(
          child: Text(
            'ხელ.-ის შედგენა',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(type: 'Contract'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('ხელშეკრულების ტიპი:'),
            Row(
              children: [
                _buildTypeToggle(
                  label: 'დღიური',
                  isActive: _contractType == 'Daily',
                  onTap: () => setState(() => _contractType = 'Daily'),
                ),
                const SizedBox(width: 12),
                _buildTypeToggle(
                  label: 'ყოველთვიური',
                  isActive: _contractType == 'Monthly',
                  onTap: () => setState(() => _contractType = 'Monthly'),
                ),
                const SizedBox(width: 12),
                _buildTypeToggle(
                  label: 'წლიური',
                  isActive: _contractType == 'Yearly',
                  onTap: () => setState(() => _contractType = 'Yearly'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('ქალაქი:'),
            Row(
              children: [
                _buildTypeToggle(
                  label: 'ბათუმი',
                  isActive: _geCity == 'ბათუმი',
                  onTap: () {
                    setState(() {
                      _geCity = 'ბათუმი';
                      _updateAddressPrefix();
                    });
                  },
                ),
                const SizedBox(width: 12),
                _buildTypeToggle(
                  label: 'თბილისი',
                  isActive: _geCity == 'თბილისი',
                  onTap: () {
                    setState(() {
                      _geCity = 'თბილისი';
                      _updateAddressPrefix();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('ანგარიშსწორების ვალუტა:'),
            Row(
              children: [
                _buildTypeToggle(
                  label: 'აშშ დოლარი',
                  isActive: _sellingCurrency == 'აშშ დოლარის',
                  onTap: () => setState(() => _sellingCurrency = 'აშშ დოლარის'),
                ),
                const SizedBox(width: 12),
                _buildTypeToggle(
                  label: 'ქართული ლარი',
                  isActive: _sellingCurrency == 'ქართული ლარის',
                  onTap: () => setState(() => _sellingCurrency = 'ქართული ლარის'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('ფასი და პერიოდი:'),
            _buildModernTextField(
              controller: _priceController,
              label: _contractType == 'Daily' ? 'დღიური ფასი' : 'ყოველთვიური ფასი',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            ),
            const SizedBox(height: 16),
            _buildModernDatePicker(
              label: 'შესვლის თარიღი',
              selectedDate: _startDate,
              onDateSelected: (date) {
                setState(() => _startDate = date);
                _updateCalculations();
              },
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime(DateTime.now().year + 5),
            ),
            const SizedBox(height: 16),
            if (_contractType == 'Daily')
              _buildModernTextField(
                controller: _periodController,
                label: 'რამდენი დღით?',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => setState(() => _period = value),
              )
            else // Monthly or Yearly
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernTextField(
                          controller: _periodController,
                          label: 'რამდენი თვით?',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernTextField(
                          controller: _periodDaysController,
                          label: 'რამდენი დღით?',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  if (_showConditionalSummerPriceField) ...[
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      // FIX: Use the new dedicated controller
                      controller: _priceSummerConditionalController,
                      label: 'თითო ზაფხულის თვის საფასური',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 8),
            Text(
              'ნიმუში: ხელშეკრულება ძალაში შედის ${_startDate == null ? 'დღე/თვე/წელი' : _formatDateGeorgian(_startDate!)}, და მოქმედებს $_period ${_contractType == 'Monthly' || _contractType == 'Yearly' ? 'თვით' : 'კალენდარული დღე'}, ${_endDate.isEmpty ? 'დღე/თვე/წელი' : _endDate}-მდე.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            if (_contractType == 'Yearly') ...[
              _buildSectionHeader('ზაფხულის თვეები:'),
              Row(
                children: [
                  _buildTypeToggle(
                    label: 'არ იხდის',
                    isActive: _summerMonthOption == 'არ იხდის',
                    onTap: () {
                      setState(() {
                        _summerMonthOption = 'არ იხდის';
                        _selectedSummerMonths.updateAll((key, value) => false);
                        _numSummerMonths = '0';
                        _summerStartDate = null;
                        _summerEndDate = null;
                        // Do not clear the controller here, to keep synchronization
                        // _priceSummer = '';
                        // _priceSummerController.clear();
                        _updateCalculations(); // Recalculate when toggled
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildTypeToggle(
                    label: 'იხდის',
                    isActive: _summerMonthOption == 'იხდის',
                    onTap: () => setState(() {
                      _summerMonthOption = 'იხდის';
                      if (_selectedSummerMonths.values.every((v) => !v)) {
                        _selectedSummerMonths['ივნისი'] = true;
                      }
                      _numSummerMonths = _selectedSummerMonths.values.where((v) => v).length.toString();
                      _updateCalculations(); // Recalculate when toggled
                    }),
                  ),
                ],
              ),
              if (_summerMonthOption == 'იხდის') ...[
                const SizedBox(height: 16),
                const Text("აირჩიეთ თვეები:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStyledCheckbox(
                        title: 'ივნისი',
                        value: _selectedSummerMonths['ივნისი']!,
                        onChanged: (val) {
                          setState(() {
                            final canDeselect = _selectedSummerMonths.values.where((v) => v).length > 1;
                            if (val == false && !canDeselect) return;
                            _selectedSummerMonths['ივნისი'] = val!;
                            _numSummerMonths = _selectedSummerMonths.values.where((v) => v).length.toString();
                          });
                        }),
                    const SizedBox(width: 8),
                    _buildStyledCheckbox(
                        title: 'ივლისი',
                        value: _selectedSummerMonths['ივლისი']!,
                        onChanged: (val) {
                          setState(() {
                            final canDeselect = _selectedSummerMonths.values.where((v) => v).length > 1;
                            if (val == false && !canDeselect) return;
                            _selectedSummerMonths['ივლისი'] = val!;
                            _numSummerMonths = _selectedSummerMonths.values.where((v) => v).length.toString();
                          });
                        }),
                    const SizedBox(width: 8),
                    _buildStyledCheckbox(
                        title: 'აგვისტო',
                        value: _selectedSummerMonths['აგვისტო']!,
                        onChanged: (val) {
                          setState(() {
                            final canDeselect = _selectedSummerMonths.values.where((v) => v).length > 1;
                            if (val == false && !canDeselect) return;
                            _selectedSummerMonths['აგვისტო'] = val!;
                            _numSummerMonths = _selectedSummerMonths.values.where((v) => v).length.toString();
                          });
                        }),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModernDatePicker(
                  label: 'ზაფხულის შესვლის თარიღი',
                  selectedDate: _summerStartDate,
                  onDateSelected: (date) => setState(() => _summerStartDate = date),
                ),
                const SizedBox(height: 16),
                _buildModernDatePicker(
                  label: 'ზაფხულის გამოსვლის თარიღი',
                  selectedDate: _summerEndDate,
                  onDateSelected: (date) => setState(() => _summerEndDate = date),
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _priceSummerController,
                  label: 'თითო ზაფხულის თვის საფასური',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                ),
                const SizedBox(height: 8),
                Text(
                  'ნიმუში: ხელშეკრულების თანახმად, ბინის ქირის ${_contractType == 'Monthly' || _contractType == 'Yearly' ? 'ყოველთვიური' : ''} საფასური დადგენილია $_price ${_sellingCurrency} ოდენობით, ხოლო ივნისში - ${_sellingCurrency == 'აშშ დოლარის' ? _getCurrencySymbol(_sellingCurrency) : ''}${_effectivePriceSummer}${_sellingCurrency == 'ქართული ლარის' ? _getCurrencySymbol(_sellingCurrency) : ''}, ივლისში - ...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
            ],

            _buildSectionHeader('გადახდის დეტალები:'),
            if (_contractType == 'Yearly') ...[
              _buildModernTextField(
                controller: _manualPrepaidAmountController,
                label: 'წინასწარ გადახდილი თანხა',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                onChanged: (value) => setState(() => _manualPrepaidAmount = value),
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _gePricePeriodDetController,
                label: 'რა თვის საფასურს იხდის (ქართულად)',
              ),
              const SizedBox(height: 8),
              Text(
                'ნიმუში: დამქირავებელი წინასწარ იხდის პირველი $_gePricePeriodDet თვის იჯარის საფასურს - ${_manualPrepaidAmount.isEmpty ? '0.00' : _manualPrepaidAmount} ${_sellingCurrency} ოდენობით,',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _ruPricePeriodDetController,
                label: 'რა თვის საფასურს იხდის (რუსულად)',
              ),
              const SizedBox(height: 8),
              Text(
                'ნიმუში: Арендатор предварительно платит сумму аренды за первый $_ruPricePeriodDet в размере ${_manualPrepaidAmount.isEmpty ? '0.00' : _manualPrepaidAmount} $_ruSellingCurrency',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
            _buildModernTextField(
              controller: _prePayedController,
              label: 'ჯავშანი',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              onChanged: (value) => setState(() => _prePayed = value.isEmpty ? '0' : value),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTypeToggle(
                  label: 'აშშ დოლარი',
                  isActive: _prePayedCurrency == 'აშშ დოლარის',
                  onTap: () => setState(() => _prePayedCurrency = 'აშშ დოლარის'),
                ),
                const SizedBox(width: 12),
                _buildTypeToggle(
                  label: 'ქართული ლარი',
                  isActive: _prePayedCurrency == 'ქართული ლარის',
                  onTap: () => setState(() => _prePayedCurrency = 'ქართული ლარის'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ნიმუში: დამქირავებელმა გადაიხადა ბინის ჯავშნის თანხა ${_prePayed == '0' ? 'ნული' : _prePayed} ${_prePayedCurrency} ოდენობით;',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            _buildModernTextField(
              controller: _petsPayedController,
              label: 'დეპოზიტი',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              onChanged: (value) => setState(() => _petsPayed = value.isEmpty ? '0' : value),
            ),
            const SizedBox(height: 16),

            _buildModernTextField(
              controller: _cleaningPriceController,
              label: 'დასუფთავების საფასური',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              onChanged: (value) => setState(() => _cleaningPrice = value.isEmpty ? '0' : value),
            ),
            if (_contractType != 'Daily') ...[
              const SizedBox(height: 16),
              const Text(
                  "დამატებითი კომუნალურები:",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStyledCheckbox(
                    title: 'ტელევიზია',
                    value: _additionalUtilities['ფასიანი ტელევიზია']!,
                    onChanged: (val) => setState(() => _additionalUtilities['ფასიანი ტელევიზია'] = val!),
                  ),
                  const SizedBox(width: 8),
                  _buildStyledCheckbox(
                    title: 'დომოფონი',
                    value: _additionalUtilities['დომოფონი']!,
                    onChanged: (val) => setState(() => _additionalUtilities['დომოფონი'] = val!),
                  ),
                  const SizedBox(width: 8),
                  _buildStyledCheckbox(
                    title: 'დაცვა',
                    value: _additionalUtilities['დაცვა']!,
                    onChanged: (val) => setState(() => _additionalUtilities['დაცვა'] = val!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
            _buildPriceInfoCard(
              label: 'სრული ფასი:',
              value: '${_priceFull} ${_getCurrencySymbol(_sellingCurrency)}',
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('ბინის მისამართი და ფართი:'),
            _buildModernTextField(
              controller: _sqMeterController,
              label: 'ფართი',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => setState(() => _sqMeter = value),
            ),
            const SizedBox(height: 8),
            Text(
              'ნიმუში: ${_geAddress}, ფართი - $_sqMeter კვ.მ.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: _geAddressController,
              label: 'მისამართი ქართულად',
              onChanged: (value) => setState(() => _geAddress = value),
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: _ruAddressController,
              label: 'მისამართი რუსულად',
              onChanged: (value) => setState(() => _ruAddress = value),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('მეპატრონის ინფორმაცია:'),
            _buildAnimatedTextFieldRow(
              geController: _geNameGiveController,
              ruController: _ruNameGiveController,
              geLabel: 'სახელი და გვარი (ქართულად)',
              ruLabel: '(რუს./ინგ.)',
              geFocusNode: _geNameGiveFocusNode,
              ruFocusNode: _ruNameGiveFocusNode,
              isRuDominant: _isRuNameGiveDominant,
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: _pnGiveController,
              label: 'პირადი ნომერი',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => setState(() => _pnGive = value),
            ),
            const SizedBox(height: 16),
            _buildModernDatePicker(
              label: 'დაბადების თარიღი',
              selectedDate: _bdGive,
              onDateSelected: (date) => setState(() => _bdGive = date),
              lastDate: DateTime.now(),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('სტუმრის ინფორმაცია:'),
            _buildAnimatedTextFieldRow(
              geController: _geNameTakeController,
              ruController: _ruNameTakeController,
              geLabel: 'სახელი და გვარი (ქართულად)',
              ruLabel: '(რუს./ინგ.)',
              geFocusNode: _geNameTakeFocusNode,
              ruFocusNode: _ruNameTakeFocusNode,
              isRuDominant: _isRuNameTakeDominant,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTypeToggle(
                  label: 'პასპორტი',
                  isActive: _idTakeType == 'პასპორტი',
                  onTap: () => setState(() => _idTakeType = 'პასპორტი'),
                ),
                const SizedBox(width: 12),
                _buildTypeToggle(
                  label: 'პირადობა',
                  isActive: _idTakeType == 'პირადობის მოწმობა',
                  onTap: () => setState(() => _idTakeType = 'პირადობის მოწმობა'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildModernTextField(
              controller: _idTakeNumController,
              label: _idTakeType == 'პასპორტი' ? 'პასპორტის ნომერი' : 'პირადობის ნომერი',
              onChanged: (value) => setState(() => _idTakeNum = value),
            ),
            const SizedBox(height: 16),
            _buildModernDatePicker(
              label: 'დაბადების თარიღი',
              selectedDate: _bdTake,
              onDateSelected: (date) => setState(() => _bdTake = date),
              lastDate: DateTime.now(),
            ),
            const SizedBox(height: 16),
            _buildAnimatedTextFieldRow(
              geController: _geCityTakeController,
              ruController: _ruCityTakeController,
              geLabel: 'წარ. ქალაქი (ქართულად)',
              ruLabel: '(რუს./ინგ.)',
              geFocusNode: _geCityTakeFocusNode,
              ruFocusNode: _ruCityTakeFocusNode,
              isRuDominant: _isRuCityTakeDominant,
            ),
            const SizedBox(height: 16),
            _buildAnimatedTextFieldRow(
              geController: _geCountryTakeController,
              ruController: _ruCountryTakeController,
              geLabel: 'წარ. ქვეყანა (ქართულად)',
              ruLabel: '(რუს./ინგ.)',
              geFocusNode: _geCountryTakeFocusNode,
              ruFocusNode: _ruCountryTakeFocusNode,
              isRuDominant: _isRuCountryTakeDominant,
            ),
            const SizedBox(height: 16),
            _buildModernDropdown<String>(
              label: 'ცხოველები/ფრინველები',
              value: _gePets,
              items: [
                'ცხოველებისა და ფრინველების გარეშე', 'ძაღლით', 'კატით',
                'ძაღლით და კატით', '2 ძაღლით', '2 კატით',
              ].map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
              onChanged: (value) {
                setState(() {
                  _gePets = value!;
                  if (_gePets == 'ცხოველებისა და ფრინველების გარეშე') {
                    _petsPayed = '0';
                    _petsPayedController.text = '';
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            _buildModernDropdown<String>(
              label: 'რამდენ პერსონასთან ერთად შედის',
              value: _gePersons,
              items: [
                'მარტო', 'ერთ პერსონასთან ერთად', 'ორ პერსონასთან ერთად',
                'სამ პერსონასთან ერთად', 'ოთხ პერსონასთან ერთად', 'ხუთ პერსონასთან ერთად',
                'ექვს პერსონასთან ერთად', 'შვიდ პერსონასთან ერთად', 'რვა პერსონასთან ერთად',
              ].map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
              onChanged: (value) => setState(() => _gePersons = value!),
            ),
            const SizedBox(height: 8),
            Text(
              'ნიმუში: იცხოვროს დაქირავებულ ფართში $_gePersons, $_gePets;',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('გადახდა:'),
            Row(
              children: [
                _buildTypeToggle(
                    label: 'ნაღდი',
                    isActive: _paymentMethod == 'ნაღდი',
                    enabled: _trPersonOption == 'არა',
                    onTap: () => setState(() {
                      _paymentMethod = 'ნაღდი';
                    })),
                const SizedBox(width: 12),
                _buildTypeToggle(
                  label: 'გადარიცხვა',
                  isActive: _paymentMethod == 'გადარიცხვა',
                  onTap: () => setState(() {
                    _paymentMethod = 'გადარიცხვა';
                  }),
                ),
              ],
            ),
            if (_paymentMethod == 'გადარიცხვა') ...[
              const SizedBox(height: 16),
              _buildModernDropdown<String>(
                label: 'ბანკი',
                value: _geBankName,
                enabled: _trPersonOption == 'არა',
                items: [
                  'საქართველოს ბანკი', 'თი-ბი-სი ბანკი',
                  'ლიბერთი ბანკი', 'ბაზის ბანკი', 'ტერა ბანკი'
                ]
                    .map((option) =>
                    DropdownMenuItem(value: option, child: Text(option)))
                    .toList(),
                onChanged: (value) => setState(() => _geBankName = value!),
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _bankController,
                label: 'ანგარიშის ნომერი',
                enabled: _trPersonOption == 'არა',
                onChanged: (value) => setState(() => _bank = value),
              ),
            ],
            const SizedBox(height: 24),

            _buildSectionHeader('მინდობილი პირი იღებს თანხას?'),
            Row(
              children: [
                _buildTypeToggle(
                    label: 'არა',
                    isActive: _trPersonOption == 'არა',
                    onTap: () => setState(() {
                      _trPersonOption = 'არა';
                      _trPersonGe = '';
                    })),
                const SizedBox(width: 12),
                _buildTypeToggle(
                  label: 'კი',
                  isActive: _trPersonOption == 'კი',
                  onTap: () => setState(() {
                    _trPersonOption = 'კი';
                    _paymentMethod = 'გადარიცხვა';
                    if (_trPersonGe.isEmpty) {
                      _trPersonGe = 'სოფიო ქათამაძეს';
                    }
                    _updateTrustedPersonBankDetails(_trPersonGe);
                  }),
                ),
              ],
            ),
            if (_trPersonOption == 'კი') ...[
              const SizedBox(height: 16),
              _buildModernDropdown<String>(
                label: 'მინდობილი პირი',
                value: _trPersonGe,
                items: _trPersonOptionsMap.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _trPersonGe = value;
                    _updateTrustedPersonBankDetails(value);
                  });
                },
              ),
            ],
            const SizedBox(height: 32),

            _buildActionButton(
              label: 'PDF-ის შედგენა',
              onPressed: () => _generateAndSavePdf(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndSavePdf(BuildContext context) async {
    // This block synchronizes all form fields with the widget's state.
    setState(() {
      _price = _priceController.text;
      _period = _periodController.text;
      _periodDays = _periodDaysController.text;
      _priceSummer = _priceSummerController.text;
      _manualPrepaidAmount = _manualPrepaidAmountController.text;
      _gePricePeriodDet = _gePricePeriodDetController.text;
      _ruPricePeriodDet = _ruPricePeriodDetController.text;
      _petsPayed = _petsPayedController.text;
      _cleaningPrice = _cleaningPriceController.text;
      _prePayed = _prePayedController.text;
      _sqMeter = _sqMeterController.text;
      _geAddress = _geAddressController.text;
      _ruAddress = _ruAddressController.text;
      _geNameGive = _geNameGiveController.text;
      _ruNameGive = _ruNameGiveController.text;
      _pnGive = _pnGiveController.text;
      _geNameTake = _geNameTakeController.text;
      _ruNameTake = _ruNameTakeController.text;
      _idTakeNum = _idTakeNumController.text;
      _geCityTake = _geCityTakeController.text;
      _ruCityTake = _ruCityTakeController.text;
      _geCountryTake = _geCountryTakeController.text;
      _ruCountryTake = _ruCountryTakeController.text;
      _bank = _bankController.text;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF004aad)),
              SizedBox(height: 16),
              Text('გთხოვთ დაელოდოთ', style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      },
    );

    try {
      // Generate PDF bytes in memory
      final pdf = pw.Document();
      // (Your existing PDF creation logic remains unchanged here)
      final georgianFontData = await rootBundle.load("assets/fonts/NotoSansGeorgian-Regular.ttf");
      final georgianFont = pw.Font.ttf(georgianFontData);
      final notoSansFontData = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
      final notoSansFont = pw.Font.ttf(notoSansFontData);
      final georgianHeaderStyle = pw.TextStyle(font: georgianFont, fontSize: 14, fontWeight: pw.FontWeight.bold);
      final georgianBodyStyle = pw.TextStyle(font: georgianFont, fontSize: 10);
      final russianHeaderStyle = pw.TextStyle(font: notoSansFont, fontSize: 14, fontWeight: pw.FontWeight.bold);
      final russianBodyStyle = pw.TextStyle(font: notoSansFont, fontSize: 10);
      String cleanSection(String text, int sectionNumber) {
        return text.replaceFirst(RegExp('^$sectionNumber\\. .*?\\n+', dotAll: true), '');
      }
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) => [
            pw.Header(level: 0, child: pw.Text('ქირავნობის ხელშეკრულება', style: pw.TextStyle(font: georgianFont, fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.Paragraph(text: _generateGeorgianHeader(), style: georgianBodyStyle),
            pw.Header(level: 1, text: '1. ხელშეკრულების საგანი', textStyle: georgianHeaderStyle),
            pw.Paragraph(text: cleanSection(_generateGeorgianSubject(), 1), style: georgianBodyStyle),
            pw.Header(level: 1, text: '2. მხარეთა უფლება-მოვალეობები', textStyle: georgianHeaderStyle),
            pw.Paragraph(text: cleanSection(_generateGeorgianObligations(), 2), style: georgianBodyStyle),
            pw.Header(level: 1, text: '3. ქირა და ანგარიშსწორების პირობები', textStyle: georgianHeaderStyle),
            pw.Paragraph(text: cleanSection(_generateGeorgianPaymentTerms(), 3), style: georgianBodyStyle),
            pw.Header(level: 1, text: '4. ხელშეკრულების ვადები', textStyle: georgianHeaderStyle),
            pw.Paragraph(text: cleanSection(_generateGeorgianContractTerms(), 4), style: georgianBodyStyle),
            pw.Header(level: 1, text: '5. დამატებითი პირობები', textStyle: georgianHeaderStyle),
            pw.Paragraph(text: cleanSection(_generateGeorgianAdditionalTerms(), 5), style: georgianBodyStyle),
            pw.Header(level: 1, text: '6. მხარეთა იურიდიული მისამართები და რეკვიზიტები', textStyle: georgianHeaderStyle),
            pw.Paragraph(text: cleanSection(_generateGeorgianSignatures(), 6), style: georgianBodyStyle),
            pw.SizedBox(height: 20),
            pw.Header(level: 0, child: pw.Text('Договор аренды', style: pw.TextStyle(font: notoSansFont, fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.Paragraph(text: _generateRussianHeader(), style: russianBodyStyle),
            pw.Header(level: 1, text: '1. Предмет договора', textStyle: russianHeaderStyle),
            pw.Paragraph(text: cleanSection(_generateRussianSubject(), 1), style: russianBodyStyle),
            pw.Header(level: 1, text: '2. Обязанности и права сторон', textStyle: russianHeaderStyle),
            pw.Paragraph(text: cleanSection(_generateRussianObligations(), 2), style: russianBodyStyle),
            pw.Header(level: 1, text: '3. Способ оплаты и сумма оплаты', textStyle: russianHeaderStyle),
            pw.Paragraph(text: cleanSection(_generateRussianPaymentTerms(), 3), style: russianBodyStyle),
            pw.Header(level: 1, text: '4. Сроки договора', textStyle: russianHeaderStyle),
            pw.Paragraph(text: cleanSection(_generateRussianContractTerms(), 4), style: russianBodyStyle),
            pw.Header(level: 1, text: '5. Заключительное положение', textStyle: russianHeaderStyle),
            pw.Paragraph(text: cleanSection(_generateRussianAdditionalTerms(), 5), style: russianBodyStyle),
            pw.Header(level: 1, text: '6. Юридические адреса сторон и реквизиты', textStyle: russianHeaderStyle),
            pw.Paragraph(text: cleanSection(_generateRussianSignatures(), 6), style: russianBodyStyle),
          ],
        ),
      );
      final Uint8List pdfBytes = await pdf.save();

      // --- NEW LOGIC STARTS HERE ---

      // 1. Generate the dynamic filename
      final invalidChars = RegExp(r'[\\/*?:"<>|]');
      final geNameGiveClean = _geNameGive.replaceAll(invalidChars, '_');
      final geNameTakeClean = _geNameTake.replaceAll(invalidChars, '_');
      final dynamicFilename = 'Contract - $geNameGiveClean - $geNameTakeClean.pdf';

      // 2. Upload the file to Firebase Storage to get a shareable URL
      final uploadResult = await DocumentHistoryManager.uploadContractFiles(
        pdfBytes: pdfBytes,
        textContent: _generateGeorgianContract() + "\n\n" + _generateRussianContract(),
        geNameGive: _geNameGive,
        geNameTake: _geNameTake,
      );

      if (uploadResult == null) {
        if(mounted) Navigator.of(context, rootNavigator: true).pop();
        if(mounted) CustomSnackBar.show(context: context, message: 'შეცდომა ფაილების ატვირთვისას', isError: true);
        return;
      }
      final pdfDownloadUrl = uploadResult['pdfUrl'];

      // 3. Save the record to Firestore history
      if (pdfDownloadUrl != null) {
        // --- EXPANDED PLACEHOLDERS MAP FOR COMPLETE DATA SAVING ---
        final placeholders = {
          // General
          'contractType': _contractType,
          'city': _geCity,
          'currency': _sellingCurrency,
          'price': _price,
          'period': _period,
          'periodDays': _periodDays,
          'startDate': _startDate?.toIso8601String(),
          // Summer
          'summerMonthOption': _summerMonthOption,
          'selectedSummerMonths': _selectedSummerMonths,
          'summerStartDate': _summerStartDate?.toIso8601String(),
          'summerEndDate': _summerEndDate?.toIso8601String(),
          'priceSummer': _priceSummer,
          // Payments
          'manualPrepaidAmount': _manualPrepaidAmount,
          'gePricePeriodDet': _gePricePeriodDet,
          'ruPricePeriodDet': _ruPricePeriodDet,
          'prepayment': _prePayed,
          'prePayedCurrency': _prePayedCurrency,
          'petsPayed': _petsPayed,
          'cleaningPrice': _cleaningPrice,
          // Apartment
          'sqMeters': _sqMeter,
          'geAddress': _geAddress,
          'ruAddress': _ruAddress,
          // Owner
          'ownerNameGe': _geNameGive,
          'ownerNameRu': _ruNameGive,
          'ownerIdNumber': _pnGive,
          'ownerBirthDate': _bdGive != null ? DateFormat('dd/MMM/yyyy', 'ka_GE').format(_bdGive!) : null,
          'ownerBankName': _geBankName,
          'ownerBankAccount': _bank,
          // Guest
          'guestNameGe': _geNameTake,
          'guestNameRu': _ruNameTake,
          'idTakeType': _idTakeType,
          'idTakeNum': _idTakeNum,
          'guestBirthDate': _bdTake?.toIso8601String(),
          'guestCityGe': _geCityTake,
          'guestCityRu': _ruCityTake,
          'guestCountryGe': _geCountryTake,
          'guestCountryRu': _ruCountryTake,
          'gePets': _gePets,
          'gePersons': _gePersons,
          // Payment Method & Trusted Person
          'paymentMethod': _paymentMethod,
          'trPersonOption': _trPersonOption,
          'trPersonGe': _trPersonGe,
          // Utilities
          'additionalUtilities': _additionalUtilities,
        };

        final DocumentHistoryItem contractHistoryItem = DocumentHistoryItem(
          type: 'Contract', pdfUrl: pdfDownloadUrl, textFileUrl: null,
          timestamp: DateTime.now(), placeholders: placeholders,
        );
        await DocumentHistoryManager.addHistoryItem(contractHistoryItem);
      }

      // 4. Handle platform-specific file sharing/opening
      if (kIsWeb) {
        // Use the helper to properly share or download on the web
        await PdfDownloadHelper.shareOrDownloadPdf(
          url: pdfDownloadUrl!,
          filename: dynamicFilename,
        );
      } else {
        // For mobile, save locally and open
        final output = await getTemporaryDirectory();
        final pdfFile = File('${output.path}/$dynamicFilename');
        await pdfFile.writeAsBytes(pdfBytes);
        await OpenFilex.open(pdfFile.path);
      }

      if(mounted) Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading dialog

      if(mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.of(context).pop();
            });
            return const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF004aad), size: 48),
                  SizedBox(height: 16),
                  Text('დამზადებულია', style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      if(mounted) Navigator.of(context, rootNavigator: true).pop();
      if(mounted) CustomSnackBar.show(context: context, message: 'შეცდომა შექმნისას: $e', isError: true);
    }
  }


  // Helper methods for date formatting
  String _formatDateGeorgian(DateTime? date) {
    if (date == null) return 'DD/MMM/YYYY';
    List<String> months = [
      'იან', 'თებ', 'მარ', 'აპრ', 'მაი', 'ივნ',
      'ივლ', 'აგვ', 'სექ', 'ოქტ', 'ნოე', 'დეკ'
    ];
    return '${date.day.toString().padLeft(2, '0')}/${months[date.month -
        1]}/${date.year}';
  }

  String _formatDateRussian(DateTime? date) {
    if (date == null) return 'DD/MMM/YYYY';
    List<String> months = [
      'Янв', 'Фев', 'Мар', 'Апр', 'Мая', 'Июн',
      'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'
    ];
    return '${date.day.toString().padLeft(2, '0')}/${months[date.month -
        1]}/${date.year}';
  }

  DateTime? _calculateEndDate() {
    if (_startDate == null || _period.isEmpty) return null;

    final duration = int.tryParse(_period) ?? 0;
    if (duration <= 0) return null;

    try {
      if (_contractType == 'Yearly' || _contractType == 'Monthly') {
        return DateTime(
            _startDate!.year,
            _startDate!.month + duration,
            _startDate!.day
        );
      } else if (_contractType == 'Daily') {
        return _startDate!.add(Duration(days: duration));
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // --- Georgian Contract Generation Methods ---
  String _generateGeorgianHeader() {
    final endDate = _calculateEndDate();
    return '''
ქ. $_geCity

${_formatDateGeorgian(_startDate)} წ.

ჩვენ, ერთის მხრივ, $_geNameGive (პ/ნ $_pnGive, დ.თ. ${_formatDateGeorgian(
        _bdGive)}, საქართველო) - შემდეგში „გამქირავებელი“

მეორეს მხრივ, $_geNameTake (${_idTakeType == 'პასპორტი'
        ? 'პასპორტი'
        : 'პ/ნ'} $_idTakeNum, დ.თ. ${_formatDateGeorgian(
        _bdTake)}, ${_geCityTake.isNotEmpty ? '$_geCityTake/' : ''}${_geCountryTake}) - შემდეგში „დამქირავებელი“

ვმოქმედებთ საქართველოს მოქმედი კანონმდებლობის, კერძოდ, საქართველოს სამოქალაქო კოდექსით მინიჭებული უფლებამოსილებით და ვდებთ წინამდებარე ხელშეკრულებას შემდეგზე:
''';
  }

  String _generateGeorgianSubject() {
    return '''
1. ხელშეკრულების საგანი

1.1. ხელშეკრულების საფუძველზე, გამქირავებელი გადასცემს, ხოლო დამქირავებელი ღებულობს დროებით სარგებლობაში, გამქირავებლის კუთვნილ საცხოვრებელ ფართს, რომელიც მდებარეობს შემდეგ მისამართზე:

$_geCity $_geAddress, ფართი - $_sqMeter კვ.მ.

1.2. გამქირავებელი აცხადებს და იძლევა გარანტიას, რომ იგი წარმოადგენს საცხოვრებელი (გასაქირავებელი) ფართის კანონიერ მესაკუთრეს და აქვს ამ ფართის გაქირავების უფლება.
''';
  }

  String _generateGeorgianObligations() {
    String obligations = '''
2. მხარეთა უფლება-მოვალეობები

2.1. დამქირავებელი ვალდებულია:
''';

    int clauseCounter = 1; // Counter for dynamic numbering

    // This clause now applies ONLY to Yearly contracts.
    if (_contractType == 'Yearly') {
      obligations += '''
    
2.1.${clauseCounter++}. ხელშეკრულების პირობის თანახმად, დროულად და სრულად დაფაროს იჯარის თანხა;
''';
    }

    if (_contractType == 'Monthly' || _contractType == 'Yearly') {
      final baseUtilitiesGe = ['ელექტროენერგია', 'გაზი', 'წყალი', 'ინტერნეტი', 'ლიფტი'];
      if (_additionalUtilities['ფასიანი ტელევიზია']!) {
        baseUtilitiesGe.add('ფასიანი ტელევიზია');
      }
      if (_additionalUtilities['დომოფონი']!) {
        baseUtilitiesGe.add('დომოფონი');
      }
      if (_additionalUtilities['დაცვა']!) {
        baseUtilitiesGe.add('დაცვა');
      }
      final utilitiesTextGe = baseUtilitiesGe.join(', ');

      obligations += '''

2.1.${clauseCounter++}. ხელშეკრულების მოქმედების პერიოდში, დროულად დაფაროს კომუნალური ხარჯები ($utilitiesTextGe);
''';
    }

    obligations += '''
  
2.1.${clauseCounter++}. დაქირავებული ფართი გამოიყენოს დანიშნულებისამებრ, გაუფრთხილდეს და უზრუნველყოს მისი მოვლა-პატრონობა;

2.1.${clauseCounter++}. იცხოვროს დაქირავებულ ფართში $_gePersons, $_gePets;

2.1.${clauseCounter++}. არ გააქირავოს და გადასცეს საცხოვრებელი ფართი მესამე პირს;

2.1.${clauseCounter++}. არ შეცვალოს საცხოვრებელი ფართის არც ერთი კარის გასაღები, გამქირავებელთან წინასწარი შეთანხმების გარეშე;
''';

    // Store the parent clause number before incrementing for use in sub-clauses.
    final subClauseParentNumber = clauseCounter;
    obligations += '''

2.1.${clauseCounter++}. დაუყოვნებლივ გაათავისუფლოს დაქირავებული ფართი, თუ:

2.1.${subClauseParentNumber}.1. დაარღვია ამ ხელშეკრულების ნებისმიერი პირობა;

2.1.${subClauseParentNumber}.2. ხელშეკრულებით განსაზღვრული ვადის გასვლისთანავე (მიუხედავად მქირავებლის, ან მასთან თანამაცხოვრებლის ფინანსური, სოციალური, პოლიტიკური ან ფიზიკური მდგომარეობისა);
''';

    obligations += '''

2.1.${clauseCounter++}. ხელშეკრულების ვადის გასვლის შემდეგ, ასევე მისი შეწყვეტისას, მქირავებელი ვალდებულებას იღებს გადასცეს გამქირავებელს ფართი იმავე მდგომარეობაში და კონდიციაში, როგორშიც მიიღო გამქირავებლისგან (ბუნებრივი ცვეთის გათვალისწინებით). წინააღმდეგ შემთხვევაში მქირავებელი თანხმდება აუნაზღაუროს გამქირავებელს ზარალი, საბაზრო ფასების გათვალისწინებით;

2.1.${clauseCounter++}. აუნაზღაუროს გამქირავებელს ზარალი, საბაზრო ფასების გათვალისწინებით, რომელიც გამქირავებლის მეზობლებს მიადგა დამქირავებლის (ან მისი თანამაცხოვრებლის / სტუმრის / ცხოველის / ფრინველის) ბრალეულობით;
''';

    if (_cleaningPrice.isNotEmpty && _cleaningPrice != '0') {
      obligations += '''

2.1.${clauseCounter++}. გადაუხადოს გამქირავებელს თანხა $_cleaningPrice ოდენობით, დაქირავებული ფართის აუცილებელი „დასუფთავების“ უზრუნველსაყოფად.
''';
    }

    if (_contractType == 'Monthly' || _contractType == 'Yearly') {
      obligations += '''
    
2.1.${clauseCounter++}. ფართის ქირით მიღებისთანავე, ასევე მისი გამქირავებელზე საბოლოოდ დაბრუნების მომენტში გადაიღოს ყველა კომუნალური მრიცხველის ფოტო (რომელზედაც გარკვევით იკითხება მრიცხველების მაჩვენებელი) და ნებისმიერი ხელმისაწვდომი მეთოდით გადაუგზავნოს ის გამქირავებელს;
''';
    }

    obligations += '''
  
2.1.${clauseCounter++}. მკაცრად დაიცვას საცხოვრებელ ფართში ხანძარსაწინააღმდეგო და ელექტროუსაფრთხოების პირობები;

2.1.${clauseCounter++}. დაუშვას დაქირავებულ ბინაში გამქირავებელი, წინასწარ გაფრთხილების საფუძველზე.
''';

    if (_contractType == 'Yearly') {
      obligations += '''
    
2.1.${clauseCounter++}. დამქირავებელი ვალდებულია დროულად და სრულად გადაიხადოს ქირავნობის ღირებულება, ყოველი თვის არაუგვიანეს ${_startDate?.day ?? 1} რიცხვისა. თუ დამქირავებელი დროულად და სრულად არ გადაიხდის ქირის საფასურს ან ხუთი დღით დააგვიანებს გადახდას და არ გამოვა გამქირავებელთან კონტაქტზე, გამქირავებელი უფლებას იტოვებს, სამი მოწმის თანდასწრებით გააღოს საკუთარი ბინის კარი და უწყვეტი ვიდეოგადაღების თანხლებით გამოიტანოს დამქირავებლის პირადი ნივთები ბინის გარეთ და გააქირაოს ბინა სხვა დამქირავებელზე.
''';
    }

    // Section 2.2
    obligations += '''

2.2. გამქირავებელი ვალდებულია:

2.2.1. დროულად გადასცეს დამქირავებელს უფლებრივად და ნივთობრივად უნაკლო ფართი (უფლებრივად უნაკლოში იგულისხმება პირობა, როდესაც ხელშეკრულებაში მითითებულ ფართზე არანაირი პრეტენზია არ ექნება მესამე პირს);

2.2.2. თუ დარღვეულია 2.2.1. პუნქტი, გამქირავებელი ვალდებულია აუნაზღაუროს დამქირავებელს მიყენებული მატერიალური ზარალი;
''';

    if (_contractType != 'Daily') {
      obligations += '''
    
2.2.3. გააკონტროლოს კომუნალური გადასახადების დროული დაფარვა დამქირავებლის მხრიდან.
''';
    }

    if (_contractType == 'Yearly') {
      obligations += '''
    
2.2.4. მოითხოვოს ხელშეკრულების გაუქმება, თუ დამქირავებელი დროულად და სრულად არ გადაიხდის ქირას;
''';
    }

    // Section 2.3 with dynamic sub-clause numbering
    obligations += '''
  
2.3. გამქირავებელს უფლება აქვს

2.3.1. ცალმხრივად შეწყვიტოს ხელშეკრულება, დამქირავებლის მხრიდან შემდეგი ქმედებისას:
''';

    int subClauseCounter = 1; // Counter for dynamic sub-numbering

    // **FIX**: Clause 2.3.1.1 is now excluded for Daily contracts.
    if (_contractType != 'Daily') {
      obligations += '''

2.3.1.${subClauseCounter++}. თუ დამქირავებელი დროულად და სრულად არ გადაიხდის ქირის ყოველთვიურ საფასურს და არ დაფარავს მის მიერ გაწეულ კომუნალურ ხარჯებს;
''';
    }

    // **FIX**: Subsequent clauses use the dynamic counter for correct numbering.
    obligations += '''

2.3.1.${subClauseCounter++}. მეზობლებთან უპატივცემულო ქცევის დროს (თუ მათი მხრიდან შემოსულია ოფიციალური საჩივარი);

2.3.1.${subClauseCounter++}. დაქირავებული ფართის მესამე პირის სარგებლობაში გადაცემისას;

2.3.1.${subClauseCounter++}. ბინაზე დამატებითი თანამაცხოვრებლების მუდმივად (სამ დღეზე მეტი ხნით) მოწვევისას;

2.3.1.${subClauseCounter++}. ბინაში სხვა ცხოველების/ფრინველების შეყვანისას (რომლებიც ხელშეკრულებაში არ არის გათვალისწინებული);

2.3.1.${subClauseCounter++}. ბინაში სიგარეტის ან სხვა მძაფრი სუნის მქონე საშუალების მოწევისას, გარდა ღია აივნის სივრცისა;

2.3.1.${subClauseCounter++}. ბინაში სწრაფადაალებადი, ფეთქებადსაშიში ან მომწამლავი ნივთიერებების შეტანისას.

2.3.2. ცალმხრივად შეწყვიტოს ხელშეკრულება ფორს-მაჟორის შემთხვევისას (ხანძარი, აფეთქება, სტიქიური უბედურება, სამხედრო მოქმედებები, აჯანყებები, არეულობები, ომი);
''';

    if (_contractType == 'Monthly' || _contractType == 'Yearly') {
      obligations += '''
    
2.3.3. დაათვალიეროს გაქირავებული ბინა, დამქირავებელთან წინასწარი შეტყობინების საფუძველზე, მაგრამ არა უმეტეს თვეში ერთხელ.

2.3.4. გააცნოს დამქირავებელს ბინის ფლობის შემზღუდავი პირობები, რომლებიც ძირითადად გამოიხატება შემდეგში, დაქირავებულ ბინაში აკრძალულია ნარკოტიკული, ალკოჰოლური, სხვა ქიმიური და ბიოლოგიური მცენარეებისა და პროდუქციის წარმოება და კულტივირება, ასევე „მაინერების“ და მსგავსი მოწყობილობების მოწყობა, რომლებიც მოიხმარენ ჭარბ ელ. ენერგიას და სხვ.
''';
    } else {
      obligations += '''
    
2.3.3. დაათვალიეროს გაქირავებული ბინა, დამქირავებელთან წინასწარი შეტყობინების საფუძველზე, მაგრამ არა უმეტეს ერთხელ.

2.3.4. გააცნოს დამქირავებელს ბინის ფლობის შემზღუდავი პირობები, რომლებიც ძირითადად გამოიხატება შემდეგში, დაქირავებულ ბინაში აკრძალულია ნარკოტიკული, ალკოჰოლური, სხვა ქიმიური და ბიოლოგიური მცენარეებისა და პროდუქციის წარმოება და კულტივირება, ასევე „მაინერების“ და მსგავსი მოწყობილობების მოწყობა, რომლებიც მოიხმარენ ჭარბ ელ. ენერგიას და სხვ.
''';
    }
    return obligations;
  }

  String _generateGeorgianPaymentTerms() {
    int clauseCounter = 1; // Counter for dynamic numbering

    String paymentTerms = '''
3. ქირა და ანგარიშსწორების პირობები
''';
    String typeTextGe = _contractType == 'Monthly' ? 'ყოველთვიური(თვედ ითვლება 30 კალენდარული დღე)' : 'დღიური';
    String deductionClauseGe = (_prePayed != '0' && _prePayed.isNotEmpty)
        ? ', რომელსაც გამოაკლდება უკვე გადახდილი ჯავშნის საფასური(პუნქტი 3.4)'
        : '';
    String currencySymbol = _getCurrencySymbol(_sellingCurrency);
    String formattedStartDate = _formatDateGeorgian(_startDate);
    String formattedSummerStartDate = _formatDateGeorgian(_summerStartDate);
    String formattedSummerEndDate = _formatDateGeorgian(_summerEndDate);
    String prepaidAmountText = _manualPrepaidAmount.isNotEmpty ? _manualPrepaidAmount : '0.00';


    if ((_contractType == 'Yearly') &&
        _summerMonthOption == 'იხდის') {

      // --- CORRECTED LOGIC for dynamic summer month clause ---
      final selectedMonths = _selectedSummerMonths.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      // Helper function for correct Georgian grammar
      String formatMonth(String month) {
        if (month.endsWith('ი')) {
          return '${month.substring(0, month.length - 1)}ში'; // Correctly forms "ივნისში", "ივლისში"
        }
        return '${month}ში'; // Handles "აგვისტოში"
      }

      String summerMonthsClause = '';
      final summerPriceText = '${_sellingCurrency == 'აშშ დოლარის' ? '\$' : ''}${_effectivePriceSummer}${_sellingCurrency == 'ქართული ლარის' ? '₾' : ''}';

      if (selectedMonths.length == 1) {
        summerMonthsClause = 'ხოლო ${formatMonth(selectedMonths[0])} - $summerPriceText';
      } else if (selectedMonths.length == 2) {
        summerMonthsClause = 'ხოლო ${formatMonth(selectedMonths[0])} - $summerPriceText და ${formatMonth(selectedMonths[1])} - $summerPriceText';
      } else if (selectedMonths.length == 3) {
        summerMonthsClause = 'ხოლო ივნისში - $summerPriceText, ივლისში - $summerPriceText და აგვისტოში - $summerPriceText';
      }

      if (summerMonthsClause.isNotEmpty) {
        summerMonthsClause += ' (დაწყებული $formattedSummerStartDate-დან და მოქმედებს $formattedSummerEndDate-მდე)';
      }
      // --- END of corrected logic ---

      paymentTerms += '''      
3.${clauseCounter++}. ხელშეკრულების თანახმად, ბინის ქირის ყოველთვიური საფასური დადგენილია ${_sellingCurrency ==
          'აშშ დოლარის' ? '\$' : ''}$_price${_sellingCurrency == 'ქართული ლარის'
          ? '₾'
          : ''} ${_sellingCurrency} ოდენობით, $summerMonthsClause. დამქირავებელი წინასწარ იხდის იჯარის პირველი $_gePricePeriodDet თვის საფასურს ${_sellingCurrency ==
          'აშშ დოლარის' ? '\$' : ''}$prepaidAmountText${_sellingCurrency == 'ქართული ლარის' ? '₾' : ''} ოდენობით$deductionClauseGe;
''';
    } else if (_contractType == 'Yearly') {
      paymentTerms += '''
3.${clauseCounter++}. ხელშეკრულების თანახმად, ბინის ქირის ყოველთვიური საფასური დადგენილია $_price ${_sellingCurrency} ოდენობით. დამქირავებელი წინასწარ იხდის პირველი $_gePricePeriodDet თვის იჯარის საფასურს - $prepaidAmountText ${_sellingCurrency} ოდენობით$deductionClauseGe;
''';
    } else {
      paymentTerms += '''
3.${clauseCounter++}. ხელშეკრულების თანახმად, ბინის ქირის $typeTextGe საფასური დადგენილია $_price ${_sellingCurrency} ოდენობით. დამქირავებელი წინასწარ იხდის იჯარის სრულ საფასურს $_priceFull ${_sellingCurrency} ოდენობით$deductionClauseGe;
''';
    }

    paymentTerms += '''

3.${clauseCounter++}. ხელშეკრულებით, ქირავნობის მთლიანი საფასური შეადგენს $_priceFull ${_sellingCurrency} ოდენობას;

3.${clauseCounter++}. თუ დამქირავებელი დაარღვევს ხელშეკრულების პირობებს, მას მიმდინარე თვის, ასევე წინასწარ გადახდილი იჯარის თანხა არ უბრუნდება;
''';

    if (_prePayed != '0' && _prePayed.isNotEmpty) {
      paymentTerms += '''

3.${clauseCounter++}. დამქირავებელმა გადაიხადა ბინის ჯავშნის თანხა $_prePayed ${_prePayedCurrency} ოდენობით;
''';
    }

    if (_petsPayed != '0' && _petsPayed.isNotEmpty) {
      paymentTerms += '''

3.${clauseCounter++}. დამქირავებელმა გადასცა გამქირავებელს თანხა $_petsPayed ${_sellingCurrency} ოდენობით, როგორც დეპოზიტი შესაძლო ზარალის დასაფარად, რომელიც შეიძლება მიადგეს ბინას მისი ჩაბარების მომენტისთვის. აღნიშნული თანხა უბრუნდება დამქირავებელს, თუ მან დაიცვა ხელშეკრულების ყველა პირობა. თუ მიყენებული ზარალი აღემატება დეპოზიტის თანხას, საკითხი სრულად რეგულირდება ამ ხელშეკრულების 2.1.8 და 2.1.10 პუნქტების შესაბამისად.
''';
    }

    return paymentTerms;
  }

  String _generateGeorgianContractTerms() {
    String contractTerms = '''
4. ხელშეკრულების ვადები
''';
    String formattedStartDate = _formatDateGeorgian(_startDate);
    DateTime? endDate = _calculateEndDate();
    String formattedEndDate = _formatDateGeorgian(endDate);

    if (_contractType == 'Monthly') {
      contractTerms += '''      
4.1. ხელშეკრულება ძალაში შედის $formattedStartDate 13:00-დან, და მოქმედებს $_period კალენდარული დღე, $formattedEndDate 12:00-მდე.
''';
    } else if (_contractType == 'Yearly') {
      contractTerms += '''
4.1. ხელშეკრულება ძალაში შედის $formattedStartDate 13:00-დან, და მოქმედებს $_period თვით, $formattedEndDate 12:00-მდე.
''';
    } else { // Daily
      contractTerms += '''
4.1. ხელშეკრულება ძალაში შედის $formattedStartDate 13:00-დან, და მოქმედებს $_period კალენდარული დღე, $formattedEndDate 12:00-მდე;
''';
    }

    contractTerms += '''

4.2. მხარეთა მიერ ხელშეკრულებით დაკისრებული ვალდებულებების არშესრულება, შესაძლოა განიხილულ იქნას ხელშეკრულების უპირობო შეწყვეტად;
''';

    if (_contractType == 'Yearly') {
      contractTerms += '''
      
4.3. დამქირავებელმა, ხელშეკრულების ვადაზე ადრე შეწყვეტის შემთხვევაში, 30 დღით ადრე უნდა აცნობოს ამის შესახებ გამქირავებელს და გადაუხადოს მას თანხა თვიური(თვედ ითვლება 30 კალენდარული დღე) ქირავნობის ოდენობით. ამ შემთხვევაში გამქირავებელზე წინასწარ გადახდილი თანხა, დამქირავებელს არ უბრუნდება;

4.4. გამქირავებელმა, ხელშეკრულების ვადაზე ადრე შეწყვეტის შემთხვევაში, 30 დღით ადრე უნდა აცნობოს ამის შესახებ დამქირავებელს. ამ შემთხვევაში დამქირავებელი იხდის იმ თვ(ეებ)ის/დღ(ეებ)ის თანხას, რამდენიც იცხოვრა ქირავნობის ბოლო თვის განმავლობაში (ქირავნობის სრულ თვედ ითვლება 30 დღე), ასევე დამქირავებელს უბრუნდება გამოუყენებელი თვ(ეებ)ის/დღ(ეებ)ის წინასწარ გადახდილი თანხა;
''';
    } else if (_contractType == 'Monthly') {
      contractTerms += '''
      
4.3. დამქირავებელმა, ხელშეკრულების ვადაზე ადრე შეწყვეტის შემთხვევაში, 10 დღით ადრე უნდა აცნობოს ამის შესახებ გამქირავებელს და გადაუხადოს მას თანხა თვიური(თვედ ითვლება 30 კალენდარული დღე) ქირავნობის ოდენობით. ამ შემთხვევაში გამქირავებელზე წინასწარ გადახდილი თანხა, დამქირავებელს არ უბრუნდება;

4.4. გამქირავებელმა, ხელშეკრულების ვადაზე ადრე შეწყვეტის შემთხვევაში, 10 დღით ადრე უნდა აცნობოს ამის შესახებ დამქირავებელს. ამ შემთხვევაში დამქირავებელი იხდის იმ თვ(ეებ)ის/დღ(ეებ)ის თანხას, რამდენიც იცხოვრა ქირავნობის ბოლო თვის განმავლობაში (ქირავნობის სრულ თვედ ითვლება 30 დღე), ასევე დამქირავებელს უბრუნდება გამოუყენებელი თვ(ეებ)ის/დღ(ეებ)ის წინასწარ გადახდილი თანხა;
''';
    } else { // Daily
      contractTerms += '''
      
4.3. დამქირავებელმა, ხელშეკრულების ვადაზე ადრე შეწყვეტის შემთხვევაში, 5 დღით ადრე უნდა აცნობოს ამის შესახებ გამქირავებელს. ამ შემთხვევაში გამქირავებელზე წინასწარ გადახდილი თანხა, დამქირავებელს არ უბრუნდება;

4.4. გამქირავებელმა, ხელშეკრულების ვადაზე ადრე შეწყვეტის შემთხვევაში, 5 დღით ადრე უნდა აცნობოს ამის შესახებ დამქირავებელს. ამ შემთხვევაში დამქირავებელს უბრუნდება გამოუყენებელი დღეების წინასწარ გადახდილი თანხა;
''';
    }

    String typeTextGe = _contractType == 'Monthly' || _contractType == 'Yearly'
        ? 'ყოველთვიური'
        : '';

    // --- MODIFICATION START ---
    final String paymentInstructionGe = _paymentMethod == 'გადარიცხვა'
        ? 'უნდა ჩაერიცხოს გამქირავებელს შემდეგ ანგარიშზე $_bank $_geBankName'
        : 'უნდა გადაეცეს გამქირავებელს ნაღდი ანგარიშსწორებით';
    // --- MODIFICATION END ---

    if (_trPersonOption == 'კი') {
      contractTerms += '''
      
4.${_contractType == 'Daily'
          ? '5'
          : '5'}. მხარეთა შეთანხმების თანახმად, ქირავნობის $typeTextGe საფასური $paymentInstructionGe. თუ ხელშეკრულებით განსაზღვრულ ვადაში არ იქნება, ამ ანგარიშზე ჩარიცხული ქირის თანხა, ბინის მესაკუთრე უფლებამოსილია ცალმხრივად გააუქმოს ქირავნობის ხელშეკრულება.
''';
    } else {
      contractTerms += '''
      
4.${_contractType == 'Daily'
          ? '5'
          : '5'}. მხარეთა შეთანხმების თანახმად, ქირავნობის $typeTextGe საფასური $paymentInstructionGe. თუ ხელშეკრულებით განსაზღვრულ ვადაში არ იქნება, ამ ანგარიშზე ჩარიცხული ქირის თანხა, ბინის მესაკუთრე უფლებამოსილია ცალმხრივად გააუქმოს ქირავნობის ხელშეკრულება.
''';
    }
    return contractTerms;
  }

  String _generateGeorgianAdditionalTerms() {
    return '''
5. დამატებითი პირობები

5.1. საკითხები, რომლებიც არ რეგულირდება ამ ხელშეკრულებით, განიხილება საქართველოს კანონმდებლობით დადგენილი წესით, სასამართლოს მიერ;

5.2. ხელშეკრულების თითოეული მხარე ამ ხელშეკრულებით გათვალისწინებული ვალდებულებების შეუსრულებლობის ან არაჯეროვანი შესრულების გამო პასუხისმგებლობისაგან თავისუფლდება, თუ ვალდებულების შეუსრულებლობა გამოწვეული იყო დაუძლეველი ძალის შედეგად (ფორს-მაჟორი);

5.3. ხელშეკრულების ცვლილებები ან დამატებები ფორმდება წერილობით და დასტურდება მხარეთა ხელმოწერით;

5.4. ხელშეკრულება შედგენილია 2 თანაბარი იურიდიული ძალის მქონე ეგზემპლარად.
''';
  }

  String _generateGeorgianSignatures() {
    return '''
6. მხარეთა იურიდიული მისამართები და რეკვიზიტები

6.1. გამქირავებელი:

$_geNameGive

პ/ნ: $_pnGive

ხელმოწერა: ____________________

6.2. დამქირავებელი:

$_geNameTake

${_idTakeType == 'პასპორტი' ? 'პასპორტი' : 'პ/ნ'} $_idTakeNum

ხელმოწერა: ____________________
''';
  }

  // Helper method for the full Georgian contract (for fallback)
  String _generateGeorgianContract() {
    return [
      _generateGeorgianHeader(),
      _generateGeorgianSubject(),
      _generateGeorgianObligations(),
      _generateGeorgianPaymentTerms(),
      _generateGeorgianContractTerms(),
      _generateGeorgianAdditionalTerms(),
      _generateGeorgianSignatures(),
    ].join('\n\n');
  }

  // --- Russian Contract Generation Methods ---
  String _generateRussianHeader() {
    final endDate = _calculateEndDate();
    return '''
г. $_ruCity

${_formatDateRussian(_startDate)} г.

Мы, с одной стороны $_ruNameGive (л/н $_pnGive, д.р. ${_formatDateRussian(
        _bdGive)}, GEORGIA) - в последствии «Арендодатель»

и со второй стороны $_ruNameTake (${_idTakeType == 'პასპორტი'
        ? 'Паспорт'
        : 'л/н'} $_idTakeNum, д.р. ${_formatDateRussian(
        _bdGive)}, ${_ruCityTake.isNotEmpty ? '$_ruCityTake/' : ''}${_ruCountryTake}) - в последствии «Арендатор»

руководствуемся действующими законами Грузии, в частности полномочиями, предоставленными Гражданским Кодексом Грузии, заключаем настоящий договор о нижеследующем:
''';
  }

  String _generateRussianSubject() {
    return '''
1. Предмет договора

1.1. На основе договора арендодатель передает, а арендатор берет во временное пользование площадь принадлежащую арендодателю по адресу:

$_ruCity $_ruAddress, площадь - $_sqMeter кв.м.

1.2. Арендодатель заявляет и дает гарантию, что он является законным владельцем квартиры и у него есть право сдавать эту площадь в аренду.
''';
  }

  String _generateRussianObligations() {
    String obligations = '''
2. Обязанности и права сторон

2.1. Арендатор обязан:
''';

    int clauseCounter = 1; // Counter for dynamic numbering in section 2.1

    // This clause applies ONLY to Yearly contracts.
    if (_contractType == 'Yearly') {
      obligations += '''
    
2.1.${clauseCounter++}. Своевременно, согласно условию договора, вовремя покрывать плату за аренду;
''';
    }

    // This clause applies to Monthly and Yearly contracts.
    if (_contractType == 'Monthly' || _contractType == 'Yearly') {
      final baseUtilitiesRu = ['электроэнергия', 'газ', 'вода', 'интернет', 'лифт'];
      if (_additionalUtilities['ფასიანი ტელევიზია']!) {
        baseUtilitiesRu.add('платное телевидение');
      }
      if (_additionalUtilities['დომოფონი']!) {
        baseUtilitiesRu.add('домофон');
      }
      if (_additionalUtilities['დაცვა']!) {
        baseUtilitiesRu.add('охрана');
      }
      final utilitiesTextRu = baseUtilitiesRu.join(', ');

      obligations += '''

2.1.${clauseCounter++}. Вовремя оплачивать коммунальные услуги, в период действия договора ($utilitiesTextRu);
''';
    }

    obligations += '''
  
2.1.${clauseCounter++}. Бережно относиться к арендуемой площади и использовать по назначению;

2.1.${clauseCounter++}. Проживать в квартире $_ruPersons, $_ruPets;

2.1.${clauseCounter++}. Не сдавать и/или передавать в пользование арендованную квартиру третьим лицам;

2.1.${clauseCounter++}. Не менять ключи замков от любых дверей квартиры без предварительного согласия Арендодателя;
''';

    // Store the parent clause number for use in sub-clauses.
    final subClauseParentNumber = clauseCounter;
    obligations += '''

2.1.${clauseCounter++}. Немедленно освободить квартиру, если:

2.1.${subClauseParentNumber}.1. При нарушении любых условии договора;

2.1.${subClauseParentNumber}.2. При истечении договорного срока аренды (не смотря на финансовое, социальное, политическое или физическое состояние Арендатора или его/ее сожителя);
''';

    obligations += '''

2.1.${clauseCounter++}. По истечению срока действия договора, а так же, в случае его прекращения, Арендатор обязуется передать Арендодателю квартиру, в том же виде и состоянии (исключая естественный износ), в котором принял у Арендодателя, в противном случае Арендатор согласен возместить Арендодателю ущерб по рыночной цене;

2.1.${clauseCounter++}. Возместить ущерб арендодателю, нанесенный по вине арендатора (или его сожителями/питомцами) соседям, в сумме рыночной стоимости ущерба;
''';

    if (_cleaningPrice.isNotEmpty && _cleaningPrice != '0') {
      obligations += '''

2.1.${clauseCounter++}. Выплатить Арендодателю сумму в размере $_cleaningPrice, в обязательном порядке, для обеспечения «Клиннинга» Арендованной квартиры.
''';
    }

    if (_contractType == 'Monthly' || _contractType == 'Yearly') {
      obligations += '''
    
2.1.${clauseCounter++}. В момент приемки Арендованной квартиры (дата настоящего договора), а также её окончательной сдаче Арендодателю, Арендатор обязан сделать фото всех коммунальных счетчиков и переслать по доступным каналам Арендодателю (на фото должны чётко читаться показания всех счетчиков);
''';
    }

    obligations += '''
  
2.1.${clauseCounter++}. Строго соблюдать условия противопожарной, а также электробезопасности в квартире;

2.1.${clauseCounter++}. Разрешить доступ Арендодателю в арендуемую квартиру по предварительному уведомлению.
''';

    if (_contractType == 'Yearly') {
      obligations += '''
    
2.1.${clauseCounter++}. Арендатор обязан вовремя платить стоимость аренды не позднее ${_startDate?.day ?? 1} числа каждого месяца. Если арендатор, в назначенный срок, не выплатит стоимость аренды или на пять дней задержит оплату аренды, а так же, не выйдет на контакт с арендатором, то арендодатель оставляет за собой право в присутствии трёх свидетелей, открыть двери собственной квартиры, собрать личные вещи нанимателя, с непрерывным режимом видеосъемки и сдать в аренду квартиру новому нанимателю.
''';
    }

    // --- Section 2.2 ---
    obligations += '''

2.2. Арендодатель обязан

2.2.1. Своевременно передать арендатору площадь без правовых погрешностей (в фразе без правовых погрешностей стороны подразумевают условия, согласно которого, на указанную площадь не возникнет никаких претензий у третьей стороны).

2.2.2. В случае нарушения условий договора по пункту 2.2.1. арендодатель будет обязан возместить арендатору причиненный материальный ущерб;
''';

    // **FIX**: Clause 2.2.3 is now excluded for Daily contracts.
    if (_contractType != 'Daily') {
      obligations += '''

2.2.3. Контролировать своевременные погашения коммунальных услуг со стороны арендатора.
''';
    }

    if (_contractType == 'Yearly') {
      obligations += '''
    
2.2.4. Попросить расторжение договора, если арендатор не уплачивает своевременно и в полном размере оплату аренды;
''';
    }

    // --- Section 2.3 with Dynamic Sub-clause Numbering ---
    obligations += '''

2.3. Арендодатель имеет право

2.3.1. Односторонне расторгнуть договор по следующим причинам:
''';

    int subClauseCounter = 1;

    // **FIX**: Clause 2.3.1.1 is now excluded for Daily contracts.
    if (_contractType != 'Daily') {
      obligations += '''

2.3.1.${subClauseCounter++}. При неуплате арендатором вовремя и/или в неполном размере месячной суммы аренды, а также при неуплате полученных коммунальных услуг;
''';
    }

    // The rest of the sub-clauses now use the dynamic counter to ensure correct numbering.
    obligations += '''

2.3.1.${subClauseCounter++}. При неуважительном отношении со стороны арендатора с соседями (при поступлении официальных жалоб с их стороны);

2.3.1.${subClauseCounter++}. При передаче квартиры в пользование третьему лицу;

2.3.1.${subClauseCounter++}. При привлечении на постоянной основе (больше трех дней) дополнительных сожителей;

2.3.1.${subClauseCounter++}. При заведении в квартиру других домашних питомцев (не указанных в договоре);

2.3.1.${subClauseCounter++}. При употреблении в квартире табачных или других веществ с резким запахом, кроме открытого пространства на балконе;

2.3.1.${subClauseCounter++}. При хранении в квартире легковоспламеняющих, взрывчатых или отравляющих веществ.

2.3.2. Односторонne расторгнуть договор при наступлении форс-мажора (пожар, взрыв, стихийное бедствие, военные действия, восстания, массовые волнения, война);
''';

    if (_contractType == 'Monthly' || _contractType == 'Yearly') {
      obligations += '''
    
2.3.3. Посещать арендуемую квартиру по предварительному уведомлению, но не более одного раза в месяц.

2.3.4. Ознакомить Аредатора с основными ограничениями пользования квартиры, которые в основном заключаются в следующем, в арендованной квартире запрещается культивация и производство наркотических, алкогольных и других химических и/или биологических веществ, а также устройство «Майнеров» и аналогичных устройств с высоким потреблением электричества и др.
''';
    } else {
      obligations += '''
    
2.3.3. Посещать арендуемую квартиру по предварительному уведомлению, но не более одного раза.

2.3.4. Ознакомить Аредатора с основными ограничениями пользования квартиры, которые в основном заключаются в следующем, в арендованной квартире запрещается культивация и производство наркотических, алкогольных и других химических и/или биологических веществ, а также устройство «Майнеров» и аналогичных устройств с высоким потреблением электричества и др.
''';
    }
    return obligations;
  }

  String _generateRussianPaymentTerms() {
    int clauseCounter = 1;

    String paymentTerms = '''
3. Способ оплаты и сумма оплаты
''';
    String typeTextRu = _contractType == 'Monthly' ? 'месячная' : 'посуточная';
    String deductionClauseRu = (_prePayed != '0' && _prePayed.isNotEmpty)
        ? ', с вычетом суммы уже выплаченного залога(пункт 3.4)'
        : '';
    String currencyTextRu = '';
    if (_sellingCurrency == 'აშშ დოლარის') {
      currencyTextRu = 'долларов США';
    } else if (_sellingCurrency == 'ქართული ლარის') {
      currencyTextRu = 'Грузинских Лари';
    }
    String formattedSummerStartDate = _formatDateRussian(_summerStartDate);
    String formattedSummerEndDate = _formatDateRussian(_summerEndDate);
    String prepaidAmountText = _manualPrepaidAmount.isNotEmpty ? _manualPrepaidAmount : '0.00';


    // --- Main Payment Clause ---
    if ((_contractType == 'Yearly') &&
        _summerMonthOption == 'იხდის') {

      // --- NEW LOGIC for dynamic Russian summer month clause ---
      final selectedMonthsGe = _selectedSummerMonths.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      const Map<String, String> monthTranslations = {
        'ივნისი': 'Июнь',
        'ივლისი': 'Июль',
        'აგვისტო': 'Август',
      };

      final selectedMonthsRu = selectedMonthsGe.map((geMonth) => monthTranslations[geMonth]!).toList();

      String summerMonthsClause = '';
      final summerPriceText = '${_sellingCurrency == 'აშშ დოლარის' ? '\$' : ''}${_effectivePriceSummer}${_sellingCurrency == 'ქართული ლარის' ? '₾' : ''}';

      if (selectedMonthsRu.isNotEmpty) {
        if (selectedMonthsRu.length == 1) {
          summerMonthsClause = 'а за ${selectedMonthsRu[0]} – $summerPriceText';
        } else if (selectedMonthsRu.length == 2) {
          summerMonthsClause = 'а за ${selectedMonthsRu[0]} – $summerPriceText и ${selectedMonthsRu[1]} – $summerPriceText';
        } else if (selectedMonthsRu.length == 3) {
          // Specific order for 3 months
          summerMonthsClause = 'а за Июнь – $summerPriceText, Июль – $summerPriceText и Август – $summerPriceText';
        }
        summerMonthsClause += ' (начиная с $formattedSummerStartDate и действует до $formattedSummerEndDate)';
      }
      // --- END of new logic ---


      paymentTerms += '''
3.${clauseCounter++}. На основе договора, месячная оплата аренды установлена в размере ${_sellingCurrency ==
          'აშშ დოლარის' ? '\$' : ''}$_price${_sellingCurrency == 'ქართული ლარის'
          ? '₾'
          : ''} $currencyTextRu, $summerMonthsClause. Арендатор предварительно платит сумму аренды за первый $_ruPricePeriodDet в размере ${_sellingCurrency ==
          'აშშ დოლარის' ? '\$' : ''}$prepaidAmountText${_sellingCurrency == 'ქართული ლარის'
          ? '₾'
          : ''} $currencyTextRu$deductionClauseRu;
''';
    } else if (_contractType == 'Yearly') {
      paymentTerms += '''
3.${clauseCounter++}. На основе договора, месячная оплата аренды установлена в размере $_price $currencyTextRu. Арендатор предварительно платит сумму аренды за первый $_ruPricePeriodDet, в размере $prepaidAmountText $currencyTextRu$deductionClauseRu;
''';
    } else {
      paymentTerms += '''
3.${clauseCounter++}. На основе договора, $typeTextRu оплата аренды установлена в размере $_price $currencyTextRu. Арендатор предварительно платит сумму аренды за весь период в размере $_priceFull $currencyTextRu$deductionClauseRu;
''';
    }

    // --- Subsequent Clauses ---
    paymentTerms += '''

3.${clauseCounter++}. Полная сумма аренды по договору составляет $_priceFull $currencyTextRu;

3.${clauseCounter++}. В случае, если арендатор нарушит условия договора, уплаченная им сумма за текущий месяц и предварительно выплаченная сумма аренды не возвращается;
''';

    // --- CONDITIONAL: Prepayment/Deposit Clause ---
    if (_prePayed != '0' && _prePayed.isNotEmpty) {
      paymentTerms += '''

3.${clauseCounter++}. Арендатор заплатил сумму залога $_prePayed $_ruPrePayedCurrency;
''';
    }

    // --- CONDITIONAL: Pet Deposit Clause ---
    if (_petsPayed != '0' && _petsPayed.isNotEmpty) {
      paymentTerms += '''
       
3.${clauseCounter++}. Арендатор передал Арендодателю сумму $_petsPayed $currencyTextRu, в виде депозита, как плату за возможный ущерб по истечении срока аренды квартиры, который подлежит возврату со стороны Арендодателя, при соблюдении Арендатором всех условии договора. Если ущерб превосходит сумму депозита, вопросы полностью регулируются согласно пунктам 2.1.8 и 2.1.10 настоящего договора.
''';
    }

    return paymentTerms;
  }

  String _generateRussianContractTerms() {
    String contractTerms = '''
4. Сроки договора
''';
    String formattedStartDate = _formatDateRussian(_startDate);
    DateTime? endDate = _calculateEndDate();
    String formattedEndDate = _formatDateRussian(endDate);

    if (_contractType == 'Monthly') {
      contractTerms += '''
4.1. Договор вступает в силу $formattedStartDate с 13:00 и действует в течение $_period ${int.parse(_period) == 1 ? 'календарного дня' : 'календарных дней'}, до $formattedEndDate 12:00;

4.2. Не исполнение обязательств, наложенных сторонам по договору, может служить безусловным прекращением договора;

4.3. Арендатор, в случае расторжения договора раньше срока, обязан уведомить арендодателя за 10 дней и оплатить аренду равной сумме месячной аренды квартиры. При этом, предварительно выплаченная арендодателю сумма аренды, арендатору не возвращается;

4.4. Арендодатель, в случае расторжения договора раньше срока, обязан уведомить арендатора за 10 дней. В таком случае, арендатор платит сумму в соответствии с прожитыми днями последнего месяца (месяц аренды считается 30 календарных дней). При этом, предварительно выплаченная арендодателю сумма за непрожитый(е) месяц(ы)/дней(и) аренды, арендатору возвращается;
''';
    } else if (_contractType == 'Yearly') {
      contractTerms += '''
4.1. Договор вступает в силу $formattedStartDate с 13:00 и действует в течение $_period месяцев, до $formattedEndDate 12:00;

4.2. Не исполнение обязательств, наложенных сторонам по договору, может служить безусловным прекращением договора;

4.3. Арендатор, в случае расторжения договора раньше срока, обязан уведомить арендодателя за 30 дней, и оплатить аренду равной сумме месячной аренды квартиры. При этом, предварительно выплаченная арендодателю сумма аренды, арендатору не возвращается;

4.4. Арендодатель, в случае расторжения договора раньше срока, обязан уведомить арендатора за 30 дней. В таком случае, арендатор платит сумму в соответствии с прожитыми днями последнего месяца (месяц аренды считается 30 календарных дней). При этом, предварительно выплаченная арендодателю сумма за непрожитый(е) месяц(ы)/дней(и) аренды, арендатору возвращается;
''';
    } else { // Daily
      contractTerms += '''
4.1. Договор вступает в силу $formattedStartDate с 12:00 и действует в течении $_period ${int.parse(_period) == 1 ? 'календарного дня' : 'календарных дней'}, до $formattedEndDate 12:00;

4.2. Не исполнение обязательств, наложенных сторонам по договору, может служить безусловным прекращением договора;

4.3. Арендатор, в случае расторжения договора раньше срока, обязан уведомить арендодателя за 5 дней. При этом, предварительно выплаченная арендодателю сумма аренды, арендатору не возвращается;

4.4. Арендодатель, в случае расторжения договора раньше срока, обязан уведомить арендатора за 5 дней. В таком случае, предварительно выплаченная арендодателю сумма за непрожитый(е) день(и) аренды, арендатору возвращается;
''';
    }

    String typeTextRu = _contractType == 'Monthly' || _contractType == 'Yearly'
        ? 'месячная'
        : '';

    // --- MODIFICATION START ---
    final String paymentInstructionRu = _paymentMethod == 'გადარიცხვა'
        ? 'должна быть зачислена на банковский счет Арендодателя $_bank $_ruBankName'
        : 'должна быть передана наличными Арендодателю';
    // --- MODIFICATION END ---

    if (_trPersonOption == 'კი') {
      if (_contractType == 'Daily') {
        contractTerms += '''
        
4.4. По обоюдному согласию сумма аренды $paymentInstructionRu. Если стоимость аренды не поступит на указанный счет в договорный срок или не будет передана наличными владельцу, то владелец имеет право в одностороннем порядке расторгнуть настоящий договор аренды.
''';
      } else {
        contractTerms += '''
        
4.5. По обоюдному согласию сумма аренды $paymentInstructionRu. Если стоимость аренды не поступит на указанный счет в договорный срок или не будет передана наличными владельцу, то владелец имеет право в одностороннем порядке расторгнуть настоящий договор аренды.
''';
      }
    } else {
      if (_contractType == 'Daily') {
        contractTerms += '''
        
4.4. По обоюдному согласию сумма аренды $paymentInstructionRu. Если стоимость аренды не поступит на указанный счет в договорный срок или не будет передана наличными владельцу, то владелец имеет право в одностороннем порядке расторгнуть настоящий договор аренды.
''';
      } else {
        contractTerms += '''
        
4.5. По обоюдному согласию сумма аренды $paymentInstructionRu. Если стоимость аренды не поступит на указанный счет в договорный срок или не будет передана наличными владельцу, то владелец имеет право в одностороннем порядке расторгнуть настоящий договор аренды.
''';
      }
    }
    return contractTerms;
  }

  String _generateRussianAdditionalTerms() {
    return '''
5. Заключительное положение

5.1. Вопросы, которые не регулируются данным договором, решаются действующим законодательством Грузии, в судебном порядке;

5.2. Стороны освобождаются от взаимных обязательств при наступлении форс-мажора;

5.3. Любые дополнения или изменения связанные с данным договором, оформляются в письменном виде и подписываются сторонами;

5.4. Договор составлен в 2-х экземплярах и имеют одинаковую юридическую силу.
''';
  }

  String _generateRussianSignatures() {
    return '''
6. Юридические адреса сторон и реквизиты

6.1. Арендодатель:

$_ruNameGive

л/н: $_pnGive

Подпись: ____________________

6.2. Арендатор:

${_idTakeType == 'პასპორტი' ? 'Паспорт' : 'л/н'} $_idTakeNum

Подпись: ____________________
''';
  }

  // Helper method for the full Russian contract (for fallback)
  String _generateRussianContract() {
    return [
      _generateRussianHeader(),
      _generateRussianSubject(),
      _generateRussianObligations(),
      _generateRussianPaymentTerms(),
      _generateRussianContractTerms(),
      _generateRussianAdditionalTerms(),
      _generateRussianSignatures(),
    ].join('\n\n');
  }
}