import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBookScreen extends StatefulWidget {
  @override
  _AddBookScreenState createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final List<Map<String, TextEditingController>> _chapters = [];
  String? _coverUrl;

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      final file = result.files.first;
      final ref = FirebaseStorage.instance.ref().child('book_covers').child(file.name);
      final uploadTask = ref.putData(file.bytes!);
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      setState(() {
        _coverUrl = url;
      });
    }
  }

  Future<void> _addBook() async {
    final title = _titleController.text;
    final author = _authorController.text.isNotEmpty ? _authorController.text : '不明';
    final summary = _summaryController.text;
    final coverUrl = _coverUrl ?? 'https://via.placeholder.com/150';

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }

    final bookRef = FirebaseFirestore.instance.collection('books').doc();

    await bookRef.set({
      'title': title,
      'author': author,
      'summary': summary,
      'cover_url': coverUrl,
    });

    for (var i = 0; i < _chapters.length; i++) {
      final chapterTitle = _chapters[i]['title']!.text;
      final chapterContent = _chapters[i]['content']!.text;

      // 章を保存
      final chapterRef = await bookRef.collection('chapters').add({
        'title': chapterTitle,
        'content': chapterContent,
        'order': i,
      });

      // 章の内容を文ごとに分割して保存
      List<String> sentences = chapterContent.split(RegExp(r'(?<=。)')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      int startIndex = 0; // 開始位置を初期化
      for (String sentence in sentences) {
        int endIndex = startIndex + sentence.length; // 終了位置を計算
        await chapterRef.collection('sentences').add({
          'text': sentence,
          'start': startIndex,
          'end': endIndex,
        });
        startIndex = endIndex; // 次の文の開始位置を更新
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('書籍が追加されました')),
    );
  }

  void _addChapter() {
    setState(() {
      _chapters.add({
        'title': TextEditingController(),
        'content': TextEditingController(),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('書籍を追加'),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'タイトル',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _authorController,
                decoration: InputDecoration(
                  labelText: '著者',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _summaryController,
                decoration: InputDecoration(
                  labelText: '本の概要',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                maxLines: 3,
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: _pickCoverImage,
                child: Text('表紙画像を選択'),
              ),
              if (_coverUrl != null) 
                Image.network(_coverUrl!, height: 150, fit: BoxFit.cover),
              if (_coverUrl == null)
                Image.network('https://via.placeholder.com/150', height: 150, fit: BoxFit.cover),
              SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _chapters.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      TextField(
                        controller: _chapters[index]['title'],
                        decoration: InputDecoration(
                          labelText: '章タイトル',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _chapters[index]['content'],
                        decoration: InputDecoration(
                          labelText: '章内容',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        maxLines: 3,
                      ),
                      Divider(),
                    ],
                  );
                },
              ),
              TextButton(
                onPressed: _addChapter,
                child: Text('章を追加'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addBook,
                child: Text('書籍を保存'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 60),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register_category');
                },
                child: Text('カテゴリー登録へ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}