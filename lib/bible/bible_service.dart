import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class BibleService {
  // Cache for loaded Bible translations
  final Map<String, Map<String, dynamic>> _bibleCache = {};

  // Available translations
  static const Map<String, String> translations = {
    'Nederlands': 'nld_svv',
    'English': 'kjv',
    'Español': 'rvr',
  };

  // Bible books in Dutch
  static const Map<String, int> bookNumbersDutch = {
    'Genesis': 1, 'Exodus': 2, 'Leviticus': 3, 'Numeri': 4, 'Deuteronomium': 5,
    'Jozua': 6, 'Richteren': 7, 'Ruth': 8, '1 Samuel': 9, '2 Samuel': 10,
    '1 Koningen': 11, '2 Koningen': 12, '1 Kronieken': 13, '2 Kronieken': 14,
    'Ezra': 15, 'Nehemia': 16, 'Esther': 17, 'Job': 18, 'Psalmen': 19,
    'Spreuken': 20, 'Prediker': 21, 'Hooglied': 22, 'Jesaja': 23,
    'Jeremia': 24, 'Klaagliederen': 25, 'Ezechiël': 26, 'Daniël': 27,
    'Hosea': 28, 'Joël': 29, 'Amos': 30, 'Obadja': 31, 'Jona': 32,
    'Micha': 33, 'Nahum': 34, 'Habakuk': 35, 'Zefanja': 36, 'Haggai': 37,
    'Zacharia': 38, 'Maleachi': 39, 'Mattheüs': 40, 'Marcus': 41, 'Lucas': 42,
    'Johannes': 43, 'Handelingen': 44, 'Romeinen': 45, '1 Corinthiërs': 46,
    '2 Corinthiërs': 47, 'Galaten': 48, 'Efeziërs': 49, 'Filippenzen': 50,
    'Kolossenzen': 51, '1 Tessalonicenzen': 52, '2 Tessalonicenzen': 53,
    '1 Timotheüs': 54, '2 Timotheüs': 55, 'Titus': 56, 'Filemon': 57,
    'Hebreeën': 58, 'Jakobus': 59, '1 Petrus': 60, '2 Petrus': 61,
    '1 Johannes': 62, '2 Johannes': 63, '3 Johannes': 64, 'Judas': 65,
    'Openbaring': 66,
  };

  // Bible books in English
  static const Map<String, int> bookNumbersEnglish = {
    'Genesis': 1, 'Exodus': 2, 'Leviticus': 3, 'Numbers': 4, 'Deuteronomy': 5,
    'Joshua': 6, 'Judges': 7, 'Ruth': 8, '1 Samuel': 9, '2 Samuel': 10,
    '1 Kings': 11, '2 Kings': 12, '1 Chronicles': 13, '2 Chronicles': 14,
    'Ezra': 15, 'Nehemiah': 16, 'Esther': 17, 'Job': 18, 'Psalms': 19,
    'Proverbs': 20, 'Ecclesiastes': 21, 'Song of Solomon': 22, 'Isaiah': 23,
    'Jeremiah': 24, 'Lamentations': 25, 'Ezekiel': 26, 'Daniel': 27,
    'Hosea': 28, 'Joel': 29, 'Amos': 30, 'Obadiah': 31, 'Jonah': 32,
    'Micah': 33, 'Nahum': 34, 'Habakkuk': 35, 'Zephaniah': 36, 'Haggai': 37,
    'Zechariah': 38, 'Malachi': 39, 'Matthew': 40, 'Mark': 41, 'Luke': 42,
    'John': 43, 'Acts': 44, 'Romans': 45, '1 Corinthians': 46,
    '2 Corinthians': 47, 'Galatians': 48, 'Ephesians': 49, 'Philippians': 50,
    'Colossians': 51, '1 Thessalonians': 52, '2 Thessalonians': 53,
    '1 Timothy': 54, '2 Timothy': 55, 'Titus': 56, 'Philemon': 57,
    'Hebrews': 58, 'James': 59, '1 Peter': 60, '2 Peter': 61,
    '1 John': 62, '2 John': 63, '3 John': 64, 'Jude': 65,
    'Revelation': 66,
  };

  // Bible books in Spanish
  static const Map<String, int> bookNumbersSpanish = {
    'Génesis': 1, 'Éxodo': 2, 'Levítico': 3, 'Números': 4, 'Deuteronomio': 5,
    'Josué': 6, 'Jueces': 7, 'Rut': 8, '1 Samuel': 9, '2 Samuel': 10,
    '1 Reyes': 11, '2 Reyes': 12, '1 Crónicas': 13, '2 Crónicas': 14,
    'Esdras': 15, 'Nehemías': 16, 'Ester': 17, 'Job': 18, 'Salmos': 19,
    'Proverbios': 20, 'Eclesiastés': 21, 'Cantares': 22, 'Isaías': 23,
    'Jeremías': 24, 'Lamentaciones': 25, 'Ezequiel': 26, 'Daniel': 27,
    'Oseas': 28, 'Joel': 29, 'Amós': 30, 'Abdías': 31, 'Jonás': 32,
    'Miqueas': 33, 'Nahúm': 34, 'Habacuc': 35, 'Sofonías': 36, 'Hageo': 37,
    'Zacarías': 38, 'Malaquías': 39, 'Mateo': 40, 'Marcos': 41, 'Lucas': 42,
    'Juan': 43, 'Hechos': 44, 'Romanos': 45, '1 Corintios': 46,
    '2 Corintios': 47, 'Gálatas': 48, 'Efesios': 49, 'Filipenses': 50,
    'Colosenses': 51, '1 Tesalonicenses': 52, '2 Tesalonicenses': 53,
    '1 Timoteo': 54, '2 Timoteo': 55, 'Tito': 56, 'Filemón': 57,
    'Hebreos': 58, 'Santiago': 59, '1 Pedro': 60, '2 Pedro': 61,
    '1 Juan': 62, '2 Juan': 63, '3 Juan': 64, 'Judas': 65,
    'Apocalipsis': 66,
  };

  // Get book names for the selected language
  static Map<String, int> getBookNumbers(String language) {
    switch (language) {
      case 'English':
        return bookNumbersEnglish;
      case 'Español':
        return bookNumbersSpanish;
      default:
        return bookNumbersDutch;
    }
  }

  // Load entire Bible translation into cache
  Future<void> _loadTranslation(String translation) async {
    if (_bibleCache.containsKey(translation)) return;

    try {
      final assetPath = 'assets/bible/$translation.json';
      final jsonString = await rootBundle.loadString(assetPath);
      _bibleCache[translation] = json.decode(jsonString);
    } catch (e) {
      debugPrint('Error loading translation $translation: $e');
      _bibleCache[translation] = {};
    }
  }

  // Get number of chapters for a book
  Future<int> getChapterCount(String translation, String book, String language) async {
    await _loadTranslation(translation);
    
    final bookNumbers = getBookNumbers(language);
    final bookNumber = bookNumbers[book];
    if (bookNumber == null) return 0;

    try {
      final bibleData = _bibleCache[translation];
      if (bibleData == null || !bibleData.containsKey(bookNumber.toString())) {
        return 0;
      }

      final bookData = bibleData[bookNumber.toString()] as Map;
      return bookData.length;
    } catch (e) {
      debugPrint('Error getting chapter count: $e');
      return 0;
    }
  }

  Future<List<String>> getVerses(String translation, String book, int chapter, String language) async {
    await _loadTranslation(translation);
    
    final bookNumbers = getBookNumbers(language);
    final bookNumber = bookNumbers[book];
    if (bookNumber == null) return [];

    try {
      final bibleData = _bibleCache[translation];
      if (bibleData == null || !bibleData.containsKey(bookNumber.toString())) {
        return ['Deze Bijbeltekst is nog niet beschikbaar.'];
      }

      final bookData = bibleData[bookNumber.toString()];
      if (!bookData.containsKey(chapter.toString())) {
        return ['Dit hoofdstuk is nog niet beschikbaar.'];
      }

      final verses = <String>[];
      final chapterData = bookData[chapter.toString()] as List;

      for (final verse in chapterData) {
        final verseNumber = verse['verse'];
        final verseText = verse['text'] as String;
        verses.add('$verseNumber. $verseText');
      }

      return verses;
    } catch (e) {
      debugPrint('Error getting verses: $e');
      return ['Fout bij het laden van de tekst.'];
    }
  }
}
