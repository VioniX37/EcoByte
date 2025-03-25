import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<Map<String, dynamic>?> getUserDataSell() async {
  User? user = FirebaseAuth.instance.currentUser; // Get logged-in user
  if (user == null) return null;

  DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

  if (userDoc.exists) {
    return userDoc.data() as Map<String, dynamic>;
  }

  return null;
}
