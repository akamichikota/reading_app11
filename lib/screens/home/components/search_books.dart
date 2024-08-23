import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchBooks extends StatefulWidget {
  final Function(List<QueryDocumentSnapshot>, bool) onSearchResults;

  SearchBooks({required this.onSearchResults});

  @override
  _SearchBooksState createState() => _SearchBooksState();
}

class _SearchBooksState extends State<SearchBooks> {
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchController.text = prefs.getString('searchQuery') ?? '';
      if (_searchController.text.isNotEmpty) {
        _searchBooks(_searchController.text);
      }
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('searchQuery', _searchController.text);
  }

  void _searchBooks(String query) async {
    if (query.isEmpty) {
      widget.onSearchResults([], false);
      return;
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    QuerySnapshot authorSnapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('author', isGreaterThanOrEqualTo: query)
        .where('author', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    List<QueryDocumentSnapshot> results = snapshot.docs + authorSnapshot.docs;
    final seen = <String>{};
    results.retainWhere((doc) => seen.add(doc.id));

    widget.onSearchResults(results, true);
    _saveState();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '本を検索する',
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.grey[400]),
        suffixIcon: IconButton(
          icon: Icon(Icons.search, color: Colors.grey),
          onPressed: () => _searchBooks(_searchController.text),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      onChanged: (value) {
        _searchBooks(value);
      },
    );
  }
}