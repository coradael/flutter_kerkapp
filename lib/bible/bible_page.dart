import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BiblePage extends StatefulWidget {
  const BiblePage({super.key});

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> {
  final List<Map<String, String>> _dailyVerses = [
    {
      'verse': 'Johannes 3:16',
      'text': 'Want zo lief heeft God de wereld gehad, dat Hij zijn eniggeboren Zoon gegeven heeft, opdat ieder die in Hem gelooft, niet verloren gaat, maar eeuwig leven heeft.',
    },
    {
      'verse': 'Psalm 23:1',
      'text': 'De HEERE is mijn Herder, het ontbreekt mij aan niets.',
    },
    {
      'verse': 'Filippenzen 4:13',
      'text': 'Ik vermag alles door Christus, Die mij kracht geeft.',
    },
    {
      'verse': 'Spreuken 3:5-6',
      'text': 'Vertrouw op de HEERE met heel uw hart en steun op uw eigen inzicht niet. Ken Hem in al uw wegen, dan zal Hij uw paden recht maken.',
    },
    {
      'verse': 'Mattheüs 11:28',
      'text': 'Kom naar Mij toe, allen die vermoeid en belast bent, en Ik zal u rust geven.',
    },
  ];

  int _currentVerseIndex = 0;

  Future<void> _openBibleOnline(String bookName) async {
    // Gebruik debijbel.nl voor Nederlandse Bijbel online
    final url = Uri.parse('https://debijbel.nl/');
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Kan bijbel niet openen')),
        );
      }
    }
  }

  Future<void> _openFullBible() async {
    final url = Uri.parse('https://debijbel.nl/');
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Kan bijbel niet openen')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentVerse = _dailyVerses[_currentVerseIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bijbel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open Bijbel Online',
            onPressed: _openFullBible,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dagelijks Vers
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade700,
                    Colors.blue.shade900,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Vers van de Dag',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentVerse['text']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '— ${currentVerse['verse']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: _currentVerseIndex > 0
                            ? () {
                                setState(() => _currentVerseIndex--);
                              }
                            : null,
                      ),
                      Text(
                        '${_currentVerseIndex + 1} / ${_dailyVerses.length}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                        onPressed: _currentVerseIndex < _dailyVerses.length - 1
                            ? () {
                                setState(() => _currentVerseIndex++);
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Bijbel Boeken Secties
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bijbel Boeken',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _BibleSection(
                    title: 'Oude Testament',
                    icon: Icons.menu_book,
                    books: [
                      'Genesis', 'Exodus', 'Leviticus', 'Numeri', 'Deuteronomium',
                      'Jozua', 'Richteren', 'Ruth', 'Samuël', 'Koningen',
                      'Kronieken', 'Ezra', 'Nehemia', 'Esther', 'Job',
                      'Psalmen', 'Spreuken', 'Prediker', 'Hooglied',
                    ],
                    openBibleOnline: _openBibleOnline,
                  ),
                  const SizedBox(height: 12),
                  _BibleSection(
                    title: 'Nieuwe Testament',
                    icon: Icons.auto_stories,
                    books: [
                      'Mattheüs', 'Marcus', 'Lucas', 'Johannes',
                      'Handelingen', 'Romeinen', 'Korintiërs', 'Galaten',
                      'Efeze', 'Filippenzen', 'Kolossenzen', 'Tessalonicenzen',
                      'Timotheüs', 'Titus', 'Filemon', 'Hebreeën',
                      'Jakobus', 'Petrus', 'Johannes', 'Judas', 'Openbaring',
                    ],
                    openBibleOnline: _openBibleOnline,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BibleSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> books;
  final Function(String) _openBibleOnline;

  const _BibleSection({
    required this.title,
    required this.icon,
    required this.books,
    required Function(String) openBibleOnline,
  }) : _openBibleOnline = openBibleOnline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text('${books.length} boeken'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: books.map((book) {
                return ActionChip(
                  avatar: const Icon(Icons.open_in_browser, size: 18),
                  label: Text(book),
                  onPressed: () => _openBibleOnline(book),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
