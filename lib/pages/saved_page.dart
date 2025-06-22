import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jelajahin_apps/services/firestore_service.dart';
import 'package:jelajahin_apps/theme/colors.dart';
import 'package:jelajahin_apps/widgets/post_card.dart';
import 'package:jelajahin_apps/pages/destination_detail_page.dart';
import 'package:jelajahin_apps/pages/login.dart'; // Untuk tombol login
import 'dart:developer' as developer;

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Posts',
          style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: AppColors.white,
      body: _currentUser == null
          ? _buildLoginPrompt(context)
          : _buildSavedPostsList(),
    );
  }

  // Widget yang ditampilkan jika user belum login
  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Simpan Destinasi Favoritmu',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Login untuk melihat postingan yang telah Anda simpan.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
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

  // Widget untuk menampilkan daftar postingan yang disimpan
  Widget _buildSavedPostsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getSavedDestinationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          developer.log("SavedPage: Error loading posts: ${snapshot.error}");
          return Center(child: Text('Gagal memuat postingan: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Anda belum menyimpan postingan apapun.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final List<Map<String, dynamic>> posts = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final postData = posts[index];
            return PostCard(
              postData: postData,
              ownerName: postData['ownerName'] ?? 'Anonim',
              ownerAvatar: postData['ownerAvatar'] ?? 'https://via.placeholder.com/50',
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
    );
  }
}
