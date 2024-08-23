import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentListScreen extends StatelessWidget {
  final String bookId;
  final String chapterId;
  final int start;
  final int end;

  CommentListScreen({
    required this.bookId,
    required this.chapterId,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('コメント一覧'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('books')
            .doc(bookId)
            .collection('chapters')
            .doc(chapterId)
            .collection('comments')
            .where('start', isLessThanOrEqualTo: end)
            .where('end', isGreaterThanOrEqualTo: start)
            .orderBy('start')
            .orderBy('end')
            .orderBy('created_at', descending: true)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final comments = snapshot.data!.docs;
          return ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final data = comments[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['comment']),
                subtitle: Text('選択されたテキスト: ${data['selected_text']}'),
              );
            },
          );
        },
      ),
    );
  }
}
