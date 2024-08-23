import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_item.dart';

class CategoryScreen extends StatelessWidget {
  final String category;

  CategoryScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$categoryの本'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('books')
            .where('categories', arrayContains: category)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final categoryBooks = snapshot.data!.docs;
          if (categoryBooks.isEmpty) {
            return Center(child: Text('No books available in this category.'));
          }
          return ListView.builder(
            itemCount: categoryBooks.length,
            itemBuilder: (context, index) {
              var book = categoryBooks[index].data() as Map<String, dynamic>;
              return buildBookItem(book, categoryBooks[index].id, context);
            },
          );
        },
      ),
    );
  }
}
