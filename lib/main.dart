import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:student_management/firebase_options.dart';
import 'package:student_management/screens/add_student_screen.dart';
import 'package:student_management/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text('Firebase Initialization Failed')),
            );
          }
          return const AddStudentScreen();
        },
      ),
    );
  }
}
