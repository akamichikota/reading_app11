import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/comment_service.dart';
import '../../utils/dialog_util.dart';
import '../../utils/preferences_util.dart';

class ReadingScreen extends StatefulWidget {
  @override
  _ReadingScreenState createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isDialogVisible = false;
  Map<String, dynamic>? book;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      book = args;
      saveBookToPreferences(book!);
    } else {
      loadBookFromPreferences((bookData) {
        setState(() {
          book = bookData;
        });
      });
    }
  }

  Future<void> _addComment(String chapterId, String selectedText, int start, int end) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showLoginAlert(context);
      return;
    }

    if (_commentController.text.isEmpty) {
      return;
    }

    await CommentService.addComment(
      book!['id'],
      chapterId,
      user.uid,
      _commentController.text,
      selectedText,
      start,
      end
    );
    _commentController.clear();
  }

  Future<void> _saveSelectedText(String chapterId, String selectedText, int start, int end) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showLoginAlert(context);
      return;
    }

    await CommentService.saveSelectedText(book!, chapterId, user.uid, selectedText, start, end);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('テキストが保存されました')));
  }

  void _showAddCommentDialog(String chapterId, String selectedText, int start, int end) {
    if (_isDialogVisible) return;
    _isDialogVisible = true;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('コメント'),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                  _isDialogVisible = false;
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, // 左寄せに設定
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(selectedText),
                    ),
                    IconButton(
                      icon: Icon(Icons.save),
                      onPressed: () {
                        _saveSelectedText(chapterId, selectedText, start, end);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          labelText: 'コメントを入力',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        _addComment(chapterId, selectedText, start, end);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _isDialogVisible = false;
                  Navigator.pushNamed(
                    context,
                    '/text_comment',
                    arguments: {'bookId': book!['id'], 'chapterId': chapterId, 'start': start, 'end': end, 'selectedText': selectedText},
                  );
                },
                child: Text('コメントを見る'),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      _isDialogVisible = false;
    });
  }

  void _showChapterSelectionDialog(List<Map<String, dynamic>> chapters, String bookId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('章を選択'),
          content: SingleChildScrollView(
            child: ListBody(
              children: chapters.map((chapter) {
                return ListTile(
                  title: Text(chapter['title']),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      '/comment_detail',
                      arguments: {'bookId': bookId, 'chapterId': chapter['id']},
                    );
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: Text('エラー')),
        body: Center(child: Text('本のデータがありません')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(book!['title'] ?? ''),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('books')
              .doc(book!['id'])
              .collection('chapters')
              .orderBy('order')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final chapters = snapshot.data!.docs.map((doc) {
              return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
            }).toList();

            return ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, chapterIndex) {
                final chapter = chapters[chapterIndex];
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('books')
                      .doc(book!['id'])
                      .collection('chapters')
                      .doc(chapter['id'])
                      .collection('sentences')
                      .orderBy('start')
                      .snapshots(),
                  builder: (context, sentenceSnapshot) {
                    if (!sentenceSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final sentences = sentenceSnapshot.data!.docs.map((doc) {
                      return {
                        'text': doc['text'],
                        'start': doc['start'],
                        'end': doc['end'],
                      };
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        Text(
                          chapter['title'],
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Wrap(
                            spacing: 4.0,
                            runSpacing: 4.0,
                            children: sentences.map((sentence) {
                              return FutureBuilder<int>(
                                future: CommentService.getCommentCount(
                                  book!['id'],
                                  chapter['id'],
                                  sentence['start'],
                                  sentence['end'],
                                ),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Text(
                                      sentence['text'] + ' ',
                                      style: TextStyle(height: 1.5),
                                    );
                                  }

                                  final commentCount = snapshot.data!;
                                  return GestureDetector(
                                    onDoubleTap: () {
                                      final text = sentence['text'];
                                      final start = sentence['start'];
                                      final end = sentence['end'];

                                      _showAddCommentDialog(chapter['id'], text, start, end);
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: sentence['text'] + ' ',
                                            style: TextStyle(
                                              height: 1.5,
                                              color: Colors.black, // スタイルを統一
                                            ),
                                          ),
                                          if (commentCount > 0)
                                            TextSpan(
                                              text: '[$commentCount]　',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          FirebaseFirestore.instance
              .collection('books')
              .doc(book!['id'])
              .collection('chapters')
              .orderBy('order')
              .get()
              .then((snapshot) {
            final chapters = snapshot.docs.map((doc) {
              return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
            }).toList();
            _showChapterSelectionDialog(chapters, book!['id']);
          });
        },
        child: Icon(Icons.comment, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
    );
  }
}