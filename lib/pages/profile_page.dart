import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jelajahin_apps/main.dart'; // Import AppColors
import 'package:jelajahin_apps/pages/login.dart'; // Untuk navigasi setelah logout
import 'package:jelajahin_apps/pages/edit_profile.dart'; // Halaman Edit Profil (akan disesuaikan juga)
import 'package:jelajahin_apps/pages/help_page.dart';    // Halaman Bantuan/FAQ (akan disesuaikan juga)
import 'package:jelajahin_apps/pages/settings.dart'; // Halaman Setting

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _currentUser; // Untuk menyimpan data pengguna yang sedang login

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser; // Ambil data pengguna saat ini
    // Listener untuk update real-time jika nama atau email berubah dari Firebase
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) { // Pastikan widget masih ada sebelum setState
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Setelah logout, arahkan ke halaman login dan hapus semua rute sebelumnya
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal logout: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Profile',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Foto Profil
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.lightTeal.withOpacity(0.2),
                  backgroundImage: _currentUser?.photoURL != null
                      ? NetworkImage(_currentUser!.photoURL!)
                      : null,
                  child: _currentUser?.photoURL == null
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: AppColors.darkTeal,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfilePage()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.darkTeal,
                      child: Icon(Icons.edit, color: AppColors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Nama
            Text(
              _currentUser?.displayName ?? 'Your Name Here',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 5),

            // Role
            Text(
              'UI UX Designer',
              style: textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),

            // Menu
            _buildProfileOption(
              context,
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingPage()),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.info_outline,
              title: 'Help',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpPage()),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.call,
              title: 'Feedback & Support',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kirim Feedback Anda akan segera hadir!')),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.logout,
              title: 'Log Out',
              onTap: _logout,
              isLogout: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Widget Opsi
  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          leading: Icon(
            icon,
            color: isLogout ? Colors.red : AppColors.darkTeal,
            size: 28,
          ),
          title: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: isLogout ? Colors.red : AppColors.primaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[400],
            size: 20,
          ),
          onTap: onTap,
        ),
        Divider(
          height: 1,
          color: Colors.grey[200],
          indent: 44,
        ),
      ],
    );
  }
}