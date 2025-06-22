import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jelajahin_apps/pages/destination_detail_page.dart';
import 'package:jelajahin_apps/services/firestore_service.dart';
import 'package:jelajahin_apps/theme/colors.dart';
import 'package:jelajahin_apps/widgets/post_card.dart';
import 'dart:developer' as developer;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Listener untuk memperbarui UI setiap kali teks di search bar berubah
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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
              _buildSearchBar(), // Search bar sekarang fungsional
              const SizedBox(height: 24),
              _buildRecentPostsSection(textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestoreService.getCurrentUserData(),
      builder: (context, snapshot) {
        String displayName = "Guest";
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          displayName = data?['name'] ?? 'Guest';
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.waving_hand, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text('Halo, $displayName', style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    )),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_getGreeting(), style: textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 16,
                )),
              ],
            ),
          ],
        );
      },
    );
  }

  // --- PERUBAHAN UTAMA: Search Bar menjadi TextField Fungsional ---
  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search destination...',
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
        prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 24),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: AppColors.darkTeal, width: 2),
        ),
      ),
    );
  }

  Widget _buildRecentPostsSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Posts', style: textTheme.titleLarge?.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 16),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestoreService.getDestinationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              developer.log("Home: Error loading posts: ${snapshot.error}");
              return Center(child: Text('Gagal memuat postingan: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Tidak ada postingan yang tersedia.'));
            }

            // --- PERUBAHAN UTAMA: Logika Filtering ---
            final allPosts = snapshot.data!;
            final filteredPosts = _searchQuery.isEmpty
                ? allPosts
                : allPosts.where((post) {
                    final title = post['title']?.toString().toLowerCase() ?? '';
                    return title.contains(_searchQuery.toLowerCase());
                  }).toList();

            if (filteredPosts.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Destinasi tidak ditemukan.'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final postData = filteredPosts[index];
                
                return PostCard(
                  postData: postData,
                  ownerName: postData['ownerName'] ?? 'Anonim',
                  ownerAvatar: postData['ownerAvatar'] ?? '',
                  onTap: () {
                    // Sembunyikan keyboard saat navigasi
                    FocusScope.of(context).unfocus(); 
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
    );
  }
}
