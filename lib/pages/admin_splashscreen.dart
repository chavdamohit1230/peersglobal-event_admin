import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminSplashscreen extends StatefulWidget {
  const AdminSplashscreen({super.key});

  @override
  State<AdminSplashscreen> createState() => _AdminSplashscreenState();
}

class _AdminSplashscreenState extends State<AdminSplashscreen> {
  @override
  void initState() {
    super.initState();


    Timer(const Duration(seconds: 3), () {
      context.go('/adminlogin');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDCEAF4),
              Color(0xFFC5D9EC),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Image.asset('assets/peersgloblelogo.png',
                width: MediaQuery.of(context).size.width * 0.6,
              ),
              const SizedBox(height: 20),
              // Loader
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
