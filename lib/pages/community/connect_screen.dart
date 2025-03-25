import 'package:e_waste/others/color.dart';
import 'package:e_waste/pages/community/add_post.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ConnectScreen extends StatefulWidget {
  @override
  _ConnectScreenState createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connect")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (ctx) => AddPost()));
        },
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()), // Chat messages
        ],
      ),
    );
  }

  /// Builds the list of messages from Firestore
  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!.docs;
        return ListView.separated(
          reverse: true,
          itemCount: messages.length,
          separatorBuilder: (context, index) => SizedBox(height: 10),
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageItem(message);
          },
        );
      },
    );
  }

  /// Builds a single message item with a like button
  Widget _buildMessageItem(QueryDocumentSnapshot message) {
    final user = _auth.currentUser;
    final isMe = user?.uid == message['senderId'];
    final String postId = message.id;
    final List likedBy = message['likedBy'] ?? [];
    final int likeCount = likedBy.length;
    final bool isLiked = likedBy.contains(user?.uid);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 300,
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.appColor,
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15))
                : BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15)),
            border:
                Border.all(color: Color.fromARGB(255, 13, 71, 161), width: 2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.appColor,
                    shape: BoxShape.circle,
                  ),
                  child: message['profile'] == ''
                      ? Icon(
                          Icons.person_outline,
                          size: 30,
                          color: Colors.white,
                        )
                      : ClipOval(
                          child: Image.network(
                            message['profile']!,
                            height: 30,
                            width: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                SizedBox(
                  width: 10,
                ),
                Text(message["senderName"],
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
            SizedBox(height: 5),
            Text(
              formatDate(message["timestamp"]),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 5),
            if (message["imageUrl"] != null)
              SizedBox(
                width: 300,
                height: 200,
                child: Image.network(
                  message["imageUrl"],
                ),
              ),
            SizedBox(height: 5),
            Text(message['description'],
                style: TextStyle(fontSize: 16, color: Colors.white)),
            SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.white : Colors.grey,
                  ),
                  onPressed: () => _toggleLike(postId, likedBy),
                ),
                Text(
                  "$likeCount Likes",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Function to toggle like/unlike on Firestore
  void _toggleLike(String postId, List likedBy) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final postRef = _firestore.collection('messages').doc(postId);

    if (likedBy.contains(user.uid)) {
      // Remove like
      await postRef.update({
        'likedBy': FieldValue.arrayRemove([user.uid])
      });
    } else {
      // Add like
      await postRef.update({
        'likedBy': FieldValue.arrayUnion([user.uid])
      });
    }
  }

  /// Function to format timestamp to "March 2, 2025"
  String formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat("MMMM d, yyyy").format(dateTime);
  }
}
