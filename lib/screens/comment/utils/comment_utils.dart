import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addComment(String bookId, String chapterId, String userId, String comment) async {
  await FirebaseFirestore.instance
      .collection('books')
      .doc(bookId)
      .collection('chapters')
      .doc(chapterId)
      .collection('comments')
      .add({
    'comment': comment,
    'user_id': userId,
    'created_at': FieldValue.serverTimestamp(),
    'selected_text': '…',
  });
}

Future<void> deleteComment(String bookId, String chapterId, String commentId) async {
  await FirebaseFirestore.instance
      .collection('books')
      .doc(bookId)
      .collection('chapters')
      .doc(chapterId)
      .collection('comments')
      .doc(commentId)
      .delete();
}

Future<void> addReply(String bookId, String chapterId, String commentId, String userId, String reply) async {
  await FirebaseFirestore.instance
      .collection('books')
      .doc(bookId)
      .collection('chapters')
      .doc(chapterId)
      .collection('comments')
      .doc(commentId)
      .collection('replies')
      .add({
    'reply': reply,
    'user_id': userId,
    'created_at': FieldValue.serverTimestamp(),
  });
}

Future<void> deleteReply(String bookId, String chapterId, String commentId, String replyId) async {
  await FirebaseFirestore.instance
      .collection('books')
      .doc(bookId)
      .collection('chapters')
      .doc(chapterId)
      .collection('comments')
      .doc(commentId)
      .collection('replies')
      .doc(replyId)
      .delete();
}
