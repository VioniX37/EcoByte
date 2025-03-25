import 'package:e_waste/others/color.dart';
import 'package:flutter/material.dart';

ValueNotifier<int> indexNotifier = ValueNotifier(0);

class BottomNavigationWidget extends StatelessWidget {
  const BottomNavigationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: indexNotifier,
        builder: (context, index, child) {
          return BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home, color: AppColors.appColor),
                  label: "Home"),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat, color:  AppColors.appColor),
                label: "Connect",
              ),
              BottomNavigationBarItem(
                  icon:
                      Icon(Icons.location_on_sharp, color:  AppColors.appColor),
                  label: "Find"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events, color:  AppColors.appColor),
                  label: "Quiz"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.smart_toy, color:  AppColors.appColor),
                  label: "Ask"),
            ],
            currentIndex: indexNotifier.value,
            onTap: (value) {
              indexNotifier.value = value;
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 5.0,
            selectedItemColor: Colors.black,
            selectedFontSize: 15,
            selectedIconTheme: IconThemeData(size: 30),
            unselectedItemColor: Colors.black,
          );
        });
  }
}

//Color.fromRGBO(54, 116, 181, 1)
