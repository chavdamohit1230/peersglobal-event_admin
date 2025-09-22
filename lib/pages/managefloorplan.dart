import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peersglobaladmin/colors/colorfile.dart';

class ManageFloorPlan extends StatefulWidget {
  const ManageFloorPlan({super.key});

  @override
  State<ManageFloorPlan> createState() => _ManageFloorPlanState();
}

class _ManageFloorPlanState extends State<ManageFloorPlan> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  // Pick image from gallery (optional)
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
      await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _selectedImageBytes = await pickedFile.readAsBytes();
        setState(() {});
      }
    } catch (e) {
      debugPrint("Pick Image Error: $e");
    }
  }

  // Upload floor plan to Firebase
  Future<void> _uploadFloorPlan() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter title")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? downloadUrl;

      // Only upload image if selected
      if (_selectedImageBytes != null) {
        String fileName =
            "floorplans/${DateTime.now().millisecondsSinceEpoch}.jpg";
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        TaskSnapshot snapshot = await ref.putData(_selectedImageBytes!);
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      // Add document to Firestore
      await FirebaseFirestore.instance.collection("floorplan").add({
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "imageUrl": downloadUrl ?? "", // empty if no image
        "timestamp": FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _descController.clear();
      _selectedImageBytes = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Floor Plan added successfully")),
      );
    } catch (e) {
      debugPrint("Upload Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload Error: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  // Delete floor plan
  Future<void> _deleteFloorPlan(String docId, String? imageUrl) async {
    try {
      await FirebaseFirestore.instance.collection("floorplan").doc(docId).delete();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Floor Plan deleted")),
      );
    } catch (e) {
      debugPrint("Delete Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Floor Plans"),
        backgroundColor: Appcolor.secondary,
      ),
      body: Column(
        children: [
          // Upload Form
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "Floor Plan Title",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text("Pick Image (Optional)"),
                        ),
                        const SizedBox(width: 12),
                        _selectedImageBytes != null
                            ? Image.memory(
                          _selectedImageBytes!,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                        )
                            : const Text("No image selected"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _uploadFloorPlan,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Appcolor.secondary,
                          minimumSize: const Size(double.infinity, 45)),
                      child: const Text("Upload Floor Plan"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          // List of floorplans
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("floorplan")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No floor plans uploaded"));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String docId = docs[index].id;

                    return ListTile(
                      leading: (data["imageUrl"] != null &&
                          data["imageUrl"].isNotEmpty)
                          ? Image.network(
                        data["imageUrl"],
                        width: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 60),
                      )
                          : const Icon(Icons.image_not_supported, size: 60),
                      title: Text(data["title"]),
                      subtitle: Text(data["description"] ?? ""),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _deleteFloorPlan(docId, data["imageUrl"]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
