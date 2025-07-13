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
        // 1. Sfondi e Superfici Chiare (il "Foglio Bianco")
        // Colore: Anti-flash White (#F1F2F6)
        scaffoldBackgroundColor: AppData.antiFlashWhite,
        cardColor: AppData.antiFlashWhite,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppData.silverLakeBlue,
          // 3. Colore Primario (il "Colore del Tema")
          // Colore: Silver Lake Blue (#6C91C2)
          primary: AppData.silverLakeBlue,
          // Testo su colore primario (Silver Lake Blue) dovrebbe essere Anti-flash White
          onPrimary: AppData.antiFlashWhite,
          // 4. Colore Secondario / Accento (il "Tasto Evidenziato")
          // Colore: Cerise (#DB2763)
          secondary: AppData.cerise,
          // Testo su colore secondario (Cerise) dovrebbe essere Anti-flash White
          onSecondary: AppData.antiFlashWhite,
          // Sfondo delle superfici (come card, dialoghi) - Anti-flash White
          surface: AppData.antiFlashWhite,
          // Testo su superfici (Anti-flash White) dovrebbe essere Charcoal
          onSurface: AppData.charcoal,
          // Sfondo generale (Scaffold background) - Anti-flash White
          background: AppData.antiFlashWhite,
          // Testo su sfondo (Anti-flash White) dovrebbe essere Charcoal
          onBackground: AppData.charcoal,
          // Colore per errori - Cerise
          error: AppData.cerise,
          // Testo su colore errore (Cerise) dovrebbe essere Anti-flash White
          onError: AppData.antiFlashWhite,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // Puoi mantenerla trasparente se hai uno sfondo con gradiente
          // Foreground color per testo e icone nella AppBar - Anti-flash White se la AppBar è scura, o Charcoal se trasparente su sfondo chiaro
          foregroundColor: AppData.antiFlashWhite, // Se la AppBar è di colore scuro, il testo è chiaro
          elevation: 0, // Nessuna ombra sotto la AppBar
          centerTitle: true, // Titolo centrato
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          // 4. Colore Secondario / Accento (il "Tasto Evidenziato")
          // Colore: Cerise (#DB2763)
          backgroundColor: AppData.cerise,
          foregroundColor: AppData.antiFlashWhite, // Testo/Icona sul FAB è Anti-flash White
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            // 3. Colore Primario (il "Colore del Tema")
            // Colore: Silver Lake Blue (#6C91C2)
            backgroundColor: AppData.silverLakeBlue,
            foregroundColor: AppData.antiFlashWhite, // Testo sul bottone è Anti-flash White
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold), // Font personalizzato
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            // Testo dei TextButton con il colore primario
            foregroundColor: AppData.silverLakeBlue,
            textStyle: GoogleFonts.poppins(),
          ),
        ),

        textTheme: GoogleFonts.poppinsTextTheme( // Applica Poppins a tutto il textTheme
          Theme.of(context).textTheme.copyWith(
            // 2. Testo e Icone Scure (il "Testo del Diario")
            // Colore: Charcoal (#2F4550)
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
          // 2. Testo e Icone Scure (il "Testo del Diario")
          // Colore: Charcoal (#2F4550)
          color: AppData.charcoal,
        ),

        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppData.silverLakeBlue), // Bordo predefinito con Silver Lake Blue
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppData.silverLakeBlue, width: 2), // Bordo focus più spesso
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: AppData.charcoal.withOpacity(0.5).toBorderSide(), // Bordo abilitato con Charcoal semi-trasparente
          ),
          labelStyle: const TextStyle(color: AppData.charcoal), // Stile dell'etichetta
          hintStyle: TextStyle(color: AppData.charcoal.withOpacity(0.6)), // Stile del testo di suggerimento
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity, // Densità visiva adattiva
      ),
      home: const HomeScreen(),
    );
  }
}

// Estensione per convertire Color in BorderSide
extension ColorToBorderSide on Color {
  BorderSide toBorderSide({double width = 1.0}) {
    return BorderSide(color: this, width: width);
  }
}