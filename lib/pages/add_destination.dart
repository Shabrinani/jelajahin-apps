import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:io' show File;
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

  XFile? _pickedImage;
  Uint8List? _webImage;

  LatLng _selectedLatLng = LatLng(-6.200000, 106.816666); // Jakarta default
  String _address = '';

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedImage = picked;
          _webImage = bytes;
        });
      } else {
        setState(() {
          _pickedImage = picked;
        });
      }
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}';

    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'jelajahin-app'
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _address = data['display_name'] ?? '';
        _locationController.text = _address;
      });
    } else {
      setState(() {
        _address = 'Alamat tidak ditemukan';
      });
    }
  }

  Future<void> _uploadDestination() async {
    if (_formKey.currentState!.validate()) {
      if (_pickedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih gambar terlebih dahulu')),
        );
        return;
      }

      final String id = const Uuid().v4();
      final String fileName = 'destinations/$id.jpg';

      try {
        final ref = FirebaseStorage.instance.ref().child(fileName);

        if (kIsWeb) {
          await ref.putData(_webImage!);
        } else {
          await ref.putFile(File(_pickedImage!.path));
        }

        final imageUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('destinations').doc(id).set({
          'id': id,
          'name': _nameController.text,
          'location': _locationController.text,
          'description': _descriptionController.text,
          'imageUrl': imageUrl,
          'lat': _selectedLatLng.latitude,
          'lng': _selectedLatLng.longitude,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': FirebaseAuth.instance.currentUser?.uid ?? 'anon',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Destinasi berhasil diunggah')),
        );

        setState(() {
          _pickedImage = null;
          _webImage = null;
          _nameController.clear();
          _locationController.clear();
          _descriptionController.clear();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.darkTeal,
        title: const Text(
          'Tambah Destinasi',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Upload Image
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.lightBrown,
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
                              size: 60, color: AppColors.lightTeal),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Nama Tempat
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

              // Lokasi
              TextFormField(
                controller: _locationController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // MAP
              SizedBox(
                height: 250,
                child: FlutterMap(
                  options: MapOptions(
                    center: _selectedLatLng,
                    zoom: 13.0,
                    onTap: (tapPosition, point) {
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

              // Deskripsi
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
              const SizedBox(height: 24),

              // Tombol Simpan
              ElevatedButton.icon(
                onPressed: _uploadDestination,
                icon: const Icon(Icons.send),
                label: const Text('Simpan Destinasi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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