import 'package:flutter/material.dart';
import '../main.dart';
import 'destination_detail_page.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  List<Map<String, dynamic>> savedPlaces = [
    {
      'image': 'images/dubai.jpg',
      'name': 'City Hut Family Dhaba',
      'location': 'Shillong',
      'description':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
      'isFavorite': true,
      'latitude': -0.30907000,
      'longitude': 100.37055000
    },
    {
      'image': 'images/dubai.jpg',
      'name': 'Flame Grilled Steakhouse',
      'location': 'Shillong',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
      'isFavorite': true,
      'latitude': -7.2458,
      'longitude': 112.7379
    },
    {
      'image': 'images/dubai.jpg',
      'name': 'Flame Grilled Steakhouse',
      'location': 'Shillong',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
      'isFavorite': true,
      'latitude': -7.2458,
      'longitude': 112.7379
    },
  ];

  late ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 0;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // Only show favorite places
    final favoritePlaces =
        savedPlaces.where((place) => place['isFavorite'] == true).toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: _isScrolled ? AppColors.darkTeal : AppColors.white,
        elevation: 0,
        leading: BackButton(color: _isScrolled ? AppColors.white : AppColors.primaryDark),
        title: Text(
          'Saved',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isScrolled ? Colors.white : AppColors.primaryDark,
              ),
        ),
        centerTitle: true,
      ),
      body: favoritePlaces.isEmpty
          ? Center(
              child: Text(
                "No saved trips yet.",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: favoritePlaces.length,
              itemBuilder: (context, index) {
                final place = favoritePlaces[index];
                return GestureDetector(
                  onTap: () async {
                    final bool? updatedFavorite = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DestinationDetailPage(destination: place),
                      ),
                    );

                    if (updatedFavorite != null) {
                      setState(() {
                        if (!updatedFavorite) {
                          // Remove from saved if unfavorited in detail page
                          savedPlaces.removeWhere(
                              (p) => p['name'] == place['name']);
                        } else {
                          // Keep favorite true
                          final idx = savedPlaces
                              .indexWhere((p) => p['name'] == place['name']);
                          if (idx != -1) {
                            savedPlaces[idx]['isFavorite'] = true;
                          }
                        }
                      });
                    }
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: Image.asset(
                                place['image'],
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    final originalIndex = savedPlaces.indexWhere(
                                        (p) => p['name'] == place['name']);
                                    if (originalIndex != -1) {
                                      bool currentFav =
                                          savedPlaces[originalIndex]['isFavorite'];
                                      if (currentFav) {
                                        // Remove if unfavorited here
                                        savedPlaces.removeAt(originalIndex);
                                      } else {
                                        savedPlaces[originalIndex]['isFavorite'] =
                                            true;
                                      }
                                    }
                                  });
                                },
                                child: Icon(
                                  place['isFavorite']
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: place['isFavorite']
                                      ? Colors.red
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(place['location'],
                                      style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                place['description'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
