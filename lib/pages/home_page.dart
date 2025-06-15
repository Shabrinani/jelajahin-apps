import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jelajahin_apps/theme/colors.dart';
import 'package:jelajahin_apps/pages/search_screen.dart';
import 'package:jelajahin_apps/pages/destination_detail_page.dart';
import 'package:jelajahin_apps/widgets/post_card.dart'; // Pastikan path ini benar
import 'dart:developer' as developer; // Untuk logging

class HomeContentPage extends StatefulWidget {
  const HomeContentPage({super.key});

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  User? _currentUser;
  Stream<List<Map<String, dynamic>>>? _allPostsStream; // Stream untuk semua postingan

  // Data kategori (opsional, jika Anda ingin mengaktifkannya kembali nanti)
  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Restaurants',
      'icon': Icons.restaurant,
      'color': AppColors.lightTeal,
    },
    {
      'name': 'Chain Sets',
      'icon': Icons.local_cafe,
      'color': AppColors.darkBrown,
    },
    {
      'name': 'Cafes',
      'icon': Icons.coffee,
      'color': AppColors.lightBrown,
    },
    {
      'name': 'Attractions',
      'icon': Icons.attractions,
      'color': AppColors.darkTeal,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Mendapatkan user saat ini saat inisialisasi
    _currentUser = FirebaseAuth.instance.currentUser;
    // Setup stream untuk fetching postingan
    _setupAllPostsStream();

    // Mendengarkan perubahan status autentikasi
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) { // Pastikan widget masih ada di tree
        setState(() {
          _currentUser = user;
        });
        _setupAllPostsStream(); // Muat ulang stream jika status auth berubah (misal: user login/logout)
      }
    });
  }

  // Fungsi untuk menyiapkan stream semua postingan dari Firestore
  void _setupAllPostsStream() {
    developer.log('Home: Setting up all posts stream...');
    _allPostsStream = FirebaseFirestore.instance
        .collection('destinations')
        // Urutkan berdasarkan waktu pembuatan terbaru
        // Pastikan field 'createdAt' ada di dokumen destinasi Anda dengan FieldValue.serverTimestamp()
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'id': doc.id, // Pastikan ID dokumen disertakan
                ...data,
                // Ambil ownerName dan ownerAvatar dari data dokumen
                // Gunakan fallback 'Anonim' dan placeholder jika tidak ada
                'ownerName': data['ownerName'] ?? 'Anonim',
                'ownerAvatar': data['ownerAvatar'] ?? 'https://via.placeholder.com/50',
              };
            }).toList());
    developer.log('Home: All posts stream setup complete.');
  }

  // Fungsi untuk mendapatkan sapaan berdasarkan waktu
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(textTheme),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 24),
              // _buildCategoriesSection(textTheme), // Uncomment jika ingin pakai kategori
              // const SizedBox(height: 24),
              _buildRecentPostsSection(textTheme),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.waving_hand,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  // Menampilkan displayName dari user, atau 'Guest' jika belum login
                  'Halo, ${_currentUser?.displayName ?? 'Guest'}',
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _getGreeting(),
              style: textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.lightTeal.withOpacity(0.2),
          child: IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: AppColors.darkTeal,
              size: 24,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Discover a city',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Icon(Icons.tune, color: Colors.grey[600], size: 24),
        ],
      ),
    );
  }

  // Bagian untuk menampilkan postingan terbaru dari Firestore
  Widget _buildRecentPostsSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Posts', // Judul untuk semua postingan
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _allPostsStream, // Menggunakan stream dari Firestore
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              developer.log("Home: Error loading posts: ${snapshot.error}");
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
                    'Tidak ada postingan yang tersedia.',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(color: AppColors.grey),
                  ),
                ),
              );
            }

            final List<Map<String, dynamic>> posts = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Penting agar tidak scroll sendiri
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final postData = posts[index];
                return PostCard(
                  postData: postData,
                  // Mengambil ownerName dan ownerAvatar dari data postingan yang sudah diproses di stream
                  // Ini akan menggunakan nilai dari Firestore atau fallback 'Anonim' / placeholder
                  ownerName: postData['ownerName'],
                  ownerAvatar: postData['ownerAvatar'],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DestinationDetailPage(destination: postData),
                      ),
                    );
                  },
                  // onDelete TIDAK perlu diteruskan di sini jika PostCard ini hanya untuk tampilan
                  // dan bukan untuk user yang bisa menghapus postingan orang lain di Home.
                  // onDelete: _deletePost, // Hapus atau komen baris ini jika tidak relevan
                );
              },
            );
          },
        ),
      ],
    );
  }
}