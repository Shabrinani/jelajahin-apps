// Import pustaka Flutter dan layanan tambahan seperti SharedPreferences dan Firebase
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jelajahin_apps/main.dart';
import 'package:jelajahin_apps/pages/notification_page.dart';
import 'package:jelajahin_apps/pages/help_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jelajahin_apps/pages/login.dart';

/// Halaman pengaturan (Settings) aplikasi.
/// Menyediakan opsi untuk mengatur tampilan (dark mode), preferensi, akses halaman bantuan, serta logout.
class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  // Status dark mode (true = dark, false = light)
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference(); // Load preferensi tema dari local storage
  }

  /// Memuat status dark mode dari SharedPreferences saat app dibuka
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool('isDarkMode') ?? false;

    setState(() {
      _isDarkMode = darkMode;
    });

    // Notifikasi tema global diubah berdasarkan preferensi
    themeNotifier.value = darkMode ? ThemeMode.dark : ThemeMode.light;
  }

  /// Menyimpan perubahan dark mode ke SharedPreferences dan update tampilan
  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);

    setState(() {
      _isDarkMode = value;
    });

    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;

    // Feedback perubahan mode ke pengguna
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? "Dark Mode Aktif" : "Light Mode Aktif"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Fungsi logout akun dari Firebase dan kembali ke halaman login
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          'Settings',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),

      // Isi halaman ditampilkan dalam ListView agar scrollable
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // === Bagian Tampilan ===
          _buildSectionTitle("Tampilan"),
          _buildSwitchTile(
            icon: Icons.dark_mode,
            title: "Dark Mode",
            value: _isDarkMode,
            onChanged: _toggleTheme,
          ),
          const Divider(height: 1),

          // === Bagian Preferensi ===
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

          // === Bantuan dan Dukungan ===
          _buildSectionTitle("Bantuan & Dukungan"),
          _buildNavigationTile(
            icon: Icons.help_outline,
            title: "Bantuan",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpPage()),
              );
            },
          ),

          // === Tentang Aplikasi ===
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

          const SizedBox(height: 30),

          // === Logout ===
          _buildNavigationTile(
            icon: Icons.logout,
            title: "Log Out",
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan judul bagian (section)
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

  /// Widget untuk switch pengaturan, seperti Dark Mode
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

  /// Widget untuk menampilkan opsi navigasi seperti Bantuan, Notifikasi, dsb.
  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
