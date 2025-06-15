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

// Pastikan path ini benar untuk AppColors Anda
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

  // FocusNode untuk mendeteksi kapan input lokasi selesai diisi
  final FocusNode _locationFocusNode = FocusNode();

  double _overallRating = 3.0; // Default rating

  XFile? _pickedImage; // Untuk menyimpan file gambar yang dipilih
  Uint8List? _webImage; // Untuk menyimpan byte gambar jika di web

  // Koordinat default (Jakarta)
  LatLng _selectedLatLng = LatLng(-6.200000, 106.816666);
  String _address = ''; // Alamat hasil geocoding

  bool _isUploading = false; // Status upload ke Imgbb dan Firebase
  bool _isLoadingLocation = false; // Status loading untuk geocoding

  final MapController _mapController = MapController(); // Controller untuk FlutterMap

  late ScrollController _scrollController;
  bool _isScrolled = false; // Untuk efek app bar saat scroll

  final Uuid _uuid = const Uuid(); // Instansiasi Uuid untuk ID unik

  // API Key Imgbb - Ganti dengan API Key Anda yang sebenarnya
  static const String _imgbbApiKey = '4000d7846dcaf738642127c07ddcfbed';

  // Variabel baru untuk kategori
  String? _selectedCategory; // Kategori yang dipilih
  final List<String> _categories = [
    'Restaurant',
    'History',
    'Nature',
    'Museum',
    'Beach',
    'Mountain',
    'City',
    'Shopping',
    'Art',
  ]; // Daftar kategori yang tersedia

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 0;
      });
    });

    // Listener untuk mendeteksi perubahan fokus pada input lokasi
    _locationFocusNode.addListener(() {
      if (!_locationFocusNode.hasFocus && _locationController.text.isNotEmpty) {
        // Jika fokus hilang dari input lokasi dan teks tidak kosong, coba cari
        developer.log('AddDestinationScreen: Location field unfocused, searching for: ${_locationController.text}');
        _searchAddress(_locationController.text);
      }
    });

    // Lakukan reverse geocode untuk lokasi default saat inisialisasi
    _reverseGeocode(_selectedLatLng);
  }

  // Handle ketika user mencoba keluar dari halaman (misal dengan tombol back)
  Future<bool> _onWillPop() async {
    if (_isUploading) {
      // Jika sedang mengunggah, berikan konfirmasi atau cegah keluar
      _showSnackBar('Tunggu proses upload selesai.');
      return false; // Cegah keluar
    }
    return true; // Izinkan keluar
  }

  // Fungsi untuk memilih gambar dari galeri
  Future<void> _pickImage() async {
    developer.log('AddDestinationScreen: Attempting to pick image.');
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        // Jika platform web, baca sebagai bytes
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImage = picked;
          _webImage = bytes;
        });
        developer.log('AddDestinationScreen: Image picked for web: ${picked.name}');
      } else {
        // Untuk mobile/desktop, gunakan File
        setState(() {
          _pickedImage = picked;
        });
        developer.log('AddDestinationScreen: Image picked for mobile: ${picked.path}');
      }
    } else {
      developer.log('AddDestinationScreen: Image picking cancelled.');
    }
  }

  // Fungsi untuk mendapatkan alamat dari koordinat (Reverse Geocoding)
  Future<void> _reverseGeocode(LatLng latLng) async {
    if (!mounted) return; // Pastikan widget masih ada

    setState(() {
      _isLoadingLocation = true;
    });
    developer.log('AddDestinationScreen: Starting reverse geocoding for: ${latLng.latitude}, ${latLng.longitude}');

    // Menentukan host Nominatim berdasarkan platform
    String nominatimHost;
    if (kIsWeb) {
      nominatimHost = 'http://localhost:8080'; // Untuk development web
    } else if (Platform.isAndroid) {
      nominatimHost = 'http://10.0.2.2:8080'; // Untuk Android emulator
    } else {
      nominatimHost = 'http://localhost:8080'; // Untuk iOS simulator atau desktop
    }

    final url = '$nominatimHost/nominatim/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=18&addressdetails=1';
    final String userAgent = 'jelajahin-app/1.0 (nurihsanishabrina1991@gmail.com)';

    try {
      final response = await http.get(Uri.parse(url), headers: {'User-Agent': userAgent});
      if (!mounted) return; // Cek mounted lagi setelah async call

      if (response.statusCode == 200) {
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
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
      });
      developer.log('AddDestinationScreen: Reverse geocoding finished.');
    }
  }

  // Fungsi untuk mencari koordinat dari alamat (Geocoding)
  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      _showSnackBar('Masukkan alamat untuk dicari.');
      return;
    }
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
    });
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
          _mapController.move(_selectedLatLng, 13.0); // Pindahkan peta ke lokasi baru
          developer.log('AddDestinationScreen: Forward geocoding successful. LatLng: $_selectedLatLng, Address: $_address');
        } else {
          _showSnackBar('Alamat tidak ditemukan.');
          setState(() {
            _address = 'Alamat tidak ditemukan.';
            _locationController.text = _address;
          });
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
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
      });
      developer.log('AddDestinationScreen: Forward geocoding finished.');
    }
  }

  // Fungsi untuk menampilkan SnackBar
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Fungsi untuk mengunggah gambar ke Imgbb API
  Future<String> _uploadImageToImgbb(XFile imageFile) async {
    developer.log('AddDestinationScreen: Starting image upload to Imgbb.');
    final uri = Uri.parse('https://api.imgbb.com/1/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['key'] = _imgbbApiKey;

    // Tambahkan file gambar ke request
    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        _webImage!,
        filename: imageFile.name,
      ));
      developer.log('AddDestinationScreen: Preparing web image for Imgbb upload.');
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: imageFile.name,
      ));
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

  // Fungsi utama untuk mengunggah destinasi ke Firebase (dan gambar ke Imgbb)
  Future<void> _uploadDestination() async {
    developer.log('AddDestinationScreen: Attempting to upload destination.');

    // 1. Validasi Form
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Mohon lengkapi semua field yang wajib diisi.');
      developer.log('AddDestinationScreen: Form validation failed.');
      return;
    }

    // 2. Validasi Gambar
    if (_pickedImage == null) {
      _showSnackBar('Silakan pilih gambar terlebih dahulu.');
      developer.log('AddDestinationScreen: No image selected.');
      return;
    }

    // 3. Validasi Kategori
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      _showSnackBar('Silakan pilih kategori destinasi.');
      developer.log('AddDestinationScreen: No category selected.');
      return;
    }

    // 4. Validasi Otentikasi Pengguna
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('Anda harus login untuk menambahkan destinasi.');
      developer.log('AddDestinationScreen: User not logged in for uploading destination.');
      // Opsi: Jika Anda ingin mengarahkan pengguna ke halaman login:
      // Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    developer.log('AddDestinationScreen: Current user UID: ${currentUser.uid}');

    if (!mounted) return;
    setState(() {
      _isUploading = true;
    });

    final String id = _uuid.v4(); // ID unik untuk dokumen

    try {
      // 5. Unggah Gambar ke Imgbb API
      final imageUrl = await _uploadImageToImgbb(_pickedImage!);
      _showSnackBar('Gambar berhasil diunggah ke Imgbb!');

      // Tentukan avatar pengguna. Gunakan photoURL dari Firebase Auth,
      // atau placeholder jika photoURL null/kosong.
      // Anda bisa mengganti placeholder ini dengan URL gambar default yang Anda inginkan.
      String ownerAvatarUrl = currentUser.photoURL ?? 'https://via.placeholder.com/150'; // Default placeholder
      if (ownerAvatarUrl.isEmpty) { // Jika photoURL kosong string
         ownerAvatarUrl = 'https://via.placeholder.com/150'; // Default placeholder lagi
      }
      developer.log('AddDestinationScreen: Owner Avatar URL: $ownerAvatarUrl');


      // 6. Simpan Data Destinasi ke Cloud Firestore
      await FirebaseFirestore.instance.collection('destinations').doc(id).set({
        'id': id,
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image': imageUrl, // URL gambar dari Imgbb
        'latitude': _selectedLatLng.latitude,
        'longitude': _selectedLatLng.longitude,
        'rating': _overallRating,
        'category': _selectedCategory,
        'createdAt': FieldValue.serverTimestamp(), // Timestamp saat dokumen dibuat
        'userId': currentUser.uid, // <-- Perbaikan: Menggunakan 'userId'
        'ownerName': currentUser.displayName ?? 'Anonim',
        'ownerAvatar': ownerAvatarUrl, // Menggunakan URL avatar yang sudah di-handle
        // Inisialisasi counters
        'reviews_count': 0,
        'views_count': 0,
        'likes_count': 0,
        'comments_count': 0,
      });

      if (!mounted) return;
      _showSnackBar('Destinasi berhasil disimpan di Firestore!');
      developer.log('AddDestinationScreen: Destination saved to Firestore with ID: $id');

      // Tambahkan delay agar SnackBar terlihat sebelum navigasi
      await Future.delayed(const Duration(seconds: 2));

      // 7. Reset Form dan Kembali ke Halaman Sebelumnya
      setState(() {
        _pickedImage = null;
        _webImage = null;
        _nameController.clear();
        _locationController.clear();
        _descriptionController.clear();
        _overallRating = 3.0;
        _selectedLatLng = LatLng(-6.200000, 106.816666); // Reset ke default Jakarta
        _address = ''; // Reset alamat
        _selectedCategory = null; // Reset kategori yang dipilih
      });
      Navigator.pop(context); // Kembali ke halaman sebelumnya
    } catch (e, stackTrace) {
      if (!mounted) return;
      String errorMessage = 'Gagal mengunggah destinasi.';
      if (e is FirebaseException) {
        if (e.code == 'permission-denied' || e.code == 'unauthorized') {
          errorMessage = 'Akses ditolak. Pastikan Anda memiliki izin yang cukup (sudah login).';
        } else if (e.code == 'unavailable') {
          errorMessage = 'Layanan Firebase tidak tersedia. Periksa koneksi internet Anda.';
        } else {
          errorMessage = 'Kesalahan Firebase: ${e.message}';
        }
      } else if (e is http.ClientException) {
        errorMessage = 'Kesalahan koneksi jaringan. Pastikan Anda terhubung ke internet dan proxy Nominatim berjalan.';
      } else {
        errorMessage = 'Terjadi kesalahan tidak terduga: $e';
      }
      _showSnackBar(errorMessage);
      developer.log('AddDestinationScreen: Error uploading destination: $e', error: e, stackTrace: stackTrace);
    } finally {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
      developer.log('AddDestinationScreen: Upload process finished.');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _locationFocusNode.dispose(); // Jangan lupa dispose FocusNode
    _mapController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: _isScrolled ? AppColors.darkTeal : AppColors.white,
          elevation: 0,
          leading: BackButton(
            color: _isScrolled ? AppColors.white : AppColors.primaryDark,
          ),
          title: Text(
            'Tambah Destinasi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isScrolled ? Colors.white : AppColors.primaryDark,
                ),
          ),
          centerTitle: true,
        ),
        body: _isUploading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.lightTeal),
                    const SizedBox(height: 16),
                    Text(
                      'Sedang mengunggah destinasi...',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Agar elemen mengisi lebar
                    children: [
                      // Bagian Pemilih Gambar
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[200], // Warna background jika belum ada gambar
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(12),
                            image: _pickedImage != null
                                ? DecorationImage(
                                    image: kIsWeb
                                        ? MemoryImage(_webImage!)
                                        : FileImage(File(_pickedImage!.path))
                                            as ImageProvider,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _pickedImage == null
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate,
                                          size: 60, color: AppColors.primaryDark),
                                      Text('Ketuk untuk memilih gambar',
                                          style: TextStyle(color: AppColors.primaryDark)),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Input Nama Destinasi
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Tempat',
                          hintText: 'Misal: Pantai Kuta, Gunung Bromo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.place),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Nama tempat wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // DROPDOWN KATEGORI BARU
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori Destinasi',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        hint: const Text('Pilih Kategori'),
                        items: _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                          developer.log('AddDestinationScreen: Selected category: $newValue');
                        },
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Kategori wajib dipilih' : null,
                      ),
                      const SizedBox(height: 16),

                      // Input Lokasi dengan Fitur Search dan Map
                      TextFormField(
                        controller: _locationController,
                        focusNode: _locationFocusNode, // Kaitkan FocusNode
                        decoration: InputDecoration(
                          labelText: 'Cari Alamat atau pilih di peta',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_on),
                          suffixIcon: _isLoadingLocation
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryDark,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: () {
                                    _searchAddress(_locationController.text);
                                  },
                                ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Lokasi wajib diisi' : null,
                        // onFieldSubmitted akan memicu _searchAddress saat enter/done ditekan
                        onFieldSubmitted: (value) {
                          _searchAddress(value);
                          _locationFocusNode.unfocus(); // Sembunyikan keyboard setelah submit
                        },
                      ),
                      const SizedBox(height: 12),

                      // Bagian Peta untuk Seleksi Lokasi
                      SizedBox(
                        height: 230,
                        child: ClipRRect(
                          // Tambahkan ClipRRect untuk border radius
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              center: _selectedLatLng,
                              zoom: 13.0,
                              onTap: (tapPosition, point) {
                                setState(() {
                                  _selectedLatLng = point;
                                });
                                developer.log('AddDestinationScreen: Map tapped. New LatLng: $point');
                                _reverseGeocode(point); // Update alamat saat peta diketuk
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
                                    child: const Icon(Icons.location_on,
                                        color: AppColors.primaryDark, size: 40),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Input Deskripsi
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Singkat',
                          hintText: 'Ceritakan singkat tentang destinasi ini...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) =>
                            value!.isEmpty ? 'Deskripsi wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // Input Rating Keseluruhan (Bintang)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Nilai keseluruhan tempat ini (1-5 Bintang)",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              return IconButton(
                                icon: Icon(
                                  index < _overallRating ? Icons.star : Icons.star_border,
                                  color: Colors.amber, // Warna bintang kuning
                                  size: 30,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _overallRating = index + 1.0;
                                  });
                                  developer.log('AddDestinationScreen: Rating set to: $_overallRating');
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tombol Simpan Destinasi
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadDestination, // Nonaktifkan saat upload
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save), // Ubah ikon menjadi save
                        label: Text(_isUploading ? 'Mengunggah...' : 'Simpan Destinasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 20), // Tambahkan sedikit padding di bawah tombol
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}