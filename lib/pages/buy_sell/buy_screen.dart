import 'package:e_waste/pages/buy_sell/product_screen.dart';
import 'package:e_waste/pages/buy_sell/sell_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuyScreen extends StatefulWidget {
  BuyScreen({super.key});

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  final TextEditingController searchController = TextEditingController();
  List<String> selectedTopics = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> searchProducts = [];
  List<Map<String, dynamic>> products = [];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Shop"),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Icon(
                    Icons.search,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                SizedBox(
                  height: 40,
                  width: 300,
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      List<Map<String, dynamic>> filteredItems = products
                          .where((item) => item["name"] == value)
                          .toList();

                      setState(() {
                        searchProducts = filteredItems;
                        filteredItems = [];
                      });
                    },
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: Color.fromRGBO(214, 241, 255, 1),
                        hintText: "Search",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20)),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    "IT equipment",
                    "Telecommunication",
                    "Domestic equipments",
                    "Industrial Components"
                  ]
                      .map((e) => Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedTopics.contains(e)
                                      ? selectedTopics.remove(e)
                                      : selectedTopics.add(e);
                                });
                              },
                              child: Chip(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                label: Text(
                                  e,
                                  style: TextStyle(
                                      color: selectedTopics.contains(e)
                                          ? Colors.white
                                          : Colors.black),
                                ),
                                backgroundColor: selectedTopics.contains(e)
                                    ? Color.fromARGB(255, 13, 71, 161)
                                    : null,
                                side: BorderSide(color: Colors.black),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            FutureBuilder(
                future: fetchProducts(),
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

                  if (searchProducts.isNotEmpty) {
                    products = searchProducts;
                  } else {
                    products = snapshot.data!;
                  }

                  final user = _auth.currentUser;

                  return Expanded(
                    child: ListView.separated(
                      itemBuilder: (context, index) {
                        // Filter products based on selected topics
                        bool shouldDisplay = selectedTopics.isEmpty ||
                            selectedTopics.any((topic) =>
                                products[index]['topics'].contains(topic));
                        if (user?.uid == products[index]['id']) {
                          shouldDisplay = false;
                        }

                        if (!shouldDisplay) {
                          return SizedBox.shrink(); // Hide item if not matching
                        }

                        return Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Card(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (ctx) => ProductScreen(
                                          productInfo: products[index],
                                        )));
                              },
                              child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Container(
                                    height: 150,
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        border: Border.all(color: Colors.black),
                                        borderRadius:
                                            BorderRadius.circular(10)),
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
                        );
                      },
                      separatorBuilder: (context, index) => SizedBox(),
                      itemCount: products.length,
                    ),
                  );
                }),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: Color.fromARGB(255, 13, 71, 161),
          foregroundColor: Colors.white,
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (ctx) => SellScreen()));
          },
          child: Text("Sell"),
        ),
      ),
    );
  }
}

Future<List<Map<String, dynamic>>> fetchProducts() async {
  try {
    // Reference to the 'products' collection
    CollectionReference products =
        FirebaseFirestore.instance.collection('products');

    // Fetch all documents
    QuerySnapshot querySnapshot = await products.get();

    // Convert documents to a list
    List<Map<String, dynamic>> productList = querySnapshot.docs.map((doc) {
      return doc.data() as Map<String, dynamic>;
    }).toList();
    return productList;

    // Print the retrieved data
  } catch (e) {
    print("Error fetching products: $e");
    return [];
  }
}
