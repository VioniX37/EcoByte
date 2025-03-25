import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyProducts extends StatefulWidget {
  const MyProducts({super.key});

  @override
  State<MyProducts> createState() => _MyProductsState();
}

class _MyProductsState extends State<MyProducts> {
  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text("My Products"),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.all(100.0),
                child: const Center(child: CircularProgressIndicator()),
              ); // Show loading spinner
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("No data found"));
            }

            var products = snapshot.data!.docs;
            final user = _auth.currentUser;

            return Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  // Filter products based on selected topics
                  bool shouldDisplay = false;
                  if (user?.uid == products[index]['id']) {
                    shouldDisplay = true;
                  }

                  if (!shouldDisplay) {
                    return SizedBox.shrink(); // Hide item if not matching
                  }

                  return Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Container(
                                  height: 150,
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 120, // Increased height
                                        width: 100,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Image.network(
                                          products[index]["imageUrl"],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              products[index]['name'],
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20),
                                            ),
                                            Text(
                                              products[index]['description'],
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "₹ ${products[index]["price"]}",
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(width: 10),
                                    ],
                                  ),
                                )),
                          ),
                        ),
                        IconButton(
                            onPressed: () {
                              showPopup(context, products[index].id);
                            },
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ))
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) => SizedBox(),
                itemCount: products.length,
              ),
            );
          }),
    );
  }

  void showPopup(BuildContext context, String docid) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Product"),
          content: Text("Are you sure you want to delete"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the popup
              },
              child: Text("No"),
            ),
            TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance
                      .collection('products')
                      .doc(docid)
                      .delete();
                },
                child: Text("Yes")),
          ],
        );
      },
    );
  }
}
