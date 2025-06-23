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
import 'package:jelajahin_apps/services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _deletePost(Map<String, dynamic> postToDelete) async {
    final String postId = postToDelete['id'] ?? '';
    final String postName = postToDelete['title'] ?? 'postingan ini';
    if (postId.isEmpty) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Postingan?'),
        content: Text('Apakah Anda yakin ingin menghapus "$postName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteDestination(postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Postingan "$postName" berhasil dihapus.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus postingan: $e')),
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
        title: const Text('Profil', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
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
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!authSnapshot.hasData || authSnapshot.data == null) {
            return _buildLoginPrompt(context);
          }
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
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (userSnapshot.hasError) {
          return Center(child: Text('Error: ${userSnapshot.error}', style: TextStyle(color: Colors.red)));
        }
        if (!userSnapshot.data!.exists) {
          return const Center(child: Text("Profil pengguna tidak ditemukan.", style: TextStyle(color: Colors.grey)));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final String userName = userData['name'] ?? 'Jelajahin Pengguna';
        final String profilePictureUrl = userData['profile_picture_url'] ?? '';

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.getUserPostsStream(),
          builder: (context, postsSnapshot) {
            if (postsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (postsSnapshot.hasError) {
              return Center(child: Text("Gagal memuat postingan: ${postsSnapshot.error}", style: TextStyle(color: Colors.red)));
            }

            final posts = postsSnapshot.data ?? [];

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                List<Widget> slivers = [
                  SliverToBoxAdapter(
                    child: _buildProfileHeader(context, userName, profilePictureUrl, userData),
                  ),
                ];

                if (posts.isNotEmpty) {
                  slivers.add(
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24.0, 20.0, 16.0, 10.0),
                        child: Text(
                          'Postingan Anda',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return slivers;
              },
              body: posts.isEmpty
                  ? _buildNoPostsYet(context)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          onEdit: () {
                            final String destinationId = postData['id'] ?? '';
                            if (destinationId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditDestinationPage(destinationId: destinationId),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Tidak dapat mengedit postingan: ID tidak ditemukan.')),
                              );
                            }
                          },
                        );
                      },
                    ),
            );
          },
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
                backgroundImage: profilePictureUrl.isNotEmpty
                    ? CachedNetworkImageProvider(profilePictureUrl)
                    : null,
                child: profilePictureUrl.isEmpty
                    ? Icon(Icons.person, size: 40, color: AppColors.darkTeal)
                    : null,
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
                            'Edit Profil',
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
        ],
      ),
    );
  }

  Widget _buildNoPostsYet(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Yuk, Bagikan Destinasimu!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada destinasi yang Anda posting. Tambahkan postingan pertama Anda dan mulailah berbagi petualangan!',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined, size: 80, color: AppColors.lightGrey),
            const SizedBox(height: 20),
            const Text(
              'Akses Profil',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Login untuk mengakses profil Anda dan melihat postingan Anda.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
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
                elevation: 5,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Login', style: TextStyle(fontSize: 16, color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }
}