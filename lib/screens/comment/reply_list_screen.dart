import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reply_list.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class ReplyListScreen extends StatefulWidget {
  final DocumentSnapshot comment;
  final String bookId;
  final String chapterId;

  ReplyListScreen({required this.comment, required this.bookId, required this.chapterId});

  @override
  _ReplyListScreenState createState() => _ReplyListScreenState();
}

class _ReplyListScreenState extends State<ReplyListScreen> {
  final TextEditingController _replyController = TextEditingController();
  String? _currentUserProfileImage;

  @override
  void initState() {
    super.initState();
    _loadState();
    _loadCurrentUserProfileImage();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _replyController.text = prefs.getString('replyText') ?? '';
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('replyText', _replyController.text);
  }

  Future<void> _loadCurrentUserProfileImage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (userSnapshot.exists) {
        setState(() {
          _currentUserProfileImage = userSnapshot['profileImageUrl'] ?? 'https://via.placeholder.com/150';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentData = widget.comment.data() as Map<String, dynamic>?; 
    if (commentData == null) {
      return Center(child: Text('コメントデータが見つかりません'));
    }

    final userId = commentData['userId'];
    if (userId == null) {
      return Center(child: Text('ユーザーIDが見つかりません'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('返信一覧'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasError) {
            return Center(child: Text('エラー: ${userSnapshot.error}'));
          }
          if (!userSnapshot.data!.exists) {
            return Center(child: Text('ユーザーが見つかりません'));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>?; 
          if (userData == null) {
            return Center(child: Text('ユーザーデータが見つかりません'));
          }

          final userProfileImage = userData['profileImageUrl'] ?? 'https://via.placeholder.com/150';
          final username = userData['username'] ?? 'Unknown';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(userProfileImage),
                  ),
                  title: Text(username, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: GestureDetector(
                    onTap: () {
                      _showFullTextPopup(context, commentData['selectedText']);
                    },
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                      child: Text(
                        '${commentData['selectedText']}',
                        style: TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 68.0),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  child: Text(
                    commentData['comment'] ?? 'No comment',
                    style: TextStyle(fontSize: 16.0),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 10,
                  ),
                ),
                Divider(),
                Container(
                  height: MediaQuery.of(context).size.height - 150,
                  child: ReplyList(
                    bookId: widget.bookId,
                    chapterId: widget.chapterId,
                    commentId: widget.comment.id,
                  ),
                ),
              ],
            ),
          );
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
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: '返信する...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                ),
                onChanged: (text) {
                  _saveState(); // 状態を保存
                },
              ),
            ),
            SizedBox(width: 12.0),
            ElevatedButton(
              onPressed: _replyController.text.isNotEmpty ? _addReply : null,
              child: Text('返信'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: _replyController.text.isNotEmpty ? Colors.blue : Colors.grey,
                foregroundColor: Colors.white,
                minimumSize: Size(60, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addReply() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginAlert();
      return;
    }

    if (_replyController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('books')
          .doc(widget.bookId)
          .collection('chapters')
          .doc(widget.chapterId)
          .collection('comments')
          .doc(widget.comment.id)
          .collection('replies')
          .add({
        'reply': _replyController.text,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'selectedText': '…',
      });
      _replyController.clear();
      _saveState();
      setState(() {});
    }
  }

  void _deleteReply(String replyId) async {
    await FirebaseFirestore.instance
        .collection('books')
        .doc(widget.bookId)
        .collection('chapters')
        .doc(widget.chapterId)
        .collection('comments')
        .doc(widget.comment.id)
        .collection('replies')
        .doc(replyId)
        .delete();
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

  void _showFullTextPopup(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('引用文章'),
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
}