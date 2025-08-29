import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realtor_app/contract_form_screen.dart';
import 'package:realtor_app/apartment_list_screen.dart';
import 'package:realtor_app/invoice_generator_screen.dart';
import 'package:realtor_app/profit_calculator_screen.dart';
import 'package:realtor_app/data/app_data.dart';
import 'package:realtor_app/ongoing_booked_apartments.dart';

// IMPROVED: Better web-specific functionality
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _buttonAnimationController;
  final Color primaryColor = const Color(0xFF004aad);

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    // IMPROVED: Simplified web-specific logic
    if (kIsWeb) {
      _setupWebPreventions();
    }
  }

// The fix: Add a check to prevent the context menu only on non-input elements.
  void _setupWebPreventions() {
    html.document.body!.addEventListener('contextmenu', (event) {
      if (event.target is! html.InputElement && event.target is! html.TextAreaElement) {
        event.preventDefault();
      }
    });
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Completely prevent back navigation
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Logo with gentle scale animation
              Padding(
                padding: const EdgeInsets.only(top: 40.0, bottom: 40.0),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  scale: 1.0,
                  child: Image.asset(
                    'assets/logo/LOGO1.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Main buttons
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimatedButton(
                        context,
                        icon: Icons.apartment,
                        label: 'ბინების სია',
                        delay: 0,
                        destination: const ApartmentListScreen(),
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedButton(
                        context,
                        icon: Icons.bookmark,
                        label: 'მიმდინარე გაქირავებები',
                        delay: 100,
                        destination: const OngoingBookedApartmentsScreen(),
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedButton(
                        context,
                        icon: Icons.receipt_long,
                        label: 'ინვოისის შედგენა',
                        delay: 200,
                        destination: const InvoiceGeneratorScreen(),
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedButton(
                        context,
                        icon: Icons.assignment,
                        label: 'ხელშეკრულების შედგენა',
                        delay: 300,
                        destination: const ContractFormScreen(),
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedButton(
                        context,
                        icon: Icons.calculate,
                        label: 'მოგების დათვლა',
                        delay: 400,
                        destination: const ProfitCalculatorScreen(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required int delay,
        required Widget destination,
      }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _buttonAnimationController,
          curve: Interval(
            delay / 1000,
            1.0,
            curve: Curves.easeOutBack,
          ),
        ),
      ),
      child: TapFeedbackButton(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => destination,
            ),
          );
        },
        child: SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 36,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TapFeedbackButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const TapFeedbackButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<TapFeedbackButton> createState() => _TapFeedbackButtonState();
}

class _TapFeedbackButtonState extends State<TapFeedbackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isPressed ? 0.97 : 1.0,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}