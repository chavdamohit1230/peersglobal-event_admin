import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class Speaker extends StatefulWidget {
  const Speaker({super.key});

  @override
  State<Speaker> createState() => _SpeakerState();
}

class _SpeakerState extends State<Speaker> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final occupationController = TextEditingController();
  final organizationController = TextEditingController();
  final countryController = TextEditingController();
  final emailController = TextEditingController();
  final cityController = TextEditingController();
  final facebookController = TextEditingController();
  final linkedinController = TextEditingController();
  final twitterController = TextEditingController();
  final instagramController = TextEditingController();

  Uint8List? _webImage;
  bool _isLoading = false;
  String? _editingDocId;

  // Pick Image
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      _webImage = await picked.readAsBytes();
      setState(() {});
    }
  }

  // Upload image
  Future<String> uploadImage() async {
    if (_webImage == null) return "";
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref = FirebaseStorage.instance.ref().child('speakerimage/$fileName.jpg');
    await ref.putData(_webImage!, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  // Save/Update
  Future<void> saveSpeaker() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        String imageUrl = "";
        if (_webImage != null) imageUrl = await uploadImage();
        List<String> socialLinks = [
          facebookController.text.trim(),
          linkedinController.text.trim(),
          twitterController.text.trim(),
          instagramController.text.trim(),
        ];

        if (_editingDocId != null) {
          Map<String, dynamic> dataToUpdate = {
            "name": nameController.text.trim(),
            "occupation": occupationController.text.trim(),
            "organization": organizationController.text.trim(),
            "country": countryController.text.trim(),
            "email": emailController.text.trim(),
            "city": cityController.text.trim(),
            "socialLinks": socialLinks,
          };
          if (imageUrl.isNotEmpty) dataToUpdate["imageUrl"] = imageUrl;
          await FirebaseFirestore.instance.collection("speakers").doc(_editingDocId).update(dataToUpdate);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Speaker updated!")));
        } else {
          await FirebaseFirestore.instance.collection("speakers").add({
            "name": nameController.text.trim(),
            "occupation": occupationController.text.trim(),
            "organization": organizationController.text.trim(),
            "country": countryController.text.trim(),
            "email": emailController.text.trim(),
            "city": cityController.text.trim(),
            "imageUrl": imageUrl,
            "socialLinks": socialLinks,
            "createdAt": FieldValue.serverTimestamp(),
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Speaker added!")));
        }
        _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Delete
  void deleteSpeaker(String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Speaker"),
        content: const Text("Are you sure you want to delete this speaker?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm) {
      await FirebaseFirestore.instance.collection("speakers").doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Speaker deleted")));
    }
  }

  // Edit
  void editSpeaker(DocumentSnapshot doc) {
    _editingDocId = doc.id;
    var data = doc.data() as Map<String, dynamic>;
    nameController.text = data["name"] ?? "";
    occupationController.text = data["occupation"] ?? "";
    organizationController.text = data["organization"] ?? "";
    countryController.text = data["country"] ?? "";
    emailController.text = data["email"] ?? "";
    cityController.text = data["city"] ?? "";
    List<String> links = List<String>.from(data["socialLinks"] ?? []);
    facebookController.text = links.isNotEmpty ? links[0] : "";
    linkedinController.text = links.length > 1 ? links[1] : "";
    twitterController.text = links.length > 2 ? links[2] : "";
    instagramController.text = links.length > 3 ? links[3] : "";
    setState(() {});
  }

  void _clearForm() {
    _formKey.currentState!.reset();
    nameController.clear();
    occupationController.clear();
    organizationController.clear();
    countryController.clear();
    emailController.clear();
    cityController.clear();
    facebookController.clear();
    linkedinController.clear();
    twitterController.clear();
    instagramController.clear();
    _webImage = null;
    _editingDocId = null;
    setState(() {});
  }

  Widget buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        validator: (val) => val == null || val.isEmpty ? "Enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  // Modern Card Design
  Widget buildSpeakerCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    List<String> links = List<String>.from(data["socialLinks"] ?? []);

    Widget buildRow(String label, String value, {bool isLink = false, String? url}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$label: ",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
            Expanded(
              child: isLink && url != null && url.isNotEmpty
                  ? GestureDetector(
                onTap: () => launchUrl(Uri.parse(url)),
                child: Text(value,
                    style: const TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                        fontSize: 14)),
              )
                  : Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                CircleAvatar(
                  radius: 50,
                  backgroundImage: data["imageUrl"] != null && data["imageUrl"] != ""
                      ? NetworkImage(data["imageUrl"])
                      : null,
                  backgroundColor: Colors.white,
                  child: (data["imageUrl"] == null || data["imageUrl"] == "")
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 20),
                // Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildRow("Name", data["name"] ?? ""),
                      buildRow("Occupation", data["occupation"] ?? ""),
                      buildRow("Organization", data["organization"] ?? ""),
                      buildRow("City", data["city"] ?? ""),
                      buildRow("Country", data["country"] ?? ""),
                      buildRow("Email", data["email"] ?? ""),
                      buildRow("Facebook", links.isNotEmpty ? links[0] : "",
                          isLink: true, url: links.isNotEmpty ? links[0] : ""),
                      buildRow("LinkedIn", links.length > 1 ? links[1] : "",
                          isLink: true, url: links.length > 1 ? links[1] : ""),
                      buildRow("Twitter", links.length > 2 ? links[2] : "",
                          isLink: true, url: links.length > 2 ? links[2] : ""),
                      buildRow("Instagram", links.length > 3 ? links[3] : "",
                          isLink: true, url: links.length > 3 ? links[3] : ""),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Edit/Delete Buttons
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.green,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                    onPressed: () => editSpeaker(doc),
                  ),
                ),
                const SizedBox(height: 8),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                    onPressed: () => deleteSpeaker(doc.id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Speaker Page")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _webImage != null ? MemoryImage(_webImage!) : null,
                  child: _webImage == null ? const Icon(Icons.camera_alt, size: 40, color: Colors.white) : null,
                ),
              ),
              const SizedBox(height: 20),
              buildTextField(nameController, "Name"),
              buildTextField(occupationController, "Occupation"),
              buildTextField(organizationController, "Organization"),
              buildTextField(countryController, "Country"),
              buildTextField(emailController, "Email"),
              buildTextField(cityController, "City"),
              const SizedBox(height: 16),
              const Text("Social Media Links", style: TextStyle(fontWeight: FontWeight.bold)),
              buildTextField(facebookController, "Facebook"),
              buildTextField(linkedinController, "LinkedIn"),
              buildTextField(twitterController, "Twitter"),
              buildTextField(instagramController, "Instagram"),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: saveSpeaker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(_editingDocId != null ? "Update Speaker" : "Save Speaker"),
              ),
              const SizedBox(height: 30),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("speakers").orderBy("createdAt", descending: true).snapshots(),
                builder: (ctx, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) => buildSpeakerCard(docs[i]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
