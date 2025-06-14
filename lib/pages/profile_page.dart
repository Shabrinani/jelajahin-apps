import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jelajahin_apps/pages/destination_detail_page.dart';
import '../theme/colors.dart';
import 'package:jelajahin_apps/pages/login.dart';
import 'package:jelajahin_apps/pages/edit_profile.dart';
import 'package:jelajahin_apps/pages/settings.dart';
import 'package:jelajahin_apps/widgets/post_card.dart'; // Import PostCard yang baru

import 'dart:developer' as developer;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _currentUser;
  String? _selectedAvatarUrl;
  String _userName = 'Pengguna Jelajahin';

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

  final List<Map<String, dynamic>> _dummyPosts = [
    {
      "id": "post_dummy_1",
      "name": "Pantai Kuta",
      "location": "Kuta, Bali",
      "description": "Pantai yang terkenal dengan ombaknya yang bagus untuk berselancar. Cocok untuk semua level peselancar.",
      "image": "https://picsum.photos/seed/kuta/400/250",
      "lat": -8.728056,
      "lng": 115.172778,
      "rating": 4.5,
      "tags": ["pantai", "selancar", "matahari terbenam"],
      "createdAt": "2024-06-14T10:00:00Z",
      "userId": "dummy_user_id_1",
      "reviews": 120,
      "commentsCount": 35
    },
    {
      "id": "post_dummy_2",
      "name": "Candi Borobudur",
      "location": "Magelang, Jawa Tengah",
      "description": "Candi Buddha terbesar di dunia, Situs Warisan Dunia UNESCO dengan keindahan arsitektur dan sejarah yang kaya.",
      "image": "https://picsum.photos/seed/borobudur/400/250",
      "lat": -7.607778,
      "lng": 110.203889,
      "rating": 4.8,
      "tags": ["candi", "sejarah", "budaya", "warisan"],
      "createdAt": "2024-06-13T14:30:00Z",
      "userId": "dummy_user_id_1",
      "reviews": 250,
      "commentsCount": 78
    },
    {
      "id": "post_dummy_3",
      "name": "Gunung Bromo",
      "location": "Probolinggo, Jawa Timur",
      "description": "Gunung berapi aktif dengan pemandangan matahari terbit yang menakjubkan dari puncaknya.",
      "image": "https://picsum.photos/seed/bromo/400/250",
      "lat": -7.941667,
      "lng": 112.953056,
      "rating": 4.7,
      "tags": ["gunung", "alam", "pemandangan", "mendaki"],
      "createdAt": "2024-06-12T09:15:00Z",
      "userId": "dummy_user_id_2",
      "reviews": 180,
      "commentsCount": 62
    },
     {
      "id": "post_dummy_4",
      "name": "Danau Toba",
      "location": "Sumatera Utara",
      "description": "Danau vulkanik terbesar di dunia, dengan pulau Samosir di tengahnya.",
      "image": "https://picsum.photos/seed/toba/400/250",
      "lat": 2.650000,
      "lng": 98.666667,
      "rating": 4.6,
      "tags": ["danau", "alam", "pulau", "vulkanik"],
      "createdAt": "2024-06-11T11:00:00Z",
      "userId": "dummy_user_id_1",
      "reviews": 95,
      "commentsCount": 21
    },
    {
      "id": "post_dummy_5",
      "name": "Raja Ampat",
      "location": "Papua Barat Daya",
      "description": "Gugusan pulau-pulau indah dengan keanekaragaman hayati laut yang luar biasa.",
      "image": "https://picsum.photos/seed/rajaampat/400/250",
      "lat": 0.350000,
      "lng": 130.666667,
      "rating": 4.9,
      "tags": ["pulau", "laut", "snorkeling", "diving"],
      "createdAt": "2024-06-10T16:45:00Z",
      "userId": "dummy_user_id_1",
      "reviews": 310,
      "commentsCount": 110
    }
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadProfileData();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _userName = _currentUser?.displayName ?? 'Pengguna Jelajahin';
        });
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
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _selectedAvatarUrl = userDoc.get('avatarUrl') as String?;
          _userName = userDoc.get('name') as String? ?? _currentUser?.displayName ?? 'Pengguna Jelajahin';
          developer.log('Profile: Avatar URL loaded from Firestore: $_selectedAvatarUrl');

          if (_selectedAvatarUrl == null || _selectedAvatarUrl!.isEmpty) {
            developer.log('Profile: avatarUrl from Firestore is null or empty, using default first avatar.');
            _selectedAvatarUrl = _availableAvatars.first;
          } else {
            if (!_availableAvatars.contains(_selectedAvatarUrl)) {
              developer.log('Profile: WARNING: Loaded avatar URL "$_selectedAvatarUrl" is not in _availableAvatars list. Using default.');
              _selectedAvatarUrl = _availableAvatars.first;
            }
          }
          developer.log('Profile: Final _selectedAvatarUrl after loading: $_selectedAvatarUrl');
        });
      } else {
        developer.log('Profile: User document does not exist for UID: ${_currentUser!.uid}. Setting default avatar.');
        setState(() {
          _selectedAvatarUrl = _availableAvatars.first;
          _userName = _currentUser?.displayName ?? 'Pengguna Jelajahin';
        });
      }
    } catch (e, stackTrace) {
      developer.log("Profile: ERROR: Failed to load profile data from Firestore: $e", error: e, stackTrace: stackTrace);
      setState(() {
        _selectedAvatarUrl = _availableAvatars.first;
        _userName = _currentUser?.displayName ?? 'Pengguna Jelajahin';
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

  void _deleteDummyPost(Map<String, dynamic> postToDelete) {
    setState(() {
      _dummyPosts.removeWhere((post) => post['id'] == postToDelete['id']);
      developer.log('Dummy post deleted: ${postToDelete['name']}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Postingan "${postToDelete['name']}" berhasil dihapus secara lokal.')),
      );
    });
    // --- INTEGRASI DATABASE (contoh) ---
    /*
    if (postToDelete.containsKey('id')) {
      FirebaseFirestore.instance.collection('destinations').doc(postToDelete['id']).delete()
        .then((_) {
          developer.log('Post deleted from Firestore: ${postToDelete['id']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Postingan "${postToDelete['name']}" berhasil dihapus.')),
          );
        }).catchError((error) {
          developer.log('Failed to delete post from Firestore: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus postingan: $error')),
          );
        });
    }
    */
    // --- AKHIR INTEGRASI DATABASE ---
  }


  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    ImageProvider? currentProfileAvatarImage;
    if (_selectedAvatarUrl != null) {
      currentProfileAvatarImage = AssetImage(_selectedAvatarUrl!);
    } else {
      currentProfileAvatarImage = AssetImage(_availableAvatars.first);
    }

    final String? currentUserId = _currentUser?.uid;

    List<Map<String, dynamic>> postsToShow = [];
    if (currentUserId != null) {
        postsToShow = _dummyPosts.where((post) => post['userId'] == "dummy_user_id_1").toList();
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.lightTeal.withOpacity(0.2),
                        backgroundImage: currentProfileAvatarImage,
                        child: currentProfileAvatarImage == null
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
                              _userName,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const EditProfilePage()),
                                );
                                _loadProfileData();
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
                ],
              ),
            ),
            
            // const Divider(height: 1, thickness: 1, color: AppColors.grey),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'Posts',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            
            const Divider(height: 1, thickness: 1, color: AppColors.grey),
            const SizedBox(height: 10),

            if (currentUserId == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Anda perlu login untuk melihat postingan Anda.',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(color: AppColors.grey),
                  ),
                ),
              )
            else if (postsToShow.isEmpty)
               Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Anda belum memiliki postingan (dummy data disaring atau kosong).',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(color: AppColors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: postsToShow.length,
                itemBuilder: (context, index) {
                  final postData = postsToShow[index];
                  return PostCard(
                    postData: postData,
                    ownerName: _userName, // Untuk post user sendiri, nama owner adalah nama user ini
                    ownerAvatar: _selectedAvatarUrl ?? _availableAvatars.first, // Avatar owner adalah avatar user ini
                    onDelete: _deleteDummyPost,
                    onTap: () { // <-- Tambahkan onTap untuk navigasi
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DestinationDetailPage(destination: postData),
                        ),
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