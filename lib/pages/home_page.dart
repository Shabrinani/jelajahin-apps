import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:jelajahin_apps/main.dart';
import 'package:jelajahin_apps/pages/search_screen.dart';
import 'package:jelajahin_apps/pages/destination_detail_page.dart';
import 'package:jelajahin_apps/pages/top_places_screen.dart';
import 'dart:developer' as developer; // For logging

class HomeContentPage extends StatefulWidget {
  const HomeContentPage({super.key});

  @override
  State<HomeContentPage> createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  User? _currentUser;
  List<Map<String, dynamic>> _featuredDestinations = [];
  List<Map<String, dynamic>> _popularDestinations = [];
  bool _isLoadingDestinations = true; // State untuk indikator loading

  // Categories (ini tetap statis atau bisa juga diambil dari Firestore jika ada koleksi kategori)
  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Restaurants',
      'icon': Icons.restaurant,
      'color': AppColors.lightTeal,
    },
    {
      'name': 'Chain Sets', // Ini mungkin maksudnya "Coffee Chains" atau sejenisnya?
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
    _currentUser = FirebaseAuth.instance.currentUser;

    // Listen for authentication state changes to update _currentUser
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });

    // Muat data destinasi dari Firestore saat initState
    _loadDestinations();
  }

  // Fungsi untuk memuat destinasi dari Firestore
  Future<void> _loadDestinations() async {
    setState(() {
      _isLoadingDestinations = true; // Set loading state
    });

    try {
      // Query untuk "Most Viewed" (contoh: berdasarkan field 'views' tertinggi)
      QuerySnapshot featuredSnapshot = await FirebaseFirestore.instance
          .collection('destinations')
          .orderBy('views', descending: true) // Asumsi ada field 'views'
          .limit(5) // Ambil 5 destinasi teratas
          .get();

      List<Map<String, dynamic>> loadedFeatured = featuredSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Tambahkan ID dokumen
        return data;
      }).toList();

      // Query untuk "Popular Destinations" (contoh: berdasarkan 'createdAt' terbaru)
      QuerySnapshot popularSnapshot = await FirebaseFirestore.instance
          .collection('destinations')
          .orderBy('createdAt', descending: true) // Asumsi ada field 'createdAt' (Timestamp)
          .limit(5) // Ambil 5 destinasi terbaru
          .get();

      List<Map<String, dynamic>> loadedPopular = popularSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Tambahkan ID dokumen
        return data;
      }).toList();

      setState(() {
        _featuredDestinations = loadedFeatured;
        _popularDestinations = loadedPopular;
      });
      developer.log('Destinations loaded successfully: Featured ${_featuredDestinations.length}, Popular ${_popularDestinations.length}');

    } catch (e, stackTrace) {
      developer.log('Error loading destinations: $e', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load destinations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDestinations = false; // Selesai loading
        });
      }
    }
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
              _buildCategoriesSection(textTheme),
              const SizedBox(height: 24),
              // Tampilkan CircularProgressIndicator jika sedang loading
              _isLoadingDestinations
                  ? Center(child: CircularProgressIndicator(color: AppColors.lightTeal))
                  : Column(
                      children: [
                        _buildFeaturedSection(textTheme),
                        const SizedBox(height: 24),
                        _buildPopularSection(textTheme),
                      ],
                    ),
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

  Widget _buildCategoriesSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TopPlacesScreen()),
                );
              },
              child: Text(
                'Show all',
                style: TextStyle(color: AppColors.lightTeal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: categories.map((category) => _buildCategoryItem(category)).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: category['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            category['icon'],
            color: category['color'],
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          category['name'],
          style: TextStyle(
            color: AppColors.primaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturedSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Most Viewed',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkTeal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Recommended',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Gunakan _featuredDestinations dari Firestore
        SizedBox(
          height: 280,
          child: _featuredDestinations.isEmpty && !_isLoadingDestinations
              ? Center(
                  child: Text(
                    'No featured destinations found.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _featuredDestinations.length,
                  itemBuilder: (context, index) {
                    return _buildFeaturedCard(_featuredDestinations[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> destination) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DestinationDetailPage(destination: destination),
          ),
        );
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Container(
                height: 280,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    // Memeriksa apakah 'image' adalah path lokal atau URL
                    image: (destination['image'] as String).startsWith('http')
                        ? NetworkImage(destination['image']) as ImageProvider
                        : AssetImage(destination['image']) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                height: 280,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: Icon(
                    Icons.favorite_border,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination['name'] ?? 'No Name', // Handle null data
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination['location'] ?? 'Unknown Location', // Handle null data
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${destination['rating'] ?? 0.0}', // Handle null data
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${destination['reviews'] ?? 0} reviews)', // Handle null data
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popular Destinations',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TopPlacesScreen()),
                );
              },
              child: Text(
                'Show all',
                style: TextStyle(color: AppColors.lightTeal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Gunakan _popularDestinations dari Firestore
        _popularDestinations.isEmpty && !_isLoadingDestinations
            ? Center(
                child: Text(
                  'No popular destinations found.',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              )
            : Column(
                children: _popularDestinations.map((destination) => _buildPopularItem(destination)).toList(),
              ),
      ],
    );
  }

  Widget _buildPopularItem(Map<String, dynamic> destination) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DestinationDetailPage(destination: destination),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image( // Use Image widget directly
                // Memeriksa apakah 'image' adalah path lokal atau URL
                image: (destination['image'] as String).startsWith('http')
                    ? NetworkImage(destination['image']) as ImageProvider
                    : AssetImage(destination['image']) as ImageProvider,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination['name'] ?? 'No Name', // Handle null data
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    destination['location'] ?? 'Unknown Location', // Handle null data
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${destination['rating'] ?? 0.0}', // Handle null data
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // Implement favorite/bookmark logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped bookmark for ${destination['name']}')),
                );
              },
              icon: Icon(
                Icons.bookmark_border,
                color: AppColors.lightTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
