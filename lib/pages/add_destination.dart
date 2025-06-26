// Import berbagai pustaka Flutter, Firebase, dan pustaka pendukung lainnya
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;
import 'package:dotted_border/dotted_border.dart';
import '../theme/colors.dart';

/// Halaman untuk menambahkan destinasi wisata baru.
/// Pengguna bisa mengunggah foto, menulis nama, lokasi, deskripsi, memilih kategori,
/// serta memilih lokasi dari peta dan memberikan rating.
class AddDestinationScreen extends StatefulWidget {
  const AddDestinationScreen({super.key});

  @override
  State<AddDestinationScreen> createState() => _AddDestinationScreenState();
}

class _AddDestinationScreenState extends State<AddDestinationScreen> {
  // Key form utama
  final _formKey = GlobalKey<FormState>();

  // Controller untuk field input teks
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Fokus input lokasi agar saat blur bisa trigger pencarian otomatis
  final FocusNode _locationFocusNode = FocusNode();

  // Kontrol peta
  final MapController _mapController = MapController();

  // Nilai rating default
  double _overallRating = 3.0;

  // Variabel penyimpanan gambar dan data byte gambar (untuk upload)
  XFile? _pickedImage;
  Uint8List? _webImageBytes;

  // Koordinat destinasi terpilih (default: Jakarta)
  LatLng _selectedLatLng = const LatLng(-6.200000, 106.816666);

  // Status untuk loading dan proses upload
  bool _isUploading = false;
  bool _isLoadingLocation = false;

  // Kategori destinasi
  String? _selectedCategory;
  final List<String> _categories = [
    'Restaurant', 'History', 'Nature', 'Museum', 'Beach',
    'Mountain', 'City', 'Shopping', 'Art',
  ];

