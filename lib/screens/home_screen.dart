import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/book.dart';
import '../services/backup_service.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box _booksBox;

  List<Book> _books = [];

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  final BackupService _backupService = BackupService();

  List<Book> get _filteredBooks {
    if (_searchQuery.isEmpty) {
      return _books;
    }

    return _books.where((book) {
      final title = book.title.toLowerCase();
      final author = book.author.toLowerCase();
      final isbn = book.isbn.toLowerCase();

      return title.contains(_searchQuery) ||
          author.contains(_searchQuery) ||
          isbn.contains(_searchQuery);
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    _booksBox = Hive.box('books');

    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadBooks() {
    final storedBooks = _booksBox.values;

    final books = storedBooks.map((book) {
      final data = Map<String, dynamic>.from(book);

      return Book(
        title: data['title'] ?? '',
        author: data['author'] ?? '',
        isbn: data['isbn'] ?? '',
        publisher: data['publisher'] ?? '',
        publishYear: data['publishYear'],
        pages: data['pages'],
        coverUrl: data['coverUrl'],
      );
    }).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _books = books;
    });
  }

  Future<bool> _addBook(Book book) async {
    for (final key in _booksBox.keys) {
      final storedBook = _booksBox.get(key);

      if (storedBook is Map &&
          storedBook['isbn']?.toString() == book.isbn) {
        return false;
      }
    }

    await _booksBox.add({
      'title': book.title,
      'author': book.author,
      'isbn': book.isbn,
      'publisher': book.publisher,
      'publishYear': book.publishYear,
      'pages': book.pages,
      'coverUrl': book.coverUrl,
    });

    _loadBooks();

    return true;
  }

  Future<void> _deleteBook(Book book) async {
    dynamic bookKey;

    for (final key in _booksBox.keys) {
      final storedBook = _booksBox.get(key);

      if (storedBook is Map &&
          storedBook['isbn']?.toString() == book.isbn) {
        bookKey = key;
        break;
      }
    }

    if (bookKey != null) {
      await _booksBox.delete(bookKey);
      _loadBooks();
    }
  }

  Future<void> _editBook(Book book) async {
    final titleController =
        TextEditingController(text: book.title);

    final authorController =
        TextEditingController(text: book.author);

    final isbnController =
        TextEditingController(text: book.isbn);

    final publisherController =
        TextEditingController(text: book.publisher);

    final yearController = TextEditingController(
      text: book.publishYear?.toString() ?? '',
    );

    final pagesController = TextEditingController(
      text: book.pages?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Book'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Book Title',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: authorController,
                    decoration: const InputDecoration(
                      labelText: 'Author',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: isbnController,
                    decoration: const InputDecoration(
                      labelText: 'ISBN',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: publisherController,
                    decoration: const InputDecoration(
                      labelText: 'Publisher',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Publish Year',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pagesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pages',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final author = authorController.text.trim();
                final isbn = isbnController.text.trim();
                final publisher = publisherController.text.trim();

                if (title.isEmpty ||
                    author.isEmpty ||
                    isbn.isEmpty) {
                  return;
                }

                dynamic bookKey;

                for (final key in _booksBox.keys) {
                  final storedBook = _booksBox.get(key);

                  if (storedBook is Map &&
                      storedBook['isbn']?.toString() ==
                          book.isbn) {
                    bookKey = key;
                    break;
                  }
                }

                if (bookKey == null) {
                  return;
                }

                int? year;
                int? pages;

                if (yearController.text.trim().isNotEmpty) {
                  year = int.tryParse(
                    yearController.text.trim(),
                  );
                }

                if (pagesController.text.trim().isNotEmpty) {
                  pages = int.tryParse(
                    pagesController.text.trim(),
                  );
                }

                await _booksBox.put(bookKey, {
                  'title': title,
                  'author': author,
                  'isbn': isbn,
                  'publisher': publisher,
                  'publishYear': year,
                  'pages': pages,
                  'coverUrl': book.coverUrl,
                });

                _loadBooks();

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    authorController.dispose();
    isbnController.dispose();
    publisherController.dispose();
    yearController.dispose();
    pagesController.dispose();
  }

  void _showAddBookDialog() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final isbnController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Book'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Book Title',
                    hintText: 'e.g. Atomic Habits',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: authorController,
                  decoration: const InputDecoration(
                    labelText: 'Author',
                    hintText: 'e.g. James Clear',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: isbnController,
                  decoration: const InputDecoration(
                    labelText: 'ISBN',
                    hintText: 'e.g. 9780735211292',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final author = authorController.text.trim();
                final isbn = isbnController.text.trim();

                if (title.isEmpty ||
                    author.isEmpty ||
                    isbn.isEmpty) {
                  return;
                }

                final book = Book(
                  title: title,
                  author: author,
                  isbn: isbn,
                );

                final added = await _addBook(book);

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.pop(dialogContext);

                if (!added && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'This book is already in your library.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save Book'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _scanBook() async {
    final book = await Navigator.push<Book>(
      context,
      MaterialPageRoute(
        builder: (context) => const ScannerScreen(),
      ),
    );

    if (book == null) {
      return;
    }

    final added = await _addBook(book);

    if (!added && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This book is already in your library.',
          ),
        ),
      );
    }
  }

  Future<void> _exportLibrary() async {
    try {
      await _backupService.exportLibrary();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Library backup exported successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
        ),
      );
    }
  }

  Future<void> _importLibrary() async {
    try {
      final importedCount =
          await _backupService.importLibrary();

      _loadBooks();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            importedCount == 0
                ? 'No new books were imported.'
                : '$importedCount book(s) imported successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
        ),
      );
    }
  }

  Widget _buildBookCard(Book book, bool isMobile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: isMobile ? 55 : 70,
              height: isMobile ? 80 : 100,
              child: book.coverUrl != null &&
                      book.coverUrl!.isNotEmpty
                  ? Image.network(
                      book.coverUrl!,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stackTrace) {
                        return const Icon(
                          Icons.menu_book,
                          size: 40,
                        );
                      },
                    )
                  : const Icon(
                      Icons.menu_book,
                      size: 40,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(
                      fontSize: isMobile ? 17 : 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ISBN: ${book.isbn}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                  if (!isMobile &&
                      book.publisher.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Publisher: ${book.publisher}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                  if (!isMobile &&
                      book.publishYear != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Year: ${book.publishYear}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit book',
                  onPressed: () => _editBook(book),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete book',
                  onPressed: () => _deleteBook(book),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrary(double width) {
    final isMobile = width < 600;

    if (_filteredBooks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.menu_book,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                _books.isEmpty
                    ? 'Your library is empty'
                    : 'No books found',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _books.isEmpty
                    ? 'Add or scan your first book to get started.'
                    : 'Try a different search.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredBooks.length,
      itemBuilder: (context, index) {
        return _buildBookCard(
          _filteredBooks[index],
          isMobile,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Personal Library Management System',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Library',
            onPressed: _exportLibrary,
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Import Library',
            onPressed: _importLibrary,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return Padding(
            padding: EdgeInsets.all(
              isMobile ? 12 : 24,
            ),
            child: Column(
              children: [
                if (isMobile)
                  Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery =
                                value.toLowerCase().trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search books...',
                          prefixIcon:
                              const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _scanBook,
                          icon: const Icon(
                            Icons.camera_alt,
                          ),
                          label: const Text('Scan Book'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showAddBookDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Book Manually'),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery =
                                  value.toLowerCase().trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search books...',
                            prefixIcon:
                                const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: _showAddBookDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Book'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _scanBook,
                        icon: const Icon(
                          Icons.camera_alt,
                        ),
                        label: const Text('Scan Book'),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildLibrary(
                    constraints.maxWidth,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}