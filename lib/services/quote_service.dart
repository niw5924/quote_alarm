import 'dart:convert';
import 'package:http/http.dart' as http;

class Quote {
  final String id;
  final String content;
  final String author;
  final String authorSlug;
  final int length;
  final List<String> tags;

  Quote({
    required this.id,
    required this.content,
    required this.author,
    required this.authorSlug,
    required this.length,
    required this.tags,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['_id'],
      content: json['content'],
      author: json['author'],
      authorSlug: json['authorSlug'],
      length: json['length'],
      tags: List<String>.from(json['tags']),
    );
  }
}

class QuoteService {
  static const String _baseUrl = 'http://api.quotable.io';

  Future<Quote> fetchRandomQuote() async {
    final response = await http.get(Uri.parse('$_baseUrl/random'));

    if (response.statusCode == 200) {
      return Quote.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load quote');
    }
  }
}
