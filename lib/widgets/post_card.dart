import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import ini untuk caching gambar
import '../theme/colors.dart';
import 'dart:developer' as developer;

class PostCard extends StatefulWidget {
  final Map<String, dynamic> postData;
  final String ownerName;
  final String ownerAvatar;
  final Function(Map<String, dynamic>)? onDelete; // Callback untuk delete, opsional
  final bool initialIsSaved; // Parameter untuk status saved awal
  final VoidCallback onTap; // <--- INI PARAMETER UNTUK KLIK KARTU KESELURUHAN

  const PostCard({
    super.key, // Gunakan super.key
    required this.postData,
    required this.ownerName,
    required this.ownerAvatar,
    this.onDelete,
    this.initialIsSaved = false, // Nilai default yang baik
    required this.onTap, // <--- Pastikan ini REQUIRED jika selalu ada aksi tap
  });

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
    // Asumsi 'likesCount' adalah jumlah likes yang sebenarnya
    // Jika 'reviews' adalah jumlah ulasan, Anda mungkin perlu field lain untuk likes.
    _currentLikesCount = widget.postData['likesCount'] ?? 0;
    // Periksa apakah user saat ini sudah me-like postingan ini (membutuhkan implementasi Firebase)
    _isLiked = _checkIfLikedByCurrentUser();
    _isSaved = widget.initialIsSaved; // Diinisialisasi dari parameter
  }

  // Helper untuk mengecek apakah user saat ini sudah me-like postingan ini
  bool _checkIfLikedByCurrentUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    final likedByUsers = List<String>.from(widget.postData['likedByUsers'] ?? []);
    return likedByUsers.contains(currentUser.uid);
  }

  // Dipanggil saat widget diperbarui (misalnya, jika postData berubah dari parent)
  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.postData['id'] != oldWidget.postData['id'] ||
        widget.postData['likesCount'] != oldWidget.postData['likesCount']) {
      setState(() {
        _currentLikesCount = widget.postData['likesCount'] ?? 0;
        _isLiked = _checkIfLikedByCurrentUser();
      });
    }
    // Perbarui status saved jika initialIsSaved dari parent berubah
    if (widget.initialIsSaved != oldWidget.initialIsSaved) {
      setState(() {
        _isSaved = widget.initialIsSaved;
      });
    }
  }

  void _toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda perlu login untuk menyukai postingan.')),
      );
      return;
    }

    final postId = widget.postData['id'];
    if (postId == null) {
      developer.log('Post ID is null, cannot toggle like.');
      return;
    }

    // Optimistic UI update
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _currentLikesCount++;
      } else {
        _currentLikesCount--;
      }
    });

    try {
      final docRef = FirebaseFirestore.instance.collection('destinations').doc(postId);
      if (_isLiked) {
        await docRef.update({
          'likesCount': FieldValue.increment(1),
          'likedByUsers': FieldValue.arrayUnion([currentUser.uid]),
        });
      } else {
        await docRef.update({
          'likesCount': FieldValue.increment(-1),
          'likedByUsers': FieldValue.arrayRemove([currentUser.uid]),
        });
      }
      developer.log('Like status updated for post $postId by user ${currentUser.uid}');
    } catch (error) {
      developer.log('Failed to update like status for post $postId: $error');
      // Revert optimistic UI update on error
      setState(() {
        _isLiked = !_isLiked;
        if (_isLiked) {
          _currentLikesCount++; // Ini seharusnya _currentLikesCount-- jika _isLiked baru saja menjadi true
        } else {
          _currentLikesCount--; // Ini seharusnya _currentLikesCount++ jika _isLiked baru saja menjadi false
        }
        // Perbaikan: Revert ke nilai sebelumnya
        _currentLikesCount = _isLiked ? _currentLikesCount - 1 : _currentLikesCount + 1;

      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status suka: $error')),
      );
    }
  }

  void _toggleSave() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda perlu login untuk menyimpan postingan.')),
      );
      return;
    }

    final postId = widget.postData['id'];
    if (postId == null) {
      developer.log('Post ID is null, cannot toggle save.');
      return;
    }

    // Optimistic UI update
    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      if (_isSaved) {
        // Tambahkan ke savedPosts
        await userDocRef.update({
          'savedPosts': FieldValue.arrayUnion([postId]),
        });
      } else {
        // Hapus dari savedPosts
        await userDocRef.update({
          'savedPosts': FieldValue.arrayRemove([postId]),
        });
        // Jika di SavedPage dan di-unsave, panggil onDelete untuk menghapus dari daftar
        if (widget.onDelete != null) {
          widget.onDelete!(widget.postData);
        }
      }
      developer.log('Save status updated for post $postId by user ${currentUser.uid}');
    } catch (error) {
      developer.log('Failed to update save status for post $postId: $error');
      // Revert optimistic UI update on error
      setState(() {
        _isSaved = !_isSaved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status simpan: $error')),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    // Hanya izinkan pemilik postingan untuk menghapus
    if (currentUser == null || currentUser.uid != widget.postData['ownerId']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda tidak memiliki izin untuk menghapus postingan ini.')),
      );
      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Postingan?'),
          content: Text('Apakah Anda yakin ingin menghapus postingan "${widget.postData['name']}"? Tindakan ini tidak dapat dibatalkan.'),
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
                } else {
                  // Fallback delete jika onDelete tidak disediakan oleh parent
                  _performDeleteLocally(widget.postData['id']);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Fungsi delete lokal jika onDelete tidak disediakan
  void _performDeleteLocally(String? postId) async {
    if (postId == null) return;
    try {
      await FirebaseFirestore.instance.collection('destinations').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Postingan berhasil dihapus.')),
      );
    } catch (e) {
      developer.log('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus postingan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isOwner = currentUser?.uid == widget.postData['ownerId'];

    final String postImage = widget.postData['image'] ?? 'https://via.placeholder.com/400x250?text=No+Image';
    final String postName = widget.postData['name'] ?? 'Nama Tempat Tidak Diketahui';
    final String postLocation = widget.postData['location'] ?? 'Lokasi Tidak Diketahui';
    final String postDescription = widget.postData['description'] ?? 'Deskripsi tidak tersedia.';
    final int commentsCount = widget.postData['commentsCount'] ?? 0;
    final double rating = (widget.postData['rating'] as num?)?.toDouble() ?? 0.0;


    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 2,
      color: AppColors.white,
      clipBehavior: Clip.hardEdge,
      child: InkWell( // Menggunakan InkWell untuk efek tap yang baik
        onTap: widget.onTap, // Menggunakan onTap dari parameter constructor
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
                    backgroundColor: AppColors.lightTeal.withOpacity(0.2),
                    child: (widget.ownerAvatar.startsWith('http') || widget.ownerAvatar.startsWith('https'))
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: widget.ownerAvatar,
                              width: 36, // 2 * radius
                              height: 36, // 2 * radius
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                              errorWidget: (context, url, error) => Icon(Icons.person, size: 18, color: AppColors.darkTeal),
                            ),
                          )
                        : Icon(Icons.person, size: 18, color: AppColors.darkTeal), // Fallback if not a network image
                  ),
                  const SizedBox(width: 8),
                  Expanded( // Menggunakan Expanded agar nama tidak overflow
                    child: Text(
                      widget.ownerName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                      overflow: TextOverflow.ellipsis, // Tambahkan ellipsis jika nama terlalu panjang
                    ),
                  ),
                  // Tampilkan PopupMenuButton hanya jika user adalah pemilik postingan
                  if (isOwner) // <--- Hanya tampilkan jika ini postingan milik user saat ini
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
            CachedNetworkImage(
              imageUrl: postImage,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 250,
                color: AppColors.grey.withOpacity(0.2),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.lightTeal,
                  ),
                ),
              ),
              errorWidget: (context, url, error) {
                developer.log('Error loading image for post: $postImage, Error: $error');
                return Container(
                  height: 250,
                  color: AppColors.grey.withOpacity(0.2),
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 50, color: AppColors.grey),
                  ),
                );
              },
            ),
            // Bagian Detail Postingan (Nama Tempat, Lokasi, Deskripsi, Rating)
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
                    maxLines: 1, // Batasi 1 baris
                    overflow: TextOverflow.ellipsis,
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
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1), // Tampilkan rating dengan 1 desimal
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark),
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
                      // Anda mungkin ingin menavigasi ke halaman komentar di sini
                      GestureDetector(
                        onTap: () {
                          // Handle tap on comments, e.g., navigate to comments page
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fitur komentar segera hadir!')),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 24, color: AppColors.primaryDark),
                            const SizedBox(width: 4),
                            Text(
                              '$commentsCount',
                              style: textTheme.bodySmall?.copyWith(color: AppColors.grey),
                            ),
                          ],
                        ),
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
                      GestureDetector(
                        onTap: () {
                          // Implementasi fitur share
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fitur share segera hadir!')),
                          );
                        },
                        child: Icon(Icons.share, size: 24, color: AppColors.primaryDark),
                      ),
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