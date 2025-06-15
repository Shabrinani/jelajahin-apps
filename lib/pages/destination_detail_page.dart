import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Firebase imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For getting current user info

class DestinationDetailPage extends StatefulWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailPage({super.key, required this.destination});

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  late bool isFavorite; // This will now represent the user's favorite status for this destination
  late ScrollController _scrollController;
  bool _isScrolled = false;
  final TextEditingController _commentController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen for comments in real-time
  Stream<QuerySnapshot>? _commentsStream;

  @override
  void initState() {
    super.initState();
    // Assuming 'id' is a unique identifier for the destination in Firestore
    // This `isFavorite` would ideally come from a user-specific 'favorites' collection
    // For now, we'll keep it as a local state that would be updated in the backend.
    isFavorite = widget.destination['isFavorite'] ?? false; // Initial dummy value, to be replaced by actual user data

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 0;
      });
    });

    // Initialize comments stream
    _commentsStream = _firestore
        .collection('destinations')
        .doc(widget.destination['id']) // Use destination ID to fetch its comments
        .collection('comments')
        .orderBy('timestamp', descending: true) // Show newest comments first
        .snapshots();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void toggleFavorite() async {
    // Implement favorite toggle logic with Firestore
    // This requires a 'users' collection with a 'favorites' subcollection
    // or a 'favorites' collection that maps users to destinations.
    // For simplicity, let's assume a 'userFavorites' collection where each doc is a user's ID
    // and it contains a map of destination IDs they have favorited.

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda perlu login untuk menambahkan favorit.')),
      );
      return;
    }

    final destinationId = widget.destination['id'];
    if (destinationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Destinasi tidak ditemukan.')),
      );
      return;
    }

    // Toggle local state immediately for a responsive UI
    setState(() {
      isFavorite = !isFavorite;
    });

    try {
      final userFavoriteDocRef = _firestore.collection('userFavorites').doc(user.uid);
      if (isFavorite) {
        await userFavoriteDocRef.set({
          'favoritedDestinations': FieldValue.arrayUnion([destinationId]),
        }, SetOptions(merge: true)); // Use merge: true to add without overwriting
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ditambahkan ke favorit!')),
        );
      } else {
        await userFavoriteDocRef.update({
          'favoritedDestinations': FieldValue.arrayRemove([destinationId]),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dihapus dari favorit.')),
        );
      }
    } catch (e) {
      // Revert local state if backend update fails
      setState(() {
        isFavorite = !isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui favorit: $e')),
      );
      print('Error toggling favorite: $e');
    }
  }

  // A function to check the favorite status from Firestore
  Future<void> _checkFavoriteStatus() async {
    final user = _auth.currentUser;
    final destinationId = widget.destination['id'];

    if (user == null || destinationId == null) {
      setState(() {
        isFavorite = false; // Not favorited if no user or no destination ID
      });
      return;
    }

    try {
      final docSnapshot = await _firestore.collection('userFavorites').doc(user.uid).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final List<dynamic>? favoritedDestinations = data?['favoritedDestinations'];
        if (favoritedDestinations != null && favoritedDestinations.contains(destinationId)) {
          setState(() {
            isFavorite = true;
          });
        } else {
          setState(() {
            isFavorite = false;
          });
        }
      } else {
        setState(() {
          isFavorite = false;
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
      setState(() {
        isFavorite = false; // Default to not favorited on error
      });
    }
  }


  Future<bool> _onWillPop() async {
    // Return the final `isFavorite` status when navigating back
    Navigator.of(context).pop(isFavorite);
    return false; // Prevent default pop as we've handled it manually
  }

  void _addComment() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda perlu login untuk menambahkan komentar.')),
      );
      return;
    }

    if (_commentController.text.trim().isNotEmpty) {
      try {
        final String? userName = user.displayName ?? user.email?.split('@')[0] ?? 'Anonim';
        final String? userAvatar = user.photoURL ?? 'https://picsum.photos/seed/${user.uid}/50/50'; // Fallback dummy avatar

        await _firestore
            .collection('destinations')
            .doc(widget.destination['id'])
            .collection('comments')
            .add({
          'userId': user.uid,
          'userName': userName,
          'userAvatar': userAvatar,
          'content': _commentController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(), // Use server timestamp for consistency
        });
        _commentController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan komentar: $e')),
        );
        print('Error adding comment: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = widget.destination['image'] as String? ?? 'https://via.placeholder.com/400x250';
    final String destinationName = widget.destination['name'] as String? ?? 'Nama Destinasi';
    final String destinationLocation = widget.destination['location'] as String? ?? 'Lokasi Tidak Diketahui';
    final String destinationDescription = widget.destination['description'] as String? ?? 'Tidak ada deskripsi.';
    final double destinationRating = (widget.destination['rating'] as num?)?.toDouble() ?? 0.0;

    final lat = widget.destination['latitude'] as double?;
    final lng = widget.destination['longitude'] as double?;
    final LatLng? destinationLatLng = (lat != null && lng != null) ? LatLng(lat, lng) : null;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: _isScrolled ? AppColors.darkTeal : Colors.transparent,
          elevation: _isScrolled ? 4 : 0,
          leading: BackButton(
            color: _isScrolled ? AppColors.white : AppColors.primaryDark,
          ),
          title: AnimatedOpacity(
            opacity: _isScrolled ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              destinationName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isScrolled ? AppColors.white : AppColors.primaryDark,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : (_isScrolled ? AppColors.white : AppColors.primaryDark),
              ),
              onPressed: toggleFavorite,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 240,
                  color: Colors.grey[200],
                  child: Center(child: CircularProgressIndicator(color: AppColors.lightTeal)),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 240,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            destinationName,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            destinationLocation,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text('${destinationRating.toStringAsFixed(1)}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      destinationDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    if (destinationLatLng != null) ...[
                      const Text(
                        "Location",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade200,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            options: MapOptions(
                              center: destinationLatLng,
                              zoom: 15,
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
                                    width: 40,
                                    height: 40,
                                    point: destinationLatLng,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: AppColors.primaryDark,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    const Divider(
                      color: Colors.grey,
                      thickness: 0.5,
                      height: 30,
                    ),

                    // --- COMMENTS SECTION ---
                    const Text(
                      "Komentar",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Listen to Firestore stream for comments
                    StreamBuilder<QuerySnapshot>(
                      stream: _commentsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator(color: AppColors.lightTeal));
                        }
                        if (snapshot.hasError) {
                          return Text('Error loading comments: ${snapshot.error}');
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Belum ada komentar. Jadilah yang pertama!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                            ),
                          );
                        }

                        // Display comments
                        final comments = snapshot.data!.docs;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final commentData = comments[index].data() as Map<String, dynamic>;
                            final String commentUserName = commentData['userName'] ?? 'Anonim';
                            final String commentUserAvatar = commentData['userAvatar'] ?? 'https://picsum.photos/seed/defaultavatar/50/50';
                            final String commentContent = commentData['content'] ?? 'No content';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundImage: CachedNetworkImageProvider(commentUserAvatar),
                                    backgroundColor: Colors.grey[200],
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          commentUserName,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryDark,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          commentContent,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Add Comment Section
                    const Text(
                      "Tambahkan Komentar",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Display current user's avatar if logged in
                        StreamBuilder<User?>(
                          stream: _auth.authStateChanges(),
                          builder: (context, snapshot) {
                            final User? user = snapshot.data;
                            final String avatarUrl = user?.photoURL ?? 'https://picsum.photos/seed/guest/50/50';
                            return CircleAvatar(
                              radius: 20,
                              backgroundImage: CachedNetworkImageProvider(avatarUrl),
                              backgroundColor: Colors.grey[200],
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Tulis komentar Anda...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _addComment,
                          color: AppColors.primaryDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}