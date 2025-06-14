import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/colors.dart'; // for AppColors.primaryDark
import 'package:cached_network_image/cached_network_image.dart'; // Untuk menampilkan gambar dari network dengan cache

class DestinationDetailPage extends StatefulWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailPage({super.key, required this.destination});

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  late bool isFavorite;
  late ScrollController _scrollController;
  bool _isScrolled = false;
  final TextEditingController _commentController = TextEditingController();

  // Data komentar dummy
  final List<Map<String, String>> _comments = [
    {
      'profileImage': 'https://picsum.photos/seed/commenter1/50/50', // Ganti dengan URL gambar profil dummy yang valid
      'name': 'Pengguna Keren',
      'comment': 'Tempat ini terlihat sangat menarik!',
    },
    {
      'profileImage': 'https://picsum.photos/seed/commenter2/50/50', // Ganti dengan URL gambar profil dummy yang valid
      'name': 'Petualang Sejati',
      'comment': 'Saya sudah pernah ke sini dan sangat merekomendasikannya!',
    },
    {
      'profileImage': 'https://picsum.photos/seed/commenter3/50/50', // Ganti dengan URL gambar profil dummy yang valid
      'name': 'Foodie Explorer',
      'comment': 'Makanan di sekitar sini sangat lezat dan otentik!',
    },
  ];

  @override
  void initState() {
    super.initState();
    // isFavorite diinisialisasi dari data yang diterima
    isFavorite = widget.destination['isFavorite'] ?? false;
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
    _commentController.dispose();
    super.dispose();
  }

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
      // Di sini Anda akan mengimplementasikan logika untuk menyimpan/menghapus dari database
      // dan memperbarui status di aplikasi global Anda jika menggunakan provider/notifier.
      // widget.destination['isFavorite'] = isFavorite; // Ini hanya mengubah data lokal widget, bukan database.
      // Jika Anda menggunakan savedPostsNotifier, panggil fungsi seperti ini:
      // if (isFavorite) {
      //   savedPostsNotifier.value = List.from(savedPostsNotifier.value)..add(widget.destination);
      // } else {
      //   savedPostsNotifier.value = List.from(savedPostsNotifier.value)..removeWhere((post) => post['id'] == widget.destination['id']);
      // }
    });
    // Jika Anda ingin mengembalikan status favorite ke halaman sebelumnya (misal SavedPage)
    // Navigator.of(context).pop(isFavorite);
  }

  Future<bool> _onWillPop() async {
    // Mengembalikan status `isFavorite` saat kembali ke halaman sebelumnya
    Navigator.of(context).pop(isFavorite);
    return false; // Mencegah pop default karena kita sudah melakukan pop manual
  }

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        _comments.add({
          'profileImage': 'https://picsum.photos/seed/currentuser/50/50', // URL gambar profil dummy user saat ini
          'name': 'Anda', // Nama user saat ini (bisa diganti dengan _currentUser.displayName jika sudah ada)
          'comment': _commentController.text.trim(),
        });
        _commentController.clear();
        // Di sini Anda akan mengimplementasikan penyimpanan komentar ke database (misalnya Firestore)
        // Contoh:
        // FirebaseFirestore.instance.collection('destinations').doc(widget.destination['id']).collection('comments').add({
        //   'userId': FirebaseAuth.instance.currentUser?.uid,
        //   'userName': 'Nama User Saat Ini',
        //   'userAvatar': 'URL Avatar User',
        //   'content': _commentController.text.trim(),
        //   'timestamp': FieldValue.serverTimestamp(),
        // });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data dari widget.destination, berikan nilai default jika null
    final String imageUrl = widget.destination['image'] as String? ?? 'https://via.placeholder.com/400x250';
    final String destinationName = widget.destination['name'] as String? ?? 'Nama Destinasi';
    final String destinationLocation = widget.destination['location'] as String? ?? 'Lokasi Tidak Diketahui';
    final String destinationDescription = widget.destination['description'] as String? ?? 'Tidak ada deskripsi.';
    final double destinationRating = (widget.destination['rating'] as num?)?.toDouble() ?? 0.0;
    // int destinationReviews = widget.destination['reviews'] as int? ?? 0; // Jika ada jumlah reviews di data

    final lat = widget.destination['latitude'] as double?;
    final lng = widget.destination['longitude'] as double?;
    final LatLng? destinationLatLng =
        (lat != null && lng != null) ? LatLng(lat, lng) : null;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor:
              _isScrolled ? AppColors.darkTeal : AppColors.white,
          elevation: 0,
          leading: BackButton(
            color: _isScrolled ? Colors.white : AppColors.primaryDark,
          ),
          title: Text(
            destinationName, // Judul AppBar adalah nama destinasi
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isScrolled ? Colors.white : AppColors.primaryDark,
                ),
            maxLines: 1, // Agar judul tidak terlalu panjang
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Destinasi - menggunakan CachedNetworkImage
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
                padding: const EdgeInsets.only(
                  top: 16.0,
                  left: 16.0,
                  right: 16.0,
                  bottom: 8,
                ),
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
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // GestureDetector(
                        //   onTap: toggleFavorite, // Panggil fungsi toggleFavorite
                        //   child: CircleAvatar(
                        //     backgroundColor: Colors.white,
                        //     radius: 18,
                        //     child: Icon(
                        //       isFavorite // Menggunakan isFavorite lokal
                        //           ? Icons.favorite
                        //           : Icons.favorite_border,
                        //       color: isFavorite ? Colors.red : Colors.grey,
                        //       size: 24,
                        //     ),
                        //   ),
                        // ),
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
                        Text(
                          destinationLocation,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Garis Divider setelah lokasi
                    // const Divider(
                    //   color: Colors.grey,
                    //   thickness: 0.5,
                    // ),
                    // const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text('${destinationRating}'),
                        // Tambahkan reviews jika ada di data
                        // const SizedBox(width: 4),
                        // Text('($destinationReviews reviews)'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      destinationDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    // Bagian Peta
                    if (destinationLatLng != null) ...[
                      const Text(
                        "Location",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            options: MapOptions(
                              center: destinationLatLng,
                              zoom: 15,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.jelajahin_apps',
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
                    ),

                    // --- BAGIAN KOMENTAR ---
                    const Text(
                      "Komentar",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Daftar Komentar
                    _comments.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Belum ada komentar. Jadilah yang pertama!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments[_comments.length - 1 - index]; // Tampilkan komentar terbaru di atas
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundImage: NetworkImage(comment['profileImage']!),
                                      backgroundColor: Colors.grey[200],
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            comment['name']!,
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryDark,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment['comment']!,
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 20),

                    // Section Tambah Komentar
                    const Text(
                      "Tambahkan Komentar",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar user saat ini (dummy)
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage('https://picsum.photos/seed/youruser/50/50'), // Ganti dengan URL avatar user saat ini
                          backgroundColor: Colors.grey[200],
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
                            maxLines: null, // Biarkan textfield memanjang sesuai isi
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
                    const SizedBox(height: 20), // Jarak di bagian bawah
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