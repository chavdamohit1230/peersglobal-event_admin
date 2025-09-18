import 'package:flutter/material.dart';

class Manageexhibiter extends StatefulWidget {
  const Manageexhibiter({super.key});

  @override
  State<Manageexhibiter> createState() => _ManageexhibiterState();
}

class _ManageexhibiterState extends State<Manageexhibiter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(
        title:Text("Exhibiter Section"),
      ),
    );
  }
}
