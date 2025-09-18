import 'package:flutter/material.dart';

class Managesponsor extends StatefulWidget {
  const Managesponsor({super.key});

  @override
  State<Managesponsor> createState() => _ManagesponsorState();
}

class _ManagesponsorState extends State<Managesponsor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(
        title:Text("Sponser Manage"),
      ),

    );
  }
}
