import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'providers/comment_reply_provider.dart';
import 'comment_list.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class CommentDetailScreen extends StatefulWidget {
  final String bookId;
  final String chapterId;

  CommentDetailScreen({required this.bookId, required this.chapterId});

  @override
  _CommentDetailScreenState createState() => _CommentDetailScreenState();
}

class _CommentDetailScreenState extends State<CommentDetailScreen> {
  late String bookId;
  late String chapterId;
  final TextEditingController _commentController = TextEditingController();
  String? _currentUserProfileImage;

  @override
  void initState() {
    super.initState();
    _loadArgsFromPreferences();
    _loadCurrentUserProfileImage();
    _commentController.addListener(_updateButtonState);
    _commentController.clear(); // ここで��ィールドを空にする

    // コメントをリアルタイムで得
    Provider.of<CommentReplyProvider>(context, listen: false).loadComments(widget.bookId, widget.chapterId);
  }

  @override
  void dispose() {
    _commentController.removeListener(_updateButtonState);
    _commentController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      bookId = args['bookId'];
      chapterId = args['chapterId'];
      _saveArgsToPreferences(args);

      // 引数のログ出力
      print('Received bookId: $bookId');
      print('Received chapterId: $chapterId');

      // 引数を受け取った後にフィールドを空にする
      _commentController.clear(); // ここでフィールドを空にする
    } else {
      setState(() {
        bookId = '';
        chapterId = '';
      });
    }
  }

  Future<void> _saveArgsToPreferences(Map<String, dynamic> args) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('commentArgs', jsonEncode(args));
  }

  Future<void> _loadArgsFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final argsString = prefs.getString('commentArgs');
    if (argsString != null) {
      final args = jsonDecode(argsString) as Map<String, dynamic>;
      setState(() {
        bookId = args['bookId'];
        chapterId = args['chapterId'];
      });
    } else {
      setState(() {
        bookId = '';
        chapterId = '';
      });
    }
  }

  Future<void> _loadCurrentUserProfileImage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      setState(() {
        _currentUserProfileImage = userSnapshot['profileImageUrl'] ?? 'https://via.placeholder.com/150';
      });
    }
  }

  Future<void> _addComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginAlert();
      return;
    }

    if (_commentController.text.isEmpty) {
      return; // コメントが空の場合は何もしない
    }

    try {
      // CommentReplyProviderからaddCommentを呼び出す
      await Provider.of<CommentReplyProvider>(context, listen: false)
          .addComment(bookId, chapterId, user.uid, _commentController.text);

      _commentController.clear(); // コメント入力フィールドをクリア
    } catch (e) {
      print('Error adding comment: $e'); // エラーハンドリング
    }
  }

  void _showLoginAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ログインが必要です'),
        content: Text('この操作を行うにはログインが必要です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bookId.isEmpty || chapterId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('エラー')),
        body: Center(child: Text('コメントデータがありません')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => CommentReplyProvider()..loadComments(widget.bookId, widget.chapterId),
      child: Scaffold(
        appBar: AppBar(title: Text('コメント')),
        body: Consumer<CommentReplyProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(child: CircularProgressIndicator());
            }
            if (provider.comments.isEmpty && !provider.isLoading) {
              return Center(child: Text('コメントがありません')); // コメントが一つもない場合の表示
            }
            return CommentList(bookId: widget.bookId, chapterId: widget.chapterId);
          },
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: _currentUserProfileImage != null
                    ? NetworkImage(_currentUserProfileImage!)
                    : null,
                child: _currentUserProfileImage == null
                    ? ProfilePicture(
                        name: FirebaseAuth.instance.currentUser!.displayName ?? 'User',
                        radius: 31,
                        fontsize: 21,
                        random: true,
                      )
                    : null,
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'コメントを追加...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0), // 縦のパディングを調整
                  ),
                ),
              ),
              SizedBox(width: 8.0),
              Container(
                width: 40.0,
                height: 40.0,
                child: ElevatedButton(
                  onPressed: _addComment,
                  child: Icon(Icons.send, size: 20.0), // アイコンの大きさを調整
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: _commentController.text.isNotEmpty ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.white,
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