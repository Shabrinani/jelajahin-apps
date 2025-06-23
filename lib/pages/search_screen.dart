import 'package:flutter/material.dart';
import 'package:jelajahin_apps/main.dart';
import 'package:jelajahin_apps/pages/destination_detail_page.dart';
import 'package:jelajahin_apps/widgets/post_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false; 

  // Master list of all searchable posts (dummy data)
  final List<Map<String, dynamic>> _allSearchablePosts = [
    {
      "id": "search_post_1",
      "name": "Pantai Indah",
      "location": "Bali, Indonesia",
      "description": "Pantai dengan pasir putih dan air jernih.",
      "image": "https://picsum.photos/seed/searchbeach1/400/250",
      "reviews": 120, "commentsCount": 35,
      "ownerName": "Wisatawan A", "ownerAvatar": "https://picsum.photos/seed/ava1/50/50"
    },
    {
      "id": "search_post_2",
      "name": "Gunung Jayawijaya",
      "location": "Papua, Indonesia",
      "description": "Puncak tertinggi di Indonesia, tantangan bagi pendaki.",
      "image": "https://picsum.photos/seed/searchmountain1/400/250",
      "reviews": 80, "commentsCount": 20,
      "ownerName": "Pendaki B", "ownerAvatar": "https://picsum.photos/seed/ava2/50/50"
    },
    {
      "id": "search_post_3",
      "name": "Kota Tua Jakarta",
      "location": "Jakarta, Indonesia",
      "description": "Distrik bersejarah dengan arsitektur kolonial Belanda.",
      "image": "https://picsum.photos/seed/searchcity1/400/250",
      "reviews": 200, "commentsCount": 50,
      "ownerName": "Sejarahwan C", "ownerAvatar": "https://picsum.photos/seed/ava3/50/50"
    },
  ];

  List<Map<String, dynamic>> _filteredPosts = [];

  @override
  void initState() {
    super.initState();
    _filteredPosts = _allSearchablePosts;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPosts = _allSearchablePosts;
        isSearching = false;
      } else {
        _filteredPosts = _allSearchablePosts.where((post) {
          final postName = (post['name'] as String).toLowerCase();
          return postName.contains(query);
        }).toList();
        isSearching = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(textTheme),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: isSearching ? _buildSearchResults() : _buildSearchHome(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(TextTheme textTheme) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.primaryDark),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Search',
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search destinations, cities, activities...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }

  // Tampilan ketika search bar kosong (hanya Popular Searches)
  Widget _buildSearchHome() {
    final TextTheme textTheme = Theme.of(context).textTheme;
    
    final List<String> popularSearches = [
      'Pantai Sanur',
      'Kota Tua Jakarta',
      'Museum Nasional',
      'Pantai Indah',
      'Restoran Seafood Jaya',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _buildSectionTitle('Browse Categories', textTheme), <-- Dihapus
          // const SizedBox(height: 12), <-- Dihapus
          // _buildCategoriesGrid(), <-- Dihapus
          // const SizedBox(height: 24), <-- Dihapus
          _buildSectionTitle('Popular Searches', textTheme),
          const SizedBox(height: 12),
          _buildPopularSearches(popularSearches),
        ],
      ),
    );
  }

  // Tampilan ketika ada hasil pencarian
  Widget _buildSearchResults() {
    final TextTheme textTheme = Theme.of(context).textTheme;
    
    if (_filteredPosts.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Text(
          'No results found for "${_searchController.text}"',
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${_filteredPosts.length} results found',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredPosts.length,
            itemBuilder: (context, index) {
              final postData = _filteredPosts[index];
              return PostCard(
                postData: postData,
                ownerName: postData['ownerName'] ?? 'Unknown User',
                ownerAvatar: postData['ownerAvatar'] ?? 'https://via.placeholder.com/50',
                onTap: () { // <-- Tambahkan onTap untuk navigasi
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DestinationDetailPage(destination: postData),
                        ),
                      );
                    },
                // onDelete tidak diteruskan, sehingga tombol delete tidak muncul
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, TextTheme textTheme) {
    return Text(
      title,
      style: textTheme.titleLarge?.copyWith(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // _buildCategoriesGrid() tidak lagi digunakan untuk tampilan

  Widget _buildPopularSearches(List<String> popularSearches) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: popularSearches.map((search) {
        return InkWell(
          onTap: () {
            _searchController.text = search;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              search,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}