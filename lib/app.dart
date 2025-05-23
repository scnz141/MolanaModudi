import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/features/settings/presentation/providers/settings_provider.dart';
import 'package:modudi/core/themes/app_theme.dart';
import 'package:modudi/core/l10n/l10n.dart';
import 'package:modudi/routes/app_router.dart'; // Import the router
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:firebase_core/firebase_core.dart';

final _log = Logger('MyApp');

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access settings for theme mode and language
    final settings = ref.watch(settingsProvider);
    
    _log.info('Building app with theme: ${settings.themeMode}, language: ${settings.language}, fontSize: ${settings.fontSize}');
    
    // Create theme with adjusted font size
    final lightTheme = _createTheme(context, AppTheme.lightTheme, settings.fontSize.size);
    final darkTheme = _createTheme(context, AppTheme.darkTheme, settings.fontSize.size);
    final sepiaTheme = _createTheme(context, AppTheme.sepiaTheme, settings.fontSize.size);

    // Determine which theme to use based on the app theme mode
    ThemeData activeTheme;
    switch (settings.themeMode) {
      case AppThemeMode.light:
        activeTheme = lightTheme;
        break;
      case AppThemeMode.dark:
        activeTheme = darkTheme;
        break;
      case AppThemeMode.sepia:
        activeTheme = sepiaTheme;
        break;
      case AppThemeMode.system:
        activeTheme = MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? darkTheme
            : lightTheme;
        break;
    }

    return MaterialApp.router(
      title: 'Modudi',
      debugShowCheckedModeBanner: false,
      // Use the theme directly based on the current mode
      theme: settings.themeMode == AppThemeMode.sepia ? sepiaTheme : lightTheme,
      darkTheme: darkTheme,
      themeMode: _getThemeMode(settings.themeMode),
      
      // Set localization delegates
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      locale: _getLocale(settings.language),
      
      // GoRouter configuration
      routerConfig: AppRouter.router,
      // Firebase initialization check
      builder: (context, child) {
        return FutureBuilder(
          // This checks if Firebase is initialized properly
          future: _checkFirebaseInitialized(), 
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Material(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (snapshot.hasError || snapshot.data == false) {
              _log.severe('Firebase not initialized: ${snapshot.error}');
              return Material(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        const Text(
                          'Firebase Initialization Error',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please restart the app. Error: ${snapshot.error ?? "Unknown error"}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Try to initialize Firebase again
                            _tryInitializeFirebase();
                            // Simple way to retry - recreation causes a rebuild
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const MyApp()),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            
            // Firebase is initialized, show the app
            return child!;
          },
        );
      },
    );
  }

  // Helper method to create a theme with adjusted font size
  ThemeData _createTheme(BuildContext context, ThemeData baseTheme, double fontSize) {
    // Get the base text theme
    final baseTextTheme = baseTheme.textTheme;
    
    // Calculate scaling factor based on the selected font size
    final scaleFactor = fontSize / 14.0; // 14.0 is our base font size
    
    // Create a new text theme with the adjusted font size, using more aggressive scaling
    final adjustedTextTheme = baseTextTheme.copyWith(
      // Scale display styles
      displayLarge: baseTextTheme.displayLarge?.copyWith(fontSize: 36 * scaleFactor),
      displayMedium: baseTextTheme.displayMedium?.copyWith(fontSize: 32 * scaleFactor),
      displaySmall: baseTextTheme.displaySmall?.copyWith(fontSize: 28 * scaleFactor),
      
      // Scale headline styles
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontSize: 26 * scaleFactor),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontSize: 24 * scaleFactor),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontSize: 22 * scaleFactor),
      
      // Scale title styles
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 20 * scaleFactor),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 18 * scaleFactor),
      titleSmall: baseTextTheme.titleSmall?.copyWith(fontSize: 16 * scaleFactor),
      
      // Scale body styles
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16 * scaleFactor),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 14 * scaleFactor),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 12 * scaleFactor),
      
      // Scale label styles
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 16 * scaleFactor),
      labelMedium: baseTextTheme.labelMedium?.copyWith(fontSize: 14 * scaleFactor),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: 12 * scaleFactor),
    );
    
    // Return a new theme with the adjusted text theme
    return baseTheme.copyWith(
      textTheme: adjustedTextTheme,
      // Also update other theme elements that contain text styles
      appBarTheme: baseTheme.appBarTheme.copyWith(
        titleTextStyle: baseTheme.appBarTheme.titleTextStyle?.copyWith(fontSize: 20 * scaleFactor),
      ),
      // Update button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: TextStyle(fontSize: 14 * scaleFactor),
        ).merge(baseTheme.elevatedButtonTheme.style),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: TextStyle(fontSize: 14 * scaleFactor),
        ).merge(baseTheme.textButtonTheme.style),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: TextStyle(fontSize: 14 * scaleFactor),
        ).merge(baseTheme.outlinedButtonTheme.style),
      ),
    );
  }

  // Helper method to get the locale
  Locale? _getLocale(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return const Locale('en', '');
      case AppLanguage.arabic:
        return const Locale('ar', '');
      case AppLanguage.urdu:
        return const Locale('ur', '');
      default:
        return const Locale('en', '');
    }
  }

  Future<bool> _checkFirebaseInitialized() async {
    try {
      // Simple check if Firebase is initialized
      final apps = Firebase.apps;
      return apps.isNotEmpty;
    } catch (e) {
      _log.severe('Error checking Firebase initialization: $e');
      return false;
    }
  }
  
  Future<void> _tryInitializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        _log.info('Firebase initialized');
      }
    } catch (e) {
      _log.severe('Error initializing Firebase: $e');
    }
  }

  ThemeMode _getThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.sepia:
        return ThemeMode.light; // Sepia is a variation of light theme
      default:
        return ThemeMode.system;
    }
  }
}
