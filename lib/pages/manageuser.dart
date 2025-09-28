import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
          countrycode: data['countrycode'] ?? '',
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

  void removeUser(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('userregister')
          .doc(userId)
          .delete();

      setState(() {
        users.removeWhere((u) => u.id == userId);
        filteredUsers.removeWhere((u) => u.id == userId);
      });
    } catch (e) {
      print("Error removing user: $e");
    }
  }

  void addUserToList(Mynetwork user) {
    setState(() {
      users.add(user);
      filteredUsers.add(user);
    });
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

  void printUsers() {
    for (var u in filteredUsers) {
      print("${u.username} - ${u.Designnation} - ${u.email}");
    }
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Users printed to console")));
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
                    backgroundImage: NetworkImage(user.ImageUrl),
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
                            onRemove: () => removeUser(user.id!),
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

class UserDetailView extends StatelessWidget {
  final Mynetwork user;
  final VoidCallback onRemove;

  const UserDetailView({super.key, required this.user, required this.onRemove});

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
                    backgroundImage: NetworkImage(user.ImageUrl),
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
                  _buildInfoRow(Icons.work_outline, "Designation", user.Designnation),
                  const Divider(),
                  _buildInfoRow(Icons.work_outline, "CompanyName ",user.compayname?? "N/A "),
                  const Divider(),
                  _buildInfoRow(Icons.flag, "Country Code", user.countrycode ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.phone, "Mobile", user.mobile ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.email_outlined, "Email", user.email ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.language, "Company Website", user.companywebsite ?? "N/A"),
                  const Divider(),
                  _buildInfoRow(Icons.location_history, "Business Location", user.businessLocation ?? "N/A"),
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
                  "Remove User",
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


class AddUserForm extends StatefulWidget {
  final Function(Mynetwork) onAddUser;
  const AddUserForm({super.key, required this.onAddUser});

  @override
  State<AddUserForm> createState() => _AddUserFormState();
}

class _AddUserFormState extends State<AddUserForm> {
  final _formKey = GlobalKey<FormState>();

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
    super.dispose();
  }

  Future<void> saveUser() async {
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
      'companyname':companynmae.text.trim(),
      'profileImage': 'https://via.placeholder.com/150',
    });

    final newUser = Mynetwork(
      id: docRef.id,
      username: nameController.text.trim(),
      Designnation: designationController.text.trim(),
      ImageUrl: 'https://via.placeholder.com/150',
      email: emailController.text.trim(),
      mobile: mobileController.text.trim(),
      companywebsite: companyWebSiteController.text.trim(),
      businessLocation: businessLocationController.text.trim(),
      contry: countryController.text.trim(),
      city: cityController.text.trim(),
      countrycode: countryCodeController.text.trim(),
      aboutme: aboutController.text.trim(),
      compayname: companynmae.text.trim()
    );

    widget.onAddUser(newUser);
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("User Added Successfully")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCEAF4),
      appBar: AppBar(
        title: const Text("Add User"),
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
                      buildTextField("Full Name", nameController, Icons.person),
                      buildTextField("Designation", designationController,
                          Icons.work_outline),
                      buildTextField("CompanyName", companynmae,
                          Icons.home_work_outlined),
                      buildTextField("Email", emailController, Icons.email,
                          keyboardType: TextInputType.emailAddress),

                      buildTextField("Mobile Number", mobileController,
                          Icons.phone, keyboardType: TextInputType.phone),
                      buildTextField("Company Website", companyWebSiteController, Icons.language,
                          keyboardType: TextInputType.url),
                      buildTextField("Business Location", businessLocationController, Icons.location_on),
                      buildTextField("Country", countryController, Icons.flag),
                      buildTextField("City", cityController, Icons.location_city),
                      buildTextField("Country Code", countryCodeController, Icons.add),
                      buildTextField("About Me", aboutController, Icons.info, maxLines: 3),
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
                    ]),
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
