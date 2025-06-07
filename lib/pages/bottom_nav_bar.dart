import 'package:flutter/material.dart';
import 'package:jelajahin_apps/main.dart'; // Import AppColors

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // Ensures all items are equally spaced
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.lightTeal, // Color for active icon
      unselectedItemColor: Colors.grey[400], // Color for inactive icons
      showSelectedLabels: true,
      showUnselectedLabels: false, // Only show label for selected item
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined), // Outline icon for inactive
          activeIcon: Icon(Icons.home), // Filled icon for active
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_border), // Outline icon for inactive
          activeIcon: Icon(Icons.bookmark), // Filled icon for active
          label: 'Saved',
        ),
        BottomNavigationBarItem(
          icon: CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.darkTeal,
            child: Icon(Icons.add, color: AppColors.white, size: 30),
          ),
          label: '', // Empty label for the central add button
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none), // Outline icon for inactive
          activeIcon: Icon(Icons.notifications), // Filled icon for active
          label: 'Notification',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline), // Outline icon for inactive
          activeIcon: Icon(Icons.person), // Filled icon for active
          label: 'Profile',
        ),
      ],
    );
  }
}