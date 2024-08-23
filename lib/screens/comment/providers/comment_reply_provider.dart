import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentReplyProvider with ChangeNotifier {
  List<QueryDocumentSnapshot> _comments = [];
  List<QueryDocumentSnapshot> _replies = [];
  bool _isDisposed = false;

  List<QueryDocumentSnapshot> get comments => _comments;
  List<QueryDocumentSnapshot> get replies => _replies;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // コメントをリアルタイムで取得するメソッド
  void loadComments(String bookId, String chapterId) {
    FirebaseFirestore.instance
        .collection('books')
        .doc(bookId)
        .collection('chapters')
        .doc(chapterId)
        .collection('comments')
        .snapshots()
        .listen((snapshot) {
      _comments = snapshot.docs;
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  void loadReplies(String bookId, String chapterId, String commentId) {
    FirebaseFirestore.instance
        .collection('books')
        .doc(bookId)
        .collection('chapters')
        .doc(chapterId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .snapshots()
        .listen((snapshot) {
      _replies = snapshot.docs;
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  // コメントを追加するメソッド
  Future<void> addComment(String bookId, String chapterId, String userId, String comment) async {
    try {
      await FirebaseFirestore.instance
          .collection('books')
          .doc(bookId)
          .collection('chapters')
          .doc(chapterId)
          .collection('comments')
          .add({
            'userId': userId,
            'comment': comment,
            'createdAt': FieldValue.serverTimestamp(),
            'selectedText': '…',
          });
      // コメント追加後に再取得する必要はない
    } catch (e) {
      print('Error adding comment: $e');
    }
  }
  Future<void> addTextComment(String bookId, String chapterId, String userId, String comment, int start, int end, String selectedText) async {
    try {
      await FirebaseFirestore.instance
          .collection('books')
          .doc(bookId)
          .collection('chapters')
          .doc(chapterId)
          .collection('comments')
          .add({
            'userId': userId,
            'comment': comment,
            'createdAt': FieldValue.serverTimestamp(),
            'selectedText': selectedText,
            'start': start,
            'end': end,
          });
      // コメント追加後に再取得する��要はない
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  // 選択したテキストに対するコメントをリアルタイムで取得するメソッド
  void loadSelectedTextComments(String bookId, String chapterId, int start, int end) {
    FirebaseFirestore.instance
        .collection('books')
        .doc(bookId)
        .collection('chapters')
        .doc(chapterId)
        .collection('comments')
        .where('start', isEqualTo: start)
        .where('end', isEqualTo: end)
        .snapshots()
        .listen((snapshot) {
      _comments = snapshot.docs;
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }
}