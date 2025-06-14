import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'package:cloud_firestore/cloud_firestore.dart'; // For Cloud Firestore
import 'package:firebase_auth/firebase_auth.dart'; // For getting current user UID
import 'package:flutter_map/flutter_map.dart'; // For OpenStreetMap integration
import 'package:latlong2/latlong.dart'; // For LatLng
import 'package:http/http.dart' as http; // For Nominatim reverse geocoding
import 'package:uuid/uuid.dart'; // For generating unique IDs
import '../theme/colors.dart'; // Ensure this path is correct for your AppColors

class AddDestinationScreen extends StatefulWidget {
  const AddDestinationScreen({super.key});

  @override
  State<AddDestinationScreen> createState() => _AddDestinationScreenState();
}

class _AddDestinationScreenState extends State<AddDestinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tagsController = TextEditingController(); // New controller for tags
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  double _overallRating = 3.0; // Star rating (1-5), can be decimal

  XFile? _pickedImage; // Image picked by ImagePicker
  Uint8List? _webImage; // Bytes for web image display
  LatLng _selectedLatLng = LatLng(-6.200000, 106.816666); // Default to Jakarta coordinates
  String _address = ''; // Address obtained from reverse geocoding or search

  bool _isUploading = false; // New state to show loading indicator
  bool _isLoadingLocation = false; // New state for location search

  final MapController _mapController = MapController(); // Controller for FlutterMap

  // Variabel untuk ScrollController
  late ScrollController _scrollController;
  bool _isScrolled = false; // Akan jadi true jika sudah discroll ke bawah

  @override
  void initState() {
    super.initState();
    // Inisialisasi ScrollController
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      // Perbarui _isScrolled jika offset berubah
      setState(() {
        _isScrolled = _scrollController.offset > 0;
      });
    });

    // Initial reverse geocode for the default location
    _reverseGeocode(_selectedLatLng);
  }

  // Fungsi untuk menangani tombol back perangkat/sistem
  Future<bool> _onWillPop() async {
    // Anda bisa menambahkan logika konfirmasi di sini
    // Misalnya, menampilkan dialog "Apakah Anda yakin ingin keluar tanpa menyimpan?"
    // Untuk saat ini, kita biarkan langsung kembali
    return true; // Mengizinkan navigasi kembali
  }

  // Function to pick an image from gallery
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        // Handle web image picking by reading bytes
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImage = picked;
          _webImage = bytes;
        });
      } else {
        // Handle mobile image picking
        setState(() {
          _pickedImage = picked;
        });
      }
    }
  }

  // Function to reverse geocode LatLng to address using Nominatim (OpenStreetMap)
  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() {
      _isLoadingLocation = true;
    });
    // Gunakan URL proxy lokal jika ada, atau kembalikan ke Nominatim OSM langsung jika ingin
    // Pastikan server proxy lokal (localhost:8080) berjalan.
    final url =
        'http://localhost:8080/nominatim/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=18&addressdetails=1';
    // Atau gunakan ini jika ingin langsung ke Nominatim OSM (perlu cek CORS di web)
    // final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=18&addressdetails=1';

    try {
      final response =
          await http.get(Uri.parse(url), headers: {'User-Agent': 'jelajahin-app/1.0 (nurihsanishabrina1991@gmail.com)'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _address = data['display_name'] ?? '';
          _locationController.text = _address; // Update location text field
          _selectedLatLng = latLng; // Ensure _selectedLatLng is updated if map was tapped
        });
      } else {
        setState(() {
          _address = 'Alamat tidak ditemukan (Status: ${response.statusCode})';
          _locationController.text = _address;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mendapatkan alamat: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _address = 'Gagal mengambil alamat: $e';
        _locationController.text = _address;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error mengambil alamat: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // Function to search for an address using Nominatim (OpenStreetMap)
  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoadingLocation = true;
    });

    // Gunakan URL proxy lokal jika ada, atau kembalikan ke Nominatim OSM langsung jika ingin
    // Pastikan server proxy lokal (localhost:8080) berjalan.
    final url =
        'http://localhost:8080/nominatim/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';
    // Atau gunakan ini jika ingin langsung ke Nominatim OSM (perlu cek CORS di web)
    // final url = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';

    try {
      final response =
          await http.get(Uri.parse(url), headers: {'User-Agent': 'jelajahin-app/1.0 (nurihsanishabrina1991@gmail.com)'});
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
          _mapController.move(_selectedLatLng, 13.0); // Move map to new location
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Alamat tidak ditemukan.')),
            );
          }
          setState(() {
            _address = 'Alamat tidak ditemukan.';
            _locationController.text = _address;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mencari alamat: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error mencari alamat: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // Function to upload destination data to Firebase Storage and Firestore
  Future<void> _uploadDestination() async {
    if (!_formKey.currentState!.validate()) {
      return; // If form validation fails, stop
    }

    if (_pickedImage == null) {
      // Show a snackbar if no image is picked
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih gambar terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _isUploading = true; // Show loading indicator
    });

    final String id = const Uuid().v4(); // Generate a unique ID for the destination
    final String fileName = 'destinations/$id.jpg'; // Path in Firebase Storage

    try {
      // Upload image to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(fileName);
      if (kIsWeb) {
        await ref.putData(_webImage!); // Use putData for web
      } else {
        await ref.putFile(File(_pickedImage!.path)); // Use putFile for mobile
      }

      final imageUrl = await ref.getDownloadURL(); // Get the public URL of the uploaded image

      // Process tags
      final List<String> tags = _tagsController.text
          .split('#')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // Save destination data to Cloud Firestore
      await FirebaseFirestore.instance.collection('destinations').doc(id).set({
        'id': id,
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image': imageUrl,
        'lat': _selectedLatLng.latitude,
        'lng': _selectedLatLng.longitude,
        'rating': _overallRating,
        'tags': tags, // Save tags as a list
        'createdAt': FieldValue.serverTimestamp(), // Timestamp of creation
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous', // User who added the destination
        'reviews': 0, // Initial reviews count for new destinations
        'views': 0, // Initial views count for new destinations
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Destinasi berhasil diunggah!')),
        );
        // Clear all fields after successful upload
        setState(() {
          _pickedImage = null;
          _webImage = null;
          _nameController.clear();
          _tagsController.clear(); // Clear tags field
          _locationController.clear();
          _descriptionController.clear();
          _overallRating = 3.0;
          _selectedLatLng = LatLng(-6.200000, 106.816666); // Reset map center
          _address = '';
        });
        Navigator.pop(context); // Go back to the previous screen (e.g., Home)
      }
    } catch (e) {
      // Handle any errors during upload or Firestore operation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah destinasi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _tagsController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _mapController.dispose();
    _scrollController.dispose(); // Dispose ScrollController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // <-- Added _onWillPop
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor:
              _isScrolled ? AppColors.darkTeal : AppColors.white, // <-- Background color changes
          elevation: 0,
          leading: BackButton(
            color: _isScrolled ? AppColors.white : AppColors.primaryDark, // <-- Back button color changes
          ),
          title: Text(
            'Tambah Destinasi', // <-- Title text added
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isScrolled ? Colors.white : AppColors.primaryDark, // <-- Title color changes
                ),
          ),
          centerTitle: true,
        ),
        body: _isUploading
            ? Center(child: CircularProgressIndicator(color: AppColors.lightTeal)) // Show loading indicator
            : SingleChildScrollView(
                controller: _scrollController, // <-- Kaitkan ScrollController di sini
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Image Picker Section
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                                  child: Icon(Icons.add_photo_alternate,
                                      size: 60, color: AppColors.primaryDark),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Destination Name Input
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Tempat',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Nama tempat wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      // Tags Input
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tag (pisahkan dengan #)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Tag wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      // Location Input (now editable for search)
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Cari Alamat atau pilih di peta',
                          border: const OutlineInputBorder(),
                          suffixIcon: _isLoadingLocation
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
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
                        onFieldSubmitted: (value) {
                          _searchAddress(value); // Trigger search on submit
                        },
                      ),
                      const SizedBox(height: 12),
                      // Map Section for Location Selection
                      SizedBox(
                        height: 230,
                        child: FlutterMap(
                          mapController: _mapController, // Assign the controller
                          options: MapOptions(
                            center: _selectedLatLng,
                            zoom: 13.0,
                            onTap: (tapPosition, point) {
                              // On map tap, update selected LatLng and reverse geocode
                              setState(() {
                                _selectedLatLng = point;
                              });
                              _reverseGeocode(point);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                      const SizedBox(height: 16),
                      // Description Input
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Singkat',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) =>
                            value!.isEmpty ? 'Deskripsi wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // Overall Rating (Stars)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Nilai keseluruhan tempat ini (1-5 Bintang)"),
                          Row(
                            children: List.generate(5, (index) {
                              return IconButton(
                                icon: Icon(
                                  index < _overallRating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _overallRating = index + 1.0;
                                  });
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _uploadDestination, // Disable button while uploading
                        icon: _isUploading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isUploading ? 'Mengunggah...' : 'Simpan Destinasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}