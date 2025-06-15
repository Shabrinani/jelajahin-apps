import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jelajahin_apps/pages/destination_detail_page.dart'; // Sesuaikan path
import 'package:jelajahin_apps/theme/colors.dart'; // Sesuaikan path
import 'package:jelajahin_apps/pages/login.dart'; // Sesuaikan path
import 'package:jelajahin_apps/pages/edit_profile.dart'; // Sesuaikan path
import 'package:jelajahin_apps/pages/settings.dart'; // Sesuaikan path
import 'package:jelajahin_apps/widgets/post_card.dart'; // Sesuaikan path

import 'dart:developer' as developer;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream untuk mendengarkan perubahan data profil pengguna secara real-time
  Stream<DocumentSnapshot>? _userProfileStream;
  Stream<List<Map<String, dynamic>>>? _userPostsStream;

  // Daftar avatar lokal (jika Anda ingin pilihan avatar default)
  final List<String> _availableLocalAvatars = [
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
    _initializeStreams();
    // Mendengarkan perubahan autentikasi untuk mengatur ulang stream
    _auth.authStateChanges().listen((user) {
      if (mounted) {
        developer.log('ProfilePage: Auth state changed. New user: ${user?.uid}');
        _initializeStreams(); // Setel ulang stream saat status auth berubah
      }
    });
  }

  // Fungsi untuk menginisialisasi stream data profil dan postingan
  void _initializeStreams() {
    final user = _auth.currentUser;
    if (user != null) {
      // Stream untuk data profil pengguna
      _userProfileStream = _firestore.collection('users').doc(user.uid).snapshots();
      developer.log('ProfilePage: User profile stream initialized for UID: ${user.uid}');

      // Stream untuk postingan pengguna
      _userPostsStream = _firestore
          .collection('destinations') // Pastikan nama koleksi postingan Anda benar
          .where('userId', isEqualTo: user.uid) // Filter berdasarkan UID pengguna yang login
          .orderBy('createdAt', descending: true) // Urutkan berdasarkan waktu pembuatan (terbaru duluan)
          .snapshots()
          .map((snapshot) {
            developer.log('ProfilePage: User posts stream has ${snapshot.docs.length} documents.');
            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id, // Selalu sertakan ID dokumen
                ...data,
              };
            }).toList();
          });
    } else {
      setState(() {
        _userProfileStream = null;
        _userPostsStream = null;
      });
      developer.log('ProfilePage: No user logged in, profile and posts streams set to null.');
    }
  }

  // Fungsi untuk logout
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
      developer.log('ProfilePage: User logged out successfully.');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal logout: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
      developer.log("ProfilePage: ERROR: Failed to logout: $e");
    }
  }

  // Fungsi untuk menghapus postingan dari Firestore
  Future<void> _deletePost(Map<String, dynamic> postToDelete) async {
    if (!postToDelete.containsKey('id')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID postingan tidak ditemukan.')),
      );
      developer.log('ProfilePage: ERROR: Attempted to delete post without an ID.');
      return;
    }

    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Postingan'),
        content: Text('Apakah Anda yakin ingin menghapus postingan "${postToDelete['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await _firestore.collection('destinations').doc(postToDelete['id']).delete();
        developer.log('ProfilePage: Post deleted from Firestore: ${postToDelete['id']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Postingan "${postToDelete['name']}" berhasil dihapus.')),
          );
        }
      } catch (e, stackTrace) {
        developer.log('ProfilePage: ERROR: Failed to delete post from Firestore: $e', error: e, stackTrace: stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus postingan: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final User? currentUser = _auth.currentUser;

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
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.primaryDark, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingPage()),
              );
            },
          ),
        ],
      ),
      body: currentUser == null
          ? _buildLoginPrompt(textTheme) // Tampilkan prompt login jika tidak ada user
          : StreamBuilder<DocumentSnapshot>(
              stream: _userProfileStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  developer.log("ProfilePage: User profile stream ERROR: ${snapshot.error}", error: snapshot.error, stackTrace: snapshot.stackTrace);
                  return Center(
                    child: Text(
                      'Gagal memuat profil: ${snapshot.error}',
                      style: textTheme.bodyLarge?.copyWith(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  // Ini bisa terjadi jika dokumen pengguna belum ada di Firestore
                  // Mungkin perlu membuat dokumen pengguna saat pendaftaran
                  developer.log('ProfilePage: User document not found for UID: ${currentUser.uid}');
                  // Fallback ke data default atau user displayName
                  final String userName = currentUser.displayName ?? 'Pengguna Jelajahin';
                  final String profilePictureUrl = _availableLocalAvatars.first;

                  return _buildProfileContent(
                    context,
                    textTheme,
                    userName,
                    profilePictureUrl,
                    _userPostsStream,
                    _deletePost,
                    _availableLocalAvatars.first, // Default avatar untuk PostCard
                  );
                }

                // Data profil berhasil dimuat
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final String userName = userData['name'] as String? ?? currentUser.displayName ?? 'Pengguna Jelajahin';
                String profilePictureUrl = userData['profile_picture_url'] as String? ?? _availableLocalAvatars.first;

                // Handle jika profilePictureUrl kosong atau tidak valid
                if (profilePictureUrl.isEmpty) {
                  profilePictureUrl = _availableLocalAvatars.first;
                } else if (!profilePictureUrl.startsWith('assets/') && !profilePictureUrl.startsWith('http')) {
                  // Jika bukan asset lokal atau URL, fallback ke default
                  profilePictureUrl = _availableLocalAvatars.first;
                }

                developer.log('ProfilePage: Displaying profile for $userName with URL: $profilePictureUrl');

                return _buildProfileContent(
                  context,
                  textTheme,
                  userName,
                  profilePictureUrl,
                  _userPostsStream,
                  _deletePost,
                  _availableLocalAvatars.first, // Default avatar untuk PostCard fallback
                );
              },
            ),
    );
  }

  // Widget terpisah untuk menampilkan prompt login
  Widget _buildLoginPrompt(TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Anda perlu login untuk melihat atau membuat postingan.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Login Sekarang',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget terpisah untuk konten profil (header dan daftar postingan)
  Widget _buildProfileContent(
    BuildContext context,
    TextTheme textTheme,
    String userName,
    String profilePictureUrl,
    Stream<List<Map<String, dynamic>>>? userPostsStream,
    Function(Map<String, dynamic>) onDeletePost,
    String defaultLocalAvatar,
  ) {
    ImageProvider profileImage;
    if (profilePictureUrl.startsWith('assets/')) {
      profileImage = AssetImage(profilePictureUrl);
    } else if (profilePictureUrl.startsWith('http')) {
      profileImage = NetworkImage(profilePictureUrl);
    } else {
      profileImage = AssetImage(defaultLocalAvatar);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Karena kita menggunakan StreamBuilder, cukup panggil _initializeStreams
        // untuk memicu pembaruan stream jika diperlukan, atau StreamBuilder akan otomatis update.
        // Namun, jika ada cache yang kuat, ini bisa membantu.
        _initializeStreams();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.lightTeal.withOpacity(0.2),
                    backgroundImage: profileImage,
                    onBackgroundImageError: (exception, stackTrace) {
                      developer.log('ProfilePage: Error loading profile image for CircleAvatar: $exception');
                      // Fallback visual jika gambar gagal dimuat
                    },
                    child: (profilePictureUrl.isEmpty || (!profilePictureUrl.startsWith('assets/') && !profilePictureUrl.startsWith('http')))
                        ? Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.darkTeal,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            // Saat kembali dari EditProfilePage, kita tidak perlu
                            // memuat ulang data secara manual karena StreamBuilder
                            // akan secara otomatis mendeteksi perubahan.
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EditProfilePage()),
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                'Edit Profile',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.edit, size: 16, color: AppColors.primaryDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: AppColors.grey),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'My Posts',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ),

            const Divider(height: 1, thickness: 1, color: AppColors.grey),
            const SizedBox(height: 10),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: userPostsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  developer.log("ProfilePage: User posts stream ERROR: ${snapshot.error}");
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Gagal memuat postingan: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(color: Colors.red),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Anda belum memiliki postingan.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(color: AppColors.grey),
                      ),
                    ),
                  );
                }

                final List<Map<String, dynamic>> posts = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final postData = posts[index];
                    return PostCard(
                      postData: postData,
                      ownerName: userName, // Nama owner dari data profil real-time
                      ownerAvatar: profilePictureUrl, // Avatar owner dari data profil real-time
                      onDelete: onDeletePost,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DestinationDetailPage(destination: postData),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}