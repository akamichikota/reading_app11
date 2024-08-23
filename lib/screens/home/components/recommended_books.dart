import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendedBooks extends StatelessWidget {
  final PageController pageController;

  RecommendedBooks(this.pageController);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('books')
          .where('is_recommended', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final recommendedBooks = snapshot.data!.docs;
        if (recommendedBooks.isEmpty) {
          return Center(child: Text('No recommended books available.'));
        }
        return PageView.builder(
          controller: pageController,
          onPageChanged: (int index) {
            if (index == recommendedBooks.length + 1) {
              pageController.jumpToPage(1);
            } else if (index == 0) {
              pageController.jumpToPage(recommendedBooks.length);
            }
          },
          itemCount: recommendedBooks.length + 2,
          itemBuilder: (context, index) {
            int dataIndex;
            if (index == 0) {
              dataIndex = recommendedBooks.length - 1;
            } else if (index == recommendedBooks.length + 1) {
              dataIndex = 0;
            } else {
              dataIndex = index - 1;
            }
            final book = recommendedBooks[dataIndex].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.all(0),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/bookdetails',
                    arguments: {
                      'id': recommendedBooks[dataIndex].id,
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
                      width: MediaQuery.of(context).size.width * 1.0, // 横幅いっぱいに
                      height: 220, // 高さを220に固定
                      decoration: BoxDecoration(
                        image: book['wide_cover_url'] != null && book['wide_cover_url'].isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(book['wide_cover_url']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: book['wide_cover_url'] == null || book['wide_cover_url'].isEmpty
                          ? Icon(Icons.book, size: 50, color: Colors.white)
                          : null,
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
}
