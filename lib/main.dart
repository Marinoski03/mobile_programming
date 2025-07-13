// main.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Importa Google Fonts
import './screens/home_screen.dart';
import './utils/app_data.dart'; // Importa la classe AppData

void main() {
  runApp(const TravelApp());
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I Miei Viaggi', // Titolo più descrittivo per l'app
      debugShowCheckedModeBanner: false, // Nasconde il banner "DEBUG"
      theme: ThemeData(
        // 1. Sfondi e Superfici Chiare (Anti-flash White)
        scaffoldBackgroundColor: AppData.antiFlashWhite,
        cardColor: AppData.antiFlashWhite,

        // 2. Definizione del ColorScheme (il cuore della palette)
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppData.silverLakeBlue, // Colore base per generare la palette
          primary: AppData.silverLakeBlue, // Colore primario (es. AppBar, bottoni principali)
          onPrimary: AppData.antiFlashWhite, // Testo/icone su colore primario
          secondary: AppData.cerise, // Colore secondario/accento (es. FAB, evidenziazioni)
          onSecondary: AppData.antiFlashWhite, // Testo/icone su colore secondario
          surface: AppData.antiFlashWhite, // Colore delle superfici (es. Card, Dialoghi)
          onSurface: AppData.charcoal, // Testo/icone su superfici
          background: AppData.antiFlashWhite, // Colore di sfondo generale
          onBackground: AppData.charcoal, // Testo/icone su sfondo generale
          error: AppData.cerise, // Colore per errori (usiamo Cerise come rosso)
          onError: AppData.antiFlashWhite, // Testo/icone su errore
        ),

        // 3. Configurazione AppBarTheme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // Mantenuta trasparente per il gradiente di sfondo
          foregroundColor: AppData.antiFlashWhite, // Colore delle icone e del testo della AppBar
          elevation: 0, // Nessuna ombra
          centerTitle: true, // Centra il titolo dell'AppBar
        ),

        // 4. Configurazione FloatingActionButtonThemeData
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppData.cerise, // Sfondo Cerise per il FAB
          foregroundColor: AppData.antiFlashWhite, // Testo/icone Anti-flash White
        ),

        // 5. Configurazione ElevatedButtonThemeData (per bottoni principali)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppData.silverLakeBlue, // Sfondo Silver Lake Blue
            foregroundColor: AppData.antiFlashWhite, // Testo Anti-flash White
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold), // Esempio con Google Fonts
          ),
        ),

        // 6. Configurazione TextButtonThemeData
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppData.silverLakeBlue, // Testo Silver Lake Blue
            textStyle: GoogleFonts.poppins(),
          ),
        ),

        // 7. Configurazione TextTheme per i colori del testo di default
        textTheme: GoogleFonts.poppinsTextTheme( // Usa Google Fonts per il tema del testo
          Theme.of(context).textTheme.copyWith(
                // Headline (titoli grandi)
                headlineLarge: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppData.charcoal),
                headlineMedium: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppData.charcoal),
                headlineSmall: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppData.charcoal),

                // Title (titoli di sezione)
                titleLarge: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppData.charcoal),
                titleMedium: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppData.charcoal),
                titleSmall: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppData.charcoal),

                // Body (testo normale)
                bodyLarge: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppData.charcoal),
                bodyMedium: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppData.charcoal),
                bodySmall: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppData.charcoal),

                // Label (etichette, bottoni piccoli)
                labelLarge: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppData.charcoal),
                labelMedium: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppData.charcoal),
                labelSmall: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppData.charcoal),
              ),
        ),

        // 8. Per i colori delle icone di default
        iconTheme: const IconThemeData(
          color: AppData.charcoal, // Colore di default per le icone
        ),

        // 9. Configurazione per i bordi delle TextField
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
            borderSide: AppData.charcoal.withOpacity(0.5).toBorderSide(), // Usa toBorderSide()
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

// Estensione per convertire Color in BorderSide
extension ColorToBorderSide on Color {
  BorderSide toBorderSide({double width = 1.0}) {
    return BorderSide(color: this, width: width);
  }
}