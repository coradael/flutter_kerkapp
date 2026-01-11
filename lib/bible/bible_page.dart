import 'package:flutter/material.dart';
import 'bible_service.dart';

class BiblePage extends StatefulWidget {
  const BiblePage({super.key});

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> {
  final _bibleService = BibleService();
  
  String _selectedLanguage = 'Nederlands';
  String _selectedBook = 'Genesis';
  int _selectedChapter = 1;
  List<String> _verses = [];
  bool _loading = false;
  int _maxChapters = 50;

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  Future<void> _loadChapter() async {
    setState(() => _loading = true);
    
    final translation = BibleService.translations[_selectedLanguage]!;
    final verses = await _bibleService.getVerses(translation, _selectedBook, _selectedChapter, _selectedLanguage);
    final chapterCount = await _bibleService.getChapterCount(translation, _selectedBook, _selectedLanguage);
    
    setState(() {
      _verses = verses;
      _maxChapters = chapterCount > 0 ? chapterCount : 50;
      _loading = false;
    });
  }

  void _showBookSelector() async {
    final bookNumbers = BibleService.getBookNumbers(_selectedLanguage);
    final book = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kies een boek'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: bookNumbers.keys.map((book) {
              return ListTile(
                title: Text(book),
                onTap: () => Navigator.pop(context, book),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (book != null) {
      setState(() {
        _selectedBook = book;
        _selectedChapter = 1;
      });
      _loadChapter();
    }
  }

  void _showChapterSelector() async {
    final chapter = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kies hoofdstuk (1-$_maxChapters)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _maxChapters,
            itemBuilder: (context, index) {
              final chapterNum = index + 1;
              final isSelected = chapterNum == _selectedChapter;
              return InkWell(
                onTap: () => Navigator.pop(context, chapterNum),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$chapterNum',
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    if (chapter != null) {
      setState(() => _selectedChapter = chapter);
      _loadChapter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bijbel'),
        actions: [
          // Language selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (language) {
              setState(() {
                _selectedLanguage = language;
                // Reset to first book in new language
                final bookNumbers = BibleService.getBookNumbers(language);
                _selectedBook = bookNumbers.keys.first;
                _selectedChapter = 1;
              });
              _loadChapter();
            },
            itemBuilder: (context) => BibleService.translations.keys.map((lang) {
              return PopupMenuItem(
                value: lang,
                child: Text(lang),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                // Book selector
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: _showBookSelector,
                    child: Text(
                      _selectedBook,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Chapter selector
                OutlinedButton(
                  onPressed: _showChapterSelector,
                  child: Text(
                    '$_selectedChapter',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                // Previous chapter
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _selectedChapter > 1
                      ? () {
                          setState(() => _selectedChapter--);
                          _loadChapter();
                        }
                      : null,
                ),
                // Next chapter
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectedChapter < _maxChapters
                      ? () {
                          setState(() => _selectedChapter++);
                          _loadChapter();
                        }
                      : null,
                ),
              ],
            ),
          ),
          // Verses
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _verses.isEmpty
                    ? const Center(
                        child: Text('Geen verzen gevonden'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _verses.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _verses[index],
                              style: const TextStyle(
                                fontSize: 17,
                                height: 1.7,
                                letterSpacing: 0.2,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}