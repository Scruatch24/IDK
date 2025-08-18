// lib/screens/add_apartment_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // ADD this import for Georgian dates
import 'package:realtor_app/data/app_data.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui'; // Needed for lerpDouble
import 'package:dropdown_search/dropdown_search.dart';

class AddApartmentScreen extends StatefulWidget {
  const AddApartmentScreen({super.key});

  @override
  State<AddApartmentScreen> createState() => _AddApartmentScreenState();
}

class _AddApartmentScreenState extends State<AddApartmentScreen> {
  List<Owner> _allOwners = [];
  Owner? _selectedOwner;
  late final Owner _addNewOwnerOption;
  bool _isProgrammaticChange = false;
  String _selectedCity = 'ბათუმი';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerNameRuController = TextEditingController();
  final TextEditingController _ownerNumberController = TextEditingController();
  final TextEditingController _geAddressController = TextEditingController();
  final TextEditingController _ruAddressController = TextEditingController();
  final TextEditingController _dailyPriceController = TextEditingController();
  final TextEditingController _monthlyPriceController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _squareMetersController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _microDistrictController = TextEditingController();
  final TextEditingController _districtRuController = TextEditingController();
  final TextEditingController _microDistrictRuController = TextEditingController();
  final TextEditingController _ownerIDController = TextEditingController();
  final TextEditingController _ownerBDController = TextEditingController();
  final TextEditingController _ownerBankController = TextEditingController();
  final TextEditingController _ownerBankNameController = TextEditingController();
  DateTime? _ownerBirthDate;

  // --- FocusNodes and Dominance flags for animated text fields ---
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


  final Color primaryColor = const Color(0xFF004aad);

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
    _scrollController.dispose();
    _descriptionController.dispose();
    _districtController.dispose();
    _microDistrictController.dispose();
    _districtRuController.dispose();
    _microDistrictRuController.dispose();
    _ownerIDController.dispose();
    _ownerBDController.dispose();
    _ownerBankController.dispose();
    _ownerBankNameController.dispose();

    // Dispose FocusNodes
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

    String gePrefixToAdd = _selectedCity == 'ბათუმი' ? 'ქ. ბათუმი, ' : 'ქ. თბილისი, ';
    String ruPrefixToAdd = _selectedCity == 'ბათუმი' ? 'г. Батуми, ' : 'г. Тбилиси, ';

