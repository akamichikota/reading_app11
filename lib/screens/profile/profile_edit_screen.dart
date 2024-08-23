import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditScreen extends StatefulWidget {
  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? _profileImageUrl;
  String? _backgroundImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadState();
  }

  Future<void> _loadUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // ユーザーがログインしていない場合はログインページにリダイレクト
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _usernameController.text = data['username'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _profileImageUrl = data['profileImageUrl'];
        _backgroundImageUrl = data['backgroundImageUrl'];
      });
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImageUrl = prefs.getString('profileImageUrl');
      _backgroundImageUrl = prefs.getString('backgroundImageUrl');
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImageUrl', _profileImageUrl ?? '');
    await prefs.setString('backgroundImageUrl', _backgroundImageUrl ?? '');
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      final file = result.files.first;
      final User user = FirebaseAuth.instance.currentUser!;
      final firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      final firebase_storage.UploadTask uploadTask = ref.putData(file.bytes!);

      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _profileImageUrl = downloadUrl;
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImageUrl': downloadUrl,
      });

      _saveState();
    }
  }

  Future<void> _pickBackgroundImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      final file = result.files.first;
      final User user = FirebaseAuth.instance.currentUser!;
      final firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('background_images')
          .child('${user.uid}.jpg');

      final firebase_storage.UploadTask uploadTask = ref.putData(file.bytes!);

      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _backgroundImageUrl = downloadUrl;
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'backgroundImageUrl': downloadUrl,
      });

      _saveState();
    }
  }

  Future<void> _deleteProfileImage() async {
    final User user = FirebaseAuth.instance.currentUser!;
    final firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('${user.uid}.jpg');

    await ref.delete();

    setState(() {
      _profileImageUrl = null;
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'profileImageUrl': FieldValue.delete(),
    });

    _saveState();
  }

  Future<void> _deleteBackgroundImage() async {
    final User user = FirebaseAuth.instance.currentUser!;
    final firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
        .ref()
        .child('background_images')
        .child('${user.uid}.jpg');

    await ref.delete();

    setState(() {
      _backgroundImageUrl = null;
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'backgroundImageUrl': FieldValue.delete(),
    });

    _saveState();
  }

  Future<void> _updateProfile() async {
    final User user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'username': _usernameController.text,
      'bio': _bioController.text,
      if (_profileImageUrl != null) 'profileImageUrl': _profileImageUrl,
      if (_backgroundImageUrl != null) 'backgroundImageUrl': _backgroundImageUrl,
    });
    _saveState();
    Navigator.pop(context, true); // 戻る際に true を渡して、プロフィールページをリフレッシュ
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('プロフィール編集'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _backgroundImageUrl != null
                  ? Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(_backgroundImageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 160,
                      color: Colors.grey,
                      child: Center(child: Icon(Icons.image, size: 50, color: Colors.white)),
                    ),
              TextButton(
                onPressed: _pickBackgroundImage,
                child: Text('背景画像を変更'),
              ),
              _backgroundImageUrl != null
                  ? TextButton(
                      onPressed: _deleteBackgroundImage,
                      child: Text('背景画像を削除'),
                    )
                  : Container(),
              SizedBox(height: 20),
              _profileImageUrl != null
                  ? CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(_profileImageUrl!),
                    )
                  : CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.account_circle),
                    ),
              TextButton(
                onPressed: _pickProfileImage,
                child: Text('プロフィール画像を変更'),
              ),
              _profileImageUrl != null
                  ? TextButton(
                      onPressed: _deleteProfileImage,
                      child: Text('プロフィール画像を削除'),
                    )
                  : Container(),
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'ユーザー名',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  filled: true,
                  fillColor: Color(0xFFF0F0F0),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: '自己紹介',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  filled: true,
                  fillColor: Color(0xFFF0F0F0),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF007BFF),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}