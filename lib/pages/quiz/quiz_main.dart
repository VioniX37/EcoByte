import 'package:e_waste/others/color.dart';
import 'package:e_waste/pages/quiz/quiz_page.dart';
import 'package:flutter/material.dart';

class QuizMain extends StatelessWidget {
  const QuizMain({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events,color: AppColors.appColor,size: 100,),
          ElevatedButton(onPressed: (){
            Navigator.of(context).push(MaterialPageRoute(builder: (ctx)=>QuizPage()));
          }, child: Text("Start quiz",style: TextStyle(color: Colors.white),),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.appColor
          ),
          )
        ],
      ),
    );
  }
}