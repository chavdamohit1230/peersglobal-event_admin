import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peersglobaladmin/colors/colorfile.dart';

class Eventprofile extends StatefulWidget {
  const Eventprofile({super.key});

  @override
  State<Eventprofile> createState() => _EventprofileState();
}

class _EventprofileState extends State<Eventprofile> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _dateController = TextEditingController();
  TextEditingController _timeController = TextEditingController();
  TextEditingController _purposeController = TextEditingController();

  File? _imageFile;
  Uint8List? _webImage;
  String? _editingDocId;
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  // Pick image
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        Uint8List bytes = await pickedFile.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        setState(() => _imageFile = File(pickedFile.path));
      }
    }
  }

  // Upload image to Firebase Storage
  Future<String?> uploadImage() async {
    if (_imageFile == null && _webImage == null) return null;
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref = FirebaseStorage.instance.ref().child('eventprofile/$fileName');

    if (kIsWeb && _webImage != null) {
      await ref.putData(_webImage!);
    } else if (_imageFile != null) {
      await ref.putFile(_imageFile!);
    }

    return await ref.getDownloadURL();
  }

  // Save event (Add / Update)
  Future<void> saveEvent() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      String? imageUrl = await uploadImage();

      if (_editingDocId == null) {
        // Add new
        await FirebaseFirestore.instance.collection('eventprofile').add({
          'name': _nameController.text,
          'date': _dateController.text,
          'time': _timeController.text,
          'purpose': _purposeController.text,
          'imageUrl': imageUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing
        Map<String, dynamic> data = {
          'name': _nameController.text,
          'date': _dateController.text,
          'time': _timeController.text,
          'purpose': _purposeController.text,
        };
        if (imageUrl != null) data['imageUrl'] = imageUrl;

        await FirebaseFirestore.instance.collection('eventprofile').doc(_editingDocId).update(data);
        _editingDocId = null;
      }

      _nameController.clear();
      _dateController.clear();
      _timeController.clear();
      _purposeController.clear();
      setState(() {
        _imageFile = null;
        _webImage = null;
        _loading = false;
      });
    }
  }

  // Delete event with alert
  Future<void> deleteEvent(String docId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this event?'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey, // Cancel button color
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Same as Add/Update
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('eventprofile').doc(docId).delete();
    }
  }

  // Fill form for edit
  void fillFormForEdit(DocumentSnapshot data) {
    _nameController.text = data['name'];
    _dateController.text = data['date'];
    _timeController.text = data['time'];
    _purposeController.text = data['purpose'];
    _editingDocId = data.id;
    if (data['imageUrl'] != null && data['imageUrl'] != '') {
      _webImage = null;
      _imageFile = null;
    }
  }

  InputDecoration customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Appcolor.backgroundLight,
      appBar: AppBar(title: Text("Event Profile"), backgroundColor:Appcolor.backgroundDark),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: kIsWeb
                          ? (_webImage != null
                          ? Image.memory(_webImage!, fit: BoxFit.cover)
                          : Icon(Icons.camera_alt, size: 50, color: Colors.grey[700]))
                          : (_imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : Icon(Icons.camera_alt, size: 50, color: Colors.grey[700])),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: customInputDecoration('Event Name'),
                    validator: (value) => value!.isEmpty ? 'Enter event name' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _dateController,
                    decoration: customInputDecoration('Event Date'),
                    validator: (value) => value!.isEmpty ? 'Enter date' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _timeController,
                    decoration: customInputDecoration('Event Time'),
                    validator: (value) => value!.isEmpty ? 'Enter time' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _purposeController,
                    decoration: customInputDecoration('Purpose of Event'),
                    maxLines: 4,
                    validator: (value) => value!.isEmpty ? 'Enter purpose' : null,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: saveEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_editingDocId == null ? ' Save Event' : 'Update Event'),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),

            // Event List
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('eventprofile')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return Center(child: Text('No events found'));

                return ListView.builder(
                  shrinkWrap: true, // Important for scroll inside SingleChildScrollView
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          data['imageUrl'] != ''
                              ? Image.network(data['imageUrl'],
                              width: double.infinity, height: 180, fit: BoxFit.cover)
                              : Container(
                            width: double.infinity,
                            height: 180,
                            color: Colors.grey[300],
                            child: Icon(Icons.image, size: 50, color: Colors.grey[700]),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'],
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text("${data['date']} | ${data['time']}",
                                    style: TextStyle(color: Colors.grey[700])),
                                SizedBox(height: 8),
                                Text(data['purpose'], style: TextStyle(color: Colors.grey[800])),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // Add/Update jaisa
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => fillFormForEdit(data),
                                child: Text('Edit'),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue, // Add/Update button ke jaisa
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => deleteEvent(data.id),
                                child: Text('Delete'),
                              ),

                              SizedBox(width: 8),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
