import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Timeline extends StatefulWidget {
  const Timeline({super.key});

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _timeStartController = TextEditingController();
  final TextEditingController _timeEndController = TextEditingController();

  int currentDay = 1;
  List<XFile> selectedSessionImages = [];
  bool isUploading = false;
  String? editingDocId;

  // Speakers
  List<XFile> selectedSpeakerImages = [];
  List<TextEditingController> speakerNameControllers = [];
  List<TextEditingController> speakerOccupationControllers = [];
  List<TextEditingController> speakerBioControllers = [];

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _timeStartController.clear();
    _timeEndController.clear();
    selectedSessionImages = [];
    selectedSpeakerImages = [];
    speakerNameControllers = [];
    speakerOccupationControllers = [];
    speakerBioControllers = [];
    editingDocId = null;
  }

  Future pickSessionImages() async {
    final picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    if (images != null) {
      setState(() {
        selectedSessionImages.addAll(images);
      });
    }
  }

  Future pickSpeakerImage(int index) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (selectedSpeakerImages.length > index) {
          selectedSpeakerImages[index] = image;
        } else {
          selectedSpeakerImages.add(image);
        }
      });
    }
  }

  Future<String> uploadSingleImage(XFile image) async {
    try {
      final ref = _storage.ref('agendaimage/${DateTime.now().millisecondsSinceEpoch}_${image.name}');
      if (kIsWeb) {
        Uint8List data = await image.readAsBytes();
        final uploadTask = ref.putData(data);
        await uploadTask;
      } else {
        final uploadTask = ref.putFile(File(image.path));
        await uploadTask;
      }
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return "";
    }
  }

  Future<void> saveSession() async {
    if (_titleController.text.isEmpty) return;
    setState(() => isUploading = true);

    List<String> sessionImageUrls = [];
    for (var img in selectedSessionImages) {
      final url = await uploadSingleImage(img);
      if (url.isNotEmpty) sessionImageUrls.add(url);
    }

    // Upload speaker images
    List<Map<String, dynamic>> speakers = [];
    for (int i = 0; i < speakerNameControllers.length; i++) {
      String imgUrl = "";
      if (i < selectedSpeakerImages.length) {
        imgUrl = await uploadSingleImage(selectedSpeakerImages[i]);
      }
      speakers.add({
        "image": imgUrl,
        "name": speakerNameControllers[i].text,
        "occupation": speakerOccupationControllers[i].text,
        "bio": speakerBioControllers[i].text,
      });
    }

    Map<String, dynamic> sessionData = {
      "title": _titleController.text,
      "description": _descriptionController.text,
      "timeStart": _timeStartController.text,
      "timeEnd": _timeEndController.text,
      "day": currentDay,
      "images": sessionImageUrls,
      "speakers": speakers,
    };

    try {
      if (editingDocId != null) {
        await _firestore.collection('eventagenda').doc(editingDocId).update(sessionData);
      } else {
        await _firestore.collection('eventagenda').add(sessionData);
      }
    } catch (e) {
      print("Error saving session: $e");
    }

    _clearForm();
    setState(() => isUploading = false);
  }

  void addSpeaker() {
    setState(() {
      speakerNameControllers.add(TextEditingController());
      speakerOccupationControllers.add(TextEditingController());
      speakerBioControllers.add(TextEditingController());
      selectedSpeakerImages.add(XFile(''));
    });
  }

  void removeSpeaker(int index) {
    setState(() {
      speakerNameControllers.removeAt(index);
      speakerOccupationControllers.removeAt(index);
      speakerBioControllers.removeAt(index);
      selectedSpeakerImages.removeAt(index);
    });
  }

  void editSession(Map<String, dynamic> data, String docId) {
    _titleController.text = data['title'] ?? "";
    _descriptionController.text = data['description'] ?? "";
    _timeStartController.text = data['timeStart'] ?? "";
    _timeEndController.text = data['timeEnd'] ?? "";
    currentDay = data['day'] ?? 1;
    editingDocId = docId;

    // Speakers
    speakerNameControllers = [];
    speakerOccupationControllers = [];
    speakerBioControllers = [];
    selectedSpeakerImages = [];

    List speakers = data['speakers'] ?? [];
    for (var sp in speakers) {
      speakerNameControllers.add(TextEditingController(text: sp['name'] ?? ""));
      speakerOccupationControllers.add(TextEditingController(text: sp['occupation'] ?? ""));
      speakerBioControllers.add(TextEditingController(text: sp['bio'] ?? ""));
      selectedSpeakerImages.add(XFile('')); // placeholder, actual image can be downloaded if needed
    }

    selectedSessionImages = [];
    List images = data['images'] ?? [];
    for (var img in images) {
      selectedSessionImages.add(XFile(img)); // placeholder for display
    }
    setState(() {});
  }

  Future<void> confirmDelete(String docId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this session?"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              deleteSession(docId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteSession(String docId) async {
    await _firestore.collection('eventagenda').doc(docId).delete();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget buildSpeakerForm(int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => pickSpeakerImage(index),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: selectedSpeakerImages[index].path.isNotEmpty
                        ? FileImage(File(selectedSpeakerImages[index].path)) as ImageProvider
                        : null,
                    child: selectedSpeakerImages[index].path.isEmpty ? const Icon(Icons.add_a_photo) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      TextField(controller: speakerNameControllers[index], decoration: _inputDecoration("Speaker Name")),
                      const SizedBox(height: 6),
                      TextField(controller: speakerOccupationControllers[index], decoration: _inputDecoration("Occupation")),
                      const SizedBox(height: 6),
                      TextField(controller: speakerBioControllers[index], decoration: _inputDecoration("Bio"), maxLines: 2),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => removeSpeaker(index)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAdminForm() {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: _inputDecoration("Session Title")),
            const SizedBox(height: 12),
            TextField(controller: _descriptionController, decoration: _inputDecoration("Description"), maxLines: 3),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _timeStartController, decoration: _inputDecoration("Start Time"))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _timeEndController, decoration: _inputDecoration("End Time"))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("Day: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: currentDay,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text("Day 1")),
                    DropdownMenuItem(value: 2, child: Text("Day 2")),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => currentDay = val);
                  },
                )
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              children: [
                for (int i = 0; i < selectedSessionImages.length; i++)
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: kIsWeb
                            ? Image.network(selectedSessionImages[i].path, width: 80, height: 80, fit: BoxFit.cover)
                            : Image.file(File(selectedSessionImages[i].path), width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedSessionImages.removeAt(i);
                            });
                          },
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                ElevatedButton(
                  onPressed: pickSessionImages,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text("Select Session Images", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
            const SizedBox(height: 12),
            // Speakers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Speakers", style: TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton(onPressed: addSpeaker, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), child: const Text("Add Speaker", style: TextStyle(color: Colors.white))),
              ],
            ),
            Column(
              children: List.generate(speakerNameControllers.length, (index) => buildSpeakerForm(index)),
            ),
            const SizedBox(height: 12),
            isUploading
                ? const LinearProgressIndicator()
                : ElevatedButton(
              onPressed: saveSession,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text(editingDocId != null ? "Update Session" : "Save Session", style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSessionCard(Map<String, dynamic> data, String docId) {
    List images = data['images'] ?? [];
    List speakers = data['speakers'] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(data['title'] ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => editSession(data, docId)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => confirmDelete(docId)),
              ],
            ),
            const SizedBox(height: 6),
            Text(data['description'] ?? "", style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text("${data['timeStart']} - ${data['timeEnd']}", style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            images.isNotEmpty
                ? SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        images[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
                : const SizedBox(),
            const SizedBox(height: 8),
            // Speakers display
            speakers.isNotEmpty
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(speakers.length, (i) {
                var sp = speakers[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: sp['image'] != null && sp['image'] != ""
                      ? CircleAvatar(backgroundImage: NetworkImage(sp['image']))
                      : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(sp['name'] ?? ""),
                  subtitle: Text("${sp['occupation'] ?? ""}\n${sp['bio'] ?? ""}"),
                );
              }),
            )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget buildSessionList(int day) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('eventagenda').where('day', isEqualTo: day).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text("No sessions"));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return buildSessionCard(data, docId);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Timeline"), backgroundColor: Colors.blue),
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildAdminForm(),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text("Day 1 Sessions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            buildSessionList(1),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text("Day 2 Sessions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            buildSessionList(2),
          ],
        ),
      ),
    );
  }
}
