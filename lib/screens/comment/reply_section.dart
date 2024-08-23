import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/comment_utils.dart';
import 'utils/user_utils.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class ReplySection extends StatelessWidget {
  final String commentId;
  final String bookId;
  final String chapterId;
  final Map<String, TextEditingController> replyControllers;
  final Map<String, bool> isReplying;

  ReplySection({
    required this.commentId,
    required this.bookId,
    required this.chapterId,
    required this.replyControllers,
    required this.isReplying,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundImage: FirebaseAuth.instance.currentUser!.photoURL != null
                  ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                  : null,
              child: FirebaseAuth.instance.currentUser!.photoURL == null
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
                controller: replyControllers[commentId] ??= TextEditingController(),
                decoration: InputDecoration(
                  hintText: '返信する...',
                  border: InputBorder.none,
                ),
                onChanged: (text) {
                  // 状態を更新するためにsetStateを呼び出す
                  (context as Element).markNeedsBuild();
                },
              ),
            ),
            TextButton(
              onPressed: replyControllers[commentId]!.text.isNotEmpty
                  ? () => _addReply(context, commentId)
                  : null,
              child: Text('返信'),
              style: TextButton.styleFrom(
                backgroundColor: replyControllers[commentId]!.text.isNotEmpty ? Colors.blue : Colors.grey,
              ),
            ),
          ],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('books')
              .doc(bookId)
              .collection('chapters')
              .doc(chapterId)
              .collection('comments')
              .doc(commentId)
              .collection('replies')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            final replies = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: replies.length,
              itemBuilder: (context, index) {
                final reply = replies[index].data() as Map<String, dynamic>;
                final replyUserId = reply['user_id'];

                return FutureBuilder<DocumentSnapshot>(
                  future: getUserInfo(replyUserId),
                  builder: (context, replyUserSnapshot) {
                    if (!replyUserSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (replyUserSnapshot.hasError) {
                      return Center(child: Text('エラー: ${replyUserSnapshot.error}'));
                    }
                    if (!replyUserSnapshot.data!.exists) {
                      return Center(child: Text('ユーザーが見つかりません'));
                    }
                    final replyUser = replyUserSnapshot.data!.data() as Map<String, dynamic>;
                    final replyUsername = replyUser['username'] ?? 'Unknown';
                    final replyUserProfileImage = replyUser['profileImageUrl'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(left: 40.0, top: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: replyUserProfileImage.isNotEmpty
                                ? NetworkImage(replyUserProfileImage)
                                : null,
                            child: replyUserProfileImage.isEmpty
                                ? ProfilePicture(
                                    name: replyUsername,
                                    radius: 31,
                                    fontsize: 21,
                                    random: true,
                                  )
                                : null,
                          ),
                          SizedBox(width: 8.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                replyUsername,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                                child: Text(
                                  reply['reply'],
                                  style: TextStyle(fontSize: 12.0),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _addReply(BuildContext context, String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginAlert(context);
      return;
    }

    final controller = replyControllers[commentId];
    if (controller != null && controller.text.isNotEmpty) {
      await addReply(bookId, chapterId, commentId, user.uid, controller.text);
      controller.clear();
      (context as Element).markNeedsBuild();
    }
  }

  void _showLoginAlert(BuildContext context) {
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
}