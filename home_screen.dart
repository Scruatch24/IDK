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

    // IMPROVED: More comprehensive web-specific logic to disable back swipe
    if (kIsWeb) {
      _setupWebBackPrevention();
    }
  }

  void _setupWebBackPrevention() {
    // Method 1: CSS-based prevention (most effective for iOS PWA)
    _injectPreventionCSS();

    // Method 2: Multiple history entries buffer
    _createHistoryBuffer();

    // Method 3: Multiple event listeners for comprehensive coverage
    _setupEventListeners();

    // Method 4: Periodic history state management
    _setupPeriodicHistoryManagement();
  }

  void _injectPreventionCSS() {
    // Inject CSS that prevents pull-to-refresh and swipe gestures
    final style = html.StyleElement();
    style.text = '''
      body {
        overscroll-behavior: none;
        -webkit-overflow-scrolling: touch;
        overflow-x: hidden;
        position: fixed;
        width: 100%;
        height: 100%;
      }
      
      html {
        overscroll-behavior: none;
        overflow-x: hidden;
      }
      
      * {
        -webkit-touch-callout: none;
        -webkit-user-select: none;
        -webkit-tap-highlight-color: transparent;
        overscroll-behavior-x: none;
      }
      
      /* Specifically target iOS PWA */
      @media (display-mode: standalone) {
        body, html {
          overscroll-behavior: none;
          overflow-x: hidden;
          position: fixed;
        }
      }
    ''';
    html.document.head?.append(style);
  }

  void _createHistoryBuffer() {
    // Create multiple history entries to provide a larger buffer
    for (int i = 0; i < 5; i++) {
      html.window.history.pushState({
        'preventBack': true,
        'buffer': i,
        'timestamp': DateTime.now().millisecondsSinceEpoch
      }, '', html.window.location.href);
    }
  }

  void _setupEventListeners() {
    // Primary popstate handler
    html.window.addEventListener('popstate', _handlePopState, true);

    // Additional event listeners for comprehensive coverage
    html.window.addEventListener('beforeunload', _handleBeforeUnload, true);
    html.document.addEventListener('touchstart', _handleTouchStart, true);
    html.document.addEventListener('touchmove', _handleTouchMove, true);

    // Handle hash changes
    html.window.addEventListener('hashchange', _handleHashChange, true);
  }

  void _setupPeriodicHistoryManagement() {
    // Periodically ensure we have enough history entries
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && kIsWeb) {
        _maintainHistoryBuffer();
        _setupPeriodicHistoryManagement();
      }
    });
  }

  void _maintainHistoryBuffer() {
    // Ensure we always have a buffer of history entries
    final currentState = html.window.history.state;
    if (currentState == null ||
        (currentState is Map && currentState['preventBack'] != true)) {
      html.window.history.pushState({
        'preventBack': true,
        'maintained': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch
      }, '', html.window.location.href);
    }
  }

  void _handlePopState(html.Event event) {
    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();

    // Immediately restore the current state
    html.window.history.pushState({
      'preventBack': true,
      'restored': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    }, '', html.window.location.href);

    // Force a small delay to ensure the state is properly set
    Future.delayed(const Duration(milliseconds: 10), () {
      if (mounted) {
        html.window.history.pushState({
          'preventBack': true,
          'double_restored': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch
        }, '', html.window.location.href);
      }
    });
  }

  void _handleBeforeUnload(html.Event event) {
    event.preventDefault();
    // This helps prevent navigation in some cases
  }

  void _handleTouchStart(html.Event event) {
    if (event is html.TouchEvent) {
      final touch = event.touches?.first;
      if (touch != null && touch.client.x < 20) {
        // Touch started near the left edge - potential swipe gesture
        event.preventDefault();
        event.stopPropagation();
      }
    }
  }

  void _handleTouchMove(html.Event event) {
    if (event is html.TouchEvent) {
      final touch = event.touches?.first;
      if (touch != null && touch.client.x < 50) {
        // Touch is moving near the left edge - likely swipe gesture
        event.preventDefault();
        event.stopPropagation();
      }
    }
  }

  void _handleHashChange(html.Event event) {
    event.preventDefault();
    // Restore the current URL without hash changes
    html.window.history.replaceState(null, '', html.window.location.pathname);
  }

  @override
  void dispose() {
    // Clean up all web-specific listeners
    if (kIsWeb) {
      html.window.removeEventListener('popstate', _handlePopState, true);
      html.window.removeEventListener('beforeunload', _handleBeforeUnload, true);
      html.document.removeEventListener('touchstart', _handleTouchStart, true);
      html.document.removeEventListener('touchmove', _handleTouchMove, true);
      html.window.removeEventListener('hashchange', _handleHashChange, true);
    }
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Enhanced WillPopScope to handle multiple back scenarios
    return WillPopScope(
      onWillPop: () async {
        // For web, we've already handled prevention
        // For mobile, prevent back navigation
        if (kIsWeb) {
          _maintainHistoryBuffer();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Center(
            child: Image.asset(
              'assets/logo/LOGO.png',
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          centerTitle: true,
          backgroundColor: primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          automaticallyImplyLeading: false, // Prevent back button in app bar
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Logo with gentle scale animation
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  scale: 1.0,
                  child: Image.asset(
                    'assets/logo/LOGO.png',
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
                        label: 'გაქირავებული ბინები',
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
          // Enhanced navigation with web-specific handling
          if (kIsWeb) {
            // Ensure history buffer before navigation
            _maintainHistoryBuffer();
          }
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