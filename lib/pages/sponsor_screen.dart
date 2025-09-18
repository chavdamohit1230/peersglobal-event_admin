import 'package:flutter/material.dart';
import 'detail_screen.dart';

class SponsorScreen extends StatefulWidget {
  const SponsorScreen({super.key});

  @override
  State<SponsorScreen> createState() => _SponsorScreenState();
}

class _SponsorScreenState extends State<SponsorScreen> {
  List<Map<String, String>> sponsors = [
    {"name": "Sponsor A", "level": "Gold", "details": "Details A"},
    {"name": "Sponsor B", "level": "Silver", "details": "Details B"},
  ];

  void _addSponsor() {
    setState(() {
      sponsors.add({"name": "New Sponsor", "level": "Bronze", "details": "New"});
    });
  }

  void _openDetail(Map<String, String> sponsor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          title: sponsor["name"]!,
          details: sponsor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: sponsors.length,
        itemBuilder: (context, index) {
          final sponsor = sponsors[index];
          return ListTile(
            title: Text(sponsor["name"]!),
            subtitle: Text(sponsor["level"]!),
            onTap: () => _openDetail(sponsor),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSponsor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
