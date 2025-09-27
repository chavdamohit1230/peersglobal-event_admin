import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peersglobaladmin/colors/colorfile.dart';
import 'package:peersglobaladmin/modelclass/mynetwork_model.dart';

class Manageexhibiter extends StatefulWidget {
  const Manageexhibiter({super.key});

  @override
  State<Manageexhibiter> createState() => _ManageexhibiterState();
}

class _ManageexhibiterState extends State<Manageexhibiter> {
  bool isLoading = true;
  List<Mynetwork> exhibitors = [];
  List<Mynetwork> filteredExhibitors = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchExhibitorsFromFirebase();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchExhibitorsFromFirebase() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("userregister")
          .where("role", isEqualTo: "exhibitor")
          .get();

      final fetchedExhibitors = snapshot.docs.map((doc) {
        final data = doc.data();
        return Mynetwork(
          id: doc.id,
          username: data['name'] ?? '',
          Designnation: data['designation'] ?? '',
          ImageUrl: data['profileImage'] ?? 'https://via.placeholder.com/150',
          email: data['email'] ?? '',
          mobile: data['mobile'] ?? '',
          organization: data['organization'] ?? '',
          businessLocation: data['businessLocation'] ?? '',
          companywebsite: data['companywebsite'] ?? '',
          industry: data['industry'] ?? '',
          contry: data['country'] ?? '',
          city: data['city'] ?? '',
          aboutme: data['aboutme'] ?? '',
        );
      }).toList();

      setState(() {
        exhibitors = fetchedExhibitors;
        filteredExhibitors = fetchedExhibitors;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching exhibitors: $e");
      setState(() => isLoading = false);
    }
  }

  void removeExhibitor(String exhibitorId) async {
    try {
      await FirebaseFirestore.instance
          .collection('userregister')
          .doc(exhibitorId)
          .delete();

      setState(() {
        exhibitors.removeWhere((e) => e.id == exhibitorId);
        filteredExhibitors.removeWhere((e) => e.id == exhibitorId);
      });
    } catch (e) {
      print("Error removing exhibitor: $e");
    }
  }

  void addExhibitorToList(Mynetwork exhibitor) {
    setState(() {
      final index = exhibitors.indexWhere((e) => e.id == exhibitor.id);
      if (index >= 0) {
        exhibitors[index] = exhibitor;
      } else {
        exhibitors.add(exhibitor);
      }
      filteredExhibitors = exhibitors;
    });
  }

