import 'package:cloud_firestore/cloud_firestore.dart';

class CommentService {
  static Future<void> addComment(
    String bookId,
    String chapterId,
    String userId,
    String comment,
    String selectedText,
    int start,
    int end,
  ) async {
    await FirebaseFirestore.instance
        .collection('books')
        .doc(bookId)
        .collection('chapters')
        .doc(chapterId)
        .collection('comments')
        .add({
      'comment': comment,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'selectedText': selectedText,
      'start': start,
      'end': end,
    });
  }

  static Future<void> saveSelectedText(
    Map<String, dynamic> book,
    String chapterId,
    String userId,
    String selectedText,
    int start,
    int end,
  ) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('savedTexts')
        .add({
      'book_id': book['id'],
      'chapter_id': chapterId,
      'selected_text': selectedText,
      'start': start,
      'end': end,
      'created_at': FieldValue.serverTimestamp(),
      'book_title': book['title'],
      'book_cover_url': book['cover_url'],
    });
  }

  static Future<bool> hasComment(String bookId, String chapterId, int start, int end) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('books')
        .doc(bookId)
        .collection('chapters')
        .doc(chapterId)
        .collection('comments')
        .where('start', isEqualTo: start)
        .where('end', isEqualTo: end)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  static Future<int> getCommentCount(String bookId, String chapterId, int start, int end) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('books')
        .doc(bookId)
        .collection('chapters')
        .doc(chapterId)
        .collection('comments')
        .where('start', isEqualTo: start)
        .where('end', isEqualTo: end)
        .get();

    return querySnapshot.docs.length;
  }
}
