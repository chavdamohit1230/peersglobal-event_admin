import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:peersglobaladmin/colors/colorfile.dart';

class Speaker extends StatefulWidget {
  const Speaker({super.key});

  @override
  State<Speaker> createState() => _SpeakerState();
}

class _SpeakerState extends State<Speaker> {
  final _formKey = GlobalKey<FormState>();

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

  // Pick image
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

  // Save or update speaker
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
            "socialLinks": socialLinks,
            "imageUrl": imageUrl,
            "createdAt": FieldValue.serverTimestamp(),
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Speaker added!")));
        }

        _clearForm();
        Navigator.pop(context); // Close dialog after save
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Delete speaker
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

  // Edit speaker
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
    _webImage = null;
    setState(() {});
    _openFormDialog(isEdit: true);
  }

  // Clear form
  void _clearForm() {
    _formKey.currentState?.reset();
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
  }

  // Open form dialog
  void _openFormDialog({bool isEdit = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? "Edit Speaker" : "Add Speaker"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _webImage != null ? MemoryImage(_webImage!) : null,
                      child: _webImage == null ? const Icon(Icons.camera_alt, size: 40) : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  buildTextField(nameController, "Name"),
                  buildTextField(occupationController, "Occupation"),
                  buildTextField(organizationController, "Organization"),
                  buildTextField(emailController, "Email"),
                  buildTextField(countryController, "Country"),
                  buildTextField(cityController, "City"),
                  buildTextField(facebookController, "Facebook Link"),
                  buildTextField(linkedinController, "LinkedIn Link"),
                  buildTextField(twitterController, "Twitter Link"),
                  buildTextField(instagramController, "Instagram Link"),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: saveSpeaker,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(isEdit ? "Update" : "Save", style: const TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build TextField
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

  // Launch social link
  void launchLink(String url) async {
    if (url.isEmpty) return;
    Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) throw 'Could not launch $url';
  }

  Widget buildSocialIcon(String url, IconData icon, Color color) {
    if (url.isEmpty) return const SizedBox();
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      onPressed: () => launchLink(url),
    );
  }

  // Speaker Card
  Widget buildSpeakerCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    List<String> links = List<String>.from(data["socialLinks"] ?? []);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: data["imageUrl"] != null && data["imageUrl"] != "" ? NetworkImage(data["imageUrl"]) : null,
              backgroundColor: Colors.grey[200],
              child: (data["imageUrl"] == null || data["imageUrl"] == "") ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data["name"] ?? "", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(data["occupation"] ?? "", style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black54)),
                  Text(data["organization"] ?? "", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  Text("${data["city"] ?? ""}, ${data["country"] ?? ""}", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      buildSocialIcon(links.isNotEmpty ? links[0] : "", Icons.facebook, Colors.blue),
                      buildSocialIcon(links.length > 1 ? links[1] : "", Icons.link, Colors.blueAccent),
                      buildSocialIcon(links.length > 2 ? links[2] : "", Icons.alternate_email, Colors.lightBlue),
                      buildSocialIcon(links.length > 3 ? links[3] : "", Icons.camera_alt, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => editSpeaker(doc),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Text("Edit", style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => deleteSpeaker(doc.id),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text("Delete", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolor.backgroundLight,
      appBar: AppBar(title: const Text("Speakers"),
      backgroundColor:Appcolor.backgroundDark,),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("speakers").orderBy("createdAt", descending: true).snapshots(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: docs.length,
            itemBuilder: (ctx, i) => buildSpeakerCard(docs[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _clearForm();
          _openFormDialog(isEdit: false);
        },
      ),
    );
  }
}
