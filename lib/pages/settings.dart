import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jelajahin_apps/main.dart'; // Untuk AppColors dan themeNotifier
import 'package:jelajahin_apps/pages/notification_page.dart'; // Pastikan path sesuai
import 'package:jelajahin_apps/pages/help_page.dart'; // Import HelpPage yang baru ditambahkan
import 'package:firebase_auth/firebase_auth.dart'; // Untuk fungsi logout
import 'package:jelajahin_apps/pages/login.dart'; // Untuk navigasi ke LoginPage setelah logout

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool('isDarkMode') ?? false;

    setState(() {
      _isDarkMode = darkMode;
    });

    // Sinkronkan dengan theme global
    themeNotifier.value = darkMode ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);

    setState(() {
      _isDarkMode = value;
    });

    // Ubah tema global
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? "Dark Mode Aktif" : "Light Mode Aktif"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Fungsi logout yang dipindahkan/direplikasi ke SettingPage
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // Hapus semua rute dan navigasi ke LoginPage
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onBackground,
        ),
        title: Text(
          'Settings',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _buildSectionTitle("Tampilan"),
          _buildSwitchTile(
            icon: Icons.dark_mode,
            title: "Dark Mode",
            value: _isDarkMode,
            onChanged: _toggleTheme,
          ),
          const Divider(height: 1),

          _buildSectionTitle("Preferensi"),
          _buildNavigationTile(
            icon: Icons.language,
            title: "Bahasa",
            subtitle: "Indonesia",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Fitur Bahasa segera hadir")),
              );
            },
          ),
          _buildNavigationTile(
            icon: Icons.notifications_active_outlined,
            title: "Notifikasi",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              );
            },
          ),
          _buildNavigationTile(
            icon: Icons.security,
            title: "Privasi & Keamanan",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Pengaturan Privasi segera hadir")),
              );
            },
          ),

          _buildSectionTitle("Bantuan & Dukungan"), // Section baru untuk Bantuan
          _buildNavigationTile(
            icon: Icons.help_outline,
            title: "Bantuan",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpPage()), // Navigasi ke HelpPage
              );
            },
          ),

          _buildSectionTitle("Tentang"),
          _buildNavigationTile(
            icon: Icons.info_outline,
            title: "Tentang Aplikasi",
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Jelajahin',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 Jelajahin Inc.',
              );
            },
          ),
          
          // Opsi Logout di bagian paling bawah
          const SizedBox(height: 30), // Memberi jarak dari section di atasnya
          _buildNavigationTile(
            icon: Icons.logout,
            title: "Log Out",
            onTap: _logout,
            // Anda bisa tambahkan warna merah jika diinginkan, tapi defaultnya sudah cukup jelas
            // trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red), // Contoh
            // iconColor: Colors.red, // Ini membutuhkan penyesuaian di _buildNavigationTile jika ingin passing color
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    // Tambahkan parameter iconColor jika ingin bisa custom warna ikon untuk logout
    // Color? iconColor,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary), // Gunakan iconColor jika ditambahkan
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              // Jika ingin teks logout merah:
              // color: title == "Log Out" ? Colors.red : null,
            ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}

