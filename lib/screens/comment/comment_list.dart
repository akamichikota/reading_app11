import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/comment_reply_provider.dart';
import 'comment_item.dart';

class CommentList extends StatelessWidget {
  final String bookId;
  final String chapterId;

  CommentList({required this.bookId, required this.chapterId});

  @override
  Widget build(BuildContext context) {
    return Consumer<CommentReplyProvider>(
      builder: (context, provider, child) {
        if (provider.comments.isEmpty) {
          return Center(child: Text('コメントがありません')); // コメントが一つもない場合の表示
        }
        // クエリ結果のログを追加
        print('Comments in CommentList: ${provider.comments.map((doc) => doc.data()).toList()}');
        return ListView.builder(
          itemCount: provider.comments.length,
          itemBuilder: (context, index) {
            final comment = provider.comments[index];
            return CommentItem(comment: comment, bookId: bookId, chapterId: chapterId);
          },
        );
      },
    );
  }
}