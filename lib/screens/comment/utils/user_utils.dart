import 'package:cloud_firestore/cloud_firestore.dart';

Future<DocumentSnapshot> getUserInfo(String userId) async {
  return await FirebaseFirestore.instance.collection('users').doc(userId).get();
}