  void filterSearch(String query) {
    if (query.isEmpty) {
      setState(() => filteredExhibitors = exhibitors);
      return;
    }

    final search = query.toLowerCase();
    final results = exhibitors.where((ex) {
      final name = ex.username.toLowerCase();
      final email = ex.email?.toLowerCase() ?? "";
      final designation = ex.Designnation.toLowerCase();
      return name.contains(search) || email.contains(search) || designation.contains(search);
    }).toList();

    setState(() {
      filteredExhibitors = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolor.backgroundLight,
      appBar: AppBar(
        title: const Text("Exhibiter Section"),
        backgroundColor: Appcolor.backgroundDark,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              onChanged: filterSearch,
              decoration: InputDecoration(
                hintText: "Search exhibitors",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF3F8FE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredExhibitors.isEmpty
                ? const Center(child: Text("No exhibitors found"))
                : ListView.separated(
              itemCount: filteredExhibitors.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final exhibitor = filteredExhibitors[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(exhibitor.ImageUrl),
                  ),
                  title: Text(
                    exhibitor.username,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  subtitle: Text(
                    exhibitor.Designnation,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExhibiterDetailView(
                            exhibiter: exhibitor,
                            onRemove: () => removeExhibitor(exhibitor.id!),
                            onEdit: addExhibitorToList,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("View",
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Appcolor.secondary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExhibiterForm(onAddExhibitor: addExhibitorToList),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Exhibiter", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ---------------- Add/Edit Exhibiter Form ----------------

class AddExhibiterForm extends StatefulWidget {
  final Function(Mynetwork) onAddExhibitor;
  final bool isEditMode;
  final Mynetwork? exhibiter;

  const AddExhibiterForm({
    super.key,
    required this.onAddExhibitor,
    this.isEditMode = false,
    this.exhibiter,
  });

  @override
  State<AddExhibiterForm> createState() => _AddExhibiterFormState();
}

class _AddExhibiterFormState extends State<AddExhibiterForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController organizationController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController businessLocationController = TextEditingController();
  final TextEditingController aboutMeController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController roleController = TextEditingController();

  File? _imageFile;
  Uint8List? webImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.exhibiter != null) {
      final ex = widget.exhibiter!;
      nameController.text = ex.username;
      emailController.text = ex.email ?? '';
      organizationController.text = ex.organization ?? '';
      websiteController.text = ex.companywebsite ?? '';
      businessLocationController.text = ex.businessLocation ?? '';
      aboutMeController.text = ex.aboutme ?? '';
      countryController.text = ex.contry ?? '';
      mobileController.text = ex.mobile ?? '';
      roleController.text = ex.Designnation;
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kIsWeb) {
        webImage = await pickedFile.readAsBytes();
      } else {
        _imageFile = File(pickedFile.path);
      }
      setState(() {});
    }
  }

  Future<void> saveExhibitor() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? imageUrl = widget.exhibiter?.ImageUrl;

      if (_imageFile != null || webImage != null) {
        final storageRef =
        FirebaseStorage.instance.ref().child("userprofile/${DateTime.now().millisecondsSinceEpoch}.jpg");

        if (kIsWeb && webImage != null) {
          await storageRef.putData(webImage!);
        } else if (_imageFile != null) {
          await storageRef.putFile(_imageFile!);
        }

        imageUrl = await storageRef.getDownloadURL();
      }

      if (widget.isEditMode && widget.exhibiter != null) {
        await FirebaseFirestore.instance.collection('userregister').doc(widget.exhibiter!.id).update({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'organization': organizationController.text.trim(),
          'companywebsite': websiteController.text.trim(),
          'businessLocation': businessLocationController.text.trim(),
          'aboutme': aboutMeController.text.trim(),
          'country': countryController.text.trim(),
          'mobile': mobileController.text.trim(),
          'role': roleController.text.trim(),
          'profileImage': imageUrl,
          'designation': roleController.text.trim(),
        });

        final updatedExhibitor = Mynetwork(
          id: widget.exhibiter!.id,
          username: nameController.text.trim(),
          Designnation: roleController.text.trim(),
          ImageUrl: imageUrl ?? 'https://via.placeholder.com/150',
          email: emailController.text.trim(),
          mobile: mobileController.text.trim(),
          organization: organizationController.text.trim(),
          businessLocation: businessLocationController.text.trim(),
          companywebsite: websiteController.text.trim(),
          industry: widget.exhibiter!.industry,
          contry: countryController.text.trim(),
          city: widget.exhibiter!.city,
          aboutme: aboutMeController.text.trim(),
        );

        widget.onAddExhibitor(updatedExhibitor);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Exhibiter Updated Successfully")));
      } else {
        final docRef = await FirebaseFirestore.instance.collection('userregister').add({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'organization': organizationController.text.trim(),
          'companywebsite': websiteController.text.trim(),
          'businessLocation': businessLocationController.text.trim(),
          'aboutme': aboutMeController.text.trim(),
          'country': countryController.text.trim(),
          'mobile': mobileController.text.trim(),
          'role': roleController.text.trim(),
          'profileImage': imageUrl ?? 'https://via.placeholder.com/150',
          'designation': roleController.text.trim(),
          'industry': '',
          'city': '',
        });

        final newExhibitor = Mynetwork(
          id: docRef.id,
          username: nameController.text.trim(),
          Designnation: roleController.text.trim(),
          ImageUrl: imageUrl ?? 'https://via.placeholder.com/150',
          email: emailController.text.trim(),
          mobile: mobileController.text.trim(),
          organization: organizationController.text.trim(),
          businessLocation: businessLocationController.text.trim(),
          companywebsite: websiteController.text.trim(),
          industry: '',
          contry: countryController.text.trim(),
          city: '',
          aboutme: aboutMeController.text.trim(),
        );

        widget.onAddExhibitor(newExhibitor);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Exhibiter Added Successfully")));
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget buildTextField(String label, TextEditingController controller, IconData icon,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Appcolor.textDark),
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFDCEAF4).withOpacity(0.4),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.indigo, width: 2)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "$label is required";
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCEAF4),
      appBar: AppBar(
        title: Text(widget.isEditMode ? "Edit Exhibiter" : "Add Exhibiter"),
        backgroundColor: const Color(0xFFDCEAF4),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: kIsWeb
                          ? (webImage != null
                          ? MemoryImage(webImage!) as ImageProvider
                          : NetworkImage(widget.exhibiter?.ImageUrl ?? 'https://via.placeholder.com/150'))
                          : (_imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : NetworkImage(widget.exhibiter?.ImageUrl ?? 'https://via.placeholder.com/150')),
                      child: (_imageFile == null && webImage == null)
                          ? const Icon(Icons.add_a_photo, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildTextField("Full Name", nameController, Icons.person),
                  buildTextField("Email", emailController, Icons.email, keyboardType: TextInputType.emailAddress),
                  buildTextField("Organization", organizationController, Icons.business),
                  buildTextField("Company Website", websiteController, Icons.language),
                  buildTextField("Business Location", businessLocationController, Icons.location_on),
                  buildTextField("About Me", aboutMeController, Icons.info, maxLines: 3),
                  buildTextField("Country", countryController, Icons.flag_outlined),
                  buildTextField("Mobile Number", mobileController, Icons.phone_iphone, keyboardType: TextInputType.phone),
                  buildTextField("Role", roleController, Icons.work_outline),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Appcolor.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: saveExhibitor,
                      icon: const Icon(Icons.save),
                      label: Text(widget.isEditMode ? "Update Exhibiter" : "Save Exhibiter",
                          style: const TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Detail View with Edit ----------------

class ExhibiterDetailView extends StatelessWidget {
  final Mynetwork exhibiter;
  final VoidCallback onRemove;
  final Function(Mynetwork) onEdit;

  const ExhibiterDetailView({super.key, required this.exhibiter, required this.onRemove, required this.onEdit});

  Widget buildInfoRow(IconData icon, String label, String value) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.blueGrey),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          subtitle: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 16)),
        ),
        const Divider(thickness: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Exhibiter Details"),
        backgroundColor: Appcolor.backgroundDark,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF84A9FF), Color(0xFF8FD3F4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(exhibiter.ImageUrl),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    exhibiter.username,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    exhibiter.Designnation,
                    style: const TextStyle(fontSize: 16, color: Colors.white70, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            buildInfoRow(Icons.email, "Email", exhibiter.email ?? ''),
            buildInfoRow(Icons.business, "Organization", exhibiter.organization ?? ''),
            buildInfoRow(Icons.language, "Company Website", exhibiter.companywebsite ?? ''),
            buildInfoRow(Icons.location_on, "Business Location", exhibiter.businessLocation ?? ''),
            buildInfoRow(Icons.info_outline, "About Me", exhibiter.aboutme ?? ''),
            buildInfoRow(Icons.flag_outlined, "Country", exhibiter.contry ?? ''),
            buildInfoRow(Icons.location_city, "City", exhibiter.city ?? ''),
            buildInfoRow(Icons.phone_iphone, "Mobile", exhibiter.mobile ?? ''),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        onRemove();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Remove Exhibiter", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddExhibiterForm(
                              onAddExhibitor: onEdit,
                              isEditMode: true,
                              exhibiter: exhibiter,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Edit Exhibiter", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
