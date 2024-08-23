import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentReplyProvider with ChangeNotifier {
  List<QueryDocumentSnapshot> _comments = [];
  List<QueryDocumentSnapshot> _replies = [];
  bool _isDisposed = false;
  bool _isLoading = false;

  List<QueryDocumentSnapshot> get comments => _comments;
  List<QueryDocumentSnapshot> get replies => _replies;
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // コメントをリアルタイムで取得するメソッド
  void loadComments(String bookId, String chapterId) {
    _isLoading = true;
    notifyListeners();

    FirebaseFirestore.instance
        .collection('books')
        .doc(bookId)
        .collection('chapters')
        .doc(chapterId)
        .collection('comments')
        .orderBy('createdAt', descending: true) // コメントを作成日時で降順に並べる
        .snapshots()
        .listen((snapshot) {
      _comments = snapshot.docs;
      _isLoading = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }, onError: (error) {
      _isLoading = false;
      if (!_isDisposed) {
        notifyListeners();
      }
      print('Error loading comments: $error');
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
        .orderBy('createdAt', descending: true) // 返信を作成日時で降順に並べる
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
      // コメント追加後にコメントリストを再読み込み
      loadSelectedTextComments(bookId, chapterId, start, end);
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  // 選択したテキストに対するコメントをリアルタイムで取得するメソッド
  void loadSelectedTextComments(String bookId, String chapterId, int start, int end) {
    _isLoading = true;
    notifyListeners();

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
      _isLoading = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }, onError: (error) {
      _isLoading = false;
      if (!_isDisposed) {
        notifyListeners();
      }
      print('Error loading selected text comments: $error');
    });
  }
}