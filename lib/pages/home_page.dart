import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jelajahin_apps/main.dart'; // Untuk AppColors
import 'package:jelajahin_apps/pages/search_screen.dart';
import 'package:jelajahin_apps/pages/destination_detail_page.dart'; // Jika masih dibutuhkan
import 'package:jelajahin_apps/pages/top_places_screen.dart'; // Jika masih dibutuhkan
import 'package:jelajahin_apps/widgets/post_card.dart'; // Import PostCard yang baru
import 'dart:developer' as developer;

class HomeContentPage extends StatefulWidget {
  const HomeContentPage({super.key});

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  User? _currentUser;
  
  // _isLoadingDestinations tidak lagi diperlukan karena menggunakan dummy data
  // bool _isLoadingDestinations = false; 

  // Categories (ini tetap statis atau bisa juga diambil dari Firestore jika ada koleksi kategori)
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

  // --- DATA DUMMY UNTUK POSTINGAN USER LAIN ---
  final List<Map<String, dynamic>> _otherUsersPosts = [
    {
      "id": "post_home_1",
      "name": "Floating Market Lembang",
      "location": "Lembang, Jawa Barat",
      "description": "Pasar terapung unik dengan berbagai kuliner dan wahana air. Pengalaman yang menyenangkan untuk keluarga.",
      "image": "https://picsum.photos/seed/floatingmarket/400/250",
      "lat": -6.8181,
      "lng": 107.6166,
      "rating": 4.2,
      "tags": ["pasar", "kuliner", "keluarga"],
      "createdAt": "2024-06-15T09:00:00Z",
      "userId": "other_user_id_A",
      "ownerName": "Traveler Sejati",
      "ownerAvatar": "https://picsum.photos/seed/avatar1/50/50",
      "reviews": 85,
      "commentsCount": 15
    },
    {
      "id": "post_home_2",
      "name": "Kebun Raya Bogor",
      "location": "Bogor, Jawa Barat",
      "description": "Area hijau luas yang ideal untuk bersantai dan belajar tentang berbagai jenis tumbuhan. Sangat sejuk dan menenangkan.",
      "image": "https://picsum.photos/seed/kebunraya/400/250",
      "lat": -6.5980,
      "lng": 106.7997,
      "rating": 4.4,
      "tags": ["taman", "alam", "edukasi", "sejuk"],
      "createdAt": "2024-06-14T18:00:00Z",
      "userId": "other_user_id_B",
      "ownerName": "Pecinta Alam",
      "ownerAvatar": "https://picsum.photos/seed/avatar2/50/50",
      "reviews": 150,
      "commentsCount": 40
    },
    {
      "id": "post_home_3",
      "name": "Taman Safari Indonesia",
      "location": "Bogor, Jawa Barat",
      "description": "Berinteraksi langsung dengan satwa liar dari berbagai benua dalam suasana yang alami dan terawat. Cocok untuk semua usia.",
      "image": "https://picsum.photos/seed/tamansafari/400/250",
      "lat": -6.7020,
      "lng": 106.9020,
      "rating": 4.6,
      "tags": ["hewan", "safari", "keluarga", "edukasi"],
      "createdAt": "2024-06-13T11:30:00Z",
      "userId": "other_user_id_C",
      "ownerName": "Safari Mania",
      "ownerAvatar": "https://picsum.photos/seed/avatar3/50/50",
      "reviews": 210,
      "commentsCount": 65
    },
    {
      "id": "post_home_4",
      "name": "Museum Angkut",
      "location": "Batu, Jawa Timur",
      "description": "Museum transportasi modern dengan koleksi kendaraan dari berbagai era dan negara. Banyak spot foto instagramable!",
      "image": "https://picsum.photos/seed/museumangkut/400/250",
      "lat": -7.8812,
      "lng": 112.5221,
      "rating": 4.5,
      "tags": ["museum", "transportasi", "sejarah", "foto"],
      "createdAt": "2024-06-12T15:00:00Z",
      "userId": "other_user_id_D",
      "ownerName": "Explore Mania",
      "ownerAvatar": "https://picsum.photos/seed/avatar4/50/50",
      "reviews": 190,
      "commentsCount": 50
    },
  ];
  // --- AKHIR DATA DUMMY ---

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

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
              // _buildCategoriesSection(textTheme),
              const SizedBox(height: 24),
              // --- Bagian Postingan dari User Lain (Dummy) ---
              _buildOtherUsersPostsSection(textTheme),
              // --- AKHIR Bagian Postingan User Lain ---
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

  // Widget _buildCategoriesSection(TextTheme textTheme) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             'Categories',
  //             style: textTheme.titleLarge?.copyWith(
  //               color: AppColors.primaryDark,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (context) => const TopPlacesScreen()),
  //               );
  //             },
  //             child: Text(
  //               'Show all',
  //               style: TextStyle(color: AppColors.lightTeal),
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 16),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: categories.map((category) => _buildCategoryItem(category)).toList(),
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildCategoryItem(Map<String, dynamic> category) {
  //   return Column(
  //     children: [
  //       Container(
  //         width: 64,
  //         height: 64,
  //         decoration: BoxDecoration(
  //           color: category['color'].withOpacity(0.1),
  //           borderRadius: BorderRadius.circular(16),
  //         ),
  //         child: Icon(
  //           category['icon'],
  //           color: category['color'],
  //           size: 32,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       Text(
  //         category['name'],
  //         style: TextStyle(
  //           color: AppColors.primaryDark,
  //           fontSize: 12,
  //           fontWeight: FontWeight.w500,
  //         ),
  //         textAlign: TextAlign.center,
  //       ),
  //     ],
  //   );
  // }

  // --- Bagian Baru: Postingan dari User Lain (menggunakan dummy data) ---
  Widget _buildOtherUsersPostsSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Posts', // Anda bisa ganti judul ini sesuai kebutuhan
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Langsung tampilkan ListView.builder atau pesan "tidak ada postingan"
        _otherUsersPosts.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Tidak ada postingan baru ditemukan.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _otherUsersPosts.length,
                itemBuilder: (context, index) {
                  final postData = _otherUsersPosts[index];
                  return PostCard(
                    postData: postData,
                    ownerName: postData['ownerName'] ?? 'Anonim', // Mengambil nama pemilik dari dummy data
                    ownerAvatar: postData['ownerAvatar'] ?? 'https://via.placeholder.com/50', // Mengambil avatar pemilik dari dummy data
                    onTap: () { // <-- Tambahkan onTap untuk navigasi
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DestinationDetailPage(destination: postData),
                        ),
                      );
                    },
                    // onDelete TIDAK DITERUSKAN di sini.
                    // Karena onDelete di PostCard bersifat opsional, tidak perlu meneruskannya di sini.
                    // Ini akan membuat tombol 3 titik (opsi delete) tidak muncul di HomeContentPage.
                  );
                },
              ),
      ],
    );
  }
}