import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/book.dart';
import '../services/book_api_service.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController =
      MobileScannerController();

  bool _isProcessing = false;
  bool _isDuplicate = false;
  Book? _foundBook;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing || _foundBook != null) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      final booksBox = Hive.box('books');

bool alreadyExists = false;

for (final key in booksBox.keys) {
  final storedBook = booksBox.get(key);

  if (storedBook is Map &&
      storedBook['isbn']?.toString() == value) {
    alreadyExists = true;
    break;
  }
}

if (alreadyExists) {
  await _scannerController.stop();

  if (!mounted) {
    return;
  }

  setState(() {
    _isDuplicate = true;
    _isProcessing = false;
  });

  return;
}

      if (value == null || value.isEmpty) {
        continue;
      }

      setState(() {
        _isProcessing = true;
      });

      await _scannerController.stop();

      final apiService = BookApiService();

      final bookData = await apiService.getBookByIsbn(value);

      if (!mounted) {
        return;
      }

      if (bookData == null) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book not found for this ISBN.'),
          ),
        );

        await _scannerController.start();

        return;
      }

      int? publishYear;

      final publishDate = bookData['publish_date'];

      if (publishDate != null) {
        final match = RegExp(r'\d{4}').firstMatch(
          publishDate.toString(),
        );

        if (match != null) {
          publishYear = int.tryParse(match.group(0)!);
        }
      }

      final publishers = bookData['publishers'];

      String publisher = '';

      if (publishers is List && publishers.isNotEmpty) {
        publisher = publishers.first.toString();
      }

      final pagesValue = bookData['number_of_pages'];

      int? pages;

      if (pagesValue is int) {
        pages = pagesValue;
      } else if (pagesValue != null) {
        pages = int.tryParse(pagesValue.toString());
      }

      final book = Book(
        title: bookData['title']?.toString() ?? 'Unknown Title',
        author: bookData['authorName']?.toString() ?? 'Unknown Author',
        isbn: value,
        publisher: publisher,
        publishYear: publishYear,
        pages: pages,
coverUrl: apiService.getBookCoverUrl(bookData),
      );

      setState(() {
        _foundBook = book;
      });

      break;
    }
  }

  void _addBookToLibrary() {
    if (_foundBook == null) {
      return;
    }

    Navigator.pop(context, _foundBook);
  }

Future<void> _scanAgain() async {
  setState(() {
    _foundBook = null;
    _isDuplicate = false;
    _isProcessing = false;
  });

  await _scannerController.start();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Book'),
      ),
body: _isDuplicate
    ? _buildDuplicateMessage()
    : _foundBook == null
        ? _buildScanner()
        : _buildBookDetails(),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcode,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Point your camera at the ISBN barcode',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              if (_isProcessing)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(),
                    ),
                    SizedBox(width: 12),
                    Text('Finding book...'),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookDetails() {
    final book = _foundBook!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 700,
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Text(
                    'Book Found',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (book.coverUrl != null)
                    SizedBox(
                      height: 260,
                      child: Image.network(
                        book.coverUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.menu_book,
                            size: 120,
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    book.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    book.author,
                    style: const TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('ISBN', book.isbn),
                  _buildDetailRow(
                    'Publisher',
                    book.publisher.isEmpty
                        ? 'Not available'
                        : book.publisher,
                  ),
                  _buildDetailRow(
                    'Year',
                    book.publishYear?.toString() ?? 'Not available',
                  ),
                  _buildDetailRow(
                    'Pages',
                    book.pages?.toString() ?? 'Not available',
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _scanAgain,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Again'),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.icon(
                        onPressed: _addBookToLibrary,
                        icon: const Icon(Icons.library_add),
                        label: const Text('Add to Library'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

Widget _buildDuplicateMessage() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.library_books,
            size: 100,
          ),
          const SizedBox(height: 12),
          const Text(
            'This book is already in your library.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _scanAgain,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan Another Book'),
          ),
        ],
      ),
    ),
  );
}
}