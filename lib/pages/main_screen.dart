import 'package:e_waste/pages/ai/ai_chat_screen.dart';
import 'package:e_waste/pages/community/connect_screen.dart';
import 'package:e_waste/pages/home/home_page.dart';
import 'package:e_waste/pages/home/widgets/bottom_navigation.dart';
import 'package:e_waste/pages/map/map.dart';
import 'package:e_waste/pages/quiz/quiz_main.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key});

  //RecyclingMap(userLat: position.latitude, userLon: position.longitude, recyclingCenters: centers!)
  final pages = [
    HomePage(),
    ConnectScreen(),
    EWasteMapPage(),
    QuizMain(),
    AiChatScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationWidget(),
      body: SafeArea(
        child: ValueListenableBuilder(
            valueListenable: indexNotifier,
            builder: (context, index, child) {
              return pages[index];
            }),
      ),
    );
  }
}
