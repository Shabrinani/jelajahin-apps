import 'dart:convert';
import 'dart:io'; // Mengimpor seluruh fungsionalitas dart:io untuk Platform dan SocketException
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Cloud Firestore
import 'package:firebase_auth/firebase_auth.dart'; // For getting current user UID
import 'package:flutter_map/flutter_map.dart'; // For OpenStreetMap integration
import 'package:latlong2/latlong.dart'; // For LatLng
import 'package:http/http.dart' as http; // For Nominatim reverse geocoding dan Imgbb API
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'dart:developer' as developer; // Untuk logging
import 'package:dotted_border/dotted_border.dart'; // <-- IMPORT BARU UNTUK UI

// Pastikan path ini benar untuk AppColors Anda
import '../theme/colors.dart';

class AddDestinationScreen extends StatefulWidget {
  const AddDestinationScreen({super.key});

  @override
  State<AddDestinationScreen> createState() => _AddDestinationScreenState();
}

class _AddDestinationScreenState extends State<AddDestinationScreen> {
  // --- SEMUA STATE LOGIKA ANDA TETAP UTUH ---
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();
  double _overallRating = 3.0;
  XFile? _pickedImage;
  Uint8List? _webImage;
  LatLng _selectedLatLng = LatLng(-6.200000, 106.816666);
  String _address = '';
  bool _isUploading = false;
  bool _isLoadingLocation = false;
  final MapController _mapController = MapController();
  final Uuid _uuid = const Uuid();
  static const String _imgbbApiKey = '4000d7846dcaf738642127c07ddcfbed';
  String? _selectedCategory;
  final List<String> _categories = [
    'Restaurant', 'History', 'Nature', 'Museum', 'Beach',
    'Mountain', 'City', 'Shopping', 'Art',
  ];

  // Variabel yang tidak lagi diperlukan oleh UI baru
  // late ScrollController _scrollController;
  // bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi ScrollController tidak lagi diperlukan
    // _scrollController = ScrollController();
    // _scrollController.addListener(() { ... });

