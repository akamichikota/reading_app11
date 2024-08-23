import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'providers/comment_reply_provider.dart';
import 'text_comment_list.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class TextCommentScreen extends StatefulWidget {
  final String bookId;
  final String chapterId;
  final int start;
  final int end;
  final String selectedText;

  TextCommentScreen({required this.bookId, required this.chapterId, required this.start, required this.end, required this.selectedText});
  
  @override
  _TextCommentScreenState createState() => _TextCommentScreenState();
}

class _TextCommentScreenState extends State<TextCommentScreen> {
  late String bookId;
  late String chapterId;
  late int start;
  late int end;
  late String selectedText;
  final TextEditingController _commentController = TextEditingController();
  String? _currentUserProfileImage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfileImage();
    _commentController.addListener(_updateButtonState);
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
    final route = ModalRoute.of(context);
    if (route != null) {
      final args = route.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          bookId = args['bookId'] ?? '';
          chapterId = args['chapterId'] ?? '';
          start = args['start'] ?? 0;
          end = args['end'] ?? 0;
          selectedText = args['selectedText'] ?? ''; // 選択テキストを取得
        });
        _saveArgsToPreferences(args);

        // 引数のログ出力
        print('Received bookId: $bookId, chapterId: $chapterId, start: $start, end: $end, selectedText: $selectedText');

        // コメントをリアルタイムで取得
        Provider.of<CommentReplyProvider>(context, listen: false).loadSelectedTextComments(bookId, chapterId, start, end);
      } else {
        setState(() {
          bookId = '';
          chapterId = '';
          start = 0;
          end = 0;
          selectedText = '';
        });
        print('引数が正しく渡されていません');
      }
    }
  }

  Future<void> _saveArgsToPreferences(Map<String, dynamic> args) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('commentArgs', jsonEncode(args));
  }

  Future<void> _loadCurrentUserProfileImage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (userSnapshot.exists) {
        setState(() {
          _currentUserProfileImage = userSnapshot.data()?['profileImageUrl'] ?? 'https://dummyimage.com/150';
        });
      }
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
      // CommentReplyProviderからaddTextCommentを呼び出す
      await Provider.of<CommentReplyProvider>(context, listen: false)
          .addTextComment(bookId, chapterId, user.uid, _commentController.text, start, end, selectedText);

      _commentController.clear(); // コメント入力フィールドをクリア

      // コメント追加後にコメントリストを再読み込み
      Provider.of<CommentReplyProvider>(context, listen: false).loadSelectedTextComments(bookId, chapterId, start, end);
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

  void _showFullTextDialog(String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('選択テキスト'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('閉じる'),
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
      create: (_) => CommentReplyProvider()..loadSelectedTextComments(bookId, chapterId, start, end),
      child: Scaffold(
        appBar: AppBar(title: Text('コメント')),
        body: Column(
          children: [
            GestureDetector(
              onTap: () => _showFullTextDialog(selectedText),
              child: Container(
                padding: EdgeInsets.all(16.0),

                child: Text(
                  selectedText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Divider(),
            Expanded(
              child: Consumer<CommentReplyProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (provider.comments.isEmpty && !provider.isLoading) {
                    return Center(child: Text('コメントがありません')); // コメントが一つもない場合の表示
                  }
                  // コメントが取得された場合、ログを出力
                  print('Received comments: ${provider.comments.map((comment) => comment.data()).toList()}');
                  return TextCommentList(bookId: widget.bookId, chapterId: widget.chapterId, start: start, end: end);
                },
              ),
            ),
          ],
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
                        name: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
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
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                  ),
                ),
              ),
              SizedBox(width: 8.0),
              Container(
                width: 40.0,
                height: 40.0,
                child: ElevatedButton(
                  onPressed: _addComment,
                  child: Icon(Icons.send, size: 20.0),
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