import 'package:flutter/material.dart';
import '../theme/colors.dart'; // Import AppColors
import 'package:jelajahin_apps/widgets/post_card.dart'; // Import PostCard yang baru
import 'destination_detail_page.dart'; // Tetap import jika ingin bisa klik PostCard ke Detail Page

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  // --- DATA DUMMY UNTUK SAVED PLACES ---
  // Field 'isFavorite' telah dihapus karena tidak lagi diperlukan
  List<Map<String, dynamic>> savedPlaces = [
    {
      'id': 'saved_1', // Tambahkan ID unik
      'image': 'https://picsum.photos/seed/shillong1/400/250', // URL gambar yang valid
      'name': 'City Hut Family Dhaba',
      'location': 'Shillong, India',
      'description': 'Restoran keluarga terkenal di Shillong dengan hidangan lokal dan India yang lezat. Suasana nyaman dan pelayanan ramah.',
      'latitude': -0.30907000,
      'longitude': 100.37055000,
      'ownerName': 'Food Explorer', // Dummy owner
      'ownerAvatar': 'https://picsum.photos/seed/owner1/50/50', // Dummy avatar
      'reviews': 75, // Dummy likes count
      'commentsCount': 10, // Dummy comments count
    },
    {
      'id': 'saved_2',
      'image': 'https://picsum.photos/seed/steakhouse1/400/250', // URL gambar yang valid
      'name': 'Flame Grilled Steakhouse',
      'location': 'Shillong, India',
      'description': 'Tempat terbaik untuk menikmati steak panggang premium di Shillong. Pilihan daging yang berkualitas dan dimasak sempurna.',
      'latitude': -7.2458,
      'longitude': 112.7379,
      'ownerName': 'Grill Master',
      'ownerAvatar': 'https://picsum.photos/seed/owner2/50/50',
      'reviews': 120,
      'commentsCount': 25,
    },
    {
      'id': 'saved_3',
      'image': 'https://picsum.photos/seed/pariscafe/400/250', // URL gambar yang valid
      'name': 'Cafe de Paris',
      'location': 'Paris, France',
      'description': 'Kafe klasik di jantung kota Paris yang menyajikan kopi Prancis otentik dan pastry lezat.',
      'latitude': 48.8566,
      'longitude': 2.3522,
      'ownerName': 'Bonjour Traveler',
      'ownerAvatar': 'https://picsum.photos/seed/owner3/50/50',
      'reviews': 300,
      'commentsCount': 80,
    },
  ];
  // --- AKHIR DATA DUMMY ---

  late ScrollController _scrollController;
  bool _isScrolled = false;
  
  get postData => null;

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

  // Fungsi untuk menghapus postingan dari daftar savedPlaces (unsave)
  void _handleUnsavePost(Map<String, dynamic> postToUnsave) {
    setState(() {
      // Hapus berdasarkan ID untuk memastikan unik
      savedPlaces.removeWhere((post) => post['id'] == postToUnsave['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Postingan "${postToUnsave['name']}" dihapus dari daftar tersimpan.')),
      );
    });
    // --- INTEGRASI DATABASE (contoh untuk unsave) ---
    /*
    // Di sini Anda akan memperbarui Firestore untuk menandai postingan ini tidak lagi disimpan oleh pengguna
    // Misalnya, menghapus ID postingan dari array 'savedPosts' di dokumen user
    if (FirebaseAuth.instance.currentUser != null && postToUnsave.containsKey('id')) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final postId = postToUnsave['id'];
      FirebaseFirestore.instance.collection('users').doc(userId).update({
        'savedPosts': FieldValue.arrayRemove([postId]),
      }).then((_) {
        // developer.log('Post $postId unsaved in Firestore for user $userId'); // Uncomment if developer.log is available
      }).catchError((error) {
        // developer.log('Failed to unsave post $postId in Firestore: $error'); // Uncomment if developer.log is available
        // Optional: If DB update fails, you might want to re-add it to local list
      });
    }
    */
    // --- AKHIR INTEGRASI DATABASE ---
  }


  @override
  Widget build(BuildContext context) {
    // Langsung gunakan savedPlaces karena tidak perlu lagi filter 'isFavorite'
    final List<Map<String, dynamic>> placesToShow = savedPlaces;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: _isScrolled ? AppColors.darkTeal : AppColors.white,
        elevation: 0,
        // leading: BackButton(color: _isScrolled ? AppColors.white : AppColors.primaryDark),
        title: Text(
          'Saved',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _isScrolled ? Colors.white : AppColors.primaryDark,
              ),
        ),
        centerTitle: true,
      ),
      body: placesToShow.isEmpty
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
              itemCount: placesToShow.length,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              itemBuilder: (context, index) {
                final placeData = placesToShow[index];
                return GestureDetector( // Wrapper untuk navigasi ke detail page
                  onTap: () {
                    // Navigasi ke DestinationDetailPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DestinationDetailPage(destination: placeData),
                      ),
                    );
                  },
                  child: PostCard(
                    postData: placeData,
                    ownerName: placeData['ownerName'] ?? 'Unknown User',
                    ownerAvatar: placeData['ownerAvatar'] ?? 'https://via.placeholder.com/50',
                    initialIsSaved: true, // Karena di SavedPage, semua post diasumsikan sudah tersimpan
                    onDelete: _handleUnsavePost, // Teruskan fungsi unsave sebagai callback delete
                    onTap: () { // <-- Tambahkan onTap untuk navigasi
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DestinationDetailPage(destination: postData),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}