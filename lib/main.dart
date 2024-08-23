import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase/firebase_options.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/book/book_list_screen.dart';
import 'screens/book/book_details_screen.dart';
import 'screens/book/reading_screen.dart';
import 'screens/comment/text_comment_screen.dart';
import 'screens/comment/comment_detail_screen.dart';
import 'screens/comment/reply_list_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/profile_edit_screen.dart';
import 'screens/book/add_book_screen.dart';
import 'screens/category/register_category_screen.dart';
import 'screens/group/group_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/auth_service.dart';
import 'navigation/navigation_provider.dart';
import 'screens/comment/providers/comment_reply_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<NavigationProvider>(
          create: (_) => NavigationProvider(),
        ),
        ChangeNotifierProvider<CommentReplyProvider>( // Added this line
          create: (_) => CommentReplyProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Reading App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            color: Colors.white,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Color.fromRGBO(30, 120, 186, 1),
            unselectedItemColor: Colors.grey,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => MainScreen(),
          '/signup': (context) => SignUpScreen(),
          '/login': (context) => LoginScreen(),
          '/booklist': (context) => BookListScreen(),
          '/bookdetails': (context) => BookDetailsScreen(),
          '/reading': (context) => ReadingScreen(),
          '/profile': (context) => MainScreen(initialIndex: 1),
          '/profile_edit': (context) => ProfileEditScreen(),
          '/comment_detail': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            if (args == null) {
              return Scaffold(
                appBar: AppBar(title: Text('エラー')),
                body: Center(child: Text('引数が正しく渡されていません')),
              );
            }
            return CommentDetailScreen(
              bookId: args['bookId'], // Added bookId argument
              chapterId: args['chapterId'], // Added chapterId argument
            );
          },
          '/text_comment': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            if (args == null) {
              return Scaffold(
                appBar: AppBar(title: Text('エラー')),
                body: Center(child: Text('引数が正しく渡されていません')),
              );
            }
            return TextCommentScreen(
              bookId: args['bookId'], // Added bookId argument
              chapterId: args['chapterId'], // Added chapterId argument
              start: args['start'],
              end: args['end'],
              selectedText: args['selectedText'],
            );
          },
          '/reply_list': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
            return ReplyListScreen(
              comment: args['comment'],
              bookId: args['bookId'],
              chapterId: args['chapterId'],
            );
          },
          '/add_book': (context) => AddBookScreen(),
          '/register_category': (context) => RegisterCategoryScreen(),
          '/groups': (context) => GroupScreen(),
          '/settings': (context) => SettingsScreen(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;

  MainScreen({this.initialIndex = 0});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
    navigationProvider.setCurrentIndex(widget.initialIndex);
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _onPageChanged(int index) {
    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
    navigationProvider.setCurrentIndex(index);
  }

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);

    final List<Widget> _widgetOptions = <Widget>[
      HomeScreen(),
      ProfileScreen(),
      GroupScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: NeverScrollableScrollPhysics(),
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: navigationProvider.currentIndex,
        selectedItemColor: Color.fromRGBO(30, 120, 186, 1),
        onTap: _onItemTapped,
      ),
    );
  }
}