import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class BackupService {
  final Box booksBox = Hive.box('books');

  Future<void> exportLibrary() async {
    final books = booksBox.values.map((book) {
      return Map<String, dynamic>.from(book);
    }).toList();

    final backup = {
      'app': 'Personal Library Management System',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'books': books,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

    await FileSaver.instance.saveFile(
      name: 'plms-library-backup',
      bytes: utf8.encode(jsonString),
      fileExtension: 'json',
      mimeType: MimeType.json,
    );
  }

  Future<int> importLibrary() async {
final result = await FilePicker.pickFiles(
          type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) {
      return 0;
    }

final fileBytes = await result.first.readAsBytes();

    if (fileBytes == null) {
      throw Exception('Could not read the selected backup file.');
    }

    final jsonString = utf8.decode(fileBytes);

    final backup = jsonDecode(jsonString);

    if (backup is! Map<String, dynamic>) {
      throw Exception('Invalid PLMS backup file.');
    }

    if (backup['app'] != 'Personal Library Management System') {
      throw Exception('This is not a PLMS backup file.');
    }

    final books = backup['books'];

    if (books is! List) {
      throw Exception('No books found in the backup.');
    }

    int importedCount = 0;

    for (final book in books) {
      if (book is! Map) {
        continue;
      }

      final isbn = book['isbn']?.toString() ?? '';

      if (isbn.isEmpty) {
        continue;
      }

      bool alreadyExists = false;

      for (final key in booksBox.keys) {
        final existingBook = booksBox.get(key);

        if (existingBook is Map &&
            existingBook['isbn']?.toString() == isbn) {
          alreadyExists = true;
          break;
        }
      }

      if (alreadyExists) {
        continue;
      }

      await booksBox.add(
        Map<String, dynamic>.from(book),
      );

      importedCount++;
    }

    return importedCount;
  }
}