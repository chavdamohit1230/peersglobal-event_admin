import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    fetchExhibitorsFromFirebase();
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
      });
    } catch (e) {
      print("Error removing exhibitor: $e");
    }
  }

  void addExhibitorToList(Mynetwork exhibitor) {
    setState(() {
      exhibitors.add(exhibitor);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Exhibiter Section"),
        backgroundColor: const Color(0xFFC5D9EC),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : exhibitors.isEmpty
          ? const Center(child: Text("No exhibitors found"))
          : ListView.separated(
        itemCount: exhibitors.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final exhibitor = exhibitors[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
                vertical: 12, horizontal: 16),
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(exhibitor.ImageUrl),
            ),
            title: Text(
              exhibitor.username,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            subtitle: Text(
              exhibitor.Designnation,
              style: const TextStyle(
                  fontSize: 14, color: Colors.black54),
            ),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExhibiterDetailView(
                      exhibiter: exhibitor,
                      onRemove: () => removeExhibitor(exhibitor.id!),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "View",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Appcolor.secondary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddExhibiterForm(onAddExhibitor: addExhibitorToList),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label:
        const Text("Add Exhibiter", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class ExhibiterDetailView extends StatelessWidget {
  final Mynetwork exhibiter;
  final VoidCallback onRemove;

  const ExhibiterDetailView({
    super.key,
    required this.exhibiter,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(exhibiter.username,
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDCEAF4), Color(0xFFFFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(exhibiter.ImageUrl),
                  ),
                  const SizedBox(height: 12),
                  Text(exhibiter.username,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 6),
                  Text(exhibiter.Designnation,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.person, "Name", exhibiter.username),
                  const Divider(),
                  _buildInfoRow(
                      Icons.work_outline, "Designation", exhibiter.Designnation),
                  const Divider(),
                  _buildInfoRow(Icons.phone, "Mobile", exhibiter.mobile ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.email_outlined, "Email", exhibiter.email ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.language, "CompanyUrl",
                      exhibiter.companywebsite ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.location_history, "BusinessLocation",
                      exhibiter.businessLocation ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.business_sharp, "Industry",
                      exhibiter.industry ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.map, "Country", exhibiter.contry ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.location_city_sharp, "City",
                      exhibiter.city ?? "N/A"),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Remove Exhibiter",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.blueGrey, size: 22),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child:
          Text("$title:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 15, color: Colors.black87))),
      ]),
    );
  }
}

class AddExhibiterForm extends StatefulWidget {
  final Function(Mynetwork) onAddExhibitor;

  const AddExhibiterForm({super.key, required this.onAddExhibitor});

  @override
  State<AddExhibiterForm> createState() => _AddExhibiterFormState();
}

class _AddExhibiterFormState extends State<AddExhibiterForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController organizationController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController businessLocationController =
  TextEditingController();
  final TextEditingController aboutMeController = TextEditingController();
  final TextEditingController otherInfoController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController countryCodeController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController brandNameController = TextEditingController();

  Future<void> saveExhibitor() async {
    final docRef = await FirebaseFirestore.instance.collection('userregister').add({
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'organization': organizationController.text.trim(),
      'companywebsite': websiteController.text.trim(),
      'businessLocation': businessLocationController.text.trim(),
      'aboutme': aboutMeController.text.trim(),
      'otherInfo': otherInfoController.text.trim(),
      'country': countryController.text.trim(),
      'countryCode': countryCodeController.text.trim(),
      'mobile': mobileController.text.trim(),
      'role': roleController.text.trim(),
      'brandName': brandNameController.text.trim(),
      'profileImage': 'https://via.placeholder.com/150', // default image
      'designation': roleController.text.trim(),
      'industry': '',
      'city': '',
    });

    final newExhibitor = Mynetwork(
      id: docRef.id,
      username: nameController.text.trim(),
      Designnation: roleController.text.trim(),
      ImageUrl: 'https://via.placeholder.com/150',
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
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Exhibiter Added Successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCEAF4),
      appBar: AppBar(
        title: const Text("Add Exhibiter"),
        backgroundColor: const Color(0xFFDCEAF4),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 6,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Exhibiter Information",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    buildTextField("Full Name", nameController, Icons.person),
                    buildTextField("Email", emailController, Icons.email,
                        keyboardType: TextInputType.emailAddress),
                    buildTextField(
                        "Organization", organizationController, Icons.business),
                    buildTextField(
                        "Company Website", websiteController, Icons.language),
                    buildTextField("Business Location",
                        businessLocationController, Icons.location_on),
                    buildTextField("About Me", aboutMeController, Icons.info,
                        maxLines: 3),
                    buildTextField("Other Info", otherInfoController,
                        Icons.notes_outlined,
                        maxLines: 3),
                    buildTextField(
                        "Country", countryController, Icons.flag_outlined),
                    buildTextField("Country Code", countryCodeController,
                        Icons.phone_android),
                    buildTextField("Mobile Number", mobileController,
                        Icons.phone_iphone,
                        keyboardType: TextInputType.phone),
                    buildTextField("Role", roleController, Icons.work_outline),
                    buildTextField("Brand Name", brandNameController,
                        Icons.shopping_bag_outlined),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Appcolor.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            saveExhibitor();
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text(
                          "Save Exhibiter",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      IconData icon,
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
          contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
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
}
