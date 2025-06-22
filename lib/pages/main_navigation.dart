import 'package:flutter/material.dart';
import 'package:jelajahin_apps/theme/colors.dart'; // <-- Mengimpor AppColors dari sumber yang benar

// Import CustomBottomNavBar
import 'package:jelajahin_apps/pages/bottom_nav_bar.dart';

// Import semua halaman konten yang akan ditampilkan
import 'package:jelajahin_apps/pages/home_page.dart';
import 'package:jelajahin_apps/pages/saved_page.dart';
import 'package:jelajahin_apps/pages/notification_page.dart';
import 'package:jelajahin_apps/pages/add_destination.dart';
import 'package:jelajahin_apps/pages/profile_page.dart';

// Nama kelas diubah dari Home menjadi MainNavigation
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  // State class juga diubah namanya
  State<MainNavigation> createState() => _MainNavigationState();
}

// State class juga diubah namanya
class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0; // Index tab yang sedang aktif
  late PageController _pageController; // Controller untuk PageView

  // Daftar halaman yang akan ditampilkan di PageView
  // Catatan: Saya mengubah HomeContentPage() menjadi HomePage() agar sesuai dengan nama kelas di file home_page.dart
  final List<Widget> _pages = [
    const HomePage(),           // Konten Home
    const SavedPage(),          // Konten Saved
    const AddDestinationScreen(), // Halaman ini tidak ditampilkan langsung di PageView, tapi ada di daftar untuk referensi.
    const NotificationPage(),   // Konten Notification
    const ProfilePage(),        // Konten Profile
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fungsi yang dijalankan saat item di navigasi bawah ditekan
  void _onItemTapped(int index) {
    // Logika khusus untuk tombol "Add Destination" (index 2)
    // yang akan menampilkan halaman sebagai modal dari bawah (bottom sheet)
    if (index == 2) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Agar modal bisa full-screen jika kontennya panjang
        backgroundColor: Colors.transparent,
        builder: (context) {
          return const AddDestinationScreen(); // Menampilkan halaman AddDestinationScreen sebagai modal
        },
      );
      // Keluar dari fungsi agar tidak mengubah state atau halaman di PageView
      return;
    }

    // Untuk tab lainnya, update state dan pindah halaman di PageView
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: PageView(
        controller: _pageController,
        // Logika untuk mengubah tab saat pengguna menggeser halaman
        onPageChanged: (index) {
          // Index 2 (Add) dilewati karena itu adalah modal
          if (index != 2) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        children: _pages,
      ),
      // Menggunakan widget CustomBottomNavBar yang telah Anda buat
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
