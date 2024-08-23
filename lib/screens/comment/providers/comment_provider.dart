import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentProvider with ChangeNotifier {
  List<QueryDocumentSnapshot> _comments = [];

  List<QueryDocumentSnapshot> get comments => _comments;

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
      notifyListeners();
    });
  }
}
