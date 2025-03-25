import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_waste/pages/ai/secrets.dart';
import 'package:e_waste/pages/main_screen.dart';
import 'package:e_waste/pages/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;


String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

void main() async {
  Gemini.init(apiKey: Secrets.googleApiKey);
  WidgetsFlutterBinding.ensureInitialized();


  await Firebase.initializeApp();
  await supa.Supabase.initialize(
    url:
        'https://ovxpdghxlxfprfjvyyog.supabase.co', // Replace with your Supabase URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im92eHBkZ2h4bHhmcHJmanZ5eW9nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDExMDgyMjAsImV4cCI6MjA1NjY4NDIyMH0.3Fta-QHOf9t_uKxBywc59Za-sTTrYlJoh_hDz3KfWs0', // Replace with your Supabase anon key
  );
   FirebaseFirestore.instance.collection('quizzes').doc(today).set({
    'question0': {
  'correct': 'Neodymium',
  'options': ['Lithium', 'Neodymium', 'Beryllium', 'Indium'],
  'text': 'Which rare earth metal, commonly found in smartphones, is critical for producing strong magnets used in electric vehicles and wind turbines?'
},

'question1': {
  'correct': 'Lead contamination',
  'options': ['Plastic pollution', 'Mercury leakage', 'Lead contamination', 'Radiation leakage'],
  'text': 'What is the primary environmental hazard caused by improper disposal of cathode ray tube (CRT) monitors?'
},

'question2': {
  'correct': 'USA',
  'options': ['India', 'China', 'USA', 'Japan'],
  'text': 'Which country is known as the world’s largest producer of e-waste according to the Global E-waste Monitor 2020?'
},

'question3': {
  'correct': 'Recovering valuable metals from e-waste',
  'options': ['Mining landfills', 'Extracting minerals from rocks', 'Recovering valuable metals from e-waste', 'Mining in cities'],
  'text': 'What is "urban mining" in the context of e-waste management?'
},

'question4': {
  'correct': 'Circuit board',
  'options': ['Battery', 'Circuit board', 'LCD screen', 'Hard disk drive'],
  'text': 'Which of the following electronic components contains the highest concentration of gold?'
},

'question5': {
  'correct': 'Basel Convention',
  'options': ['Paris Agreement', 'Kyoto Protocol', 'Basel Convention', 'Geneva Protocol'],
  'text': 'Which international treaty regulates the transboundary movement of hazardous e-waste?'
},

'question6': {
  'correct': '300g',
  'options': ['5g', '100g', '300g', '1kg'],
  'text': 'What is the approximate average gold content in 1 ton of mobile phones?'
},

'question7': {
  'correct': 'Polychlorinated biphenyls (PCBs)',
  'options': ['Polychlorinated biphenyls (PCBs)', 'DDT', 'CFCs', 'Methanol'],
  'text': 'Which harmful chemical is used as a flame retardant in older electronics and is known to cause serious health problems?'
},

'question8': {
  'correct': 'Metal wires with PVC coating',
  'options': ['Glass', 'Metal wires with PVC coating', 'Lithium-ion batteries', 'Ceramic resistors'],
  'text': 'Which of these e-waste components is most responsible for releasing dioxins when burned improperly?'
},

'question9': {
  'correct': 'Because of toxic exposure like mercury and cadmium',
  'options': ['Because of high voltage shocks', 'Because of toxic exposure like mercury and cadmium', 'Because devices explode when opened', 'Because of sharp plastic edges'],
  'text': 'Why is improper e-waste recycling dangerous for informal workers?'
},

  });
  User? user = FirebaseAuth.instance.currentUser;
  runApp(MaterialApp(
      home: user == null ? LoginScreen() : MainScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFE5F5F0),
        appBarTheme: AppBarTheme(backgroundColor: const Color(0xFF1A5269), foregroundColor: Colors.white),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          bodySmall: TextStyle(color: Colors.black),
        ),
      )
      ));
}
