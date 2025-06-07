// lib/pages/home.dart
import 'package:flutter/material.dart';
import 'package:jelajahin_apps/main.dart'; // Import AppColors

// Import CustomBottomNavBar
import 'package:jelajahin_apps/pages/bottom_nav_bar.dart';

// Import semua halaman konten yang terpisah
import 'package:jelajahin_apps/pages/home_page.dart';
import 'package:jelajahin_apps/pages/saved_page.dart';
import 'package:jelajahin_apps/pages/notification_page.dart';
import 'package:jelajahin_apps/pages/Add_destination.dart';
import 'package:jelajahin_apps/pages/profile_page.dart';


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0; // Current selected tab index
  late PageController _pageController; // Controller for PageView

  // List of pages to be displayed in the PageView (semua diimpor dari file terpisah)
  final List<Widget> _pages = [
    const HomeContentPage(),      // Konten Home
    const SavedPage(),            // Konten Saved
    const AddDestinationScreen(), // Konten Add Trip
    const NotificationPage(),     // Konten Notification
    const ProfilePage(),          // Konten Profile
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

  void _onItemTapped(int index) {
    // Jika Anda ingin menampilkan halaman "Add Trip" sebagai modal/dialog,
    // Anda bisa menanganinya secara khusus di sini.
    // Misalnya, jika index 2 adalah tombol Add Trip:
    if (index == 2) { // Index 2 adalah "Add Trip"
      showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Untuk full screen modal jika form panjang
        builder: (context) {
          return const AddDestinationScreen(); // Tampilkan halaman AddTripPage sebagai modal
        },
      );
      // Jangan ubah _selectedIndex agar tab sebelumnya tetap aktif
      // dan jangan animate PageView
      return; // Keluar dari fungsi agar tidak melanjutkan ke animateToPage
    }

    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: PageView(
        controller: _pageController,
        // Disable physics for PageView if you only want navigation via BottomNavBar
        // physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          if (index != 2) { // Jangan update selected index jika itu tab "Add Trip" (karena itu modal)
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}