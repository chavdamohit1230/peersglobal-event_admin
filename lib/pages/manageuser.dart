import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peersglobaladmin/colors/colorfile.dart';
import 'package:peersglobaladmin/modelclass/mynetwork_model.dart';

class Manageuser extends StatefulWidget {
  const Manageuser({super.key});

  @override
  State<Manageuser> createState() => _ManageuserState();
}

class _ManageuserState extends State<Manageuser> {
  bool isLoading = true;
  List<Mynetwork> users = [];
  List<Mynetwork> filteredUsers = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsersFromFirebase();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchUsersFromFirebase() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection("userregister").get();

      final fetchedUsers = snapshot.docs.map((doc) {
        final data = doc.data();
        return Mynetwork(
          id: doc.id,
          username: data['name'] ?? 'N/A',
          Designnation: data['designation'] ?? 'N/A',
          photoUrl: data['photoUrl'] ??
              'https://via.placeholder.com/150', // updated field
          email: data['email'] ?? 'N/A',
          mobile: data['mobile'] ?? 'N/A',
          organization: data['organization'] ?? 'N/A',
          businessLocation: data['businessLocation'] ?? 'N/A',
          companywebsite: data['companywebsite'] ?? 'N/A',
          industry: data['industry'] ?? 'N/A',
          contry: data['country'] ?? 'N/A',
          city: data['city'] ?? 'N/A',
          aboutme: data['aboutme'] ?? 'N/A',
          countrycode: data['countrycode'] ?? 'N/A',
          compayname: data['companyname'] ?? 'N/A',
          role: data['role'] ?? 'user',
          category: data['category'] ?? 'N/A',

        );
      }).toList();

      setState(() {
        users = fetchedUsers;
        filteredUsers = fetchedUsers;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching users from Firebase: $e");
      setState(() => isLoading = false);
    }
  }

  void filterSearch(String query) {
    if (query.isEmpty) {
      setState(() => filteredUsers = users);
      return;
    }

    final search = query.toLowerCase();
    final results = users.where((u) {
      final name = u.username.toLowerCase();
      final email = u.email?.toLowerCase() ?? "";
      final designation = u.Designnation.toLowerCase();
      return name.contains(search) ||
          email.contains(search) ||
          designation.contains(search);
    }).toList();

    setState(() {
      filteredUsers = results;
    });
  }

  void addUserToList(Mynetwork user) {
    setState(() {
      users.add(user);
      filteredUsers.add(user);
    });
  }

