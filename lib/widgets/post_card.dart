// lib/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Dibutuhkan jika Anda mengaktifkan logika Firebase di dalamnya
import 'package:cloud_firestore/cloud_firestore.dart'; // Dibutuhkan jika Anda mengaktifkan logika Firebase di dalamnya
import '../theme/colors.dart'; // Sesuaikan path jika berbeda
import 'dart:developer' as developer; // Untuk log

// Import DestinationDetailPage
import '../pages/destination_detail_page.dart'; // Sesuaikan path jika berbeda

class PostCard extends StatefulWidget {
  final Map<String, dynamic> postData;
  final String ownerName;
  final String ownerAvatar;
  final Function(Map<String, dynamic>)? onDelete; // Callback untuk delete, opsional
  final bool initialIsSaved; // <--- INI PARAMETER BARU YANG HARUS ADA

  const PostCard({
    required this.postData,
    required this.ownerName,
    required this.ownerAvatar,
    this.onDelete,
    this.initialIsSaved = false, // <--- INI INILITIALISASI DEFAULTNYA
    Key? key, required Null Function() onTap,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _currentLikesCount;
  late bool _isSaved; // Variabel state internal untuk status saved

  @override
  void initState() {
    super.initState();
    _isLiked = false;
    _currentLikesCount = widget.postData['reviews'] ?? 0;
    _isSaved = widget.initialIsSaved; // <--- DIINISIALISASI DARI PARAMETER
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _currentLikesCount++;
      } else {
        _currentLikesCount--;
      }
    });
    // --- INTEGRASI DATABASE (contoh untuk like) ---
    /*
    if (FirebaseAuth.instance.currentUser != null) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final postId = widget.postData['id'];
      if (postId != null) {
        FirebaseFirestore.instance.collection('destinations').doc(postId).update({
          'reviews': FieldValue.increment(_isLiked ? 1 : -1),
          // 'likedByUsers': _isLiked ? FieldValue.arrayUnion([userId]) : FieldValue.arrayRemove([userId]),
        }).then((_) {
          developer.log('Like status updated for post $postId');
        }).catchError((error) {
          developer.log('Failed to update like status for post $postId: $error');
          setState(() {
            _isLiked = !_isLiked;
            _currentLikesCount = _isLiked ? _currentLikesCount - 1 : _currentLikesCount + 1;
          });
        });
      }
    }
    */
    // --- AKHIR INTEGRASI DATABASE ---
  }

  void _toggleSave() {
    setState(() {
      _isSaved = !_isSaved;
    });
    // Jika ini di SavedPage dan _isSaved berubah menjadi false (di-unsave), panggil onDelete
    if (!_isSaved && widget.onDelete != null) {
      widget.onDelete!(widget.postData);
    }
    // --- INTEGRASI DATABASE (contoh untuk save) ---
    /*
    if (FirebaseAuth.instance.currentUser != null) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final postId = widget.postData['id'];
      if (postId != null) {
        FirebaseFirestore.instance.collection('users').doc(userId).update({
          'savedPosts': _isSaved ? FieldValue.arrayUnion([postId]) : FieldValue.arrayRemove([postId]),
        }).then((_) {
          developer.log('Save status updated for post $postId');
        }).catchError((error) {
          developer.log('Failed to update save status for post $postId: $error');
          setState(() { _isSaved = !_isSaved; });
        });
      }
    }
    */
    // --- AKHIR INTEGRASI DATABASE ---
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Postingan?'),
          content: Text('Apakah Anda yakin ingin menghapus postingan "${widget.postData['name']}"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Batal', style: TextStyle(color: AppColors.primaryDark)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (widget.onDelete != null) {
                  widget.onDelete!(widget.postData);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String postImage = widget.postData['image'] ?? 'https://via.placeholder.com/150';
    final String postName = widget.postData['name'] ?? 'Nama Tempat Tidak Diketahui';
    final String postLocation = widget.postData['location'] ?? 'Lokasi Tidak Diketahui';
    final String postDescription = widget.postData['description'] ?? 'Deskripsi tidak tersedia.';
    final int commentsCount = widget.postData['commentsCount'] ?? 0;

    return GestureDetector( // <--- Tambahkan GestureDetector di sini
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DestinationDetailPage(destination: widget.postData),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 2,
        color: AppColors.white,
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Post (Owner Avatar, Owner Name, dan Tombol Opsi Tiga Titik)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: widget.ownerAvatar.startsWith('http')
                        ? NetworkImage(widget.ownerAvatar) as ImageProvider
                        : AssetImage(widget.ownerAvatar) as ImageProvider,
                    backgroundColor: AppColors.lightTeal.withOpacity(0.2),
                    child: widget.ownerAvatar.isEmpty
                        ? Icon(Icons.person, size: 18, color: AppColors.darkTeal)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.ownerName,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const Spacer(),
                  // Tampilkan PopupMenuButton hanya jika onDelete callback diberikan
                  if (widget.onDelete != null)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: AppColors.primaryDark),
                      onSelected: (String result) {
                        if (result == 'delete') {
                          _showDeleteConfirmationDialog();
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete Post', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Gambar Postingan
            Image.network(
              postImage,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 250,
                  color: AppColors.grey.withOpacity(0.2),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.lightTeal,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                developer.log('Error loading image for post: $postImage, Error: $error', error: error, stackTrace: stackTrace);
                return Container(
                  height: 250,
                  color: AppColors.grey.withOpacity(0.2),
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 50, color: AppColors.grey),
                  ),
                );
              },
            ),
            // Bagian Detail Postingan (Nama Tempat, Lokasi, Deskripsi)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    postName,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          postLocation,
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    postDescription,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Icon Aksi (Like, Comment, Save, Share) - jumlah di samping kanan
                  Row(
                    children: [
                      // Like Icon dengan hitungan
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Row(
                          children: [
                            Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 24,
                              color: _isLiked ? Colors.red : AppColors.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_currentLikesCount',
                              style: textTheme.bodySmall?.copyWith(color: AppColors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Comment Icon dengan hitungan
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 24, color: AppColors.primaryDark),
                          const SizedBox(width: 4),
                          Text(
                            '$commentsCount',
                            style: textTheme.bodySmall?.copyWith(color: AppColors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Save Icon (sekarang bisa dipencet)
                      GestureDetector(
                        onTap: _toggleSave,
                        child: Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                          size: 24,
                          color: _isSaved ? AppColors.primaryDark : AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Share Icon
                      Icon(Icons.share, size: 24, color: AppColors.primaryDark),
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
}