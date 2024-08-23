import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class UserInfo extends StatelessWidget {
  final String userId;

  UserInfo({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('エラー: ${snapshot.error}'));
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final userProfileImage = userData['profileImageUrl'];
        final username = userData['username'] ?? 'Unknown';

        return Row(
          children: [
            CircleAvatar(
              backgroundImage: userProfileImage != null
                  ? NetworkImage(userProfileImage)
                  : null,
              child: userProfileImage == null
                  ? ProfilePicture(
                      name: username,
                      radius: 31,
                      fontsize: 21,
                      random: true,
                    )
                  : null,
            ),
            SizedBox(width: 8.0),
            Text(username),
          ],
        );
      },
    );
  }
}