  void removeUser(Mynetwork user) async {
    // Role check
    if (user.role == "exhibitor" || user.role == "sponsor") {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Action Denied"),
          content: Text(
              "You can't delete ${user.username} because they are ${user.role}."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    // Confirm delete
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete User"),
        content: Text("Do you want to delete ${user.username}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              try {
                await FirebaseFirestore.instance
                    .collection('userregister')
                    .doc(user.id)
                    .delete();

                setState(() {
                  users.removeWhere((u) => u.id == user.id);
                  filteredUsers.removeWhere((u) => u.id == user.id);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${user.username} deleted successfully")),
                );
              } catch (e) {
                print("Error deleting user: $e");
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void printUsers() {
    for (var u in filteredUsers) {
      print("${u.username} - ${u.Designnation} - ${u.email}");
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Users printed to console")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolor.backgroundLight,
      appBar: AppBar(
        title: const Text("Manage Users"),
        backgroundColor: Appcolor.backgroundDark,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: printUsers,
              style: TextButton.styleFrom(
                backgroundColor: Appcolor.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text("Print"),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              onChanged: filterSearch,
              decoration: InputDecoration(
                hintText: "Search users",
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
                : filteredUsers.isEmpty
                ? const Center(child: Text("No users found"))
                : ListView.separated(
              itemCount: filteredUsers.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Colors.grey),
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(user.photoUrl),
                  ),
                  title: Text(
                    user.username,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  subtitle: Text(
                    user.Designnation,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black54),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserDetailView(
                            user: user,
                            onRemove: () => removeUser(user),
                            onUpdate: (updatedUser) {
                              setState(() {
                                int idx = users.indexWhere(
                                        (element) =>
                                    element.id ==
                                        updatedUser.id);
                                if (idx != -1) {
                                  users[idx] = updatedUser;
                                  filteredUsers[idx] = updatedUser;
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: const Text(
                      "View",
                      style: TextStyle(
                          color: Colors.white, fontSize: 14),
                    ),
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
              builder: (context) => AddUserForm(onAddUser: addUserToList),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add User",
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ------------------- User Detail View -------------------

class UserDetailView extends StatelessWidget {
  final Mynetwork user;
  final VoidCallback onRemove;
  final Function(Mynetwork)? onUpdate;

  const UserDetailView(
      {super.key, required this.user, required this.onRemove, this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(user.username,
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
                    backgroundImage: NetworkImage(user.photoUrl),
                  ),
                  const SizedBox(height: 12),
                  Text(user.username,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 6),
                  Text(user.Designnation,
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
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.person, "Name", user.username),
                  const Divider(),
                  _buildInfoRow(
                      Icons.work_outline, "Designation", user.Designnation),
                  const Divider(),
                  _buildInfoRow(Icons.work_outline, "CompanyName ",
                      user.compayname ?? "N/A "),
                  const Divider(),
                  _buildInfoRow(Icons.category_sharp, "Category",
                      user.category ?? "N/A "),
                  const Divider(),
                  _buildInfoRow(Icons.phone, "Mobile", user.mobile ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.email_outlined, "Email", user.email ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.language, "Website",
                      user.companywebsite ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.location_history, "Business Address",
                      user.businessLocation ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(
                      Icons.flag, "Country Code", user.countrycode ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.map, "Country", user.contry ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.location_city_sharp, "City", user.city ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.info, "About Me", user.aboutme ?? "N/A"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: onRemove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Remove User",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updatedUser = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddUserForm(
                          existingUser: user,
                          onAddUser: (u) {
                            if (onUpdate != null) onUpdate!(u);
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Edit User",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
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
          child: Text("$title:",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 15, color: Colors.black87))),
      ]),
    );
  }
}

// ------------------ Add / Edit Form with Image Upload ------------------

class AddUserForm extends StatefulWidget {
  final Function(Mynetwork) onAddUser;
  final Mynetwork? existingUser;

  const AddUserForm({super.key, required this.onAddUser, this.existingUser});

  @override
  State<AddUserForm> createState() => _AddUserFormState();
}

class _AddUserFormState extends State<AddUserForm> {
  final _formKey = GlobalKey<FormState>();
  File? selectedImage;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController companyWebSiteController = TextEditingController();
  final TextEditingController businessLocationController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController countryCodeController = TextEditingController();
  final TextEditingController companynmae = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController category = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingUser != null) {
      final u = widget.existingUser!;
      nameController.text = u.username;
      emailController.text = u.email ?? 'N/A';
      designationController.text = u.Designnation;
      mobileController.text = u.mobile ?? 'N/A';
      companyWebSiteController.text = u.companywebsite ?? 'N/A';
      businessLocationController.text = u.businessLocation ?? 'N/A';
      countryController.text = u.contry ?? 'N/A';
      cityController.text = u.city ?? 'N/A';
      countryCodeController.text = u.countrycode ?? 'N/A';
      companynmae.text = u.compayname ?? 'N/A';
      aboutController.text = u.aboutme ?? 'N/A';
      category.text = u.category ?? 'N/A';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    designationController.dispose();
    mobileController.dispose();
    companyWebSiteController.dispose();
    businessLocationController.dispose();
    countryController.dispose();
    cityController.dispose();
    countryCodeController.dispose();
    aboutController.dispose();
    companynmae.dispose();
    category.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String> uploadImage() async {
    if (selectedImage == null) {
      return widget.existingUser?.photoUrl ??
          'https://via.placeholder.com/150';
    }
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('userprofile/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await storageRef.putFile(selectedImage!);
    return await storageRef.getDownloadURL();
  }

  Future<void> saveUser() async {
    final photoUrl = await uploadImage();

    if (widget.existingUser != null) {
      // Update existing
      await FirebaseFirestore.instance
          .collection('userregister')
          .doc(widget.existingUser!.id)
          .update({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'designation': designationController.text.trim(),
        'mobile': mobileController.text.trim(),
        'companywebsite': companyWebSiteController.text.trim(),
        'businessLocation': businessLocationController.text.trim(),
        'country': countryController.text.trim(),
        'city': cityController.text.trim(),
        'countrycode': countryCodeController.text.trim(),
        'aboutme': aboutController.text.trim(),
        'companyname': companynmae.text.trim(),
        'photoUrl': photoUrl,
        'category':category.text.trim()
      });
      final updatedUser = Mynetwork(
        id: widget.existingUser!.id,
        username: nameController.text.trim(),
        Designnation: designationController.text.trim(),
          photoUrl: photoUrl,
        email: emailController.text.trim(),
        mobile: mobileController.text.trim(),
        companywebsite: companyWebSiteController.text.trim(),
        businessLocation: businessLocationController.text.trim(),
        contry: countryController.text.trim(),
        city: cityController.text.trim(),
        countrycode: countryCodeController.text.trim(),
        aboutme: aboutController.text.trim(),
        compayname: companynmae.text.trim(),
        category: category.text.trim()
      );
      widget.onAddUser(updatedUser);
    } else {
      // Add new
      final docRef =
      await FirebaseFirestore.instance.collection('userregister').add({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'designation': designationController.text.trim(),
        'mobile': mobileController.text.trim(),
        'companywebsite': companyWebSiteController.text.trim(),
        'businessLocation': businessLocationController.text.trim(),
        'country': countryController.text.trim(),
        'city': cityController.text.trim(),
        'countrycode': countryCodeController.text.trim(),
        'aboutme': aboutController.text.trim(),
        'companyname': companynmae.text.trim(),
        'photoUrl': photoUrl,
        'role': 'user', // default role
        'category':category.text.trim()
      });

      final newUser = Mynetwork(
        id: docRef.id,
        username: nameController.text.trim(),
        Designnation: designationController.text.trim(),
        photoUrl: photoUrl,
        email: emailController.text.trim(),
        mobile: mobileController.text.trim(),
        companywebsite: companyWebSiteController.text.trim(),
        businessLocation: businessLocationController.text.trim(),
        contry: countryController.text.trim(),
        city: cityController.text.trim(),
        countrycode: countryCodeController.text.trim(),
        aboutme: aboutController.text.trim(),
        compayname: companynmae.text.trim(),
        category: category.text.trim(),
      );

      widget.onAddUser(newUser);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("User saved successfully")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCEAF4),
      appBar: AppBar(
        title: Text(widget.existingUser != null ? "Edit User" : "Add User"),
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
                    const Text("User Information",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: pickImage,
                      child: Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : (widget.existingUser != null
                              ? NetworkImage(widget.existingUser!.photoUrl)
                          as ImageProvider
                              : const NetworkImage(
                              'https://via.placeholder.com/150')),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildTextField("Full Name", nameController, Icons.person),
                    buildTextField("Designation", designationController,
                        Icons.work_outline),
                    buildTextField(
                        "CompanyName", companynmae, Icons.home_work_outlined),
                    buildTextField('category', category, Icons.category_rounded,keyboardType:TextInputType.text),
                    buildTextField("Mobile Number", mobileController, Icons.phone,
                        keyboardType: TextInputType.phone),
                    buildTextField("Email", emailController, Icons.email,
                        keyboardType: TextInputType.emailAddress),
                    buildTextField("Website", companyWebSiteController,
                        Icons.language,
                        keyboardType: TextInputType.url),
                    buildTextField("Business Address",
                        businessLocationController, Icons.location_on),
                    buildTextField("Country", countryController, Icons.flag),
                    buildTextField("City", cityController, Icons.location_city),
                    buildTextField(
                        "Country Code", countryCodeController, Icons.add),
                    buildTextField("About Me", aboutController, Icons.info,
                        maxLines: 3),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Appcolor.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            saveUser();
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text("Save User",
                            style: TextStyle(
                                fontSize: 16, color: Colors.white)),
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
}
