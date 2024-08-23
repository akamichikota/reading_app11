import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReplyProvider with ChangeNotifier {
  List<QueryDocumentSnapshot> _replies = [];

  List<QueryDocumentSnapshot> get replies => _replies;

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
      notifyListeners();
    });
  }
}
