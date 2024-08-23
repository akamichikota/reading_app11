import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LikeButton extends StatelessWidget {
  final bool isLiked;
  final List<String> likes;
  final DocumentSnapshot comment;

  LikeButton({required this.isLiked, required this.likes, required this.comment});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.thumb_up, color: isLiked ? Colors.blue : Colors.grey),
      onPressed: () => _toggleLike(context),
    );
  }

  void _toggleLike(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginAlert(context);
      return;
    }

    List<dynamic> updatedLikes = List.from(likes);

    if (updatedLikes.contains(user.uid)) {
      updatedLikes.remove(user.uid);
    } else {
      updatedLikes.add(user.uid);
    }

    try {
      await comment.reference.update({'likes': updatedLikes});
    } catch (e) {
      print('Error updating likes: $e'); // エラーをログに出力
      // ユーザーにエラーメッセージを表示するなどの処理を追加
    }
  }

  void _showLoginAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ログインが必要です'),
        content: Text('この操作を行うにはログインが必要です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}