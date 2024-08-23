import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookListScreen extends StatefulWidget {
  @override
  _BookListScreenState createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchText = prefs.getString('searchText') ?? '';
      _searchController.text = _searchText;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('searchText', _searchText);
  }

  void _searchBooks(String query) {
    setState(() {
      _searchText = query;
    });
    _saveState();
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('書籍一覧'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: BookSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '検索',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchBooks,
            ),
            SizedBox(height: 20),
            // カテゴリーフィルタリング用のドロップダウン
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('categories').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final categories = snapshot.data!.docs;
                return DropdownButton<String>(
                  value: _selectedCategory.isEmpty ? null : _selectedCategory,
                  hint: Text('カテゴリーでフィルタリング'),
                  onChanged: (value) {
                    _filterByCategory(value!);
                  },
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category['name']),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _searchText.isEmpty
                    ? (_selectedCategory.isEmpty
                        ? FirebaseFirestore.instance.collection('books').snapshots()
                        : FirebaseFirestore.instance
                            .collection('books')
                            .where('categories', arrayContains: _selectedCategory)
                            .snapshots())
                    : FirebaseFirestore.instance
                        .collection('books')
                        .where('title', isGreaterThanOrEqualTo: _searchText)
                        .where('title', isLessThanOrEqualTo: '$_searchText\uf8ff')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final books = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index].data() as Map<String, dynamic>;
                      final bookId = books[index].id;
                      return ListTile(
                        leading: book['cover_url'] != null
                            ? Image.network(book['cover_url'], width: 50, fit: BoxFit.cover)
                            : Icon(Icons.book),
                        title: Text(book['title'] ?? 'No Title'),
                        subtitle: FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('books')
                              .doc(bookId)
                              .collection('categories')
                              .get(),
                          builder: (context, categorySnapshot) {
                            if (!categorySnapshot.hasData) {
                              return Text('Loading categories...');
                            }
                            final categories = categorySnapshot.data!.docs.map((doc) => doc['name']).join(', ');
                            return Text(categories);
                          },
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/bookdetails', arguments: bookId);
                        },
                      );
                    },
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

class BookSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.isEmpty
          ? FirebaseFirestore.instance.collection('books').snapshots()
          : FirebaseFirestore.instance
              .collection('books')
              .where('title', isGreaterThanOrEqualTo: query)
              .where('title', isLessThanOrEqualTo: '$query\uf8ff')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final books = snapshot.data!.docs;
        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index].data() as Map<String, dynamic>;
            final bookId = books[index].id;
            return ListTile(
              leading: book['cover_url'] != null
                  ? Image.network(book['cover_url'], width: 50, fit: BoxFit.cover)
                  : Icon(Icons.book),
              title: Text(book['title'] ?? 'No Title'),
              subtitle: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('books')
                    .doc(bookId)
                    .collection('categories')
                    .get(),
                builder: (context, categorySnapshot) {
                  if (!categorySnapshot.hasData) {
                    return Text('Loading categories...');
                  }
                  final categories = categorySnapshot.data!.docs.map((doc) => doc['name']).join(', ');
                  return Text(categories);
                },
              ),
              onTap: () {
                Navigator.pushNamed(context, '/bookdetails', arguments: bookId);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.isEmpty
          ? FirebaseFirestore.instance.collection('books').snapshots()
          : FirebaseFirestore.instance
              .collection('books')
              .where('title', isGreaterThanOrEqualTo: query)
              .where('title', isLessThanOrEqualTo: '$query\uf8ff')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final books = snapshot.data!.docs;
        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index].data() as Map<String, dynamic>;
            final bookId = books[index].id;
            return ListTile(
              leading: book['cover_url'] != null
                  ? Image.network(book['cover_url'], width: 50, fit: BoxFit.cover)
                  : Icon(Icons.book),
              title: Text(book['title'] ?? 'No Title'),
              subtitle: FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('books')
                    .doc(bookId)
                    .collection('categories')
                    .get(),
                builder: (context, categorySnapshot) {
                  if (!categorySnapshot.hasData) {
                    return Text('Loading categories...');
                  }
                  final categories = categorySnapshot.data!.docs.map((doc) => doc['name']).join(', ');
                  return Text(categories);
                },
              ),
              onTap: () {
                Navigator.pushNamed(context, '/bookdetails', arguments: bookId);
              },
            );
          },
        );
      },
    );
  }
}