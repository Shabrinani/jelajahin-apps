import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:jelajahin_apps/main.dart'; // Import AppColors
import 'dart:developer' as developer; // Import for developer.log

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  // final TextEditingController _phoneController = TextEditingController(); // <<< DIHAPUS

  User? _currentUser;
  bool _isLoading = false;

  String? _selectedAvatarUrl; // Untuk menyimpan path avatar yang dipilih

  final List<String> _availableAvatars = [
    'assets/profile_avatars/avatar1.png',
    'assets/profile_avatars/avatar2.png',
    'assets/profile_avatars/avatar3.png',
    'assets/profile_avatars/avatar4.png',
    'assets/profile_avatars/avatar5.png',
    'assets/profile_avatars/avatar6.png',
    'assets/profile_avatars/avatar7.png',
    'assets/profile_avatars/avatar8.png',
    'assets/profile_avatars/avatar9.png',
    'assets/profile_avatars/avatar10.png',
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _fullNameController.text = _currentUser!.displayName ?? '';
      _emailController.text = _currentUser!.email ?? '';

      // Muat data pengguna dari Firestore saat initState
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) {
      developer.log('WARNING: _loadUserData called but _currentUser is null.');
      return;
    }

    try {
      developer.log('Attempting to load user data for UID: ${_currentUser!.uid}');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        // Data ditemukan di Firestore
        setState(() {
          _selectedAvatarUrl = userDoc.get('avatarUrl') as String?;
          // _phoneController.text = userDoc.get('phoneNumber') as String? ?? ''; // <<< DIHAPUS

          if (_selectedAvatarUrl == null || _selectedAvatarUrl!.isEmpty) { // Tambah check .isEmpty
            developer.log('Firestore: avatarUrl is null or empty, using default first avatar.'); // Update log
            _selectedAvatarUrl = _availableAvatars.first;
          } else {
            developer.log('Firestore: Avatar URL loaded: $_selectedAvatarUrl');
            // Tambahkan validasi jika URL dari Firestore tidak ada di daftar _availableAvatars
            if (!_availableAvatars.contains(_selectedAvatarUrl)) {
              developer.log('WARNING: Loaded avatar URL "$_selectedAvatarUrl" is not in _availableAvatars list. Using default.');
              _selectedAvatarUrl = _availableAvatars.first;
            }
          }
          developer.log('Final _selectedAvatarUrl after loading: $_selectedAvatarUrl');
          // developer.log('Phone number loaded: ${_phoneController.text}'); // <<< DIHAPUS
        });
      } else {
        // Dokumen pengguna tidak ada di Firestore, atur avatar default
        developer.log('User document does not exist for UID: ${_currentUser!.uid}. Setting default avatar.');
        setState(() {
          _selectedAvatarUrl = _availableAvatars.first; // Atur ke avatar pertama sebagai default
        });
      }
    } catch (e, stackTrace) {
      developer.log("ERROR: Failed to load user data from Firestore: $e", error: e, stackTrace: stackTrace);
      // Opsional: Tampilkan SnackBar kepada pengguna jika gagal memuat data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Atur avatar default sebagai fallback bahkan jika ada error loading
      setState(() {
        _selectedAvatarUrl = _availableAvatars.first;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    // _phoneController.dispose(); // <<< DIHAPUS
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentUser != null) {
        // 1. Update display name di Firebase Authentication
        if (_fullNameController.text.trim() != (_currentUser!.displayName ?? '')) {
          await _currentUser!.updateDisplayName(_fullNameController.text.trim());
          developer.log('Firebase Auth display name updated.'); // LOGGING
        }

        // 2. Update data tambahan (avatar URL) di Cloud Firestore
        // Catatan: 'phoneNumber' dihapus dari sini juga.
        await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set({
          // 'phoneNumber': _phoneController.text.trim(), // <<< DIHAPUS
          'avatarUrl': _selectedAvatarUrl, // Simpan URL avatar yang dipilih
          'lastUpdated': FieldValue.serverTimestamp(), // Tambahkan timestamp
        }, SetOptions(merge: true)); // Gunakan merge agar tidak menimpa field lain
        developer.log('Firestore user data updated. Avatar URL saved: $_selectedAvatarUrl'); // LOGGING

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profil berhasil diperbarui!'),
              backgroundColor: AppColors.lightTeal,
            ),
          );
          Navigator.pop(context); // Kembali ke halaman profil
        }
      } else {
        developer.log('Current user is null, cannot update profile.'); // LOGGING
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Gagal memperbarui profil: ${e.message}';
      developer.log('FirebaseAuthException: $errorMessage'); // LOGGING
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      developer.log('Unexpected error updating profile: $e'); // LOGGING
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan tak terduga: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi untuk menampilkan Bottom Sheet pilihan avatar
  void _showAvatarSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pilih Avatar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: _availableAvatars.length,
                  itemBuilder: (context, index) {
                    final avatarPath = _availableAvatars[index];
                    final isSelected = _selectedAvatarUrl == avatarPath;
                    developer.log('Attempting to load avatar: $avatarPath'); // LOGGING
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAvatarUrl = avatarPath;
                        });
                        developer.log('Selected avatar: $_selectedAvatarUrl'); // LOGGING
                        Navigator.pop(context); // Tutup bottom sheet setelah memilih
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: AssetImage(avatarPath),
                            // Anda bisa menambahkan errorBuilder jika ingin melihat error langsung di UI
                            // onImageError: (exception, stackTrace) {
                            //   developer.log('Failed to load asset $avatarPath: $exception');
                            // },
                          ),
                          if (isSelected)
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.darkTeal.withOpacity(0.5),
                              child: Icon(Icons.check_circle, color: AppColors.white, size: 30),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Menentukan gambar avatar yang akan ditampilkan di halaman edit
    ImageProvider? currentAvatarImage;
    if (_selectedAvatarUrl != null) {
      currentAvatarImage = AssetImage(_selectedAvatarUrl!);
      developer.log('Current profile avatar being used: $_selectedAvatarUrl'); // LOGGING
    } else if (_currentUser?.photoURL != null) {
      currentAvatarImage = NetworkImage(_currentUser!.photoURL!);
      developer.log('Current profile avatar using Firebase Auth photoURL: ${_currentUser!.photoURL!}'); // LOGGING
    } else {
      developer.log('No specific avatar selected, using default person icon.'); // LOGGING
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.lightTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Bagian Foto Profil
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.lightTeal.withOpacity(0.2),
                          backgroundImage: currentAvatarImage, // Gunakan yang sudah ditentukan
                          child: currentAvatarImage == null
                              ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.darkTeal,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showAvatarSelectionBottomSheet, // Panggil fungsi ini
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.darkTeal,
                              child: Icon(Icons.camera_alt, color: AppColors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Nama Pengguna (Display Only)
                    Text(
                      _currentUser?.displayName ?? 'Your Name Here',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Form Fields
                    _buildInputField(
                      context,
                      controller: _fullNameController,
                      label: 'Full Name',
                      hintText: 'Mahamud Hasan',
                      icon: Icons.person,
                      readOnly: false,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      context,
                      controller: _emailController,
                      label: 'Email Address',
                      hintText: 'hallo@fillo.com',
                      icon: Icons.mail_outline,
                      readOnly: true, // Email biasanya read-only
                    ),
                    // const SizedBox(height: 20), // <<< DIHAPUS
                    // _buildInputField( // <<< DIHAPUS
                    //   context,
                    //   controller: _phoneController,
                    //   label: 'Phone Number',
                    //   hintText: '+8801763204103',
                    //   icon: Icons.call,
                    //   keyboardType: TextInputType.phone,
                    //   readOnly: false,
                    // ),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: AppColors.white)
                            : Text(
                                "Save Changes",
                                style: textTheme.labelLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper Widget untuk setiap input field dengan ikon
  Widget _buildInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          validator: (value) {
            // Validator hanya berlaku jika field tidak readOnly.
            // Untuk email, Anda bisa menambahkan validator khusus email jika diperlukan.
            if (!readOnly && (value == null || value.isEmpty)) {
              return '$label tidak boleh kosong';
            }
            return null;
          },
        ),
      ],
    );
  }
}