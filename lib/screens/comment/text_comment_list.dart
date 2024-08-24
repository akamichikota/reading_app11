import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/comment_reply_provider.dart';
import 'text_comment_item.dart';

class TextCommentList extends StatelessWidget {
  final String bookId;
  final String chapterId;
  final int start;
  final int end;

  TextCommentList({required this.bookId, required this.chapterId, required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return Consumer<CommentReplyProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (provider.comments.isEmpty && !provider.isLoading) {
          return Center(child: Text('コメントがありません'));
        }
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