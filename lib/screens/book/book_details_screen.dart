import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookDetailsScreen extends StatefulWidget {
  @override
  _BookDetailsScreenState createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  Map<String, dynamic>? book;
  bool isInBookshelf = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      book = args;
      _saveBookToPreferences(book!);
      _fetchBookDetails();
      _checkIfInBookshelf();
    } else {
      _loadBookFromPreferences();
    }
    _loadState();
  }

  Future<void> _fetchBookDetails() async {
    if (book != null) {
      final bookRef = FirebaseFirestore.instance.collection('books').doc(book!['id']);
      final doc = await bookRef.get();
      setState(() {
        book = {...doc.data()!, 'id': book!['id']};
      });
    }
  }

  Future<void> _checkIfInBookshelf() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && book != null) {
      final bookshelfRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookshelf')
          .doc(book!['id']);
      final doc = await bookshelfRef.get();
      setState(() {
        isInBookshelf = doc.exists;
      });
    }
  }

  Future<void> _addToBookshelf() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && book != null) {
      final bookshelfRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookshelf')
          .doc(book!['id']);

      await bookshelfRef.set({
        'id': book!['id'], // ドキュメントIDを保存
        'title': book!['title'],
        'author': book!['author'],
        'cover_url': book!['cover_url'],
        'added_at': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('本棚に追加されました')));
      setState(() {
        isInBookshelf = true;
      });
      _saveState();
    }
  }

  Future<void> _removeFromBookshelf() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && book != null) {
      final bookshelfRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookshelf')
          .doc(book!['id']);

      await bookshelfRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('本棚から削除されました')));
      setState(() {
        isInBookshelf = false;
      });
      _saveState();
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isInBookshelf = prefs.getBool('isInBookshelf_${book?['id']}') ?? false;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isInBookshelf_${book?['id']}', isInBookshelf);
  }

  Future<void> _saveBookToPreferences(Map<String, dynamic> book) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('book', jsonEncode(book));
  }

  Future<void> _loadBookFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final bookString = prefs.getString('book');
    if (bookString != null) {
      setState(() {
        book = jsonDecode(bookString);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (book == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('本の詳細'),
        ),
        body: Center(child: Text('書籍データがありません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('本の詳細'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                book!['cover_url'] != null
                    ? Image.network(book!['cover_url'], width: 136, height: 184, fit: BoxFit.cover)
                    : Image.network('https://via.placeholder.com/150', width: 136, height: 150, fit: BoxFit.cover),
                SizedBox(width: 16.0),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book!['title'] ?? '', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8.0),
                        Text(book!['author'] ?? '不明', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                        SizedBox(height: 16.0),
                        isInBookshelf
                            ? ElevatedButton(
                                onPressed: _removeFromBookshelf,
                                style: ElevatedButton.styleFrom(
                                  side: BorderSide(color: Colors.blue),
                                  backgroundColor: Colors.white,
                                ),
                                child: Text('追加済み', style: TextStyle(color: Colors.blue)),
                              )
                            : ElevatedButton(
                                onPressed: _addToBookshelf,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // 背景色を変更
                                ),
                                child: Text('本棚追加', style: TextStyle(color: Colors.white)),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.0),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/reading',
                  arguments: book,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // 背景色を変更
                foregroundColor: Colors.white, // 文字色を白にする
                minimumSize: Size(double.infinity, 50), // 幅いっぱいに広げる
              ),
              child: Text('みんなで読む', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 48.0),
            Divider(),
            SizedBox(height: 16.0),
            Text('本の概要', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.0),
            Text(book!['summary'] ?? '概要が登録されていません', style: TextStyle(fontSize: 16)),
            SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }
}