    _geAddressController.text = gePrefixToAdd + cleanGeAddress;
    _ruAddressController.text = ruPrefixToAdd + cleanRuAddress;
  }

  Widget _buildImageGrid() {
    if (_selectedImages.isEmpty && !_isUploading) {
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
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + (_isUploading ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isUploading && index == _selectedImages.length) {
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final imageFile = _selectedImages[index];
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
                      child: FutureBuilder<Uint8List>(
                        future: imageFile.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          }
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImages.remove(imageFile)),
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
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
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
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
          _selectedImages.addAll(pickedFiles);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('სურათების არჩევის შეცდომა: $e')),
        );
      }
    }
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

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
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
  final List<String> _bankOptions = [
    'საქართველოს ბანკი',
    'თი-ბი-სი ბანკი',
    'ლიბერთი ბანკი',
    'ბაზის ბანკი',
    'ტერა ბანკი'
  ];
  String? _selectedBank;

  late Apartment _apartment;
  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String _seaView = 'არა';
  String? _selectedSeaLine;
  String? _selectedRooms;
  String? _selectedBedrooms;
  String? _selectedBalcony;
  String? _selectedTerrace;
  String? _selectedBathroom;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ka_GE'); // Initialize Georgian locale data

    // --- Initialize Owner Dropdown ---
    _addNewOwnerOption = Owner(id: 'add_new', name: 'ახლის დამატება');
    _selectedOwner = _addNewOwnerOption;
    _fetchOwners();


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

    // --- Setup Focus Listeners ---
    void setupFocusListeners(FocusNode geNode, FocusNode ruNode, Function(bool) updateDominance) {
      geNode.addListener(() {
        if (geNode.hasFocus) setState(() => updateDominance(false));
      });
      ruNode.addListener(() {
        if (ruNode.hasFocus) setState(() => updateDominance(true));
      });
    }
    setupFocusListeners(_geOwnerNameFocusNode, _ruOwnerNameFocusNode, (isRuDominant) => _isRuOwnerNameDominant = isRuDominant);
    setupFocusListeners(_geAddressFocusNode, _ruAddressFocusNode, (isRuDominant) => _isRuAddressDominant = isRuDominant);
    setupFocusListeners(_geDistrictFocusNode, _ruDistrictFocusNode, (isRuDominant) => _isRuDistrictDominant = isRuDominant);
    setupFocusListeners(_geMicroDistrictFocusNode, _ruMicroDistrictFocusNode, (isRuDominant) => _isRuMicroDistrictDominant = isRuDominant);


    _apartment = Apartment(
      id: '',
      ownerId: '',
      ownerName: '',
      geAddress: '',
      ruAddress: '',
      district: '',
      microDistrict: '',
      districtRu: '',
      microDistrictRu: '',
      seaView: 'არა',
      seaLine: 'პირველი ზოლი',
      geAppRoom: '3-ოთახიანი',
      geAppBedroom: '1-საძინებლიანი',
      balcony: '1 აივანი',
      terrace: 'ტერასის გარეშე',
      bathrooms: '1 სველი წერტილი',
      description: '',
      hasAC: true, // Amenity default
      hasElevator: true, // Amenity default
      hasInternet: true, // Amenity default
      hasWiFi: true, // Amenity default
      warmWater: true,
    );
    _selectedBank = _bankOptions[0];
    _selectedSeaLine = _seaLineOptions[0];
    _selectedRooms = _roomOptions[2];
    _selectedBedrooms = _bedroomOptions[1];
    _selectedBalcony = _balconyOptions[1];
    _selectedTerrace = _terraceOptions[0];
    _selectedBathroom = _bathroomOptions[0];
    _geAddressController.text = 'ქ. ბათუმი, ';
    _ruAddressController.text = 'г. Батуми, ';
  }

  void _handleManualFieldChange() {
    // If a change happens and it's not programmatic, reset the dropdown.
    if (!_isProgrammaticChange && _selectedOwner != _addNewOwnerOption) {
      setState(() {
        _selectedOwner = _addNewOwnerOption;
      });
    }
  }

  void _fetchOwners() async {
    // Use context.read to get the service once
    final owners = await context.read<FirestoreService>().getOwners().first;
    if (mounted) {
      setState(() {
        _allOwners = owners;
      });
    }
  }

  void _onOwnerSelected(Owner? owner) {
    if (owner == null) return;

    setState(() {
      _isProgrammaticChange = true; // Prevent listeners from firing
      _selectedOwner = owner;

      if (owner.id == 'add_new') {
        // Clear all fields if "Add New" is selected
        _ownerNameController.clear();
        _ownerNameRuController.clear();
        _ownerNumberController.clear();
        _ownerIDController.clear();
        _ownerBDController.clear();
        _ownerBankController.clear();
        _ownerBankNameController.clear();
        _ownerBirthDate = null;
        _selectedBank = _bankOptions[0];
      } else {
        // Auto-fill fields with selected owner's data
        _ownerNameController.text = owner.name;
        _ownerNameRuController.text = owner.nameRu;
        _ownerNumberController.text = owner.ownerNumber;
        _ownerIDController.text = owner.ownerID;
        _ownerBDController.text = owner.ownerBD;
        _ownerBankController.text = owner.ownerBank;
        _ownerBankNameController.text = owner.ownerBankName;
        _selectedBank = _bankOptions.contains(owner.ownerBankName) ? owner.ownerBankName : _bankOptions[0];
        if (owner.ownerBD.isNotEmpty) {
          try {
            _ownerBirthDate = DateFormat('dd/MMM/yyyy', 'ka_GE').parse(owner.ownerBD);
          } catch (e) {
            _ownerBirthDate = null;
          }
        } else {
          _ownerBirthDate = null;
        }
      }

      // Use addPostFrameCallback to reset the flag after the build cycle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isProgrammaticChange = false;
      });
    });
  }

  void _setupOwnerFieldListeners() {
    void listener() {
      if (!_isProgrammaticChange && _selectedOwner != _addNewOwnerOption) {
        setState(() {
          _selectedOwner = _addNewOwnerOption;
        });
      }
    }

    _ownerNameController.addListener(listener);
    _ownerNameRuController.addListener(listener);
    _ownerNumberController.addListener(listener);
    _ownerIDController.addListener(listener);
    _ownerBDController.addListener(listener);
    _ownerBankController.addListener(listener);
    _ownerBankNameController.addListener(listener);
    // Note: We'll check _ownerBirthDate and _selectedBank directly where they are changed
  }

  Future<void> _saveApartment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('გთხოვთ დაამატოთ მინიმუმ ერთი სურათი')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
    });

    try {
      final String finalGeAddress = _geAddressController.text.trim();
      final String finalRuAddress = _ruAddressController.text.trim();

      final List<String> imageUrls = [];

      for (final imageFile in _selectedImages) {
        try {
          final url = await _uploadImage(imageFile, finalGeAddress);
          imageUrls.add(url);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('სურათის ატვირთვა ვერ მოხერხდა: ${e.toString()}')),
            );
          }
          setState(() {
            _isLoading = false;
            _isUploading = false;
          });
          return;
        }
      }

      final newApartment = Apartment(
        city: _selectedCity,
        id: finalGeAddress,
        ownerId: 'owner_${DateTime.now().millisecondsSinceEpoch}',
        ownerName: _ownerNameController.text.trim(),
        ownerNameRu: _ownerNameRuController.text.trim(),
        ownerNumber: _ownerNumberController.text.trim(),
        ownerID: _ownerIDController.text.trim(),
        ownerBD: _ownerBDController.text.trim(),
        ownerBank: _ownerBankController.text.trim(),
        ownerBankName: _ownerBankNameController.text.trim(),
        description: _descriptionController.text.trim(),
        district: _districtController.text.trim(),
        microDistrict: _microDistrictController.text.trim(),
        districtRu: _districtRuController.text.trim(),
        microDistrictRu: _microDistrictRuController.text.trim(),
        geAddress: finalGeAddress,
        ruAddress: finalRuAddress,
        seaView: _seaView,
        seaLine: _selectedSeaLine ?? 'პირველი ზოლი',
        geAppRoom: _selectedRooms ?? '1-ოთახიანი',
        geAppBedroom: _selectedBedrooms ?? '1-საძინებლიანი',
        balcony: _selectedBalcony ?? 'აივნის გარეშე',
        terrace: _selectedTerrace ?? 'ტერასის გარეშე',
        bathrooms: _selectedBathroom ?? '1 სველი წერტილი',
        dailyPrice: double.tryParse(_dailyPriceController.text) ?? 0,
        monthlyPrice: double.tryParse(_monthlyPriceController.text) ?? 0,
        peopleCapacity: int.tryParse(_capacityController.text) ?? 1,
        squareMeters: double.tryParse(_squareMetersController.text) ?? 0,
        imageUrls: imageUrls,
        hasAC: _apartment.hasAC,
        hasElevator: _apartment.hasElevator,
        hasInternet: _apartment.hasInternet,
        hasWiFi: _apartment.hasWiFi,
        warmWater: _apartment.warmWater,
        tags: _tagsController.text.split(',').map((e) => e.trim()).toList(),
      );

      await Provider.of<FirestoreService>(context, listen: false)
          .saveApartment(newApartment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ბინა წარმატებით დაემატა!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ბინის შენახვა ვერ მოხერხდა: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }
  // --- Reusable Widget Builders ---

  // Helper to build the custom dropdown item with icon and divider
