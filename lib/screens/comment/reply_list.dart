import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'providers/comment_reply_provider.dart';
import 'utils/comment_utils.dart';
import 'utils/user_utils.dart';
import 'like_button.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class ReplyList extends StatelessWidget {
  final String bookId;
  final String chapterId;
  final String commentId;

  ReplyList({required this.bookId, required this.chapterId, required this.commentId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommentReplyProvider()..loadReplies(bookId, chapterId, commentId),
      child: Consumer<CommentReplyProvider>(
        builder: (context, provider, child) {
          if (provider.replies.isEmpty) {
            print('No replies found');
            return Center(child: Text('返信がありません'));
          }
          return ListView.builder(
            itemCount: provider.replies.length,
            itemBuilder: (context, index) {
              final reply = provider.replies[index];
              final replyData = reply.data() as Map<String, dynamic>?;

              // 返信データのログ出力
              print('Reply Data: $replyData');

              if (replyData == null) {
                return ListTile(
                  title: Text('データがありません'),
                  subtitle: Text('この返信データは存在しません。'),
                );
              }

              final replyUserId = replyData['user_id'];
              final currentUser = FirebaseAuth.instance.currentUser;
              final likes = replyData.containsKey('likes') ? List<String>.from(replyData['likes']) : [];
              final isLiked = likes.contains(FirebaseAuth.instance.currentUser?.uid);

              return FutureBuilder<DocumentSnapshot>(
                future: getUserInfo(replyUserId),
                builder: (context, replyUserSnapshot) {
                  if (!replyUserSnapshot.hasData) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage('https://dummyimage.com/150'),
                      ),
                      title: Text('Unknown User'),
                      subtitle: Text(replyData['reply'] ?? 'No reply'),
                    );
                  }
                  if (replyUserSnapshot.hasError) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage('https://dummyimage.com/150'),
                      ),
                      title: Text('Error'),
                      subtitle: Text(replyData['reply'] ?? 'No reply'),
                    );
                  }

                  final replyUserData = replyUserSnapshot.data?.data() as Map<String, dynamic>?;

                  if (replyUserData == null) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage('https://dummyimage.com/150'),
                      ),
                      title: Text('ユーザーデータがありません'),
                      subtitle: Text('このユーザーデータは存在しません。'),
                    );
                  }

                  final replyUserProfileImage = replyUserData['profileImageUrl'] ?? '';
                  final replyUsername = replyUserData['username'] ?? 'Unknown';

                  return ListTile(
                    title: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: replyUserProfileImage.isNotEmpty
                                ? NetworkImage(replyUserProfileImage)
                                : NetworkImage('https://dummyimage.com/150'),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(replyUsername),
                                    ),
                                    if (replyUserId == currentUser?.uid)
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        iconSize: 16.0,
                                        onPressed: () => deleteReply(bookId, chapterId, commentId, reply.id),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  replyData['reply'] ?? 'No reply',
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                ),
                                Row(
                                  children: [
                                    LikeButton(
                                      isLiked: isLiked,
                                      likes: List<String>.from(likes),
                                      comment: reply,
                                    ),
                                    SizedBox(width: 4.0),
                                    Text('${likes.length}'), // いいねの数を表示
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}