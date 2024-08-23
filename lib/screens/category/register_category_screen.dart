import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RegisterCategoryScreen extends StatefulWidget {
  @override
  _RegisterCategoryScreenState createState() => _RegisterCategoryScreenState();
}

class _RegisterCategoryScreenState extends State<RegisterCategoryScreen> {
  String? _selectedBookId;
  String? _wideCoverUrl;
  List<String> _selectedCategories = [];
  List<Map<String, dynamic>> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('categories').get();
    final List<Map<String, dynamic>> categories = snapshot.docs.map((doc) => {
      'id': doc.id,
      'name': doc['name']
    }).toList();

    setState(() {
      _availableCategories = categories;
    });
  }

  Future<void> _pickWideCoverImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      final file = result.files.first;
      final ref = FirebaseStorage.instance.ref().child('wide_book_covers').child(file.name);
      final uploadTask = ref.putData(file.bytes!);
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      setState(() {
        _wideCoverUrl = url;
      });
    }
  }

  Future<void> _recommendBook() async {
    if (_selectedBookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('本を選択してください')),
      );
      return;
    }

    final bookRef = FirebaseFirestore.instance.collection('books').doc(_selectedBookId);

    await bookRef.update({
      'wide_cover_url': _wideCoverUrl ?? 'https://via.placeholder.com/300x100',
      'is_recommended': true,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('書籍がおすすめとして登録されました')),
    );

    setState(() {
      _selectedBookId = null;
      _wideCoverUrl = null;
    });
  }

  Future<void> _addCategories() async {
    if (_selectedBookId == null || _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('本とカテゴリーを選択してください')),
      );
      return;
    }

    final bookRef = FirebaseFirestore.instance.collection('books').doc(_selectedBookId);

    for (String categoryId in _selectedCategories) {
      final categoryDoc = FirebaseFirestore.instance.collection('categories').doc(categoryId);
      final categorySnapshot = await categoryDoc.get();
      if (categorySnapshot.exists) {
        await bookRef.collection('categories').doc(categoryId).set({
          'name': categorySnapshot['name'],
        });
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('カテゴリーが登録されました')),
    );

    setState(() {
      _selectedBookId = null;
      _selectedCategories = [];
    });
  }

  Future<void> _removeCategories() async {
    if (_selectedBookId == null || _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('本とカテゴリーを選択してください')),
      );
      return;
    }

    final bookRef = FirebaseFirestore.instance.collection('books').doc(_selectedBookId);

    for (String categoryId in _selectedCategories) {
      await bookRef.collection('categories').doc(categoryId).delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('カテゴリーが削除されました')),
    );

    setState(() {
      _selectedBookId = null;
      _selectedCategories = [];
    });
  }

  Future<void> _removeFromRecommended(String bookId) async {
    final bookRef = FirebaseFirestore.instance.collection('books').doc(bookId);

    await bookRef.update({
      'wide_cover_url': FieldValue.delete(),
      'is_recommended': FieldValue.delete(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('書籍がおすすめ本から削除されました')),
    );
  }

  Widget _buildRecommendedBookList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('books').where('is_recommended', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final books = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index].data() as Map<String, dynamic>;
            return Card(
              color: Colors.grey[200],
              child: ListTile(
                leading: Image.network(book['cover_url'], width: 50, height: 75, fit: BoxFit.cover),
                title: Row(
                  children: [
                    if (book['wide_cover_url'] != null)
                      Image.network(book['wide_cover_url'], width: 150, height: 50, fit: BoxFit.cover)
                    else
                      Container(width: 150, height: 50, color: Colors.grey),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('著者: ${book['author']}'),
                        ],
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFromRecommended(books[index].id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryCheckboxList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _availableCategories.length,
      itemBuilder: (context, index) {
        final category = _availableCategories[index];
        return CheckboxListTile(
          title: Text(category['name']),
          value: _selectedCategories.contains(category['id']),
          onChanged: (isSelected) {
            setState(() {
              if (isSelected == true) {
                _selectedCategories.add(category['id']);
              } else {
                _selectedCategories.remove(category['id']);
              }
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('本の管理'),
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pushNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('books').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final books = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedBookId,
                    onChanged: (value) {
                      setState(() {
                        _selectedBookId = value;
                      });
                    },
                    items: books.map((book) {
                      return DropdownMenuItem<String>(
                        value: book.id,
                        child: Text(book['title']),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: '本を選択',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  );
                },
              ),
              SizedBox(height: 10),
              Text('おすすめの本として登録', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: _pickWideCoverImage,
                child: Text('横長のカバー画像を選択'),
              ),
              if (_wideCoverUrl != null)
                Image.network(_wideCoverUrl!, height: 100, fit: BoxFit.cover),
              if (_wideCoverUrl == null)
                Image.network('https://via.placeholder.com/300x100', height: 100, fit: BoxFit.cover),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _recommendBook,
                child: Text('おすすめ本として登録'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('カテゴリーとして登録', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildCategoryCheckboxList(),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addCategories,
                child: Text('カテゴリーを登録'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _removeCategories,
                child: Text('カテゴリーを削除'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('おすすめの本一覧', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildRecommendedBookList(),
            ],
          ),
        ),
      ),
    );
  }
}