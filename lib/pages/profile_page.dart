// ignore_for_file: prefer_const_constructors, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jelajahin_apps/pages/destination_detail_page.dart';
import 'package:jelajahin_apps/pages/edit_destination_page.dart';
import 'package:jelajahin_apps/theme/colors.dart';
import 'package:jelajahin_apps/pages/login.dart';
import 'package:jelajahin_apps/pages/edit_profile.dart';
import 'package:jelajahin_apps/pages/settings.dart';
import 'package:jelajahin_apps/widgets/post_card.dart';
import 'package:jelajahin_apps/services/firestore_service.dart'; // <-- Import service
// import 'dart:developer' as developer;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Fungsi untuk menghapus postingan
  Future<void> _deletePost(Map<String, dynamic> postToDelete) async {
    final String postId = postToDelete['id'] ?? '';
    final String postName = postToDelete['title'] ?? 'postingan ini';
    if (postId.isEmpty) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Are you sure you want to delete "$postName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteDestination(postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('The post "$postName" has been deleted.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete the post: $e')),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.primaryDark, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingPage()));
            },
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!authSnapshot.hasData || authSnapshot.data == null) {
            return _buildLoginPrompt(context);
          }
          // Jika user sudah login, bangun UI profil
          return _buildProfileView();
        },
      ),
    );
  }

  Widget _buildProfileView() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.getUserStream(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userSnapshot.hasError) {
          return Center(child: Text('Error: ${userSnapshot.error}'));
        }
        if (!userSnapshot.data!.exists) {
          return const Center(child: Text("User profile not found."));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final String userName = userData['name'] ?? 'Jelajahin Users';
        final String profilePictureUrl = userData['profile_picture_url'] ?? '';

        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildProfileHeader(context, userName, profilePictureUrl, userData),
              ),
            ];
          },
          body: _buildUserPostsList(userName, profilePictureUrl),
        );
      },
    );
  }
  
  Widget _buildProfileHeader(BuildContext context, String userName, String profilePictureUrl, Map<String, dynamic> userData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.lightTeal.withOpacity(0.2),
                backgroundImage: profilePictureUrl.isNotEmpty ? NetworkImage(profilePictureUrl) : null,
                child: profilePictureUrl.isEmpty ? Icon(Icons.person, size: 40, color: AppColors.darkTeal) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 4),
                     GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage()));
                      },
                      child: Row(
                        children: [
                          Text(
                            'Edit Profile',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.primaryDark),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, size: 16, color: AppColors.primaryDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: AppColors.grey),
        ],
      ),
    );
  }
  
  Widget _buildUserPostsList(String userName, String profilePictureUrl) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getUserPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Failed to load the post: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No posts yet. Create your first post!"));
        }
        
        final posts = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final postData = posts[index];
            return PostCard(
              postData: postData,
              ownerName: userName,
              ownerAvatar: profilePictureUrl,
              onDelete: () => _deletePost(postData),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DestinationDetailPage(destination: postData)),
                );
              },
              // --- INI BARIS KUNCI YANG PERLU ANDA TAMBAHKAN ---
              // Solusi Cepat: Pastikan Anda mengirim 'destination: postData'
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DestinationDetailPage(destination: postData),
                  ),
                );
              },
              // ----------------------------------------------------
            );
          },
        );
      },
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Profile Access',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Log in to access your profile and see your posts.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Login', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
