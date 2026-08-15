import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/book.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box _booksBox;

  List<Book> _books = [];
final TextEditingController _searchController = TextEditingController();
String _searchQuery = '';

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

  void _loadBooks() {
    final storedBooks = _booksBox.values;

    setState(() {
      _books = storedBooks.map((book) {
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
    final data = Map<String, dynamic>.from(
      _booksBox.get(key),
    );

    if (data['isbn'] == book.isbn) {
      bookKey = key;
      break;
    }
  }

  if (bookKey != null) {
    await _booksBox.delete(bookKey);
    _loadBooks();
  }
}

  void _showAddBookDialog() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final isbnController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final author = authorController.text.trim();
                final isbn = isbnController.text.trim();

                if (title.isEmpty || author.isEmpty || isbn.isEmpty) {
                  return;
                }

                final book = Book(
                  title: title,
                  author: author,
                  isbn: isbn,
                );

                await _addBook(book);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Book'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Library Management System'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                      controller: _searchController,
  onChanged: (value) {
    setState(() {
      _searchQuery = value.toLowerCase().trim();
    });
  },
  decoration: InputDecoration(
    hintText: 'Search books...',
    prefixIcon: const Icon(Icons.search),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
                  ),
                ),
                const SizedBox(width: 16),
Row(
  children: [
    FilledButton.icon(
      onPressed: _showAddBookDialog,
      icon: const Icon(Icons.add),
      label: const Text('Add Book'),
    ),
    const SizedBox(width: 12),
    OutlinedButton.icon(
onPressed: () async {
  final book = await Navigator.push<Book>(
    context,
    MaterialPageRoute(
      builder: (context) => const ScannerScreen(),
    ),
  );

if (book != null) {
  final added = await _addBook(book);

  if (!added && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This book is already in your library.'),
      ),
    );
  }
}
},
      icon: const Icon(Icons.camera_alt),
      label: const Text('Scan Book'),
    ),
  ],
),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _books.isEmpty
                  ? const Center(
                      child: Text(
                        '📚 Your library is empty\n\n'
                        'Add your first book to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredBooks.length,
                      itemBuilder: (context, index) {
                        final book = _filteredBooks[index];

return Card(
  child: ListTile(
    contentPadding: const EdgeInsets.all(12),
    leading: SizedBox(
      width: 60,
      height: 90,
      child: book.coverUrl != null && book.coverUrl!.isNotEmpty
          ? Image.network(
              book.coverUrl!,
fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
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
    title: Text(
      book.title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: Text(
      '${book.author}\nISBN: ${book.isbn}',
    ),
    isThreeLine: true,
    trailing: IconButton(
      icon: const Icon(Icons.delete),
      tooltip: 'Delete book',
      onPressed: () {
        _deleteBook(book);
      },
    ),
  ),
);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}