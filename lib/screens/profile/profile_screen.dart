import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final CollectionReference users = FirebaseFirestore.instance.collection('users');
  int _bookCount = 0;
  bool _isBookShelfSelected = true; // 本棚と保存したテキストの表示を切り替えるフラグ

  Future<DocumentSnapshot<Map<String, dynamic>>>? _profileData;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _loadUserProfile();
      _loadBookCount();
    }
  }

  void _loadUserProfile() {
    setState(() {
      _profileData = users.doc(user!.uid).get() as Future<DocumentSnapshot<Map<String, dynamic>>>;
    });
  }

  void _loadBookCount() async {
    if (user != null) {
      final bookCollection = await users.doc(user!.uid).collection('bookshelf').get();
      setState(() {
        _bookCount = bookCollection.size;
      });
    }
  }

  void _logout(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _navigateToProfileEdit() async {
    final result = await Navigator.pushNamed(context, '/profile_edit');
    if (result == true) {
      _loadUserProfile(); // プロフィールを再ロード
    }
  }

  Future<bool> _onWillPop() async {
    _loadUserProfile();
    return true;
  }

  void _showFullTextDialog(Map<String, dynamic> savedText) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('保存したテキスト'),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(savedText['selected_text']),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/reading',
                    arguments: {'id': savedText['book_id']},
                  );
                },
                child: Text('読書ページに移動'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _profileData,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data?.data() == null) {
              return Center(child: Text('プロフィールデータが見つかりません'));
            }

            final data = snapshot.data!.data()!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 220,
                      ),
                      Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(data['backgroundImageUrl'] ?? 'https://via.placeholder.com/150'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 140, // 背景画像とアイコンが重なる位置に調整
                        left: 16,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(3),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(data['profileImageUrl'] ?? 'https://via.placeholder.com/150'),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 170,
                        right: 16,
                        child: ElevatedButton(
                          onPressed: _navigateToProfileEdit,
                          child: Text('編集', style: TextStyle(fontSize: 14)), // 文字サイズを調整
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // 背景色を白に設定
                            foregroundColor: Colors.grey, // 文字色をグレーに設定
                            side: BorderSide(color: Colors.grey), // ボーダーをグレーに設定
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20), // ボーダーの角を少し丸く
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // パディングを調整
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24), // プロフィール画像の下にスペースを追加
                        Text(
                          '${data['username']}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${data['bio'] ?? "No bio available"}',
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '読書量: $_bookCount',
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.menu_book),
                              color: _isBookShelfSelected ? Colors.blue : Colors.grey[200],
                              onPressed: () {
                                setState(() {
                                  _isBookShelfSelected = true;
                                });
                              },
                            ),
                            Container(
                              height: 2,
                              color: _isBookShelfSelected ? Colors.blue : Colors.grey[200],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            IconButton(
                              icon: Icon(Icons.description),
                              color: !_isBookShelfSelected ? Colors.blue : Colors.grey[200],
                              onPressed: () {
                                setState(() {
                                  _isBookShelfSelected = false;
                                });
                              },
                            ),
                            Container(
                              height: 2,
                              color: !_isBookShelfSelected ? Colors.blue : Colors.grey[200],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _isBookShelfSelected ? _buildBookShelf() : _buildSavedTexts(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookShelf() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('bookshelf')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final bookshelfBooks = snapshot.data!.docs;

        if (bookshelfBooks.isEmpty) {
          return Center(child: Text('本棚に本がありません'));
        }

        return GridView.builder(
          shrinkWrap: true, // 親のSingleChildScrollViewの高さに合わせる
          physics: NeverScrollableScrollPhysics(), // 親のスクロールに合わせる
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.75,
          ),
          itemCount: bookshelfBooks.length,
          itemBuilder: (context, index) {
            final bookData = bookshelfBooks[index].data() as Map<String, dynamic>;
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('books').doc(bookData['id']).get(),
              builder: (context, bookSnapshot) {
                if (bookSnapshot.hasError) {
                  return Center(child: Text('Error: ${bookSnapshot.error}'));
                }
                if (bookSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!bookSnapshot.hasData || bookSnapshot.data?.data() == null) {
                  return Center(child: Text('本のデータが見つかりません'));
                }
                final book = bookSnapshot.data!.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/bookdetails',
                        arguments: {
                          'id': bookSnapshot.data!.id,
                          'title': book['title'],
                          'author': book['author'] ?? '不明',
                          'cover_url': book['cover_url'] ?? 'https://via.placeholder.com/150',
                          'summary': book['summary'] ?? '概要が登録されていません',
                        },
                      );
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 128,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: NetworkImage(book['cover_url'] ?? 'https://via.placeholder.com/150'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          book['title'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSavedTexts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('savedTexts')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final savedTexts = snapshot.data!.docs;

        if (savedTexts.isEmpty) {
          return Center(child: Text('保存したテキストがありません'));
        }

        return ListView.builder(
          shrinkWrap: true, // 親のSingleChildScrollViewの高さに合わせる
          physics: NeverScrollableScrollPhysics(), // 親のスクロールに合わせる
          itemCount: savedTexts.length,
          itemBuilder: (context, index) {
            final savedText = savedTexts[index].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  _showFullTextDialog(savedText);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 75, // 縦長の画像にするため高さを設定
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.grey,
                          image: savedText['book_cover_url'] != null && savedText['book_cover_url'].isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(savedText['book_cover_url']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: savedText['book_cover_url'] == null || savedText['book_cover_url'].isEmpty
                            ? Icon(Icons.book, size: 50, color: Colors.white)
                            : null,
                      ),
                      SizedBox(width: 24),
                      Expanded(
                        child: Text(
                          savedText['selected_text'],
                          style: TextStyle(fontSize: 14),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}