    _locationFocusNode.addListener(() {
      if (!_locationFocusNode.hasFocus && _locationController.text.isNotEmpty) {
        developer.log('AddDestinationScreen: Location field unfocused, searching for: ${_locationController.text}');
        _searchAddress(_locationController.text);
      }
    });
    _reverseGeocode(_selectedLatLng);
  }

  // --- SEMUA FUNGSI LOGIKA ANDA TETAP UTUH DAN TIDAK BERUBAH ---

  Future<bool> _onWillPop() async {
    if (_isUploading) {
      _showSnackBar('Tunggu proses upload selesai.');
      return false;
    }
    return true;
  }

  Future<void> _pickImage() async {
    developer.log('AddDestinationScreen: Attempting to pick image.');
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImage = picked;
          _webImage = bytes;
        });
        developer.log('AddDestinationScreen: Image picked for web: ${picked.name}');
      } else {
        setState(() {
          _pickedImage = picked;
        });
        developer.log('AddDestinationScreen: Image picked for mobile: ${picked.path}');
      }
    } else {
      developer.log('AddDestinationScreen: Image picking cancelled.');
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);
    developer.log('AddDestinationScreen: Starting reverse geocoding for: ${latLng.latitude}, ${latLng.longitude}');
    String nominatimHost;
    if (kIsWeb) {
      nominatimHost = 'http://localhost:8080';
    } else if (Platform.isAndroid) {
      nominatimHost = 'http://10.0.2.2:8080';
    } else {
      nominatimHost = 'http://localhost:8080';
    }
    final url = '$nominatimHost/nominatim/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=18&addressdetails=1';
    final String userAgent = 'jelajahin-app/1.0 (nurihsanishabrina1991@gmail.com)';
    try {
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': userAgent});
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _address = data['display_name'] ?? 'Alamat tidak ditemukan';
          _locationController.text = _address;
          _selectedLatLng = latLng;
        });
        developer.log('AddDestinationScreen: Reverse geocoding successful. Address: $_address');
      } else {
        setState(() {
          _address = 'Gagal mendapatkan alamat (Status: ${response.statusCode})';
          _locationController.text = _address;
        });
        _showSnackBar('Gagal mendapatkan alamat: ${response.statusCode}');
        developer.log('AddDestinationScreen: Reverse geocoding failed with status: ${response.statusCode}, body: ${response.body}');
      }
    } on SocketException catch (e, stackTrace) {
      if (!mounted) return;
      setState(() {
        _address = 'Koneksi ke Nominatim proxy gagal. Pastikan proxy berjalan.';
        _locationController.text = _address;
      });
      _showSnackBar('Koneksi ke server lokasi gagal. Periksa koneksi internet atau proxy.');
      developer.log('AddDestinationScreen: SocketException during reverse geocoding: $e', error: e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      if (!mounted) return;
      setState(() {
        _address = 'Error mengambil alamat: $e';
        _locationController.text = _address;
      });
      _showSnackBar('Terjadi kesalahan saat mengambil alamat: $e');
      developer.log('AddDestinationScreen: General error during reverse geocoding: $e', error: e, stackTrace: stackTrace);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
      developer.log('AddDestinationScreen: Reverse geocoding finished.');
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      _showSnackBar('Masukkan alamat untuk dicari.');
      return;
    }
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);
    developer.log('AddDestinationScreen: Starting forward geocoding for query: $query');
    String nominatimHost;
    if (kIsWeb) {
      nominatimHost = 'http://localhost:8080';
    } else if (Platform.isAndroid) {
      nominatimHost = 'http://10.0.2.2:8080';
    } else {
      nominatimHost = 'http://localhost:8080';
    }
    final url = '$nominatimHost/nominatim/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';
    final String userAgent = 'jelajahin-app/1.0 (nurihsanishabrina1991@gmail.com)';
    try {
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': userAgent});
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final newLatLng = LatLng(lat, lon);
          setState(() {
            _selectedLatLng = newLatLng;
            _address = data[0]['display_name'] ?? query;
            _locationController.text = _address;
          });
          _mapController.move(_selectedLatLng, 13.0);
          developer.log('AddDestinationScreen: Forward geocoding successful. LatLng: $_selectedLatLng, Address: $_address');
        } else {
          _showSnackBar('Alamat tidak ditemukan.');
          setState(() => _address = 'Alamat tidak ditemukan.');
          developer.log('AddDestinationScreen: Forward geocoding found no results for: $query');
        }
      } else {
        _showSnackBar('Gagal mencari alamat: ${response.statusCode}');
        developer.log('AddDestinationScreen: Forward geocoding failed with status: ${response.statusCode}, body: ${response.body}');
      }
    } on SocketException catch (e, stackTrace) {
      if (!mounted) return;
      _showSnackBar('Koneksi ke server lokasi gagal. Periksa koneksi internet atau proxy.');
      developer.log('AddDestinationScreen: SocketException during forward geocoding: $e', error: e, stackTrace: stackTrace);
    } catch (e, stackTrace) {
      if (!mounted) return;
      _showSnackBar('Error mencari alamat: $e');
      developer.log('AddDestinationScreen: General error during forward geocoding: $e', error: e, stackTrace: stackTrace);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
      developer.log('AddDestinationScreen: Forward geocoding finished.');
    }
  }
  
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<String> _uploadImageToImgbb(XFile imageFile) async {
    developer.log('AddDestinationScreen: Starting image upload to Imgbb.');
    final uri = Uri.parse('https://api.imgbb.com/1/upload');
    final request = http.MultipartRequest('POST', uri)..fields['key'] = _imgbbApiKey;
    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes('image', _webImage!, filename: imageFile.name));
      developer.log('AddDestinationScreen: Preparing web image for Imgbb upload.');
    } else {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path, filename: imageFile.name));
      developer.log('AddDestinationScreen: Preparing mobile image for Imgbb upload.');
    }
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);
      if (data['success']) {
        developer.log('AddDestinationScreen: Image uploaded successfully to Imgbb. URL: ${data['data']['url']}');
        return data['data']['url'];
      } else {
        developer.log('AddDestinationScreen: Imgbb upload failed: ${data['error']['message']}');
        throw Exception('Gagal mengunggah gambar ke Imgbb: ${data['error']['message']}');
      }
    } else {
      final errorBody = await response.stream.bytesToString();
      developer.log('AddDestinationScreen: Imgbb upload failed with status ${response.statusCode}: $errorBody');
      throw Exception('Gagal mengunggah gambar. Status: ${response.statusCode}, Respons: $errorBody');
    }
  }
  
  Future<void> _uploadDestination() async {
    developer.log('AddDestinationScreen: Attempting to upload destination.');
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Mohon lengkapi semua field yang wajib diisi.');
      developer.log('AddDestinationScreen: Form validation failed.');
      return;
    }
    if (_pickedImage == null) {
      _showSnackBar('Silakan pilih gambar terlebih dahulu.');
      developer.log('AddDestinationScreen: No image selected.');
      return;
    }
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      _showSnackBar('Silakan pilih kategori destinasi.');
      developer.log('AddDestinationScreen: No category selected.');
      return;
    }
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('Anda harus login untuk menambahkan destinasi.');
      developer.log('AddDestinationScreen: User not logged in for uploading destination.');
      return;
    }
    developer.log('AddDestinationScreen: Current user UID: ${currentUser.uid}');
    if (!mounted) return;
    setState(() => _isUploading = true);
    final String id = _uuid.v4();
    try {
      final imageUrl = await _uploadImageToImgbb(_pickedImage!);
      _showSnackBar('Gambar berhasil diunggah!');
      String ownerAvatarUrl = currentUser.photoURL ?? 'https://via.placeholder.com/150';
      if (ownerAvatarUrl.isEmpty) {
        ownerAvatarUrl = 'https://via.placeholder.com/150';
      }
      developer.log('AddDestinationScreen: Owner Avatar URL: $ownerAvatarUrl');
      await FirebaseFirestore.instance.collection('destinations').doc(id).set({
        'id': id,
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image': imageUrl,
        'latitude': _selectedLatLng.latitude,
        'longitude': _selectedLatLng.longitude,
        'rating': _overallRating,
        'category': _selectedCategory,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
        'ownerName': currentUser.displayName ?? 'Anonim',
        'ownerAvatar': ownerAvatarUrl,
        'reviews_count': 0,
        'views_count': 0,
        'likes_count': 0,
        'comments_count': 0,
      });
      if (!mounted) return;
      _showSnackBar('Destinasi berhasil disimpan di Firestore!');
      developer.log('AddDestinationScreen: Destination saved to Firestore with ID: $id');
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _pickedImage = null;
        _webImage = null;
        _nameController.clear();
        _locationController.clear();
        _descriptionController.clear();
        _overallRating = 3.0;
        _selectedLatLng = LatLng(-6.200000, 106.816666);
        _address = '';
        _selectedCategory = null;
      });
      Navigator.pop(context);
    } catch (e, stackTrace) {
      if (!mounted) return;
      String errorMessage = 'Gagal mengunggah destinasi.';
      if (e is FirebaseException) {
        errorMessage = 'Kesalahan Firebase: ${e.message}';
      } else if (e is http.ClientException) {
        errorMessage = 'Kesalahan koneksi jaringan.';
      } else {
        errorMessage = 'Terjadi kesalahan tidak terduga: $e';
      }
      _showSnackBar(errorMessage);
      developer.log('AddDestinationScreen: Error uploading destination: $e', error: e, stackTrace: stackTrace);
    } finally {
      if (mounted) setState(() => _isUploading = false);
      developer.log('AddDestinationScreen: Upload process finished.');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _locationFocusNode.dispose();
    _mapController.dispose();
    // _scrollController.dispose(); // Tidak lagi diperlukan
    super.dispose();
  }

  // =======================================================================
  // UI BARU DITERAPKAN DI SINI
  // =======================================================================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tambah Destinasi Baru'),
          centerTitle: true,
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primaryDark,
          elevation: 1.0,
        ),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                // Padding bawah untuk memberi ruang bagi tombol yang menempel
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
            // Tombol Simpan yang menempel di bagian bawah
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5)),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadDestination,
                  icon: _isUploading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Icon(Icons.cloud_upload_outlined),
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
            ),
            // Loading overlay
            if (_isUploading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.white),
                      const SizedBox(height: 16),
                      Text(
                        'Sedang mengunggah destinasi...',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER UNTUK UI MODERN ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickImage,
      child: DottedBorder(
        color: AppColors.grey,
        strokeWidth: 2,
        dashPattern: const [8, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(15),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: AppColors.lightGrey.withOpacity(0.5),
          ),
          child: _pickedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(13.0),
                  child: kIsWeb
                      ? Image.memory(_webImage!, fit: BoxFit.cover)
                      : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 50, color: AppColors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Ketuk untuk memilih gambar',
                        style: TextStyle(color: AppColors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Tempat', prefixIcon: Icon(Icons.place_outlined)),
              validator: (v) => v!.isEmpty ? 'Nama tempat wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Kategori', prefixIcon: Icon(Icons.category_outlined)),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Kategori wajib dipilih' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Deskripsi', prefixIcon: Icon(Icons.description_outlined)),
              maxLines: 4,
              validator: (v) => v!.isEmpty ? 'Deskripsi wajib diisi' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _locationController,
              focusNode: _locationFocusNode,
              decoration: InputDecoration(
                labelText: 'Cari alamat atau pilih di peta',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoadingLocation
                    ? const Padding(padding: EdgeInsets.all(10.0), child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
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
                  options: MapOptions(
                    center: _selectedLatLng,
                    zoom: 13.0,
                    onTap: (pos, p) {
                      setState(() => _selectedLatLng = p);
                      _reverseGeocode(p);
                    },
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
                          point: _selectedLatLng,
                          child: const Icon(Icons.location_on, color: AppColors.primaryDark, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _overallRating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () => setState(() => _overallRating = index + 1.0),
              );
            }),
          ),
        ),
      ),
    );
  }
}