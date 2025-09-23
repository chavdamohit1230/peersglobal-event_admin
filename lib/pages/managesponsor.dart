import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peersglobaladmin/colors/colorfile.dart';
import 'package:peersglobaladmin/modelclass/mynetwork_model.dart';

class Managesponsor extends StatefulWidget {
  const Managesponsor({super.key});

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
          ImageUrl: data['profileImage'] ?? 'https://via.placeholder.com/150',
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

  void removeSponsor(String id) async {
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(sponsor.ImageUrl),
                  ),
                  title: Text(
                    sponsor.username,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    sponsor.industry ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SponsorDetailView(
                            sponsor: sponsor,
                            onRemove: () => removeSponsor(sponsor.id!),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("View", style: TextStyle(color: Colors.white)),
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
              builder: (context) => AddSponsorForm(onAddSponsor: addSponsorToList),
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

  const SponsorDetailView({super.key, required this.sponsor, required this.onRemove});

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
          title: Text(sponsor.username, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
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
                      gradient: LinearGradient(colors: [Color(0xFFDCEAF4), Color(0xFFFFFFFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(radius: 60, backgroundColor: Colors.white, backgroundImage: NetworkImage(sponsor.ImageUrl)),
                        const SizedBox(height: 12),
                        Text(sponsor.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(sponsor.Designnation, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _detailRow("Name", sponsor.username),
                        _detailRow("Designation", sponsor.Designnation),
                        _detailRow("Email", sponsor.email ?? ""),
                        _detailRow("Mobile", sponsor.mobile ?? ""),
                        _detailRow("Role", sponsor.role ?? ""),
                        _detailRow("Brand Name", sponsor.brandname ?? ""),
                        _detailRow("Business Location", sponsor.businessLocation ?? ""),
                        _detailRow("Organization", sponsor.organization ?? ""),
                        _detailRow("Country Code", sponsor.countrycode ?? ""),
                        _detailRow("Category", sponsor.industry ?? ""),
                        _detailRow("Other Info", sponsor.otherinfo ?? ""),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        onRemove();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Remove Sponsor", style: TextStyle(color: Colors.white)),
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
          SizedBox(width: 120, child: Text("$title:", style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// -------------------- Add Sponsor Form --------------------
class AddSponsorForm extends StatefulWidget {
  final Function(Mynetwork) onAddSponsor;
  const AddSponsorForm({super.key, required this.onAddSponsor});

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

  String selectedCategory = "Silver";
  final List<String> categories = ["Silver", "Gold", "Platinum"];

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
    super.dispose();
  }

  Future<void> saveSponsor() async {
    if (!_formKey.currentState!.validate()) return;

    final docRef = await FirebaseFirestore.instance.collection("userregister").add({
      "name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "designation": designationController.text.trim(),
      "organization": organizationController.text.trim(),
      "businessLocation": businessLocationController.text.trim(),
      "brandName": brandNameController.text.trim(),
      "otherInfo": otherInfoController.text.trim(),
      "countryCode": countryCodeController.text.trim(),
      "role": "sponsor",
      "sponsorType": selectedCategory,
      "profileImage": "https://via.placeholder.com/150",
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
      role: "sponsor",
      industry: selectedCategory,
      ImageUrl: "https://via.placeholder.com/150",
    );

    widget.onAddSponsor(newSponsor);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sponsor Added Successfully")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCEAF4),
      appBar: AppBar(
        title: const Text("Add Sponsor"),
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
                    buildTextField("Full Name", nameController, Icons.person),
                    buildTextField("Email", emailController, Icons.email, keyboardType: TextInputType.emailAddress),
                    buildTextField("Designation", designationController, Icons.work_outline),
                    buildTextField("Organization", organizationController, Icons.business),
                    buildTextField("Business Location", businessLocationController, Icons.location_on),
                    buildTextField("Brand Name", brandNameController, Icons.shopping_bag_outlined),
                    buildTextField("Other Info", otherInfoController, Icons.notes_outlined, maxLines: 3),
                    buildTextField("Country Code", countryCodeController, Icons.phone_android),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => selectedCategory = value);
                      },
                      decoration: InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFFDCEAF4).withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: saveSponsor,
                        icon: const Icon(Icons.save),
                        label: const Text("Save Sponsor", style: TextStyle(color: Colors.white)),
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
          fillColor: const Color(0xFFDCEAF4).withOpacity(0.4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "$label is required";
          return null;
        },
      ),
    );
  }
}
