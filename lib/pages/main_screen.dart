import 'package:e_waste/pages/ai/ai_chat_screen.dart';
import 'package:e_waste/pages/community/connect_screen.dart';
import 'package:e_waste/pages/home/home_page.dart';
import 'package:e_waste/pages/home/widgets/dashboard_bottom_navigation.dart';
import 'package:e_waste/pages/map/map.dart';
import 'package:e_waste/pages/quiz/quiz_main.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  List<Widget> get pages => [
        const HomePage(),
      ConnectScreen(),
      const EWasteMapPage(),
      const QuizMain(),
      const AiChatScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: dashboardIndexNotifier,
      builder: (context, index, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final backgroundGradient = isDark
            ? const [Color(0xFF091419), Color(0xFF112128), Color(0xFF152A33)]
            : const [Color(0xFFF8FCFA), Color(0xFFE3F2EC), Color(0xFFD4EAE2)];

        return Scaffold(
          backgroundColor: backgroundGradient.last,
          extendBody: true,
          bottomNavigationBar: DashboardBottomNavigationWidget(),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: backgroundGradient,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: index,
                children: pages,
              ),
            ),
          ),
        );
      },
    );
  }
}
