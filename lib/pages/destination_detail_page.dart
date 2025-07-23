import 'dart:math' as developer;
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jelajahin_apps/services/firestore_service.dart';
import 'package:jelajahin_apps/theme/colors.dart';
import 'package:jelajahin_apps/widgets/comment_section.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DestinationDetailPage extends StatefulWidget {
  final Map<String, dynamic> destination;
  const DestinationDetailPage({super.key, required this.destination});

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late ScrollController _scrollController;
  bool _isAppBarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    const double collapseThreshold = 200.0;

    if (_scrollController.hasClients) {
      if (_scrollController.offset > collapseThreshold && !_isAppBarCollapsed) {
        setState(() {
          _isAppBarCollapsed = true;
        });
      } else if (_scrollController.offset <= collapseThreshold && _isAppBarCollapsed) {
        setState(() {
          _isAppBarCollapsed = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String destinationId = widget.destination['id'] ?? '';
    if (destinationId.isEmpty) {
      return const Scaffold(body: Center(child: Text("ID Destinasi tidak valid.")));
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getDestinationStream(destinationId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Scaffold(body: Center(child: Text("Destinasi tidak ditemukan.")));
          }

          final destinationData = snapshot.data!.data() as Map<String, dynamic>;

          final List<dynamic>? imageDataList = destinationData['imageData'] as List<dynamic>?;
          Uint8List? imageDataBytes;
          if (imageDataList != null) {
            imageDataBytes = Uint8List.fromList(imageDataList.cast<int>());
          }
          
          final String title = destinationData['title'] ?? 'Judul Tidak Tersedia';
          final String location = destinationData['location'] ?? 'Lokasi Tidak Tersedia';
          final String description = destinationData['description'] ?? 'Deskripsi tidak tersedia.';
          final String ownerName = destinationData['ownerName'] ?? 'Anonim';
          final String ownerAvatar = destinationData['ownerAvatar'] ?? 'https://via.placeholder.com/150';
          final double rating = (destinationData['rating'] as num?)?.toDouble() ?? 0.0;
          final double latitude = (destinationData['latitude'] as num?)?.toDouble() ?? -6.200000;
          final double longitude = (destinationData['longitude'] as num?)?.toDouble() ?? 106.816666;
          final LatLng destinationLatLng = LatLng(latitude, longitude);

          final List likes = destinationData['likes'] ?? [];
          final bool isLiked = _currentUser != null ? likes.contains(_currentUser!.uid) : false;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildEnhancedSliverAppBar(context, title, location, imageDataBytes, destinationId, isLiked, likes.length), // Pass imageDataBytes
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOwnerAndRatingInfo(ownerAvatar, ownerName, rating),
                        const SizedBox(height: 20),

                        _buildSectionHeader('Deskripsi'),
                        Text(
                          description,
                          style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey[800]),
                        ),
                        const SizedBox(height: 20),

                        _buildSectionHeader('Lokasi'),
                        _buildLocationDetail(location, destinationLatLng),

                        const Divider(height: 48, color: AppColors.lightGrey),
                        _buildCommentSection(destinationId),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildEnhancedSliverAppBar(BuildContext context, String title, String location, Uint8List? imageBytes, String destinationId, bool isLiked, int likeCount) {
    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      stretch: true,
      backgroundColor: _isAppBarCollapsed ? AppColors.white : Colors.transparent,
      foregroundColor: _isAppBarCollapsed ? AppColors.primaryDark : Colors.white,
      elevation: _isAppBarCollapsed ? 4.0 : 0.0,
      shadowColor: Colors.black.withOpacity(0.2),

      title: AnimatedOpacity(
        opacity: _isAppBarCollapsed ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          title,
          style: const TextStyle(color: AppColors.primaryDark, fontSize: 20),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      centerTitle: false,
      titleSpacing: 0,

      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded, color: _isAppBarCollapsed ? AppColors.primaryDark : Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isAppBarCollapsed ? (isLiked ? Colors.red : AppColors.primaryDark) : (isLiked ? Colors.red : Colors.white),
              ),
              onPressed: () {
                if (_currentUser != null) {
                  _firestoreService.toggleLike(destinationId, isLiked);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silakan login untuk menyukai postingan ini.")));
                }
              },
            ),
            Text(
              likeCount.toString(),
              style: TextStyle(color: _isAppBarCollapsed ? AppColors.primaryDark : Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
          ],
        ),
        StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.getUserStream(),
          builder: (context, userSnapshot) {
            bool isBookmarked = false;
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              final savedPosts = userData['saved_posts_ids'] as List<dynamic>? ?? [];
              isBookmarked = savedPosts.contains(destinationId);
            }
            return IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _isAppBarCollapsed ? AppColors.primaryDark : Colors.white,
              ),
              onPressed: () {
                if (_currentUser != null) {
                  _firestoreService.toggleBookmark(destinationId, isBookmarked);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silakan login untuk menyimpan postingan ini.")));
                }
              },
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Positioned.fill(
              child: Hero(
                tag: 'post_image_$destinationId',
                child: imageBytes != null && imageBytes.isNotEmpty
                    ? Image.memory(
                        imageBytes,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          developer.log('Error displaying image from bytes: $error' as num);
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 50),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 50),
                      ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
            ),
            if (!_isAppBarCollapsed)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildOwnerAndRatingInfo(String ownerAvatar, String ownerName, double rating) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.lightGrey,
          backgroundImage: CachedNetworkImageProvider(ownerAvatar),
          onBackgroundImageError: (exception, stacktrace) => const Icon(Icons.person, color: Colors.grey, size: 30),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ditambahkan oleh ${ownerName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber[600], size: 20),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),
                  Text(
                    ' / 5.0',
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]?.withOpacity(0.7)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationDetail(String location, LatLng latLng) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                location,
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: FlutterMap(
              options: MapOptions(
                center: latLng,
                zoom: 13.0,
                interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.jelajahin_apps',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: latLng,
                      child: const Icon(Icons.location_on, color: AppColors.primaryDark, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection(String destinationId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getCommentsStream(destinationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat komentar: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        final comments = snapshot.data?.docs ?? [];
        return CommentSection(
          noteId: destinationId,
          firestoreService: _firestoreService,
          currentUser: _currentUser,
          comments: comments,
        );
      },
    );
  }
}