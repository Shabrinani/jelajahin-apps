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
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ticketPriceController = TextEditingController();
  final _openingHoursController = TextEditingController();

  int _recommendationRating = 5; // A rating from 1-10 (your custom rating)
  double _overallRating = 3; // Star rating (1-5) for display on home page
  String? _accessType; // Selected access type

  XFile? _pickedImage; // Image picked by ImagePicker
  Uint8List? _webImage; // Bytes for web image display
  LatLng _selectedLatLng = LatLng(-6.200000, 106.816666); // Default to Jakarta coordinates
  String _address = ''; // Address obtained from reverse geocoding

  bool _isUploading = false; // New state to show loading indicator

  final List<String> _accessOptions = ['Jalan Kaki', 'Motor', 'Mobil']; // Access type options

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
    // Nominatim API endpoint for reverse geocoding
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}';
    try {
      // Make HTTP GET request with a User-Agent header (required by Nominatim)
      final response =
          await http.get(Uri.parse(url), headers: {'User-Agent': 'jelajahin-app'});
      if (response.statusCode == 200) {
        // Decode JSON response
        final data = json.decode(response.body);
        setState(() {
          // Extract display_name as the address, or empty string if not found
          _address = data['display_name'] ?? '';
          _locationController.text = _address; // Update location text field
        });
      } else {
        // Handle HTTP error
        setState(() {
          _address = 'Alamat tidak ditemukan (Status: ${response.statusCode})';
          _locationController.text = _address;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to get address: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      // Handle network or other errors
      setState(() {
        _address = 'Gagal mengambil alamat: $e';
        _locationController.text = _address;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting address: $e')),
        );
      }
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

      // Save destination data to Cloud Firestore
      await FirebaseFirestore.instance.collection('destinations').doc(id).set({
        'id': id,
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image': imageUrl, // Changed from 'imageUrl' to 'image' for consistency with HomeContentPage
        'lat': _selectedLatLng.latitude,
        'lng': _selectedLatLng.longitude,
        'recommendationRating': _recommendationRating, // Keep this as a new custom field
        'rating': _overallRating, // Changed from 'overallRating' to 'rating' for consistency with HomeContentPage
        'ticketPrice': _ticketPriceController.text.trim(),
        'accessType': _accessType,
        'openingHours': _openingHoursController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), // Timestamp of creation
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous', // User who added the destination
        'reviews': 0, // Initial reviews count for new destinations (consistent with HomeContentPage expectations)
        'views': 0, // Initial views count for new destinations (consistent with HomeContentPage expectations for 'Most Viewed')
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
          _locationController.clear();
          _descriptionController.clear();
          _ticketPriceController.clear();
          _openingHoursController.clear();
          _accessType = null;
          _recommendationRating = 5;
          _overallRating = 3;
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
    _locationController.dispose();
    _descriptionController.dispose();
    _ticketPriceController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Tambah Destinasi'),
        elevation: 1,
      ),
      body: _isUploading
          ? Center(child: CircularProgressIndicator(color: AppColors.lightTeal)) // Show loading indicator
          : SingleChildScrollView(
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
                    // Location Input (read-only, populated by map)
                    TextFormField(
                      controller: _locationController,
                      readOnly: true, // Location is picked from map
                      decoration: const InputDecoration(
                        labelText: 'Alamat',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Lokasi wajib dipilih di peta' : null,
                    ),
                    const SizedBox(height: 12),
                    // Map Section for Location Selection
                    SizedBox(
                      height: 230,
                      child: FlutterMap(
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

                    // Recommendation Rating (1-10) Slider
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Seberapa merekomendasikan tempat ini? (1–10)"),
                        Slider(
                          value: _recommendationRating.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9, // 1 to 10 has 9 divisions
                          label: '$_recommendationRating',
                          onChanged: (value) {
                            setState(() {
                              _recommendationRating = value.toInt();
                            });
                          },
                          activeColor: AppColors.lightTeal,
                          inactiveColor: Colors.grey[300],
                        ),
                      ],
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
                    const SizedBox(height: 16),

                    // Ticket Price Input (Optional)
                    TextFormField(
                      controller: _ticketPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Harga Tiket Masuk (opsional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Access Type Dropdown (Optional)
                    DropdownButtonFormField<String>(
                      value: _accessType,
                      hint: const Text('Pilih Tipe Akses (opsional)'),
                      items: _accessOptions
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _accessType = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Tipe Akses (opsional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Opening Hours Input (Optional, with TimePicker)
                    TextFormField(
                      controller: _openingHoursController,
                      readOnly: true, // Time picked from time picker
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.lightTeal, // Header background color
                                  onPrimary: AppColors.white, // Header text color
                                  onSurface: AppColors.primaryDark, // Body text color
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.darkTeal, // Button text color
                                  ),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          _openingHoursController.text = picked.format(context);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Jam Buka (opsional)',
                        border: OutlineInputBorder(),
                      ),
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
    );
  }
}
