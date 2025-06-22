import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jelajahin_apps/services/firestore_service.dart';
import 'package:jelajahin_apps/theme/colors.dart';
import 'package:jelajahin_apps/widgets/comment_section.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DestinationDetailPage extends StatefulWidget {
  final Map<String, dynamic> destination;
  const DestinationDetailPage({super.key, required this.destination});

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

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
          
          final String imageUrl = destinationData['imageUrl'] ?? '';
          final String title = destinationData['title'] ?? 'Judul Tidak Tersedia';
          final String location = destinationData['location'] ?? 'Lokasi Tidak Tersedia';
          final String description = destinationData['description'] ?? 'Deskripsi tidak tersedia.';
          final String ownerAvatar = destinationData['ownerAvatar'] ?? '';

          final List likes = destinationData['likes'] ?? [];
          final bool isLiked = _currentUser != null ? likes.contains(_currentUser!.uid) : false;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, title, imageUrl, destinationId, isLiked, likes.length),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOwnerInfo(ownerAvatar, title, location),
                        const SizedBox(height: 20),
                        const Text('Deskripsi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
                        const Divider(height: 48),
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

  SliverAppBar _buildSliverAppBar(BuildContext context, String title, String imageUrl, String destinationId, bool isLiked, int likeCount) {
    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      actions: [
        Row(
          children: [
            IconButton(
              icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.white),
              onPressed: () {
                if (_currentUser != null) {
                  _firestoreService.toggleLike(destinationId, isLiked);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Silakan login untuk menyukai postingan ini.")));
                }
              },
            ),
            Text(likeCount.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.white),
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
        centerTitle: true,
        title: Text(title, style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
        background: Hero(
          tag: 'post_image_${widget.destination['id'] ?? imageUrl}',
          // DIUBAH: Menggunakan CachedNetworkImage untuk penanganan error yang lebih baik
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade300,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 50),
            ),
          ),
        ),
        stretchModes: const [StretchMode.zoomBackground],
      ),
    );
  }
  
  Widget _buildOwnerInfo(String ownerAvatar, String title, String location) {
    return Row(
      children: [
        // DIUBAH: Menggunakan CachedNetworkImageProvider untuk avatar
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: ownerAvatar.isNotEmpty ? CachedNetworkImageProvider(ownerAvatar) : null,
          child: ownerAvatar.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text(location, style: const TextStyle(fontSize: 16, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection(String destinationId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getCommentsStream(destinationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Gagal memuat komentar: ${snapshot.error}'));
        
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
