import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfitCalculatorScreen extends StatefulWidget {
  const ProfitCalculatorScreen({super.key});

  @override
  State<ProfitCalculatorScreen> createState() => _ProfitCalculatorScreenState();
}

class _ProfitCalculatorScreenState extends State<ProfitCalculatorScreen> {
  final Color primaryColor = const Color(0xFF004aad);
  final Color backgroundColor = Colors.white;
  final TextStyle headerStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );
  final TextStyle inputLabelStyle = const TextStyle(
    color: Colors.black54,
    fontSize: 14,
  );

  // State variables
  String _hasPartner = 'კი'; // 'კი' or 'არა'
  final TextEditingController _periodController = TextEditingController();
  final TextEditingController _pricePerPeriodController = TextEditingController();
  final TextEditingController _addedPriceController = TextEditingController();

  // Calculated values
  double _ownerAmount = 0.0;
  double _ourAmount = 0.0;
  double _myAmount = 0.0;
  double _partnerAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _periodController.addListener(_calculateProfit);
    _pricePerPeriodController.addListener(_calculateProfit);
    _addedPriceController.addListener(_calculateProfit);
  }

  @override
  void dispose() {
    _periodController.dispose();
    _pricePerPeriodController.dispose();
    _addedPriceController.dispose();
    super.dispose();
  }

  void _calculateProfit() {
    final double period = double.tryParse(_periodController.text) ?? 0.0;
    final double pricePerPeriod = double.tryParse(_pricePerPeriodController.text) ?? 0.0;
    final double addedPrice = double.tryParse(_addedPriceController.text) ?? 0.0;

    final double totalPrice = pricePerPeriod * period;

    setState(() {
      _ownerAmount = totalPrice - (addedPrice * period);
      _ourAmount = addedPrice * period;

      if (_hasPartner == 'კი') {
        _myAmount = _ourAmount / 2;
        _partnerAmount = _ourAmount / 2;
      } else {
        _myAmount = _ourAmount;
        _partnerAmount = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'მოგების დათვლა',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Partner question
            _buildSectionHeader('გყავთ მეწილე?'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPartnerToggle(
                    label: 'კი',
                    isActive: _hasPartner == 'კი',
                    onTap: () {
                      setState(() {
                        _hasPartner = 'კი';
                        _calculateProfit();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPartnerToggle(
                    label: 'არა',
                    isActive: _hasPartner == 'არა',
                    onTap: () {
                      setState(() {
                        _hasPartner = 'არა';
                        _calculateProfit();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Price section
            _buildSectionHeader('მოგება'),
            const SizedBox(height: 16),

            // Period input
            _buildModernTextField(
              controller: _periodController,
              label: 'პერიოდი',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Price per period input
            _buildModernTextField(
              controller: _pricePerPeriodController,
              label: 'ერთი პერიოდის ფასი',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),

            // Added price input
            _buildModernTextField(
              controller: _addedPriceController,
              label: 'დამატებული ფასი (1 პერიოდზე)',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 32),

            // Distribution title
            if (_periodController.text.isNotEmpty &&
                _pricePerPeriodController.text.isNotEmpty &&
                _addedPriceController.text.isNotEmpty)
              Center(
                child: Text(
                  'განაწილება',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Animated results
            if (_periodController.text.isNotEmpty &&
                _pricePerPeriodController.text.isNotEmpty &&
                _addedPriceController.text.isNotEmpty)
              _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final double period = double.tryParse(_periodController.text) ?? 0.0;
    final double pricePerPeriod = double.tryParse(_pricePerPeriodController.text) ?? 0.0;
    final double totalPrice = pricePerPeriod * period;

    return Column(
      children: [
        // Total price display
        _buildAnimatedAmountCard(
          label: 'სულ',
          amount: totalPrice,
          icon: Icons.calculate,
          isTotal: true,
        ),
        const SizedBox(height: 16),

        // Owner amount
        _buildAnimatedAmountCard(
          label: 'მეპატრონეს',
          amount: _ownerAmount,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),

        // Our amount (or split amounts if partner exists)
        if (_hasPartner == 'არა')
          _buildAnimatedAmountCard(
            label: 'მე',
            amount: _ourAmount,
            icon: Icons.person,
          )
        else
          Column(
            children: [
              _buildAnimatedAmountCard(
                label: 'მე',
                amount: _myAmount,
                icon: Icons.person,
              ),
              const SizedBox(height: 8),
              _buildAnimatedAmountCard(
                label: 'მეწილეს',
                amount: _partnerAmount,
                icon: Icons.person_outline,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAnimatedAmountCard({
    required String label,
    required double amount,
    required IconData icon,
    bool isTotal = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isTotal ? primaryColor.withOpacity(0.2) : primaryColor.withOpacity(0.2),
          width: isTotal ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isTotal ? Color(0xFF004aad) : primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isTotal ? Color(0xFF004aad) : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '${amount.toStringAsFixed(2)} ₾',
                    key: ValueKey<double>(amount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isTotal ? Color(0xFF004aad) : primaryColor,
                    ),
                  ),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: headerStyle,
    );
  }

  Widget _buildPartnerToggle({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: inputLabelStyle.copyWith(color: primaryColor), // Changed this line
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
}