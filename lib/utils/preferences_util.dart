import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

Future<void> saveBookToPreferences(Map<String, dynamic> book) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('book', jsonEncode(book));
}

Future<void> loadBookFromPreferences(Function(Map<String, dynamic>?) callback) async {
  final prefs = await SharedPreferences.getInstance();
  final bookString = prefs.getString('book');
  if (bookString != null) {
    final bookData = jsonDecode(bookString) as Map<String, dynamic>;
    callback(bookData);
  } else {
    callback(null);
  }
}