// Helper to build the custom dropdown item with icon and divider
// Helper to build the custom dropdown item with icon and divider
  Widget _customPopupItemBuilder(BuildContext context, Owner owner, bool isSelected) {
    if (owner.id == 'add_new') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(Icons.add_circle, color: primaryColor),
                const SizedBox(width: 12),
                Text(owner.name),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
        ],
      );
    }
    // Updated part for regular owner items
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Text('${owner.name} - ${owner.ownerNumber}'),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          color: primaryColor.withOpacity(0.5),
          // --- ADD these properties to create side margins ---
          indent: 35,
          endIndent: 35,
        ),
      ],
    );
  }

  // Helper to build the widget shown when the dropdown is closed
  Widget _customDropdownBuilder(BuildContext context, Owner? owner) {
    if (owner == null) {
      return const Text('');
    }
    if (owner.id == 'add_new') {
      return Row(
        children: [
          Icon(Icons.add_circle, color: primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(owner.name),
        ],
      );
    }
    return Text('${owner.name} - ${owner.ownerNumber}');
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
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
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
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
                    onChanged: onChanged,
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
                    onChanged: onChanged,
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
    void Function(String)? onChanged, // ADD THIS
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      minLines: minLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(
          color: primaryColor,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          color: primaryColor,
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
          borderSide: BorderSide(color: primaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                fontSize: 14,
              ),
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
          locale: const Locale('ka', 'GE'), // Set Georgian Locale for Calendar
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
              child: Transform.scale( // Scale the calendar pop up
                scale: 1.2,
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
          labelStyle: TextStyle(
            color: primaryColor,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.grey.shade50,
          suffixIcon: Icon(Icons.calendar_today, color: primaryColor, size: 20),
        ),
        child: Text(
          selectedDate != null
              ? DateFormat('dd/MMM/yyyy', 'ka_GE').format(selectedDate) // Use Georgian date format
              : 'აირჩიეთ თარიღი',
          style: TextStyle(
            fontSize: 14,
            color: selectedDate == null ? Colors.grey.shade600 : Colors.black87,
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
              child: value
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
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
          'ახალი ბინის დამატება',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveApartment,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildSectionHeader('მეპატრონის ინფორმაცია'),
              DropdownSearch<Owner>(
                selectedItem: _selectedOwner,
                items: [_addNewOwnerOption, ..._allOwners],
                onChanged: _onOwnerSelected,

                // ADD THIS LINE
                itemAsString: (Owner owner) => '${owner.name} - ${owner.ownerNumber}',

                dropdownBuilder: _customDropdownBuilder,
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  // REMOVE filterFn FROM HERE
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "მეპატრონის ძებნა...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  fit: FlexFit.loose,
                  itemBuilder: _customPopupItemBuilder,
                ),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: 'მეპატრონის არჩევა',
                    labelStyle: TextStyle(
                      color: primaryColor,
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
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                  },
                  onChanged: (_) => _handleManualFieldChange(),
              ),
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
                onChanged: (_) => _handleManualFieldChange(),
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _ownerIDController,
                labelText: 'პირადი ნომერი',
                onChanged: (_) => _handleManualFieldChange(),
              ),
              const SizedBox(height: 16),
              _buildModernDatePicker(
                label: 'მეპატრონის დაბადების თარიღი',
                selectedDate: _ownerBirthDate,
                onDateSelected: (date) {
                  _handleManualFieldChange();
                  setState(() {
                    if (!_isProgrammaticChange && _selectedOwner != _addNewOwnerOption) {
                      _selectedOwner = _addNewOwnerOption;
                    }
                    _ownerBirthDate = date;
                    _ownerBDController.text = DateFormat('dd/MMM/yyyy', 'ka_GE').format(date);
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildModernDropdown<String>(
                label: 'ბანკი',
                items: _bankOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                value: _selectedBank!,
                onChanged: (value) {
                  _handleManualFieldChange();
                  setState(() {
                    if (!_isProgrammaticChange && _selectedOwner != _addNewOwnerOption) {
                      _selectedOwner = _addNewOwnerOption;
                    }
                    _selectedBank = value;
                    _ownerBankNameController.text = value ?? '';
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _ownerBankController,
                labelText: 'ბანკის ანგარიში ნომერი',
                onChanged: (_) => _handleManualFieldChange(),
              ),
              const SizedBox(height: 24),

              _buildSectionHeader('ბინის ფოტოები'),
              _buildImageGrid(),
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
                  geLabel: 'რაიონი (ქართულად)*',
                  ruLabel: '(რუსულად)',
                  geFocusNode: _geDistrictFocusNode,
                  ruFocusNode: _ruDistrictFocusNode,
                  isRuDominant: _isRuDistrictDominant,
                  validator: (value) {
                    if (_selectedCity == 'თბილისი' && (value == null || value.isEmpty)) {
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
                  ruLabel: '(რუსულად)',
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
                  items: _seaLineOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                  value: _selectedSeaLine!,
                  onChanged: (value) => setState(() => _selectedSeaLine = value),
                ),
                const SizedBox(height: 16),
                _buildModernDropdown<String>(
                  label: 'ზღვის ხედი',
                  value: _seaView,
                  items: ['კი', 'არა'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
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
                items: _roomOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                value: _selectedRooms!,
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
                items: _bedroomOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                value: _selectedBedrooms!,
                onChanged: _selectedRooms == 'სტუდიო'
                    ? null
                    : (value) => setState(() => _selectedBedrooms = value ?? '1-საძინებლიანი'),
              ),
              const SizedBox(height: 16),
              _buildModernDropdown<String>(
                label: 'სველი წერტილი',
                items: _bathroomOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                value: _selectedBathroom!,
                onChanged: (value) => setState(() => _selectedBathroom = value),
              ),
              const SizedBox(height: 16),
              _buildModernDropdown<String>(
                label: 'აივანი',
                items: _balconyOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                value: _selectedBalcony!,
                onChanged: (value) => setState(() => _selectedBalcony = value),
              ),
              const SizedBox(height: 16),
              _buildModernDropdown<String>(
                label: 'ტერასა',
                items: _terraceOptions.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                value: _selectedTerrace!,
                onChanged: (value) => setState(() => _selectedTerrace = value),
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _squareMetersController,
                labelText: 'კვადრატული მეტრი',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'გთხოვთ შეიყვანოთ კვადრატული მეტრი';
                  if (double.tryParse(value) == null) return 'გთხოვთ შეიყვანოთ კორექტული რიცხვი';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _capacityController,
                labelText: 'მაქს. სტუმრების რაოდენობა',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'გთხოვთ შეიყვანოთ მაქს. სტუმრების რაოდენობა';
                  if (int.tryParse(value) == null) return 'გთხოვთ შეიყვანოთ კორექტული რიცხვი';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCircularCheckbox(
                      title: 'კონდიციონერი',
                      value: _apartment.hasAC,
                      onChanged: (value) => setState(() => _apartment.hasAC = value ?? false),
                    ),
                  ),
                  Expanded(
                    child: _buildCircularCheckbox(
                      title: 'ლიფტი',
                      value: _apartment.hasElevator,
                      onChanged: (value) => setState(() => _apartment.hasElevator = value ?? false),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildCircularCheckbox(
                      title: 'ცხელი წყალი',
                      value: _apartment.warmWater,
                      onChanged: (value) => setState(() => _apartment.warmWater = value ?? false),
                    ),
                  ),
                  Expanded(
                    child: _buildCircularCheckbox(
                      title: 'Wi-Fi',
                      value: _apartment.hasWiFi,
                      onChanged: (value) {
                        setState(() {
                          _apartment.hasWiFi = value ?? false;
                          _apartment.hasInternet = value ?? false;
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
                  if (value == null || value.isEmpty) return 'გთხოვთ შეიყვანოთ დღიური ფასი';
                  if (double.tryParse(value) == null) return 'გთხოვთ შეიყვანოთ კორექტული რიცხვი';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _monthlyPriceController,
                labelText: 'ყოველთვიური ფასი (\$)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'გთხოვთ შეიყვანოთ თვიური ფასი';
                  if (double.tryParse(value) == null) return 'გთხოვთ შეიყვანოთ კორექტული რიცხვი';
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