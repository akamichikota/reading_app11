import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/search_books.dart';
import 'components/book_item.dart';
import 'components/recommended_books.dart';
import 'components/category_bar.dart';
import 'components/category_section.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  late PageController _pageController;

  List<String> categories = ['すべて']; // 「すべて」のみを初期化

  String? _selectedCategory; // 選択されたカテゴリーを保持する変数

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    _loadState();
    _fetchCategories(); // カテゴリーを取得するメソッドを呼び出す
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCategory = prefs.getString('selectedCategory');
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCategory', _selectedCategory ?? '');
  }

  Future<void> _fetchCategories() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('categories').get();
    List<String> fetchedCategories = snapshot.docs.map((doc) => doc['name'] as String).toList();
    
    setState(() {
      categories.addAll(fetchedCategories); // 取得したカテゴリーを追加
    });
  }

  void _updateSearchResults(List<QueryDocumentSnapshot> results, bool isSearching) {
    setState(() {
      _searchResults = results;
      _isSearching = isSearching;
    });
    _saveState();
  }

  void _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _saveState();
      return;
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    QuerySnapshot authorSnapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('author', isGreaterThanOrEqualTo: query)
        .where('author', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    List<QueryDocumentSnapshot> results = snapshot.docs + authorSnapshot.docs;
    final seen = <String>{};
    results.retainWhere((doc) => seen.add(doc.id));

    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
    _saveState();
  }

  void _searchCategory(String category) async {
    if (category == 'すべて') {
      setState(() {
        _selectedCategory = null;
        _searchResults = [];
        _isSearching = false;
      });
      _saveState();
      return;
    }

    // 新しいクエリロジック
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

    setState(() {
      _selectedCategory = category;
      _searchResults = results;
      _isSearching = true;
    });
    _saveState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            floating: true,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.notifications, color: Colors.grey),
              onPressed: () {
                // 通知画面への遷移処理をここに記述
              },
            ),
            title: Container(
              height: 40,
              margin: EdgeInsets.only(right: 12.0),
              child: SearchBooks(onSearchResults: _updateSearchResults),
            ),
          ),
          SliverPersistentHeader(
            pinned: false,
            delegate: _SliverAppBarDelegate(
              minHeight: 60.0,
              maxHeight: 60.0,
              child: CategoryBar(
                categories: categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: _searchCategory,
              ),
            ),
          ),
          _isSearching
              ? SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      var book = _searchResults[index].data() as Map<String, dynamic>;
                      return buildBookItem(book, _searchResults[index].id, context);
                    },
                    childCount: _searchResults.length,
                  ),
                )
              : SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      SizedBox(
                        height: 220,
                        child: RecommendedBooks(_pageController),
                      ),
                      for (var category in categories.skip(1)) ...[
                        _buildSectionTitle(category),
                        Container(
                          height: 180,
                          child: CategorySection(category),
                        ),
                      ],
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 0),
      child: Row(
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          IconButton(
            icon: Icon(Icons.chevron_right, color: Colors.grey),
            onPressed: () => _searchCategory(title),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}