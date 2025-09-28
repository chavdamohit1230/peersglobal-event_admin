import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peersglobaladmin/colors/colorfile.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {

  int totalUsers = 250;
  int totalExhibitors = 45;
  int totalSponsors = 20;
  int totalTickets = 1200;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Appcolor.backgroundDark,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ---------- OVERVIEW SECTION ----------
            const Text(
              "Overview",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildStatCard("Users", totalUsers, Icons.people, Colors.blue),
                _buildStatCard("Exhibitors", totalExhibitors, Icons.business, Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard("Sponsors", totalSponsors, Icons.handshake, Colors.green),
                _buildStatCard("Tickets", totalTickets, Icons.confirmation_num, Colors.purple),
              ],
            ),

            const SizedBox(height: 30),

            // ---------- MANAGEMENT SECTION ----------
            const Text(
              "Management & Event Functions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.2,
              children: [
                _buildDashboardCard("Manage Users", Icons.supervised_user_circle, Colors.purple, () {
                  context.push('/manageuser');
                }),
                _buildDashboardCard("Manage Exhibitors", Icons.business, Colors.blue, () {
                  context.push('/manageexhibiter');
                }),
                _buildDashboardCard("Manage Sponsors", Icons.handshake, Colors.green, () {
                  context.push('/managesponsor');
                }),
                _buildDashboardCard("Speakers ", Icons.mic, Colors.deepOrange, () {
                  context.push('/speaker');
                }),
                _buildDashboardCard("Event Timeline", Icons.timeline, Colors.teal, () {
                  context.push('/timeline');
                }),
                _buildDashboardCard("Announcements", Icons.notifications_active, Colors.redAccent, () {
                  context.push('/announcements');
                }),
                _buildDashboardCard("Ticketing", Icons.confirmation_num, Colors.amber, () {
                  context.push('/ticketing');
                }),
                _buildDashboardCard("Venue & Maps", Icons.map, Colors.cyan, () {
                  context.push('/managefloorplan');
                }),
                _buildDashboardCard("Analytics & Reports", Icons.bar_chart, Colors.indigo, () {
                  context.push('/analytics');
                }),
                _buildDashboardCard("Feedback & Support", Icons.feedback, Colors.brown, () {
                  context.push('/feedback');
                }),
                _buildDashboardCard("Event profile", Icons.calendar_month_sharp, Colors.grey, () {
                  context.push('/eventprofile');
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              "$count",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Reusable Dashboard Card ----------
  Widget _buildDashboardCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 28,
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
