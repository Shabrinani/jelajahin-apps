import 'dart:math' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:jelajahin_apps/services/firestore_service.dart';
import 'package:jelajahin_apps/theme/colors.dart';
import 'dart:typed_data';

import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  final Map<String, dynamic> postData;

  final String ownerName;
  final String ownerAvatar;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const PostCard({
    super.key,
    required this.postData,
    required this.onTap,
    required this.ownerName,
    required this.ownerAvatar,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final currentUser = FirebaseAuth.instance.currentUser;

    final List likes = postData['likes'] ?? [];
    final int commentCount = postData['commentCount'] ?? 0;
    final String destinationId = postData['id'] ?? '';
    final String ownerId = postData['ownerId'] ?? '';
    final bool isLiked = likes.contains(currentUser?.uid);
    final bool isOwner = currentUser?.uid == ownerId;

    final String title = postData['title'] ?? 'Tanpa Judul';
    final String location = postData['location'] ?? 'Tanpa Lokasi';

    final List<dynamic>? imageDataList = postData['imageData'] as List<dynamic>?;
    Uint8List? imageDataBytes;
    if (imageDataList != null && imageDataList.isNotEmpty) {
      try {
        imageDataBytes = Uint8List.fromList(imageDataList.cast<int>());
      } catch (e) {
        developer.log('Error casting imageData to Uint8List: $e' as num);
        imageDataBytes = null;
      }
    }

    final dynamic createdAtData = postData['createdAt'];
    String timeAgo = 'Baru saja';
    if (createdAtData is Timestamp) {
      timeago.setLocaleMessages('id', timeago.IdMessages());
      timeAgo = timeago.format(createdAtData.toDate(), locale: 'id');
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      color: AppColors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: ownerAvatar.isNotEmpty ? CachedNetworkImageProvider(ownerAvatar) : null,
                    backgroundColor: Colors.grey.shade200,
                    child: ownerAvatar.isEmpty ? const Icon(Icons.person, size: 24, color: Colors.grey) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ownerName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          timeAgo,
                          style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  // PopupMenuButton hanya akan dirender jika user adalah pemilik
                  if (isOwner && (onDelete != null || onEdit != null))
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.primaryDark),
                      onSelected: (String result) {
                        if (result == 'edit' && onEdit != null) onEdit!();
                        if (result == 'delete' && onDelete != null) onDelete!();
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        if (onEdit != null)
                          const PopupMenuItem<String>(value: 'edit', child: Text('Edit Post')),
                        if (onDelete != null)
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Hapus Post', style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            // --- Gambar Post ---
            Hero(
              tag: 'post_image_$destinationId',
              child: Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey.shade200,
                child: imageDataBytes != null && imageDataBytes.isNotEmpty
                    ? Image.memory(
                        imageDataBytes,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
                        },
                      )
                    : const Center(
                        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
              ),
            ),

            // --- Judul dan Lokasi ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- Baris Aksi dan Statistik ---
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 4.0, 16.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildStatIcon(Icons.favorite_rounded, likes.length.toString()),
                      const SizedBox(width: 20),
                      _buildStatIcon(Icons.chat_bubble_rounded, commentCount.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk statistik jumlah
  Widget _buildStatIcon(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Text(count, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    );
  }
}