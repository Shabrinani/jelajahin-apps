import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jelajahin_apps/main.dart'; // Import AppColors

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController(); // Untuk Nama Lengkap
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); // Untuk Nomor Telepon
  final TextEditingController _birthDateDayController = TextEditingController();
  final TextEditingController _birthDateMonthController = TextEditingController();
  final TextEditingController _birthDateYearController = TextEditingController();

  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _fullNameController.text = _currentUser!.displayName ?? '';
      _emailController.text = _currentUser!.email ?? '';
      _phoneController.text = '+8801763204103'; // Placeholder
      _birthDateDayController.text = '07'; // Placeholder
      _birthDateMonthController.text = 'March'; // Placeholder
      _birthDateYearController.text = '2002'; // Placeholder
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateDayController.dispose();
    _birthDateMonthController.dispose();
    _birthDateYearController.dispose();
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
        // Update display name (Nama Lengkap)
        if (_fullNameController.text.trim() != _currentUser!.displayName) {
          await _currentUser!.updateDisplayName(_fullNameController.text.trim());
        }

        // TODO: Update nomor telepon dan tanggal lahir ke database Anda
        // Perlu diingat: updateEmail() di Firebase memerlukan re-authentication
        // dan tidak bisa dilakukan langsung dari sini tanpa logic tambahan.
        // Untuk data seperti nomor telepon dan tanggal lahir, Anda perlu
        // menyimpannya di Firestore atau Realtime Database yang terkait dengan UID pengguna.

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: AppColors.lightTeal,
            ),
          );
          Navigator.pop(context); // Kembali ke halaman profil
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Gagal memperbarui profil: ${e.message}';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

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
                          backgroundImage: _currentUser?.photoURL != null
                              ? NetworkImage(_currentUser!.photoURL!)
                              : null,
                          child: _currentUser?.photoURL == null
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
                            onTap: () {
                              // TODO: Implementasi ganti foto profil
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Fitur ganti foto profil akan segera hadir!')),
                              );
                            },
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.darkTeal,
                              child: Icon(Icons.camera_alt, color: AppColors.white, size: 18), // Ikon kamera
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Nama Pengguna
                    Text(
                      _currentUser?.displayName ?? 'Your Name Here',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Role/Profesi
                    Text(
                      'UI UX Designer', // Contoh role/profesi sesuai UI
                      style: textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 30),

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
                      label: 'Email Adress',
                      hintText: 'hallo@fillo.com',
                      icon: Icons.mail_outline,
                      readOnly: true, // Email biasanya read-only untuk mencegah perubahan tanpa re-auth
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      context,
                      controller: _phoneController,
                      label: 'Phone Number',
                      hintText: '+8801763204103',
                      icon: Icons.call,
                      keyboardType: TextInputType.phone,
                      readOnly: false,
                    ),
                    const SizedBox(height: 20),

                    // Birth Date
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Birth Date',
                        style: textTheme.labelLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateInputField(
                            context,
                            controller: _birthDateDayController,
                            hintText: '07',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDateInputField(
                            context,
                            controller: _birthDateMonthController,
                            hintText: 'March',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDateInputField(
                            context,
                            controller: _birthDateYearController,
                            hintText: '2002',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Save Button (Jika ada tombol save di desain)
                    // Mengacu pada desain profil yang tidak ada tombol save eksplisit
                    // saya asumsikan Save dilakukan di parent widget atau tidak diperlukan lagi.
                    // Namun jika ingin ada, bisa seperti ini:
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 50,
                    //   child: ElevatedButton(
                    //     onPressed: _updateProfile,
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: AppColors.primaryDark,
                    //       foregroundColor: AppColors.white,
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(10),
                    //       ),
                    //       elevation: 0,
                    //     ),
                    //     child: Text(
                    //       "Save Changes",
                    //       style: textTheme.labelLarge?.copyWith(
                    //         fontSize: 18,
                    //         fontWeight: FontWeight.bold,
                    //         color: AppColors.white,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
      // Bottom navigation bar (jika ini adalah bagian dari Home yang memiliki bottom nav bar)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Fixed type agar semua item terlihat
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.lightTeal, // Warna icon aktif
        unselectedItemColor: Colors.grey[400], // Warna icon tidak aktif
        showSelectedLabels: true,
        showUnselectedLabels: false, // Label hanya tampil di yang terpilih
        currentIndex: 4, // Index Profile tab
        onTap: (index) {
          // TODO: Handle navigation to different tabs if this is part of Home
          // If this page is a standalone route, this BottomNavBar might not be needed
          // or needs to be managed by the parent Navigator (e.g., Home page)
          if (index == 0) {
            // Navigate to Home
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Text('Home Page Placeholder')));
          } else if (index == 4) {
            // Already on Profile page (or navigating to Profile itself if it's the target)
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            activeIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.darkTeal,
              child: Icon(Icons.add, color: AppColors.white, size: 30),
            ),
            label: '', // Label kosong untuk tombol tambah
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: 'Notification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
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
            prefixIcon: Icon(icon, color: Colors.grey[600]), // Ikon di dalam TextField
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), // Radius border sesuai UI
              borderSide: BorderSide.none, // Tanpa border outline yang terlihat
            ),
            filled: true,
            fillColor: Colors.grey[100], // Warna fill sesuai UI
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          validator: (value) {
            if (!readOnly && (value == null || value.isEmpty)) {
              return '$label tidak boleh kosong';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Helper Widget untuk input tanggal lahir (tanpa ikon di dalamnya)
  Widget _buildDateInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true, // Biasanya dipilih dari DatePicker
      keyboardType: keyboardType,
      textAlign: TextAlign.center, // Teks di tengah
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), // Padding lebih kecil
      ),
      onTap: () async {
        // TODO: Implementasi DatePicker jika ingin dinamis
        // Contoh:
        // DateTime? pickedDate = await showDatePicker(
        //   context: context,
        //   initialDate: DateTime.now(),
        //   firstDate: DateTime(1900),
        //   lastDate: DateTime.now(),
        // );
        // if (pickedDate != null) {
        //   controller.text = DateFormat('dd').format(pickedDate); // Contoh format
        //   _birthDateMonthController.text = DateFormat('MMMM').format(pickedDate);
        //   _birthDateYearController.text = DateFormat('yyyy').format(pickedDate);
        // }
      },
    );
  }
}