import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reply_section.dart';
import 'like_button.dart';
import 'utils/comment_utils.dart';
import 'utils/user_utils.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:provider/provider.dart'; // 追加
import 'providers/comment_reply_provider.dart';

class CommentItem extends StatefulWidget {
  final DocumentSnapshot comment;
  final String bookId;
  final String chapterId;

  CommentItem({required this.comment, required this.bookId, required this.chapterId});

  @override
  _CommentItemState createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, bool> _isReplying = {};
  final Map<String, bool> _isReplyDetailsVisible = {};

  @override
  Widget build(BuildContext context) {
    final commentData = widget.comment.data() as Map<String, dynamic>;

    // User IDのnullチェック
    final userId = commentData['userId'] ?? '不明'; // デフォルト値を設定
    final selectedText = commentData['selectedText'] ?? '選択されたテキストはありません'; // デフォルト値を設定
    final commentText = commentData['comment'] ?? 'コメントがありません'; // デフォルト値を設定

    print('User ID: $userId');
    print('Selected Text: $selectedText');
    print('Comment: $commentText');

    final commentUserId = userId;
    final commentId = widget.comment.id;

    return FutureBuilder<DocumentSnapshot>(
      future: getUserInfo(commentUserId),
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
        final user = userSnapshot.data!.data() as Map<String, dynamic>;
        final username = user['username'] ?? 'Unknown';
        final userProfileImage = user['profileImageUrl'] ?? '';
        final likes = commentData.containsKey('likes') ? List<String>.from(commentData['likes']) : [];
        final isLiked = likes.contains(FirebaseAuth.instance.currentUser?.uid);

        // ユーザー情報のログ出力
        print('User Data: $user');
        print('Username: $username');
        print('Profile Image URL: $userProfileImage');

        _replyControllers[commentId] ??= TextEditingController();
        _isReplying[commentId] ??= false;
        _isReplyDetailsVisible[commentId] ??= false;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: userProfileImage.isNotEmpty
                        ? NetworkImage(userProfileImage)
                        : null,
                    child: userProfileImage.isEmpty
                        ? ProfilePicture(
                            name: username,
                            radius: 31,
                            fontsize: 21,
                            random: true,
                          )
                        : null,
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username, style: TextStyle(fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () {
                            _showFullTextPopup(context, selectedText);
                          },
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                            child: Text(
                              '$selectedText',
                              style: TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (commentUserId == FirebaseAuth.instance.currentUser?.uid)
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => deleteComment(widget.bookId, widget.chapterId, commentId),
                    ),
                ],
              ),
              SizedBox(height: 4.0),
              GestureDetector(
                onTap: () {
                  _showFullCommentDialog(context, commentText);
                },
                child: Container(
                  margin: EdgeInsets.only(left: 48.0),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  child: Text(
                    commentText,
                    style: TextStyle(fontSize: 16.0),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5, // コメントは最大5行まで表示される
                  ),
                ),
              ),
              SizedBox(height: 4.0),
              Container(
                margin: EdgeInsets.only(left: 48.0), // コメント本文と同じ開始位置に揃える
                child: Row(
                  children: [
                    LikeButton(
                      isLiked: isLiked,
                      likes: List<String>.from(likes),
                      comment: widget.comment,
                    ),
                    Text('${likes.length}'), // いいねの数を表示
                    SizedBox(width: 8.0),
                    IconButton(
                      icon: Icon(Icons.sms),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/reply_list',
                          arguments: {
                            'comment': widget.comment,
                            'bookId': widget.bookId,
                            'chapterId': widget.chapterId,
                          },
                        );
                      },
                    ),
                    // ここで返信数を表示
                    FutureBuilder<int>(
                      future: Provider.of<CommentReplyProvider>(context, listen: false)
                          .getReplyCount(widget.bookId, widget.chapterId, commentId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator(); // ローディング中
                        }
                        if (snapshot.hasError) {
                          return Text('エラー'); // エラー処理
                        }
                        return Text('${snapshot.data}'); // 返信数を表示
                      },
                    ),
                  ],
                ),
              ),
              if (_isReplyDetailsVisible[commentId]!)
                ReplySection(
                  commentId: commentId,
                  bookId: widget.bookId,
                  chapterId: widget.chapterId,
                  replyControllers: _replyControllers,
                  isReplying: _isReplying,
                ),
              if (_isReplying[commentId]!)
                Padding(
                  padding: const EdgeInsets.only(left: 48.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: userProfileImage.isNotEmpty
                            ? NetworkImage(userProfileImage)
                            : null,
                        child: userProfileImage.isEmpty
                            ? ProfilePicture(
                                name: username,
                                radius: 31,
                                fontsize: 21,
                                random: true,
                              )
                            : null,
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          controller: _replyControllers[commentId],
                          decoration: InputDecoration(
                            hintText: '返信する...',
                            border: InputBorder.none,
                          ),
                          onChanged: (text) {
                            setState(() {});
                          },
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isReplying[commentId] = false;
                          });
                        },
                        child: Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () {
                          addReply(widget.bookId, widget.chapterId, commentId, FirebaseAuth.instance.currentUser!.uid, _replyControllers[commentId]!.text);
                          _replyControllers[commentId]?.clear();
                          setState(() {
                            _isReplying[commentId] = false;
                          });
                        },
                        child: Text('返信'),
                        style: TextButton.styleFrom(
                          backgroundColor: _replyControllers[commentId]!.text.isNotEmpty ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
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

  void _showFullCommentDialog(BuildContext context, String comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('コメント全文'),
        content: Text(comment),
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