  @override
  void initState() {
    super.initState();
    _locationFocusNode.addListener(() {
      if (!_locationFocusNode.hasFocus && _locationController.text.isNotEmpty) {
        _searchAddress(_locationController.text);
      }
    });
    _reverseGeocode(_selectedLatLng);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _locationFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Fungsi utama untuk mengunggah data destinasi ke Firebase.
  /// Validasi form, unggah gambar (dalam bentuk byte), dan simpan data ke koleksi Firestore.
  Future<void> _uploadDestination() async {
    if (!_formKey.currentState!.validate() || _pickedImage == null || _selectedCategory == null) {
      _showSnackBar('Mohon lengkapi semua data termasuk gambar dan kategori.');
      return;
    }

    if (kIsWeb && _webImageBytes == null) {
      _showSnackBar('Mohon pilih gambar terlebih dahulu (Web).');
      return;
    } else if (!kIsWeb && _pickedImage == null) {
      _showSnackBar('Mohon pilih gambar terlebih dahulu (Mobile).');
      return;
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('Anda harus login untuk menambahkan destinasi.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      Uint8List? imageDataBytes;
      if (kIsWeb) {
        imageDataBytes = _webImageBytes;
      } else {
        imageDataBytes = await _pickedImage!.readAsBytes();
      }

      if (imageDataBytes == null || imageDataBytes.isEmpty) {
        throw Exception("Gagal mendapatkan data gambar.");
      }

      if (imageDataBytes.lengthInBytes > 1 * 1024 * 1024) {
        _showSnackBar('Ukuran gambar terlalu besar (maks 1MB). Mohon pilih gambar yang lebih kecil.', isError: true);
        setState(() => _isUploading = false);
        return;
      }

      _showSnackBar('Mengunggah data destinasi...', isError: false);

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final ownerName = userDoc.data()?['name'] ?? 'Anonim';
      final ownerAvatar = userDoc.data()?['profile_picture_url'] ?? 'https://via.placeholder.com/150';

      final String destinationId = const Uuid().v4();

      await FirebaseFirestore.instance.collection('destinations').doc(destinationId).set({
        'id': destinationId,
        'title': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageData': imageDataBytes.toList(),
        'latitude': _selectedLatLng.latitude,
        'longitude': _selectedLatLng.longitude,
        'rating': _overallRating,
        'category': _selectedCategory,
        'createdAt': FieldValue.serverTimestamp(),
        'ownerId': currentUser.uid,
        'ownerName': ownerName,
        'ownerAvatar': ownerAvatar,
        'likes': [],
        'commentCount': 0,
      });

      if (!mounted) return;
      _showSnackBar('Destinasi berhasil ditambahkan!');
      Navigator.pop(context);
    } catch (e) {
      developer.log('Error uploading destination: $e');
      if (mounted) {
        _showSnackBar('Gagal mengunggah destinasi: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Menampilkan feedback snackbar di bawah layar
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : AppColors.lightTeal,
        ),
      );
    }
  }

  /// Fungsi reverse geocoding untuk mengubah koordinat ke alamat teks
  Future<void> _reverseGeocode(LatLng latLng) async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}';
    try {
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'jelajahin-app/1.0'});
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _locationController.text = data['display_name'] ?? 'Alamat tidak ditemukan';
          _selectedLatLng = latLng;
        });
      }
    } catch (e) {
      _showSnackBar('Gagal mendapatkan alamat.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  /// Mencari alamat berdasarkan input teks (geocoding)
  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);
    final url = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';
    try {
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'jelajahin-app/1.0'});
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final newLatLng = LatLng(lat, lon);
          setState(() {
            _selectedLatLng = newLatLng;
            _locationController.text = data[0]['display_name'] ?? query;
          });
          _mapController.move(_selectedLatLng, 13.0);
        } else {
          _showSnackBar('Alamat tidak ditemukan.');
        }
      }
    } catch (e) {
      _showSnackBar('Error mencari alamat: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  /// Cegah kembali saat proses upload sedang berlangsung
  Future<bool> _onWillPop() async {
    if (_isUploading) {
      _showSnackBar('Tunggu proses upload selesai.');
      return false;
    }
    return true;
  }

  /// Pilih gambar dari galeri
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImage = picked;
          _webImageBytes = bytes;
        });
      } else {
        setState(() => _pickedImage = picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Tambah Destinasi Baru',
            style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          centerTitle: true,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primaryDark,
          elevation: 1.0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.primaryDark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Foto Destinasi'),
                    _buildImagePicker(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Informasi Dasar'),
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Lokasi'),
                    _buildLocationCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Rating Anda'),
                    _buildRatingCard(),
                  ],
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // === WIDGET PEMBANTU UI ===

  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
      );

  /// Widget pemilih gambar (dengan batasan + preview)
  Widget _buildImagePicker() => GestureDetector(
        onTap: _isUploading ? null : _pickImage,
        child: DottedBorder(
          color: Colors.grey,
          strokeWidth: 2,
          dashPattern: const [8, 4],
          borderType: BorderType.RRect,
          radius: const Radius.circular(15),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0), color: Colors.grey.shade100),
            child: _pickedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13.0),
                    child: kIsWeb
                        ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                        : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                  )
                : const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Ketuk untuk memilih gambar', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ])),
          ),
        ),
      );

  Widget _buildInfoCard() => Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Tempat', prefixIcon: Icon(Icons.place_outlined)),
                validator: (v) => v!.isEmpty ? 'Nama tempat wajib diisi' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Kategori', prefixIcon: Icon(Icons.category_outlined)),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Kategori wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi', prefixIcon: Icon(Icons.description_outlined)),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Deskripsi wajib diisi' : null),
          ]),
        ),
      );

  Widget _buildLocationCard() => Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            TextFormField(
              controller: _locationController,
              focusNode: _locationFocusNode,
              decoration: InputDecoration(
                labelText: 'Cari alamat atau pilih di peta',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoadingLocation ? const Padding(padding: EdgeInsets.all(10.0), child: CircularProgressIndicator(strokeWidth: 2)) : null,
              ),
              onFieldSubmitted: (v) => _searchAddress(v),
              validator: (v) => v!.isEmpty ? 'Lokasi wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(center: _selectedLatLng, zoom: 13.0, onTap: (pos, p) => _reverseGeocode(p)),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.jelajahin_apps'),
                    MarkerLayer(markers: [Marker(point: _selectedLatLng, child: const Icon(Icons.location_on, color: AppColors.primaryDark, size: 40))]),
                  ],
                ),
              ),
            ),
          ]),
        ),
      );

  Widget _buildRatingCard() => Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(index < _overallRating ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 36),
                onPressed: () => setState(() => _overallRating = index + 1.0),
              );
            }),
          ),
        ),
      );

  Widget _buildBottomButton() => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.white.withOpacity(0.9),
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _uploadDestination,
            icon: _isUploading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Icon(Icons.cloud_upload_outlined),
            label: Text(_isUploading ? 'Mengunggah...' : 'Simpan Destinasi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightTeal,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
}
