import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jelajahin_apps/services/firestore_service.dart';
import 'package:jelajahin_apps/theme/colors.dart';
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  User? _currentUser;
  bool _isLoading = true; // Start with loading true

  String? _selectedAvatarUrl;
  DateTime? _selectedDate;
  String? _selectedGender;

  final List<String> _availableAvatars = [
    'assets/profile_avatars/avatar1.png', 'assets/profile_avatars/avatar2.png',
    'assets/profile_avatars/avatar3.png', 'assets/profile_avatars/avatar4.png',
    'assets/profile_avatars/avatar5.png', 'assets/profile_avatars/avatar6.png',
    'assets/profile_avatars/avatar7.png', 'assets/profile_avatars/avatar8.png',
    'assets/profile_avatars/avatar9.png', 'assets/profile_avatars/avatar10.png',
  ];
  final List<String> _genderOptions = ['Pria', 'Wanita', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      DocumentSnapshot userDoc = await _firestoreService.getCurrentUserData();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        _fullNameController.text = userData['name'] ?? _currentUser!.displayName ?? '';
        _emailController.text = userData['email'] ?? _currentUser!.email ?? '';
        _phoneController.text = userData['phoneNumber'] ?? '';
        
        String? loadedAvatarUrl = userData['profile_picture_url'];
        _selectedAvatarUrl = (loadedAvatarUrl != null && _availableAvatars.contains(loadedAvatarUrl))
            ? loadedAvatarUrl
            : _availableAvatars.first;
            
        Timestamp? dobTimestamp = userData['dateOfBirth'];
        if (dobTimestamp != null) {
          _selectedDate = dobTimestamp.toDate();
          _dobController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
        }

        _selectedGender = userData['gender'];
        if (_selectedGender != null && !_genderOptions.contains(_selectedGender)) {
          _selectedGender = null;
        }
      }
    } catch (e) {
      _showSnackBar('Gagal memuat data profil: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _firestoreService.updateUserProfile(
        name: _fullNameController.text.trim(),
        profilePictureUrl: _selectedAvatarUrl,
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: _selectedDate,
        gender: _selectedGender,
      );

      if (mounted) {
        _showSnackBar('Profil berhasil diperbarui!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Gagal memperbarui profil: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.lightTeal,
      ));
    }
  }

  // --- UI Methods (DatePicker, AvatarPicker, etc.) ---

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.lightTeal, onPrimary: AppColors.white, onSurface: AppColors.primaryDark),
          textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.darkTeal)),
        ),
        child: child!,
      ),
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pilih Avatar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: _availableAvatars.length,
              itemBuilder: (context, index) {
                final avatarPath = _availableAvatars[index];
                final isSelected = _selectedAvatarUrl == avatarPath;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAvatarUrl = avatarPath);
                    Navigator.pop(context);
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(radius: 40, backgroundImage: AssetImage(avatarPath)),
                      if (isSelected)
                        CircleAvatar(radius: 40, backgroundColor: AppColors.darkTeal.withOpacity(0.5), child: const Icon(Icons.check_circle, color: Colors.white, size: 30)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.lightTeal))
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
                          backgroundImage: _selectedAvatarUrl != null ? AssetImage(_selectedAvatarUrl!) : null,
                          child: _selectedAvatarUrl == null ? const Icon(Icons.person, size: 60, color: AppColors.darkTeal) : null,
                        ),
                        GestureDetector(
                          onTap: _showAvatarSelectionBottomSheet,
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.darkTeal,
                            child: Icon(Icons.camera_alt, color: AppColors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildInputField(controller: _fullNameController, label: 'Full Name', icon: Icons.person),
                    const SizedBox(height: 20),
                    _buildInputField(controller: _emailController, label: 'Email Address', icon: Icons.mail_outline, readOnly: true),
                    const SizedBox(height: 20),
                    _buildInputField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.call,
                      keyboardType: TextInputType.phone,
                      validator: (value) => (value != null && value.isNotEmpty && !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value)) ? 'Format nomor telepon tidak valid.' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildDateField(),
                    const SizedBox(height: 20),
                    _buildGenderField(),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark, foregroundColor: AppColors.white),
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- UI HELPER WIDGETS ---
  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, bool readOnly = false, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          validator: validator ?? (value) => (!readOnly && (value == null || value.isEmpty)) ? '$label tidak boleh kosong' : null,
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of Birth', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dobController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'DD/MM/YYYY',
            prefixIcon: Icon(Icons.calendar_today, color: Colors.grey[600]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onTap: () => _selectDate(context),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          hint: Text('Pilih jenis kelamin', style: TextStyle(color: Colors.grey[600])),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.people, color: Colors.grey[600]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          items: _genderOptions.map((String gender) => DropdownMenuItem<String>(value: gender, child: Text(gender))).toList(),
          onChanged: (String? newValue) => setState(() => _selectedGender = newValue),
        ),
      ],
    );
  }
}
