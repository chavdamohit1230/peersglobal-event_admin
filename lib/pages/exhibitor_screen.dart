import 'package:flutter/material.dart';
import 'detail_screen.dart';

class ExhibitorScreen extends StatefulWidget {
  const ExhibitorScreen({super.key});

  @override
  State<ExhibitorScreen> createState() => _ExhibitorScreenState();
}

class _ExhibitorScreenState extends State<ExhibitorScreen> {
  List<Map<String, String>> exhibitors = [
    {"name": "Exhibitor A", "company": "Company A", "details": "Details A"},
    {"name": "Exhibitor B", "company": "Company B", "details": "Details B"},
    {"name": "Exhibitor C", "company": "Company C", "details": "Details C"},
  ];

  void _addExhibitor() {
    setState(() {
      exhibitors.add({
        "name": "New Exhibitor",
        "company": "New Company",
        "details": "New Details"
      });
    });
  }

  void _openDetail(Map<String, String> exhibitor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          title: exhibitor["name"]!,
          details: exhibitor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header + count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Exhibitors (${exhibitors.length})",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addExhibitor,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Exhibitor"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Grid of exhibitors
            Expanded(
              child: GridView.builder(
                itemCount: exhibitors.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 cards per row
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final exhibitor = exhibitors[index];
                  return GestureDetector(
                    onTap: () => _openDetail(exhibitor),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.business,
                                size: 48, color: Colors.blue),
                            const SizedBox(height: 12),
                            Text(
                              exhibitor["name"]!,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              exhibitor["company"]!,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
