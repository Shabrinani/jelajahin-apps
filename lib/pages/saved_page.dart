import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jelajahin_apps/services/firestore_service.dart';
import 'package:jelajahin_apps/theme/colors.dart';
import 'package:jelajahin_apps/widgets/post_card.dart';
import 'package:jelajahin_apps/pages/destination_detail_page.dart';
import 'package:jelajahin_apps/pages/login.dart';
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
            const Icon(Icons.bookmark_border, size: 80, color: AppColors.lightGrey),
            const SizedBox(height: 20),
            const Text(
              'Simpan Destinasi Favoritmu',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Login untuk melihat postingan yang telah Anda simpan dan jelajahi berbagai destinasi menarik!',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
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
                elevation: 5,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Login untuk Menjelajahi', style: TextStyle(fontSize: 16, color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Daftar postingan yang disimpan
  Widget _buildSavedPostsList() {
    if (_currentUser == null) {
      return _buildLoginPrompt(context);
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getSavedDestinationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          developer.log("SavedPage: Error loading posts: ${snapshot.error}");
          return Center(child: Text('Gagal memuat postingan: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Tampilan jika tidak ada postingan yang disimpan
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_add_outlined, size: 80, color: AppColors.primary),
                  const SizedBox(height: 20),
                  const Text(
                    'Belum Ada Destinasi Tersimpan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sepertinya Anda belum menambahkan destinasi ke daftar tersimpan. Jelajahi berbagai tempat dan simpan favorit Anda!',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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