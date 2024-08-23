import 'package:flutter/material.dart';

Widget buildBookItem(Map<String, dynamic> book, String docId, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 16.0),
    child: InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/bookdetails',
          arguments: {
            'id': docId,
            'title': book['title'],
            'author': book['author'],
            'content': book['content'],
            'cover_url': book['cover_url'],
          },
        );
      },
      child: Card(
        color: Colors.grey[100],
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 74,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.grey,
                  image: book['cover_url'] != null && book['cover_url'].isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(book['cover_url']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: book['cover_url'] == null || book['cover_url'].isEmpty
                    ? Icon(Icons.book, size: 30, color: Colors.white)
                    : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(book['author'] ?? 'Unknown Author', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
