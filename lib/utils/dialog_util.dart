import 'package:flutter/material.dart';

void showLoginAlert(BuildContext context) {
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

class AddCommentDialog extends StatelessWidget {
  final String selectedText;
  final TextEditingController commentController;
  final VoidCallback onSave;
  final VoidCallback onViewComments;
  final VoidCallback onComment;

  AddCommentDialog({
    required this.selectedText,
    required this.commentController,
    required this.onSave,
    required this.onViewComments,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedText,
            style: TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onSave,
                child: Text('保存'),
              ),
              TextButton(
                onPressed: onViewComments,
                child: Text('コメント閲覧'),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'コメントを入力',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  maxLines: 1,
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: onComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
