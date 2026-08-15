import 'dart:convert';

import 'package:http/http.dart' as http;

class BookApiService {
  Future<Map<String, dynamic>?> getBookByIsbn(String isbn) async {
    final url = Uri.parse(
      'https://openlibrary.org/isbn/$isbn.json',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return null;
      }

      final bookData =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (bookData['authors'] != null &&
          (bookData['authors'] as List).isNotEmpty) {
        final authorKey = bookData['authors'][0]['key'];

        final author = await _getAuthor(authorKey);

        if (author != null) {
          bookData['authorName'] = author;
        }
      }

      return bookData;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _getAuthor(String authorKey) async {
    final url = Uri.parse(
      'https://openlibrary.org$authorKey.json',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return null;
      }

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      return data['name'] as String?;
    } catch (e) {
      return null;
    }
  }

  String? getBookCoverUrl(Map<String, dynamic> bookData) {
    final covers = bookData['covers'];

    if (covers is List && covers.isNotEmpty) {
      final coverId = covers.first;

      if (coverId is int && coverId > 0) {
        return 'https://covers.openlibrary.org/b/id/$coverId-L.jpg';
      }
    }

    return null;
  }
}