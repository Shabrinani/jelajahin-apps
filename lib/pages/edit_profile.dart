import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:jelajahin_apps/main.dart'; // <--- Ubah ini jika AppColors ada di tempat lain
import 'package:jelajahin_apps/theme/colors.dart'; // Asumsi AppColors ada di sini
import 'dart:developer' as developer;
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  User? _currentUser;
  bool _isLoading = false;

  String? _selectedAvatarUrl;
  DateTime? _selectedDate;
  String? _selectedGender;

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

  final List<String> _genderOptions = ['Pria', 'Wanita', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _fullNameController.text = _currentUser!.displayName ?? '';
      _emailController.text = _currentUser!.email ?? '';

      _loadUserData();
    }
  }

  // --- START: Perubahan di _loadUserData() ---
  Future<void> _loadUserData() async {
    if (_currentUser == null) {
      developer.log('WARNING: _loadUserData called but _currentUser is null.');
      return;
    }

    setState(() {
      _isLoading = true; // Set loading true while fetching data
    });

    try {
      developer.log('Attempting to load user data for UID: ${_currentUser!.uid}');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Memuat avatar URL
        String? loadedAvatarUrl = userData['avatarUrl'] as String?;
        if (loadedAvatarUrl != null && _availableAvatars.contains(loadedAvatarUrl)) {
          _selectedAvatarUrl = loadedAvatarUrl;
          developer.log('Firestore: Avatar URL loaded: $_selectedAvatarUrl');
        } else {
          _selectedAvatarUrl = _availableAvatars.first; // Default jika tidak ada/tidak valid
          developer.log('Firestore: avatarUrl is null, empty, or not in list. Using default: $_selectedAvatarUrl');
        }

        // Memuat nomor telepon
        _phoneController.text = userData['phoneNumber'] as String? ?? '';
        developer.log('Firestore: Phone number loaded: ${_phoneController.text}');

        // Memuat tanggal lahir
        Timestamp? dobTimestamp = userData['dateOfBirth'] as Timestamp?;
        if (dobTimestamp != null) {
          _selectedDate = dobTimestamp.toDate();
          _dobController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
          developer.log('Firestore: Date of Birth loaded: ${_dobController.text}');
        } else {
          _selectedDate = null;
          _dobController.text = '';
          developer.log('Firestore: Date of Birth is null.');
        }

        // Memuat jenis kelamin
        _selectedGender = userData['gender'] as String?;
        // Pastikan nilai yang dimuat ada di dalam _genderOptions
        if (_selectedGender != null && !_genderOptions.contains(_selectedGender)) {
          _selectedGender = null; // Atur ke null jika nilai tidak valid
          developer.log('Firestore: Loaded gender "$_selectedGender" is not in _genderOptions list. Setting to null.');
        }
        developer.log('Firestore: Gender loaded: $_selectedGender');

      } else {
        // Dokumen pengguna tidak ada di Firestore, atur nilai default
        developer.log('User document does not exist for UID: ${_currentUser!.uid}. Setting default values.');
        _selectedAvatarUrl = _availableAvatars.first;
        _phoneController.text = '';
        _dobController.text = '';
        _selectedDate = null;
        _selectedGender = null;
      }
    } catch (e, stackTrace) {
      developer.log("ERROR: Failed to load user data from Firestore: $e", error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Atur nilai default sebagai fallback bahkan jika ada error loading
      _selectedAvatarUrl = _availableAvatars.first;
      _phoneController.text = '';
      _dobController.text = '';
      _selectedDate = null;
      _selectedGender = null;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Set loading false after fetching data
        });
      }
    }
  }
  // --- END: Perubahan di _loadUserData() ---

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // --- START: Perubahan di _updateProfile() ---
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
          developer.log('Firebase Auth display name updated.');
        }

        // 2. Siapkan data untuk update di Cloud Firestore
        Map<String, dynamic> updateData = {
          'avatarUrl': _selectedAvatarUrl, // Simpan URL avatar yang dipilih
          'phoneNumber': _phoneController.text.trim(), // Simpan nomor telepon
          'lastUpdated': FieldValue.serverTimestamp(), // Tambahkan timestamp
        };

        // Tanggal Lahir: Jika ada tanggal yang dipilih, simpan sebagai Timestamp. Jika tidak, hapus field.
        if (_selectedDate != null) {
          updateData['dateOfBirth'] = Timestamp.fromDate(_selectedDate!);
          developer.log('Saving dateOfBirth as Timestamp: ${Timestamp.fromDate(_selectedDate!)}');
        } else {
          updateData['dateOfBirth'] = FieldValue.delete(); // Hapus field dari Firestore
          developer.log('dateOfBirth will be deleted from Firestore.');
        }

        // Jenis Kelamin: Jika ada jenis kelamin yang dipilih dan tidak kosong, simpan. Jika tidak, hapus field.
        if (_selectedGender != null && _selectedGender!.isNotEmpty) {
          updateData['gender'] = _selectedGender;
          developer.log('Saving gender: $_selectedGender');
        } else {
          updateData['gender'] = FieldValue.delete(); // Hapus field dari Firestore
          developer.log('gender will be deleted from Firestore.');
        }

        // Lakukan update ke Firestore
        await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set(
          updateData,
          SetOptions(merge: true), // Gunakan merge agar tidak menimpa field lain
        );
        developer.log('Firestore user data updated. Final data: $updateData');

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
        developer.log('Current user is null, cannot update profile.');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Gagal memperbarui profil: ${e.message}';
      developer.log('FirebaseAuthException: $errorMessage', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log('Unexpected error updating profile: $e', error: e, stackTrace: stackTrace);
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
  // --- END: Perubahan di _updateProfile() ---

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      });
    }
  }

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
                    developer.log('Attempting to load avatar: $avatarPath');
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAvatarUrl = avatarPath;
                        });
                        developer.log('Selected avatar: $_selectedAvatarUrl');
                        Navigator.pop(context);
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: AssetImage(avatarPath),
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

    ImageProvider? currentAvatarImage;
    if (_selectedAvatarUrl != null) {
      currentAvatarImage = AssetImage(_selectedAvatarUrl!);
      developer.log('Current profile avatar being used: $_selectedAvatarUrl');
    } else {
      currentAvatarImage = AssetImage(_availableAvatars.first); // Fallback to default if _selectedAvatarUrl is null
      developer.log('No specific avatar selected, using default first avatar: ${_availableAvatars.first}');
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
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.lightTeal.withOpacity(0.2),
                          backgroundImage: currentAvatarImage,
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
                            onTap: _showAvatarSelectionBottomSheet,
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
                    Text(
                      _currentUser?.displayName ?? 'Your Name Here',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _buildInputField(
                      context,
                      controller: _fullNameController,
                      label: 'Full Name',
                      hintText: 'Jelajahin',
                      icon: Icons.person,
                      readOnly: false,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      context,
                      controller: _emailController,
                      label: 'Email Address',
                      hintText: 'Jelajahin@gmail.com',
                      icon: Icons.mail_outline,
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      context,
                      controller: _phoneController,
                      label: 'Phone Number',
                      hintText: '+62812xxxxxx',
                      icon: Icons.call,
                      keyboardType: TextInputType.phone,
                      readOnly: false,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nomor telepon tidak boleh kosong.';
                        }
                        if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value)) {
                          return 'Format nomor telepon tidak valid.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date of Birth',
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _dobController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'DD/MM/YYYY',
                            prefixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          ),
                          onTap: () => _selectDate(context),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Tanggal lahir tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gender',
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          hint: Text('Select your gender', style: TextStyle(color: Colors.grey[600])),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.people, color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          ),
                          items: _genderOptions.map((String gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedGender = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Jenis kelamin tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
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

  Widget _buildInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
          validator: validator ??
              (value) {
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