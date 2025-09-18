import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final String title;
  final Map<String, String> details;

  const DetailScreen({super.key, required this.title, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: details.entries
              .map((e) => Text("${e.key}: ${e.value}",
              style: const TextStyle(fontSize: 18)))
              .toList(),
        ),
      ),
    );
  }
}
