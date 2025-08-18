import 'package:flutter/material.dart';
import 'package:realtor_app/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:realtor_app/data/app_data.dart';
import 'package:realtor_app/firebase_options.dart';

// --- ADD THESE IMPORTS ---
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
// -------------------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- INITIALIZE GEORGIAN DATE FORMATTING ---
  await initializeDateFormatting('ka_GE', null);
  // -------------------------------------------

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Verify Firebase Auth is ready
    await _initializeAuth();

    runApp(
      ChangeNotifierProvider(
        create: (context) => FirestoreService(),
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('FATAL ERROR: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Initialization Error', style: TextStyle(fontSize: 24)),
                Text(e.toString(), style: const TextStyle(color: Colors.red)),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _initializeAuth() async {
  try {
    // Sign out any existing user
    await FirebaseAuth.instance.signOut();

    // Sign in anonymously with timeout
    final user = await FirebaseAuth.instance.signInAnonymously()
        .timeout(const Duration(seconds: 10));

    print('Signed in with UID: ${user.user?.uid}');
  } on FirebaseAuthException catch (e) {
    print('Auth Exception: ${e.code} - ${e.message}');
    rethrow;
  } catch (e) {
    print('General Auth Error: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define your primary color for reuse in the theme
    const Color primaryBlue = Color(0xFF004aad);

    return MaterialApp(
      title: 'SophiaHome',

      // --- ADD THIS THEME DATA ---
      theme: ThemeData(
        primaryColor: primaryBlue,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
        textSelectionTheme: const TextSelectionThemeData(
          // This sets the blinking cursor color
          cursorColor: primaryBlue,
          // By removing selectionColor and selectionHandleColor,
          // Flutter will use the default system colors for these properties.
        ),
      ),
      // -----------------------------

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('ka', 'GE'), // Georgian
      ],
      locale: const Locale('ka', 'GE'), // Set Georgian as the default locale
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Authentication Error'),
                    Text(snapshot.error.toString()),
                    ElevatedButton(
                      onPressed: () => _initializeAuth(),
                      child: const Text('Retry Auth'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const HomeScreen();
        },
      ),
    );
  }
}
