// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_theme.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Status bar: dark icons on light background
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
  ));

  await DatabaseService.instance.initialize();

  runApp(const BiomechCoachApp());
}

class BiomechCoachApp extends StatelessWidget {
  const BiomechCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biomech Coach',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentBlue,
        brightness: Brightness.dark,
        primary: AppColors.accentBlue,
        secondary: AppColors.accentLive,
        surface: AppColors.surface,
        error: AppColors.accentAlert,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
    );
  }
}
