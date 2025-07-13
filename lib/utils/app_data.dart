// lib/utils/app_data.dart

import 'package:flutter/material.dart';

class AppData {
  // ***** CATEGORIE ESISTENTI *****
  static const List<String> categories = [
    'Avventura',
    'Cultura',
    'Relax',
    'Natura',
    'Cibo',
    'Sport',
    'Lavoro',
    'Altro',
  ];
  // ********************************

  // ***** DEFINIZIONI DI COLORE CHE VUOI USARE *****
  static const Color cerise = Color(0xFFDB2763);
  static const Color silverLakeBlue = Color(0xFF6C91C2);
  static const Color charcoal = Color(0xFF2F4550);
  static const Color antiFlashWhite = Color(0xFFF1F2F6);
  static const Color errorRed = Color(0xFFB00020); // Questo è per errori specifici, non nel tuo mapping
  // Charcoal con 60% di opacità
  static const Color charcoalWithOpacity60 = Color.fromRGBO(47, 69, 80, 0.6);
  // *************************************************
}