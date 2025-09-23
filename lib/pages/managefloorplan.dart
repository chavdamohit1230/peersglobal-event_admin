import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peersglobaladmin/colors/colorfile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Floor Plan Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF3F8FE),
      ),
      home: const ManageFloorPlan(),
    );
  }
}

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
  String? _updatingDocId;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _selectedImageBytes = await pickedFile.readAsBytes();
        setState(() {});
      }
    } catch (e) {
      debugPrint("Pick Image Error: $e");
    }
  }

  Future<void> _saveFloorPlan() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter title")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? downloadUrl;
      if (_selectedImageBytes != null) {
        String fileName =
            "FloorplanImage/${DateTime.now().millisecondsSinceEpoch}.jpg";
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        TaskSnapshot snapshot = await ref.putData(_selectedImageBytes!);
        downloadUrl = Uri.encodeFull(await snapshot.ref.getDownloadURL());
      }

      if (_updatingDocId != null) {
        await FirebaseFirestore.instance
            .collection("floorplan")
            .doc(_updatingDocId)
            .update({
          "title": _titleController.text.trim(),
          "description": _descController.text.trim(),
          if (downloadUrl != null) "imageUrl": downloadUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Updated successfully")));
      } else {
        await FirebaseFirestore.instance.collection("floorplan").add({
          "title": _titleController.text.trim(),
          "description": _descController.text.trim(),
          "imageUrl": downloadUrl ?? "",
          "timestamp": FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Added successfully")));
      }

      _titleController.clear();
      _descController.clear();
      _selectedImageBytes = null;
      _updatingDocId = null;
    } catch (e) {
      debugPrint("Save Error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteFloorPlan(String docId, String? imageUrl) async {
    bool confirm = await showDialog(
      context: context,

      builder: (ctx) => AlertDialog(
        backgroundColor:Appcolor.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Delete Confirmation"),
        content:
        const Text("Are you sure you want to delete this floor plan?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel",style:TextStyle(color:Colors.black),),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor:Appcolor.secondary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete",style:TextStyle(color:Colors.black),),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection("floorplan").doc(docId).delete();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(Uri.decodeFull(imageUrl)).delete();
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Deleted successfully")));
    } catch (e) {
      debugPrint("Delete Error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _prepareUpdate(Map<String, dynamic> data, String docId) {
    _titleController.text = data['title'] ?? "";
    _descController.text = data['description'] ?? "";
    _updatingDocId = docId;
    _selectedImageBytes = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Appcolor.backgroundLight,
      appBar: AppBar(
        title: const Text("Manage Floor Plans"),
        backgroundColor:Appcolor.backgroundDark,
        elevation: 1,
        titleTextStyle:
        const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Add / Update form
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              color:Appcolor.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child:ElevatedButton.icon(
                            onPressed: _pickImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Appcolor.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3,
                            ),
                            icon: const Icon(Icons.image, color: Colors.white),
                            label: const Text(
                              "Pick Image",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )

                        ),
                        const SizedBox(width: 12),
                        _selectedImageBytes != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _selectedImageBytes!,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Text("No image selected"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveFloorPlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Appcolor.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : Text(
                          _updatingDocId != null ? "Update" : "Add",
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floorplan list
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
                  return const Center(child: Text("No floor plans available"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String docId = docs[index].id;
                    String imageUrl = data['imageUrl'] ?? "";

                    return Card(
                      color:Appcolor.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            Uri.decodeFull(imageUrl),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                ),
                          )
                              : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                        title: Text(
                          data['title'] ?? "",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            data['description'] ?? "",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _prepareUpdate(data, docId),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteFloorPlan(docId, imageUrl),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FloorPlanDetailView(
                                title: data['title'] ?? "",
                                imageUrl: imageUrl,
                              ),
                            ),
                          );
                        },
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

class FloorPlanDetailView extends StatelessWidget {
  final String title;
  final String imageUrl;

  const FloorPlanDetailView({super.key, required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: imageUrl.isNotEmpty
              ? Image.network(
            Uri.decodeFull(imageUrl),
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) =>
            progress == null ? child : const CircularProgressIndicator(),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white, size: 80),
            ),
          )
              : const Center(
            child: Text(
              "No image available",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
