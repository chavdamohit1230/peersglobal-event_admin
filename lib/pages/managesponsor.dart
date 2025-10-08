import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peersglobaladmin/colors/colorfile.dart';
import 'package:peersglobaladmin/modelclass/mynetwork_model.dart';

// -------------------- Manage Sponsor Screen --------------------
class Managesponsor extends StatefulWidget {
  const Managesponsor({Key? key}) : super(key: key);

  @override
  State<Managesponsor> createState() => _ManagesponsorState();
}

class _ManagesponsorState extends State<Managesponsor> {
  bool isLoading = true;
  List<Mynetwork> sponsors = [];
  List<Mynetwork> filteredSponsors = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSponsorsFromFirebase();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchSponsorsFromFirebase() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("userregister")
          .where("role", isEqualTo: "sponsor")
          .get();

      final fetchedSponsors = snapshot.docs.map((doc) {
        final data = doc.data();
        return Mynetwork(
          id: doc.id,
          username: data['name'] ?? '',
          Designnation: data['designation'] ?? '',
          photoUrl: data['photoUrl'] ?? 'https://via.placeholder.com/150',
          email: data['email'] ?? '',
          mobile: data['mobile'] ?? '',
          organization: data['organization'] ?? '',
          businessLocation: data['businessLocation'] ?? '',
          companywebsite: data['companywebsite'] ?? '',
          industry: data['sponsorType'] ?? '',
          contry: data['country'] ?? '',
          city: data['city'] ?? '',
          aboutme: data['aboutme'] ?? '',
          otherinfo: data['otherInfo'] ?? '',
          countrycode: data['countryCode'] ?? '',
          role: data['role'] ?? 'sponsor',
          brandname: data['brandName'] ?? '',
        );
      }).toList();

