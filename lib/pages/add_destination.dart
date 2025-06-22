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

class AddDestinationScreen extends StatefulWidget {
  const AddDestinationScreen({super.key});

  @override
  State<AddDestinationScreen> createState() => _AddDestinationScreenState();
}

class _AddDestinationScreenState extends State<AddDestinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();
  final MapController _mapController = MapController();
  double _overallRating = 3.0;
  XFile? _pickedImage;
  Uint8List? _webImage;
  LatLng _selectedLatLng = const LatLng(-6.200000, 106.816666);
  bool _isUploading = false;
  bool _isLoadingLocation = false;
  static const String _imgbbApiKey = '4000d7846dcaf738642127c07ddcfbed';
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

  Future<String> _uploadImageToImgbb(XFile imageFile) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload');
    final request = http.MultipartRequest('POST', uri)..fields['key'] = _imgbbApiKey;
    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes('image', _webImage!, filename: imageFile.name));
    } else {
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path, filename: imageFile.name));
    }
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);
      if (data['success']) {
        return data['data']['url'];
      } else {
        throw Exception('Imgbb upload failed: ${data['error']['message']}');
      }
    } else {
      final errorBody = await response.stream.bytesToString();
      throw Exception('Imgbb upload error. Status: ${response.statusCode}, Body: $errorBody');
    }
  }

  Future<void> _uploadDestination() async {
    if (!_formKey.currentState!.validate() || _pickedImage == null || _selectedCategory == null) {
      _showSnackBar('Mohon lengkapi semua data termasuk gambar dan kategori.');
      return;
    }
    
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('Anda harus login untuk menambahkan destinasi.');
      return;
    }
    
    setState(() => _isUploading = true);

    try {
      final imageUrl = await _uploadImageToImgbb(_pickedImage!);
      _showSnackBar('Gambar berhasil diunggah! Menyimpan data...');
      
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final ownerName = userDoc.data()?['name'] ?? 'Anonim';
      final ownerAvatar = userDoc.data()?['profile_picture_url'] ?? 'https://via.placeholder.com/150';
      
      final String destinationId = const Uuid().v4();

      await FirebaseFirestore.instance.collection('destinations').doc(destinationId).set({
        'id': destinationId,
        'title': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
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
  
  Future<bool> _onWillPop() async {
    if (_isUploading) {
      _showSnackBar('Tunggu proses upload selesai.');
      return false;
    }
    return true;
  }
  
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImage = picked;
          _webImage = bytes;
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
          title: const Text('Tambah Destinasi Baru'), centerTitle: true,
          backgroundColor: AppColors.white, foregroundColor: AppColors.primaryDark,
          elevation: 1.0,
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

  // --- UI WIDGETS (Dengan Perbaikan) ---
  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
      );
  
  Widget _buildImagePicker() => GestureDetector(
        onTap: _isUploading ? null : _pickImage,
        child: DottedBorder(
          color: Colors.grey, // DIUBAH: Menggunakan warna standar dari Flutter
          strokeWidth: 2, dashPattern: const [8, 4],
          borderType: BorderType.RRect, radius: const Radius.circular(15),
          child: Container(
            height: 200, width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0), color: Colors.grey.shade100), // DIUBAH
            child: _pickedImage != null
                ? ClipRRect(borderRadius: BorderRadius.circular(13.0), child: kIsWeb ? Image.memory(_webImage!, fit: BoxFit.cover) : Image.file(File(_pickedImage!.path), fit: BoxFit.cover))
                : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey), // DIUBAH
                      SizedBox(height: 12),
                      Text('Tap to select an image', style: TextStyle(color: Colors.grey, fontSize: 16)), // DIUBAH
                    ])),
          ),
        ),
      );

  Widget _buildInfoCard() => Card(
        elevation: 2, shadowColor: Colors.black.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Place Name', prefixIcon: Icon(Icons.place_outlined)), validator: (v) => v!.isEmpty ? 'Nama tempat wajib diisi' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Category is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)), maxLines: 4, validator: (v) => v!.isEmpty ? 'Deskripsi wajib diisi' : null),
          ]),
        ),
      );

  Widget _buildLocationCard() => Card(
        elevation: 2, shadowColor: Colors.black.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            TextFormField(
              controller: _locationController, focusNode: _locationFocusNode,
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
        elevation: 2, shadowColor: Colors.black.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
              backgroundColor: AppColors.lightTeal, foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
}
