import 'dart:convert';
import 'dart:io' show File;
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
  final _ticketPriceController = TextEditingController();
  final _openingHoursController = TextEditingController();

  int _recommendationRating = 5;
  double _overallRating = 3;
  String? _accessType;

  XFile? _pickedImage;
  Uint8List? _webImage;
  LatLng _selectedLatLng = LatLng(-6.200000, 106.816666);
  String _address = '';

  final List<String> _accessOptions = ['Jalan Kaki', 'Motor', 'Mobil'];

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
    final response =
        await http.get(Uri.parse(url), headers: {'User-Agent': 'jelajahin-app'});
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
          'recommendationRating': _recommendationRating,
          'overallRating': _overallRating,
          'ticketPrice': _ticketPriceController.text,
          'accessType': _accessType,
          'openingHours': _openingHoursController.text,
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
          _ticketPriceController.clear();
          _openingHoursController.clear();
          _accessType = null;
          _recommendationRating = 5;
          _overallRating = 3;
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Tambah Destinasi'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
              TextFormField(
                controller: _locationController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 230,
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

              // NEW: Recommendation Rating (1-10)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Seberapa merekomendasikan tempat ini? (1–10)"),
                  Slider(
                    value: _recommendationRating.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$_recommendationRating',
                    onChanged: (value) {
                      setState(() {
                        _recommendationRating = value.toInt();
                      });
                    },
                  ),
                ],
              ),

              // NEW: Overall Rating (Stars)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Nilai keseluruhan tempat ini"),
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

              // NEW: Ticket Price (Optional)
              TextFormField(
                controller: _ticketPriceController,
                decoration: const InputDecoration(
                  labelText: 'Harga Tiket Masuk (opsional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // NEW: Access Type (Optional)
              DropdownButtonFormField<String>(
                value: _accessType,
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

              // NEW: Opening Hours (Optional)
              TextFormField(
                controller: _openingHoursController,
                readOnly: true,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
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

              ElevatedButton.icon(
                onPressed: _uploadDestination,
                icon: const Icon(Icons.send),
                label: const Text('Simpan Destinasi'),
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