import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_waste/others/color.dart';
import 'package:e_waste/pages/auth/login_screen.dart';
import 'package:e_waste/pages/home/know_ewaste.dart';
import 'package:e_waste/pages/home/widgets/sdg_goals.dart';
import 'package:e_waste/pages/profile/profile.dart';
import 'package:e_waste/pages/buy_sell/buy_screen.dart';
import 'package:e_waste/pages/buy_sell/sell_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> getUserData() async {
  User? user = FirebaseAuth.instance.currentUser; // Get logged-in user
  if (user == null) return null;

  DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

  if (userDoc.exists) {
    return userDoc.data() as Map<String, dynamic>;
  }

  return null;
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

void logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (ctx) => LoginScreen()), (route) => false);
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            ); // Show loading spinner
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No data found"));
          }

          List<Map<String, dynamic>> data = snapshot.data!;

          return Scaffold(
            backgroundColor: const Color(0xFFE5F5F0),
            appBar: AppBar(
              title: Text(
                'EcoByte',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (String result) {
                    if (result == 'Profile') {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => ProfileScreen(
                                userData: getUserData(),
                              )));
                    } else if (result == 'Log Out') {
                      logout(context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'Profile',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Colors.black,
                          ),
                          SizedBox(width: 8),
                          Text('Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'Log Out',
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout,
                            color: Colors.black,
                          ),
                          SizedBox(width: 8),
                          Text('Log Out'),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Reduce E-Waste,\nReward Yourself',
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A5269),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Recycle. Repair. Reuse.',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFF1A5269),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Image.asset(
                            'assets/waste.png',
                            fit: BoxFit.contain,
                            height: 120,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => SellScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.appColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (ctx) => BuyScreen()));
                      },
                      child: Text(
                        "View Products",
                        style: TextStyle(
                            color: AppColors.appColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (ctx) => BuyScreen()));
                      },
                      child: SizedBox(
                        height:
                            100, // Sufficient height to show ListTile content
                        child: ListView.builder(
                          scrollDirection:
                              Axis.horizontal, // Enables horizontal scrolling
                          itemCount: 4, // Ensure itemCount matches data length
                          itemBuilder: (context, index) {
                            return Container(
                              width: 175, // Set a fixed width for each item
                              margin: EdgeInsets.symmetric(
                                  horizontal: 8), // Add spacing between items
                              child: ListTile(
                                tileColor: AppColors
                                    .appColor, // Add color to confirm visibility
                                leading: Image.network(
                                  data[index]['imageUrl'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(
                                  data[index]['name'],
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  data[index]['price'],
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Our Impact Goals',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A5269),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          sdgCard(
                            url: 'assets/3.png',
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          sdgCard(
                            url: 'assets/9.png',
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          sdgCard(
                            url: 'assets/11.png',
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          sdgCard(
                            url: 'assets/12.png',
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          sdgCard(
                            url: 'assets/13.png',
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          sdgCard(
                            url: 'assets/17.png',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                              MaterialPageRoute(builder: (ctx) => EWasteApp()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: const Text(
                          'Know your E-Waste',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
