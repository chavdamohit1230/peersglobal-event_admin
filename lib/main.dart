import 'package:flutter/material.dart';
import 'package:peersglobaladmin/pages/admin_home_screen.dart';
import 'package:peersglobaladmin/routers/rout.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Flutter widgets ko ensure karo ki initialize ho gaye hain
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialize karna zaroori hai
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ab app run karo
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return
        MaterialApp.router(
          routerConfig:AppRout.router,
        );
  }
}

