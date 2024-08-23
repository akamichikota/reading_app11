import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategorySection extends StatelessWidget {
  final String category;

  CategorySection(this.category);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _getCategoryBooks(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final categoryBooks = snapshot.data!;
        if (categoryBooks.isEmpty) {
          return Center(child: Text('No books available in this category.'));
        }

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categoryBooks.length,
          itemBuilder: (context, index) {
            final book = categoryBooks[index].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/bookdetails',
                    arguments: {
                      'id': categoryBooks[index].id,
                      'title': book['title'],
                      'author': book['author'],
                      'content': book['content'],
                      'cover_url': book['cover_url'],
                    },
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 128,
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
                          ? Icon(Icons.book, size: 50, color: Colors.white)
                          : null,
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: 100,
                      child: Text(
                        book['title'],
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<QueryDocumentSnapshot>> _getCategoryBooks() async {
    List<QueryDocumentSnapshot> results = [];
    QuerySnapshot booksSnapshot = await FirebaseFirestore.instance.collection('books').get();

    for (var bookDoc in booksSnapshot.docs) {
      QuerySnapshot categoriesSnapshot = await bookDoc.reference.collection('categories')
          .where('name', isEqualTo: category)
          .get();

      if (categoriesSnapshot.docs.isNotEmpty) {
        results.add(bookDoc);
      }
    }

    return results;
  }
}