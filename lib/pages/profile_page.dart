import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jelajahin_apps/main.dart'; // Import AppColors
import 'package:jelajahin_apps/pages/login.dart'; // Untuk navigasi setelah logout
import 'package:jelajahin_apps/pages/edit_profile.dart'; // Halaman Edit Profil
import 'package:jelajahin_apps/pages/help_page.dart';
import 'package:jelajahin_apps/pages/settings.dart'; 
import 'dart:developer' as developer; // <<< MASIH DIBUTUHKAN UNTUK LOG LAIN

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _currentUser; // Untuk menyimpan data pengguna yang sedang login
  String? _selectedAvatarUrl; // Untuk menyimpan path avatar yang ditampilkan

  final List<String> _availableAvatars = [
    'assets/profile_avatars/avatar1.png',
    'assets/profile_avatars/avatar2.png',
    'assets/profile_avatars/avatar3.png',
    'assets/profile_avatars/avatar4.png',
    'assets/profile_avatars/avatar5.png',
    'assets/profile_avatars/avatar6.png',
    'assets/profile_avatars/avatar7.png',
    'assets/profile_avatars/avatar8.png',
    'assets/profile_avatars/avatar9.png',
    'assets/profile_avatars/avatar10.png',
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadProfileData(); // PANGGIL INI UNTUK MEMUAT AVATAR AWAL
    // Listener untuk update real-time jika nama atau email berubah dari Firebase
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) { // Pastikan widget masih ada sebelum setState
        setState(() {
          _currentUser = user;
        });
        // Jika user berubah atau kembali, coba muat ulang data avatar
        _loadProfileData();
      }
    });
  }

  Future<void> _loadProfileData() async {
    if (_currentUser == null) {
      developer.log('WARNING: _loadProfileData called but _currentUser is null. Aborting load.');
      return;
    }

    try {
      // developer.log('Attempting to load profile data for UID: ${_currentUser!.uid}'); // BAGIAN INI SUDAH DIHAPUS
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        // Data ditemukan di Firestore
        setState(() {
          _selectedAvatarUrl = userDoc.get('avatarUrl') as String?;
          developer.log('Profile: Avatar URL loaded from Firestore: $_selectedAvatarUrl');

          if (_selectedAvatarUrl == null || _selectedAvatarUrl!.isEmpty) {
            developer.log('Profile: avatarUrl from Firestore is null or empty, using default first avatar.');
            _selectedAvatarUrl = _availableAvatars.first;
          } else {
            // Validasi jika URL dari Firestore tidak ada di daftar _availableAvatars
            if (!_availableAvatars.contains(_selectedAvatarUrl)) {
              developer.log('Profile: WARNING: Loaded avatar URL "$_selectedAvatarUrl" is not in _availableAvatars list. Using default.');
              _selectedAvatarUrl = _availableAvatars.first;
            }
          }
          developer.log('Profile: Final _selectedAvatarUrl after loading: $_selectedAvatarUrl');
        });
      } else {
        // Dokumen pengguna tidak ada di Firestore, atur avatar default
        developer.log('Profile: User document does not exist for UID: ${_currentUser!.uid}. Setting default avatar.');
        setState(() {
          _selectedAvatarUrl = _availableAvatars.first; // Atur ke avatar pertama sebagai default
        });
      }
    } catch (e, stackTrace) {
      developer.log("Profile: ERROR: Failed to load profile data from Firestore: $e", error: e, stackTrace: stackTrace);
      // Atur avatar default sebagai fallback bahkan jika ada error loading
      setState(() {
        _selectedAvatarUrl = _availableAvatars.first;
      });
    }
  }

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
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Menentukan gambar avatar yang akan ditampilkan di halaman profil
    ImageProvider? currentProfileAvatarImage;
    if (_selectedAvatarUrl != null) {
      currentProfileAvatarImage = AssetImage(_selectedAvatarUrl!); // GUNAKAN INI
      developer.log('Profile: Current profile avatar being used (from _selectedAvatarUrl): $_selectedAvatarUrl');
    } else if (_currentUser?.photoURL != null) {
      // Ini hanya fallback jika _selectedAvatarUrl null, atau jika Anda ingin menggunakan photoURL dari Firebase Auth
      currentProfileAvatarImage = NetworkImage(_currentUser!.photoURL!);
      developer.log('Profile: Current profile avatar using Firebase Auth photoURL (fallback): ${_currentUser!.photoURL!}');
    } else {
      developer.log('Profile: No specific avatar found, using default person icon.');
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
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
            // Bagian Foto Profil
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.lightTeal.withOpacity(0.2),
                  backgroundImage: currentProfileAvatarImage, // GUNAKAN INI
                  // Tambahkan onImageError jika Flutter SDK Anda mendukungnya
                  // onImageError: (exception, stackTrace) {
                  //   developer.log('Profile: ERROR LOADING MAIN AVATAR: $_selectedAvatarUrl, Exception: $exception', error: exception, stackTrace: stackTrace);
                  // },
                  child: currentProfileAvatarImage == null
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
                    onTap: () async { 
                      await Navigator.push( 
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfilePage()),
                      );
                      
                      _loadProfileData();
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

            // Nama Pengguna
            Text(
              'Halo, ${_currentUser?.displayName ?? ''}',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 5),

            // Opsi Profil
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