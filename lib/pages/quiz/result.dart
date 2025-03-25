import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_waste/pages/home/widgets/bottom_navigation.dart';
import 'package:e_waste/pages/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ResultPage extends StatelessWidget {
  final Map<int, String> selectedAnswers;
  final Map<String, dynamic> quizData;
  final String userId;

  const ResultPage({
    required this.selectedAnswers,
    required this.quizData,
    required this.userId,
  });

  Future<int> fetchUserScore() async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('quiz')
        .doc(today);
    var docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      return docSnapshot.data()?['score'] ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quiz Result"),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<int>(
        future: fetchUserScore(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          int score = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text("Your Score: $score / ${quizData.length}",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: quizData.length,
                    itemBuilder: (context, index) {
                      String correctAnswer =
                          quizData["question${(index).toString()}"]['correct'];
                      String? selectedAnswer = selectedAnswers[index];

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(
                              "${index + 1}. ${quizData["question${(index).toString()}"]['text']}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Your Answer: ${selectedAnswer ?? 'Not Answered'}",
                                  style: TextStyle(
                                      color: selectedAnswer == correctAnswer
                                          ? Colors.green
                                          : Colors.red)),
                              Text("Correct Answer: $correctAnswer",
                                  style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 13, 71, 161)),
                  onPressed: () {
                    indexNotifier.value = 0;
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (ctx) => MainScreen()),
                        (route) => false); // Go back to the main page
                  },
                  child: Text(
                    "Back to Home",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
