import 'package:e_waste/others/color.dart';
import 'package:e_waste/pages/quiz/result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class QuizPage extends StatefulWidget {
  @override
  _QuizPageState createState() => _QuizPageState();
}

Future<String?> getUserId() async {
  User? user = FirebaseAuth.instance.currentUser;
  return user?.uid; // Return user ID or null if user is not logged in
}

class _QuizPageState extends State<QuizPage> {
  PageController _pageController = PageController();
  List<Map<String, dynamic>> questions = [];
  Map<int, String> selectedAnswers = {}; // Store selected answers
  bool isLoading = true;
  bool hasAttempted = false;

  @override
  void initState() {
    super.initState();
    checkUserAttempt();
  }

  Future<void> checkUserAttempt() async {
    String? userId = await getUserId();
    if (userId != null) {
      bool attempted = await hasUserAttemptedQuiz(userId);
      if (!attempted) {
        // If the user hasn't attempted, fetch the quiz questions
        await loadQuestions();
      }
      setState(() {
        hasAttempted = attempted;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadQuestions() async {
    List<Map<String, dynamic>> quizQuestions = await fetchQuestions();
    print(quizQuestions);
    setState(() {
      questions = quizQuestions;
      isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchQuestions() async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    var docRef = FirebaseFirestore.instance.collection('quizzes').doc(today);
    var docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

      List<String> keys = data.keys.toList();

      keys.sort((a, b) => b.compareTo(a));

      return keys.map((key) {
        var questionData = data[key];
        return {
          "question": questionData["text"],
          "options": questionData["options"],
          "answer": questionData["correct"]
        };
      }).toList();
    } else {
      return [];
    }
  }

  void nextPage() {
    if (_pageController.page!.toInt() < questions.length - 1) {
      _pageController.nextPage(
          duration: Duration(milliseconds: 300), curve: Curves.easeIn);
    }
  }

  void previousPage() {
    if (_pageController.page!.toInt() > 0) {
      _pageController.previousPage(
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<bool> hasUserAttemptedQuiz(String userId) async {
    String today =
        DateFormat('yyyy-MM-dd').format(DateTime.now()); // Get today's date
    var docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('quiz')
        .doc(today);

    var docSnapshot = await docRef.get();

    // If the document exists and 'attempted' is true, the user has already attempted the quiz
    if (docSnapshot.exists && docSnapshot.data() != null) {
      var data = docSnapshot.data();
      return data?['attempted'] ?? false; // Return the 'attempted' status
    }

    if (!docSnapshot.exists) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('quiz')
          .doc(today)
          .set({'score': 0, 'attempted': false});
    }

    return false; // If the user hasn't attempted today
  }

  Future<void> markQuizAsAttempted(String userId) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Mark quiz as attempted in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('quiz')
        .doc(today)
        .set({
      'attempted': true,
      'score': 0, // Initialize score, you can update it after quiz submission
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Quiz")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Quiz")),
      body: hasAttempted == true
          ? Center(
              child: Text("Quiz already attempted !\nCome back tomorrow !!"))
          : PageView.builder(
              controller: _pageController,
              itemCount: questions.length,
              physics: NeverScrollableScrollPhysics(), // Disable swipe
              itemBuilder: (context, index) {
                var question = questions[questions.length - 1 - index];
                return QuizQuestion(
                  question: question['question'],
                  options: List<String>.from(question['options']),
                  selectedAnswer: selectedAnswers[index],
                  onOptionSelected: (value) {
                    setState(() {
                      selectedAnswers[index] = value;
                    });
                  },
                  onNext: nextPage,
                  onPrevious: previousPage,
                  isLastQuestion: index == questions.length - 1,
                  isFirstQuestion: index == 0,
                  index: index,
                  selectedAnswers: selectedAnswers,
                );
              },
            ),
    );
  }
}

class QuizQuestion extends StatelessWidget {
  final String question;
  final List<String> options;
  final String? selectedAnswer;
  final ValueChanged<String> onOptionSelected;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool isLastQuestion;
  final bool isFirstQuestion;
  final int index;
  final Map<int, String> selectedAnswers;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.selectedAnswer,
    required this.onOptionSelected,
    required this.onNext,
    required this.onPrevious,
    required this.isLastQuestion,
    required this.isFirstQuestion,
    required this.index,
    required this.selectedAnswers,
  });

  Future<Map<String, dynamic>> calculateAndStoreScore(String userId) async {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Reference to today's quiz document
    print(selectedAnswers);
    var quizRef = FirebaseFirestore.instance.collection('quizzes').doc(today);
    var quizSnapshot = await quizRef.get();

    var quizData = quizSnapshot.data();

    int score = 0;

    // Compare user answers with correct answers
    selectedAnswers.forEach((index, selectedAnswer) {
      String correctAnswer =
          quizData?["question${(index).toString()}"]['correct'];

      if (correctAnswer == selectedAnswer) {
        score++; // Increase score for correct answers
      }
    });

    // Store score in user's Firestore document
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('quiz')
        .doc(today)
        .update({'score': score, 'attempted': true}).catchError((e) {
      print("Error updating score: $e");
    });

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    int total = userDoc["total_score"];

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'total_score': total + score});

    return quizData!;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: AppColors.appColor,
                border: Border.all(width: 2),
                borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${index + 1}. $question",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Colors.white)),
                  SizedBox(height: 20),
                  Column(
                    children: options.map((option) {
                      return RadioListTile<String>(
                        fillColor:
                            MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.white;
                          }
                          return Colors.white; // Border color when not selected
                        }),
                        title: Text(
                          option,
                          style: TextStyle(color: Colors.white),
                        ),
                        value: option,
                        groupValue: selectedAnswer,
                        onChanged: (value) {
                          onOptionSelected(value!);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isFirstQuestion) SizedBox.shrink(),
                  if (isFirstQuestion)
                    ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appColor),
                      child: Text(
                        "Next",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (isLastQuestion)
                    ElevatedButton(
                      onPressed: onPrevious,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appColor),
                      child: Text(
                        "Previous",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (isLastQuestion)
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.appColor),
                        onPressed: () async {
                          String? userId = await getUserId();
                          if (userId != null) {
                            var quizData = await calculateAndStoreScore(userId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultPage(
                                  quizData: quizData,
                                  selectedAnswers: selectedAnswers,
                                  userId: userId,
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          "Submit",
                          style: TextStyle(color: Colors.white),
                        )),
                  if (!isFirstQuestion && !isLastQuestion)
                    ElevatedButton(
                      onPressed: onPrevious,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appColor),
                      child: Text(
                        "Previous",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (!isFirstQuestion && !isLastQuestion)
                    ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appColor),
                      child: Text(
                        "Next",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
