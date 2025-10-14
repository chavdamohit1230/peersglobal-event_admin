import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement extends StatefulWidget {
  const Announcement({super.key});

  @override
  State<Announcement> createState() => _AnnouncementState();
}

class _AnnouncementState extends State<Announcement> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  void _showAddAnnouncementForm({DocumentSnapshot? docToEdit}) {
    // If a document is provided, pre-fill the form for editing
    if (docToEdit != null) {
      _titleController.text = docToEdit['title'];
      _descriptionController.text = docToEdit['description'];
    } else {
      _titleController.clear();
      _descriptionController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                docToEdit == null ? "Create New Announcement" : "Edit Announcement",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (docToEdit == null) {
                      _saveAnnouncement();
                    } else {
                      _updateAnnouncement(docToEdit);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    docToEdit == null ? 'Save Announcement' : 'Update Announcement',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // CREATE (C)
  Future<void> _saveAnnouncement() async {
    if (_titleController.text.isNotEmpty && _descriptionController.text.isNotEmpty) {
      final collection = FirebaseFirestore.instance.collection('notifications');
      await collection.add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'date': DateTime.now().toIso8601String(),
        'isRead': false,
      });

      _titleController.clear();
      _descriptionController.clear();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  // UPDATE (U)
  Future<void> _updateAnnouncement(DocumentSnapshot doc) async {
    if (_titleController.text.isNotEmpty && _descriptionController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('notifications').doc(doc.id).update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'date': DateTime.now().toIso8601String(), // Update the date to show it's been edited
      });

      if (context.mounted) Navigator.of(context).pop();
    }
  }

  // DELETE (D) with Confirmation Alert
  Future<void> _deleteAnnouncement(String docId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Announcement'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this announcement?'),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('notifications').doc(docId).delete();
                if (context.mounted) Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Announcements'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No announcements yet."));
          }

          final announcements = snapshot.data!.docs;

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              final String announcementId = announcement.id;

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: ListTile(
                  title: Text(
                    announcement['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    announcement['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Button
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddAnnouncementForm(docToEdit: announcement),
                      ),
                      // Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAnnouncement(announcementId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAnnouncementForm(),
        backgroundColor: Colors.blue.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}