import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('設定')),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey,
            height: 1.0,
          ),
        ),
      ),
      body: ListView(
        children: [
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.person, color: Colors.black),
            title: Text('アカウント'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // アカウント画面への遷移
            },
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.lock, color: Colors.black),
            title: Text('プライバシー'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // プライバシー画面への遷移
            },
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.notifications, color: Colors.black),
            title: Text('通知'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // 通知画面への遷移
            },
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.more_horiz, color: Colors.black),
            title: Text('その他'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // その他画面への遷移
            },
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.book, color: Colors.black),
            title: Text('本の追加'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/add_book');
            },
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.category, color: Colors.black),
            title: Text('カテゴリー登録'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/register_category');
            },
          ),
          SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                // ログアウト処理
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              child: Text(
                'ログアウト',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}