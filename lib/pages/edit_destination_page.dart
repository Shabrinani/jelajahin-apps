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
  XFile? _pickedImage;
  Uint8List? _webImage;
  String? _currentImageUrl; // For storing the existing image URL

  LatLng _selectedLatLng = const LatLng(-6.200000, 106.816666); // Default Jakarta
  bool _isSaving = false;
  bool _isFetchingData = true;
  bool _isLoadingLocation = false;

  static const String _imgbbApiKey = '4000d7846dcaf738642127c07ddcfbed'; // Use the same API Key

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
        _currentImageUrl = data['imageUrl']; // Store the existing image URL

        final initialCategory = data['category'];
        if (initialCategory != null && _categories.contains(initialCategory)) {
          _selectedCategory = initialCategory;
        }

        final initialLatitude = data['latitude'] as double?;
        final initialLongitude = data['longitude'] as double?;
        if (initialLatitude != null && initialLongitude != null) {
          _selectedLatLng = LatLng(initialLatitude, initialLongitude);
          // Move the map to this location after data is fetched
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Direct call, no need to check hasListeners for MapController
            _mapController.move(_selectedLatLng, 13.0);
          });
        } else {
          // If no lat/lon, reverse geocode from text location
          _searchAddress(_locationController.text);
        }

        _overallRating = (data['rating'] as num?)?.toDouble() ?? 3.0;
      }
    } catch (e) {
      developer.log('Error fetching destination data: $e');
      if (mounted) {
        _showSnackBar('Failed to load destination data: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isFetchingData = false);
    }
  }

  Future<String> _uploadImageToImgbb(XFile imageFile) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['key'] = _imgbbApiKey;
    if (kIsWeb) {
      request.files.add(
          http.MultipartFile.fromBytes('image', _webImage!, filename: imageFile.name));
    } else {
      request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path, filename: imageFile.name));
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
      throw Exception(
          'Imgbb upload error. Status: ${response.statusCode}, Body: $errorBody');
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please complete all required fields.');
      return;
    }

    // If no image selected and no old image
    if (_pickedImage == null && _currentImageUrl == null) {
      _showSnackBar('Please select an image for this destination.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrlToSave = _currentImageUrl;
      if (_pickedImage != null) {
        // Only upload if a new image is selected
        imageUrlToSave = await _uploadImageToImgbb(_pickedImage!);
        _showSnackBar('Image uploaded successfully! Saving data...');
      }

      final dataToUpdate = {
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrlToSave, // Use the updated image URL
        'latitude': _selectedLatLng.latitude,
        'longitude': _selectedLatLng.longitude,
        'rating': _overallRating,
        'category': _selectedCategory,
        'updatedAt': FieldValue.serverTimestamp(), // Add update timestamp
      };

      await _firestoreService.updateDestination(widget.destinationId, dataToUpdate);

      if (!mounted) return;
      _showSnackBar('Post updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      developer.log('Error updating destination: $e');
      if (mounted) {
        _showSnackBar('Failed to update destination: ${e.toString()}',
            isError: true);
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
          _locationController.text = data['display_name'] ?? 'Address not found';
          _selectedLatLng = latLng;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to get address.', isError: true);
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
          _showSnackBar('Address not found.');
        }
      }
    } catch (e) {
      _showSnackBar('Error searching for address: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSaving) {
      _showSnackBar('Please wait for the saving process to complete.');
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
          _webImage = bytes;
          _currentImageUrl = null; // Clear old image URL if a new image is picked
        });
      } else {
        setState(() {
          _pickedImage = picked;
          _currentImageUrl = null; // Clear old image URL if a new image is picked
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
                  color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: AppColors.white,
          elevation: 1.0,
          foregroundColor: AppColors.primaryDark,
        ),
        body: _isFetchingData
            ? const Center(child: CircularProgressIndicator())
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

  // --- UI WIDGETS (Copied from AddDestinationScreen and Adjusted) ---
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
                        ? Image.memory(_webImage!, fit: BoxFit.cover)
                        : Image.file(File(_pickedImage!.path),
                            fit: BoxFit.cover))
                : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13.0),
                        child: Image.network(_currentImageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                              child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ));
                        }, errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    size: 50, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('Failed to load image',
                                    style: TextStyle(color: Colors.grey)),
                                Text('Tap to select a new image',
                                    style: TextStyle(color: Colors.grey))
                              ],
                            ),
                          );
                        }),
                      )
                    : const Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  size: 50, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('Tap to select an image',
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
                    labelText: 'Place Name',
                    prefixIcon: Icon(Icons.place_outlined)),
                validator: (v) => v!.isEmpty ? 'Place name is required' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined)),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Category is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined)),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'Description is required' : null),
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
                labelText: 'Search address or select on map',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isLoadingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
              ),
              onFieldSubmitted: (v) => _searchAddress(v),
              validator: (v) => v!.isEmpty ? 'Location is required' : null,
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
                onPressed: _isSaving ? null : () => setState(() => _overallRating = index + 1.0),
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
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3))
                : const Icon(Icons.save_outlined), // Change icon to save
            label: Text(_isSaving ? 'Saving...' : 'Save Changes'), // Change button text
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