// jelajahin_apps/pages/edit_destination_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart'; // Make sure this is imported
import 'package:latlong2/latlong.dart'; // Make sure this is imported
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:dotted_border/dotted_border.dart';
import 'package:jelajahin_apps/services/firestore_service.dart';
import '../theme/colors.dart'; // Adjust path if different

class EditDestinationPage extends StatefulWidget {
  final String destinationId;

  const EditDestinationPage({super.key, required this.destinationId});

  @override
  State<EditDestinationPage> createState() => _EditDestinationPageState();
}

class _EditDestinationPageState extends State<EditDestinationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  final FocusNode _locationFocusNode = FocusNode();
  final MapController _mapController = MapController();

  String? _selectedCategory;
  double _overallRating = 3.0; // Default rating
  XFile? _pickedImage; // Gambar baru yang dipilih dari galeri
  Uint8List? _webImageBytes; // Byte gambar baru untuk web
  Uint8List? _currentImageDataBytes; // Byte gambar yang sudah ada dari Firestore

  LatLng _selectedLatLng = const LatLng(-6.200000, 106.816666); // Default Jakarta
  bool _isSaving = false;
  bool _isFetchingData = true;
  bool _isLoadingLocation = false;

  // static const String _imgbbApiKey = '4000d7846dcaf738642127c07ddcfbed'; // Tidak lagi digunakan

  final List<String> _categories = [
    'Restaurant', 'History', 'Nature', 'Museum', 'Beach',
    'Mountain', 'City', 'Shopping', 'Art',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _locationController = TextEditingController();
    _descriptionController = TextEditingController();

    _locationFocusNode.addListener(() {
      if (!_locationFocusNode.hasFocus && _locationController.text.isNotEmpty) {
        _searchAddress(_locationController.text);
      }
    });

    _fetchAndSetInitialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _locationFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndSetInitialData() async {
    try {
      final docSnapshot =
          await _firestoreService.getDestinationById(widget.destinationId);

      if (docSnapshot.exists && mounted) {
        final data = docSnapshot.data() as Map<String, dynamic>;

        _titleController.text = data['title'] ?? '';
        _locationController.text = data['location'] ?? '';
        _descriptionController.text = data['description'] ?? '';

        // Ambil imageData sebagai List<dynamic> dari Firestore
        final List<dynamic>? imageDataList = data['imageData'] as List<dynamic>?;
        if (imageDataList != null && imageDataList.isNotEmpty) {
          try {
            _currentImageDataBytes = Uint8List.fromList(imageDataList.cast<int>());
          } catch (e) {
            developer.log('Error casting imageData to Uint8List in fetch: $e');
            _currentImageDataBytes = null;
          }
        }

        final initialCategory = data['category'];
        if (initialCategory != null && _categories.contains(initialCategory)) {
          _selectedCategory = initialCategory;
        }

        final initialLatitude = data['latitude'] as double?;
        final initialLongitude = data['longitude'] as double?;
        if (initialLatitude != null && initialLongitude != null) {
          _selectedLatLng = LatLng(initialLatitude, initialLongitude);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(_selectedLatLng, 13.0);
          });
        } else {
          _searchAddress(_locationController.text);
        }

        _overallRating = (data['rating'] as num?)?.toDouble() ?? 3.0;
      }
    } catch (e) {
      developer.log('Error fetching destination data: $e');
      if (mounted) {
        _showSnackBar('Gagal memuat data destinasi: $e', isError: true); // Pesan BH
      }
    } finally {
      if (mounted) setState(() => _isFetchingData = false);
    }
  }

  // Fungsi upload gambar ImgBB dihapus atau dikomentari
  // Future<String> _uploadImageToImgbb(XFile imageFile) async { ... }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Mohon lengkapi semua kolom yang wajib diisi.'); // Pesan BH
      return;
    }

    // Tentukan byte gambar yang akan disimpan
    Uint8List? imageDataToSave;
    if (_pickedImage != null) {
      // Jika gambar baru dipilih
      if (kIsWeb) {
        imageDataToSave = _webImageBytes;
      } else {
        imageDataToSave = await _pickedImage!.readAsBytes();
      }

      // Validasi ukuran gambar jika ada gambar baru
      if (imageDataToSave != null && imageDataToSave.lengthInBytes > 1 * 1024 * 1024) {
        _showSnackBar('Ukuran gambar terlalu besar (maks 1MB). Mohon pilih gambar yang lebih kecil.', isError: true);
        setState(() => _isSaving = false);
        return;
      }
    } else {
      // Jika tidak ada gambar baru dipilih, gunakan gambar yang sudah ada (jika ada)
      imageDataToSave = _currentImageDataBytes;
    }

    // Jika tidak ada gambar sama sekali
    if (imageDataToSave == null || imageDataToSave.isEmpty) {
      _showSnackBar('Mohon pilih gambar untuk destinasi ini.'); // Pesan BH
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dataToUpdate = {
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageData': imageDataToSave.toList(), // Simpan byte gambar
        'latitude': _selectedLatLng.latitude,
        'longitude': _selectedLatLng.longitude,
        'rating': _overallRating,
        'category': _selectedCategory,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestoreService.updateDestination(widget.destinationId, dataToUpdate);

      if (!mounted) return;
      _showSnackBar('Postingan berhasil diperbarui!'); // Pesan BH
      Navigator.pop(context);
    } catch (e) {
      developer.log('Error updating destination: $e');
      if (mounted) {
        _showSnackBar('Gagal memperbarui destinasi: ${e.toString()}', isError: true); // Pesan BH
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}';
    try {
      final response = await http.get(Uri.parse(url),
          headers: {'User-Agent': 'jelajahin-app/1.0'});
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _locationController.text = data['display_name'] ?? 'Alamat tidak ditemukan'; // Pesan BH
          _selectedLatLng = latLng;
        });
      }
    } catch (e) {
      _showSnackBar('Gagal mendapatkan alamat.', isError: true); // Pesan BH
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);
    final url =
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';
    try {
      final response = await http.get(Uri.parse(url),
          headers: {'User-Agent': 'jelajahin-app/1.0'});
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
          _showSnackBar('Alamat tidak ditemukan.'); // Pesan BH
        }
      }
    } catch (e) {
      _showSnackBar('Error mencari alamat: $e', isError: true); // Pesan BH
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSaving) {
      _showSnackBar('Mohon tunggu proses penyimpanan selesai.'); // Pesan BH
      return false;
    }
    return true;
  }

  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImage = picked;
          _webImageBytes = bytes; // Ini akan digunakan jika dipilih gambar baru di web
          _currentImageDataBytes = null; // Hapus gambar lama jika ada gambar baru dipilih
        });
      } else {
        setState(() {
          _pickedImage = picked;
          _currentImageDataBytes = null; // Hapus gambar lama jika ada gambar baru dipilih
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Destinasi',
              style: TextStyle(
                  color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 20)), // Font disesuaikan
          centerTitle: true,
          backgroundColor: AppColors.white,
          elevation: 1.0,
          foregroundColor: AppColors.primaryDark,
          leading: IconButton( // Tombol kembali disesuaikan
            icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.primaryDark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isFetchingData
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) // Warna loading
            : Stack(
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

  // --- UI WIDGETS (Disempurnakan dan Diterjemahkan) ---
  Widget _buildSectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark)),
      );

  Widget _buildImagePicker() => GestureDetector(
        onTap: _isSaving ? null : _pickImage,
        child: DottedBorder(
          color: Colors.grey,
          strokeWidth: 2,
          dashPattern: const [8, 4],
          borderType: BorderType.RRect,
          radius: const Radius.circular(15),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: Colors.grey.shade100),
            child: (_pickedImage != null)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13.0),
                    child: kIsWeb
                        ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                        : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                  )
                : (_currentImageDataBytes != null && _currentImageDataBytes!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13.0),
                        child: Image.memory(
                          _currentImageDataBytes!, // Menampilkan gambar dari byte yang sudah ada
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text('Gagal memuat gambar', style: TextStyle(color: Colors.grey)),
                                  Text('Ketuk untuk memilih gambar baru', style: TextStyle(color: Colors.grey))
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  size: 50, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('Ketuk untuk memilih gambar',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16)),
                            ]))),
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
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'Nama Tempat', // Diterjemahkan
                    prefixIcon: Icon(Icons.place_outlined)),
                validator: (v) =>
                    v!.isEmpty ? 'Nama tempat wajib diisi' : null), // Diterjemahkan
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                  labelText: 'Kategori', // Diterjemahkan
                  prefixIcon: Icon(Icons.category_outlined)),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Kategori wajib diisi' : null, // Diterjemahkan
            ),
            const SizedBox(height: 16),
            TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Deskripsi', // Diterjemahkan
                    prefixIcon: Icon(Icons.description_outlined)),
                maxLines: 4,
                validator: (v) =>
                    v!.isEmpty ? 'Deskripsi wajib diisi' : null), // Diterjemahkan
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
                labelText: 'Cari alamat atau pilih di peta', // Diterjemahkan
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoadingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
              ),
              onFieldSubmitted: (v) => _searchAddress(v),
              validator: (v) =>
                  v!.isEmpty ? 'Lokasi wajib diisi' : null, // Diterjemahkan
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
                      onTap: (pos, p) => _reverseGeocode(p)),
                  children: [
                    TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.jelajahin_apps'),
                    MarkerLayer(markers: [
                      Marker(
                          point: _selectedLatLng,
                          child: const Icon(Icons.location_on,
                              color: AppColors.primaryDark, size: 40))
                    ]),
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
                icon: Icon(
                    index < _overallRating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 36),
                onPressed:
                    _isSaving ? null : () => setState(() => _overallRating = index + 1.0),
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
            onPressed: _isSaving ? null : _saveChanges,
            icon: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child:
                        CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Perubahan'), // Diterjemahkan
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