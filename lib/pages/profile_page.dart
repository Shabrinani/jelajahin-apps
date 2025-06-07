import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jelajahin_apps/main.dart'; // Import AppColors
import 'package:jelajahin_apps/pages/login.dart'; // Untuk navigasi setelah logout
import 'package:jelajahin_apps/pages/edit_profile.dart'; // Halaman Edit Profil (akan disesuaikan juga)
import 'package:jelajahin_apps/pages/help_page.dart';    // Halaman Bantuan/FAQ (akan disesuaikan juga)

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
      if (mounted) { // Pastikan widget masih ada sebelum navigasi
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false, // Hapus semua rute sebelumnya
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
      backgroundColor: AppColors.white, // Background putih sesuai UI
      appBar: AppBar(
        backgroundColor: AppColors.white, // AppBar putih
        elevation: 0, // Tanpa shadow
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryDark), // Panah kembali
          onPressed: () {
            Navigator.pop(context); // Kembali ke halaman sebelumnya
          },
        ),
        title: Text(
          'Profile', // Judul "Profile"
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), // Padding disesuaikan
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Bagian Foto Profil
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60, // Ukuran sesuai UI
                  backgroundColor: AppColors.lightTeal.withOpacity(0.2), // Warna background avatar
                  backgroundImage: _currentUser?.photoURL != null
                      ? NetworkImage(_currentUser!.photoURL!)
                      : null, // Tampilkan foto profil jika ada
                  child: _currentUser?.photoURL == null
                      ? Icon(
                          Icons.person,
                          size: 60, // Ukuran ikon default
                          color: AppColors.darkTeal,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Implementasi ganti foto profil
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfilePage()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 18, // Ukuran ikon edit
                      backgroundColor: AppColors.darkTeal, // Warna icon edit
                      child: Icon(Icons.edit, color: AppColors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Nama Pengguna
            Text(
              _currentUser?.displayName ?? 'Your Name Here', // Nama pengguna
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 5),

            // Role/Profesi (jika ada, atau bisa diganti email)
            Text(
              // _currentUser?.email ?? 'UI UX Designer', // Jika ingin menampilkan email
              'UI UX Designer', // Contoh role/profesi sesuai UI
              style: textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),

            // Opsi Profil
            _buildProfileOption(
              context,
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                // Navigasi ke halaman pengaturan (belum ada, bisa dibuat nanti)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Halaman Pengaturan akan segera hadir!')),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.info_outline, // Ikon info
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
              icon: Icons.call, // Ikon telepon/kontak
              title: 'Feedback & Support',
              onTap: () {
                // TODO: Navigasi ke halaman Feedback & Support atau email client
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kirim Feedback Anda akan segera hadir!')),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.logout, // Ikon logout
              title: 'Log Out',
              onTap: _logout, // Panggil fungsi logout
              isLogout: true, // Beri tanda bahwa ini opsi logout
            ),
            const SizedBox(height: 20),
            // Bottom navigation bar akan berada di parent widget (Home)

          ],
        ),
      ),
    );
  }

  // Helper Widget untuk setiap opsi profil, disesuaikan dengan UI baru
  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false, // Parameter baru untuk styling logout
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0), // Hapus padding default ListTile
          leading: Icon(
            icon,
            color: isLogout ? Colors.red : AppColors.darkTeal, // Warna ikon logout merah
            size: 28,
          ),
          title: Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: isLogout ? Colors.red : AppColors.primaryDark, // Warna teks logout merah
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
          color: Colors.grey[200], // Garis pemisah antar opsi
          indent: 44, // Indentasi agar sejajar dengan teks
        ),
      ],
    );
  }
}