class Book {
  final String title;
  final String author;
  final String isbn;
  final String publisher;
  final int? publishYear;
  final int? pages;
  final String? coverUrl;

  Book({
    required this.title,
    required this.author,
    required this.isbn,
    this.publisher = '',
    this.publishYear,
    this.pages,
    this.coverUrl,
  });
}