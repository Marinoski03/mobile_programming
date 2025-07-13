// main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './screens/home_screen.dart';
import './utils/app_data.dart';

void main() {
  runApp(const TravelApp());
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I Miei Viaggi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppData.antiFlashWhite,
        cardColor: AppData.antiFlashWhite,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppData.silverLakeBlue,
          primary: AppData.silverLakeBlue,
          onPrimary: AppData.antiFlashWhite,
          secondary: AppData.cerise, 
          onSecondary: AppData.antiFlashWhite, 
          surface: AppData.antiFlashWhite, 
          onSurface: AppData.charcoal, 
          background: AppData.antiFlashWhite, 
          onBackground: AppData.charcoal, 
          error: AppData.cerise, 
          onError: AppData.antiFlashWhite, 
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, 
          foregroundColor: AppData.antiFlashWhite, 
          elevation: 0, 
          centerTitle: true, 
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppData.cerise, 
          foregroundColor: AppData.antiFlashWhite, 
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppData.silverLakeBlue, 
            foregroundColor: AppData.antiFlashWhite, 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold), 
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppData.silverLakeBlue, 
            textStyle: GoogleFonts.poppins(),
          ),
        ),

        textTheme: GoogleFonts.poppinsTextTheme( 
          Theme.of(context).textTheme.copyWith(
                headlineLarge: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppData.charcoal),
                headlineMedium: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppData.charcoal),
                headlineSmall: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppData.charcoal),
                titleLarge: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppData.charcoal),
                titleMedium: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppData.charcoal),
                titleSmall: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppData.charcoal),
                bodyLarge: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppData.charcoal),
                bodyMedium: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppData.charcoal),
                bodySmall: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppData.charcoal),
                labelLarge: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppData.charcoal),
                labelMedium: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppData.charcoal),
                labelSmall: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppData.charcoal),
              ),
        ),

        iconTheme: const IconThemeData(
          color: AppData.charcoal,
        ),

        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppData.silverLakeBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppData.silverLakeBlue, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: AppData.charcoal.withOpacity(0.5).toBorderSide(), 
          ),
          labelStyle: const TextStyle(color: AppData.charcoal),
          hintStyle: TextStyle(color: AppData.charcoal.withOpacity(0.6)),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}

extension ColorToBorderSide on Color {
  BorderSide toBorderSide({double width = 1.0}) {
    return BorderSide(color: this, width: width);
  }
}