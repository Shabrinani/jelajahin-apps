import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jelajahin_apps/services/firestore_service.dart';

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
  String? _selectedCategory;

  bool _isSaving = false;
  bool _isFetchingData = true;

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
    // 2. Panggil fungsi untuk mengambil data awal berdasarkan ID
    _fetchAndSetInitialData();
  }

  Future<void> _fetchAndSetInitialData() async {
    try {
      final docSnapshot = await _firestoreService.getDestinationById(widget.destinationId);

      if (docSnapshot.exists && mounted) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        
        _titleController.text = data['title'] ?? '';
        _locationController.text = data['location'] ?? '';
        _descriptionController.text = data['description'] ?? '';

        final initialCategory = data['category'];
        if (initialCategory != null && _categories.contains(initialCategory)) {
          _selectedCategory = initialCategory;
        }
      }
    } catch (e) {
      // Handle error jika gagal memuat data
    } finally {
      if (mounted) setState(() => _isFetchingData = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final dataToUpdate = {
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
      };
      // 3. Gunakan widget.destinationId untuk update
      await _firestoreService.updateDestination(widget.destinationId, dataToUpdate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Postingan berhasil diperbarui!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Destinasi')),
      body: _isFetchingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                // Di dalam SingleChildScrollView di build method Anda
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Membuat tombol menjadi lebar penuh
                  children: [
                    // --- NAMA TEMPAT ---
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Tempat',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama tempat tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- LOKASI ---
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Lokasi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- KATEGORI ---
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      // 'items' adalah daftar pilihan yang akan muncul
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      // 'onChanged' adalah fungsi yang dijalankan saat user memilih item baru
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Kategori wajib dipilih';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- DESKRIPSI ---
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                        // alignLabelWithHint membuat label 'Deskripsi' tetap di atas
                        // saat fieldnya multi-baris, ini lebih rapi.
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5, // Mengizinkan input hingga 5 baris
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Deskripsi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}