      setState(() {
        sponsors = fetchedSponsors;
        filteredSponsors = fetchedSponsors;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching sponsors: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> removeSponsor(String id) async {
    try {
      await FirebaseFirestore.instance.collection('userregister').doc(id).delete();
      setState(() {
        sponsors.removeWhere((s) => s.id == id);
        filteredSponsors.removeWhere((s) => s.id == id);
      });
    } catch (e) {
      print("Error removing sponsor: $e");
    }
  }

  void addSponsorToList(Mynetwork sponsor) {
    setState(() {
      sponsors.add(sponsor);
      filteredSponsors.add(sponsor);
    });
  }

  void updateSponsorInList(Mynetwork sponsor) {
    setState(() {
      final index = sponsors.indexWhere((s) => s.id == sponsor.id);
      if (index != -1) {
        sponsors[index] = sponsor;
        filteredSponsors[index] = sponsor;
      }
    });
  }

  void filterSearch(String query) {
    if (query.isEmpty) {
      setState(() => filteredSponsors = sponsors);
      return;
    }
    final search = query.toLowerCase();
    final results = sponsors.where((s) {
      final name = s.username.toLowerCase();
      final email = s.email?.toLowerCase() ?? '';
      final type = s.industry?.toLowerCase() ?? '';
      return name.contains(search) || email.contains(search) || type.contains(search);
    }).toList();

    setState(() {
      filteredSponsors = results;
    });
  }

  Future<bool> showDeleteConfirmation() async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this sponsor?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolor.backgroundLight,
      appBar: AppBar(
        title: const Text("Sponsor Management"),
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
                hintText: "Search sponsors",
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
                : filteredSponsors.isEmpty
                ? const Center(child: Text("No sponsors found"))
                : ListView.separated(
              itemCount: filteredSponsors.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final sponsor = filteredSponsors[index];
                return ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(sponsor.photoUrl),
                  ),
                  title: Text(
                    sponsor.username,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    sponsor.industry ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddSponsorForm(
                                sponsor: sponsor,
                                onAddSponsor: addSponsorToList,
                                onEditSponsor: updateSponsorInList,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("Edit",
                            style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SponsorDetailView(
                                sponsor: sponsor,
                                onRemove: () async {
                                  final confirmed =
                                  await showDeleteConfirmation();
                                  if (confirmed) {
                                    removeSponsor(sponsor.id!);
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("View",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
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
              builder: (context) => AddSponsorForm(
                onAddSponsor: addSponsorToList,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Sponsor", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// -------------------- Sponsor Detail View --------------------
class SponsorDetailView extends StatelessWidget {
  final Mynetwork sponsor;
  final VoidCallback onRemove;

  const SponsorDetailView({Key? key, required this.sponsor, required this.onRemove})
      : super(key: key);

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this sponsor?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F8FE),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black87),
          title: Text(sponsor.username,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: "Details", icon: Icon(Icons.info_outline)),
              Tab(text: "Posts", icon: Icon(Icons.post_add)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFFDCEAF4), Color(0xFFFFFFFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: NetworkImage(sponsor.photoUrl),
                        ),
                        const SizedBox(height: 12),
                        Text(sponsor.username,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(sponsor.Designnation,
                            style: const TextStyle(
                                fontSize: 16, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration:
                    BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _detailRow("Name", sponsor.username),
                        _detailRow("Organization", sponsor.organization ?? ""),
                        _detailRow("Mobile", sponsor.mobile ?? ""),
                        _detailRow("Email", sponsor.email ?? ""),
                        _detailRow("Business Address", sponsor.businessLocation ?? ""),
                        _detailRow("Country", sponsor.contry?? ""),
                        _detailRow("City", sponsor.city ?? ""),

                        // _detailRow("Brand Name", sponsor.brandname ?? ""),
                        // _detailRow("Designation", sponsor.Designnation),
                        // _detailRow('mobile',sponsor.mobile?? ""),
                        _detailRow("Role", sponsor.role ?? ""),
                        // _detailRow("Category", sponsor.industry ?? ""),
                        _detailRow("About", sponsor.otherinfo ?? ""),
                        const SizedBox(height: 12),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('userregister')
                              .doc(sponsor.id)
                              .get(),
                          builder: (context, snap) {
                            if (snap.connectionState != ConnectionState.done)
                              return const SizedBox();
                            if (!snap.hasData || !(snap.data!.data() is Map<String, dynamic>)) {
                              return const SizedBox();
                            }
                            final data = snap.data!.data() as Map<String, dynamic>;
                            final website = (data['companywebsite'] ?? sponsor.companywebsite ?? '')
                            as String;
                            final social = (data['socialLinks'] ?? {}) as Map<String, dynamic>;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (website.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.language, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(website)),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                if (social.isNotEmpty) ...[
                                  const Text("Social Links",
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  for (final entry in social.entries)
                                    if ((entry.value as String).isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          children: [
                                            Icon(_iconForSocialKey(entry.key), size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(entry.value ?? "")),
                                          ],
                                        ),
                                      ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () async {
                        final confirmed = await _showDeleteDialog(context);
                        if (confirmed) {
                          onRemove();
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child:
                      const Text("Remove Sponsor", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            const Center(child: Text("Posts Section (Coming Soon)")),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
              width: 120,
              child: Text("$title:", style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  IconData _iconForSocialKey(String key) {
    switch (key.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'linkedin':
        return Icons.work;
      case 'twitter':
        return Icons.alternate_email;
      case 'youtube':
        return Icons.video_library;
      default:
        return Icons.link;
    }
  }
}

// -------------------- Add/Edit Sponsor Form --------------------
// ... Keep your AddSponsorForm code unchanged (already handles city & social links)

// -------------------- Add/Edit Sponsor Form --------------------
class AddSponsorForm extends StatefulWidget {
  final Mynetwork? sponsor;
  final Function(Mynetwork)? onAddSponsor;
  final Function(Mynetwork)? onEditSponsor;

  const AddSponsorForm({Key? key, this.sponsor, this.onAddSponsor, this.onEditSponsor}) : super(key: key);

  @override
  State<AddSponsorForm> createState() => _AddSponsorFormState();
}

class _AddSponsorFormState extends State<AddSponsorForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController organizationController = TextEditingController();
  final TextEditingController businessLocationController = TextEditingController();
  final TextEditingController brandNameController = TextEditingController();
  final TextEditingController otherInfoController = TextEditingController();
  final TextEditingController countryCodeController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController country = TextEditingController();
  final TextEditingController mobile =TextEditingController();

  // Social media controllers
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController linkedinController = TextEditingController();
  final TextEditingController twitterController = TextEditingController();
  final TextEditingController youtubeController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.sponsor != null) {
      final s = widget.sponsor!;
      nameController.text = s.username;
      emailController.text = s.email ?? '';
      designationController.text = s.Designnation;
      organizationController.text = s.organization ?? '';
      businessLocationController.text = s.businessLocation ?? '';
      brandNameController.text = s.brandname ?? '';
      otherInfoController.text = s.otherinfo ?? '';
      countryCodeController.text = s.countrycode ?? '';
      cityController.text = s.city ?? '';
      websiteController.text = s.companywebsite ?? '';
      categoryController.text = s.industry ?? '';
      mobile.text = s.mobile ?? '';
      // Try to prefill social links from firestore doc (if present)
      if (s.id != null) {
        FirebaseFirestore.instance.collection('userregister').doc(s.id).get().then((doc) {
          final data = doc.data();
          if (data != null && data['socialLinks'] is Map) {
            final social = Map<String, dynamic>.from(data['socialLinks']);
            setState(() {
              facebookController.text = social['facebook'] ?? '';
              instagramController.text = social['instagram'] ?? '';
              linkedinController.text = social['linkedin'] ?? '';
              twitterController.text = social['twitter'] ?? '';
              youtubeController.text = social['youtube'] ?? '';
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    designationController.dispose();
    organizationController.dispose();
    businessLocationController.dispose();
    brandNameController.dispose();
    otherInfoController.dispose();
    countryCodeController.dispose();
    cityController.dispose();
    websiteController.dispose();
    categoryController.dispose();
    facebookController.dispose();
    instagramController.dispose();
    linkedinController.dispose();
    twitterController.dispose();
    youtubeController.dispose();
    mobile.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
  }

  Future<void> saveSponsor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    String? imageUrl;
    if (_selectedImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child("sponsor_images")
          .child("${DateTime.now().millisecondsSinceEpoch}.jpg");
      await ref.putFile(_selectedImage!);
      imageUrl = await ref.getDownloadURL();
    }

    final socialLinks = {
      "facebook": facebookController.text.trim(),
      "instagram": instagramController.text.trim(),
      "linkedin": linkedinController.text.trim(),
      "twitter": twitterController.text.trim(),
      "youtube": youtubeController.text.trim(),
    };

    if (widget.sponsor == null) {
      // Add New Sponsor
      final docRef = await FirebaseFirestore.instance.collection("userregister").add({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "designation": designationController.text.trim(),
        "organization": organizationController.text.trim(),
        "businessLocation": businessLocationController.text.trim(),
        "brandName": brandNameController.text.trim(),
        "otherInfo": otherInfoController.text.trim(),
        "countryCode": countryCodeController.text.trim(),
        "city": cityController.text.trim(),
        "companywebsite": websiteController.text.trim(),
        "role": "sponsor",
        "country":country.text.trim(),
        "sponsorType": categoryController.text.trim(),
        "socialLinks": socialLinks,
        "photoUrl": imageUrl ?? "https://via.placeholder.com/150",
        "mobile":mobile.text.trim()
      });

      final newSponsor = Mynetwork(
        id: docRef.id,
        username: nameController.text.trim(),
        Designnation: designationController.text.trim(),
        organization: organizationController.text.trim(),
        businessLocation: businessLocationController.text.trim(),
        brandname: brandNameController.text.trim(),
        otherinfo: otherInfoController.text.trim(),
        countrycode: countryCodeController.text.trim(),
        city: cityController.text.trim(),
        mobile:mobile.text.trim(),
        role: "sponsor",
        contry:country.text.trim(),
        companywebsite: websiteController.text.trim(),
        industry: categoryController.text.trim(),
        photoUrl: imageUrl ?? 'https://via.placeholder.com/150',
      );

      widget.onAddSponsor?.call(newSponsor);
    } else {
      // Edit Sponsor
      final s = widget.sponsor!;
      final docRef = FirebaseFirestore.instance.collection("userregister").doc(s.id);
      await docRef.update({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "designation": designationController.text.trim(),
        "organization": organizationController.text.trim(),
        "businessLocation": businessLocationController.text.trim(),
        "brandName": brandNameController.text.trim(),
        "otherInfo": otherInfoController.text.trim(),
        "countryCode": countryCodeController.text.trim(),
        "city": cityController.text.trim(),
        "companywebsite": websiteController.text.trim(),
        "sponsorType": categoryController.text.trim(),
        "socialLinks": socialLinks,
        "mobile":mobile.text.trim(),
        "photoUrl": imageUrl ?? s.photoUrl,
        "country":country.text.trim()
      });

      final updatedSponsor = Mynetwork(
        id: s.id,
        username: nameController.text.trim(),
        Designnation: designationController.text.trim(),
        organization: organizationController.text.trim(),
        businessLocation: businessLocationController.text.trim(),
        brandname: brandNameController.text.trim(),
        otherinfo: otherInfoController.text.trim(),
        countrycode: countryCodeController.text.trim(),
        city: cityController.text.trim(),
        role: s.role,
        companywebsite: websiteController.text.trim(),
        industry: categoryController.text.trim(),
          photoUrl: imageUrl ?? s.photoUrl,
        mobile: mobile.text.trim(),
        contry: country.text.trim()
      );

      widget.onEditSponsor?.call(updatedSponsor);
    }

    setState(() => isLoading = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.sponsor == null ? "Sponsor Added Successfully" : "Sponsor Updated Successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFDCEAF4),
          appBar: AppBar(
            title: Text(widget.sponsor == null ? "Add Sponsor" : "Edit Sponsor"),
            backgroundColor: const Color(0xFFDCEAF4),
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (widget.sponsor != null
                                  ? NetworkImage(widget.sponsor!.photoUrl)
                                  : const NetworkImage("https://via.placeholder.com/150")) as ImageProvider,
                              child: _selectedImage == null && widget.sponsor == null
                                  ? const Icon(Icons.camera_alt, size: 30, color: Colors.white70)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        buildTextField("Full Name", nameController, Icons.person),
                        buildTextField("Organization", organizationController, Icons.business),
                        buildTextField("Country Code", countryCodeController, Icons.phone_android),
                        buildTextField("mobile", mobile, Icons.call, keyboardType: TextInputType.phone),
                        buildTextField("Email", emailController, Icons.email, keyboardType: TextInputType.emailAddress),
                        buildTextField("Website", websiteController, Icons.language),
                        buildTextField("Business Address", businessLocationController, Icons.location_on),
                        buildTextField("Country", country, Icons.location_city_outlined),
                        buildTextField("City", cityController, Icons.location_city),
                        const Divider(height: 40),
                        const Text("Social Media Links",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        buildTextField("Facebook", facebookController, Icons.facebook),
                        buildTextField("Instagram", instagramController, Icons.camera_alt),
                        buildTextField("LinkedIn", linkedinController, Icons.work),
                        buildTextField("Twitter", twitterController, Icons.alternate_email),
                        buildTextField("YouTube", youtubeController, Icons.video_library),
                        const SizedBox(height: 30),
                        // buildTextField("Designation", designationController, Icons.work_outline),
                        // buildTextField("Brand Name", brandNameController, Icons.shopping_bag_outlined),
                        buildTextField("About", otherInfoController, Icons.notes_outlined, maxLines: 3),
                        const SizedBox(height: 20),
                        // buildTextField("Category", categoryController, Icons.category),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: saveSponsor,
                            icon: const Icon(Icons.save),
                            label: Text(widget.sponsor == null ? "Save Sponsor" : "Update Sponsor",
                                style: const TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Appcolor.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
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
          fillColor: Color(0xFFDCEAF4).withOpacity(0.4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          // make some fields optional if you want (here we require name & email)
          if (label == "Full Name" || label == "Email") {
            if (value == null || value.isEmpty) return "$label is required";
          }
          return null;
        },
      ),
    );
  }
}
