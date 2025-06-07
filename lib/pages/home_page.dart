// lib/pages/home_content_page.dart
import 'package:flutter/material.dart';
import 'package:jelajahin_apps/main.dart'; // Import AppColors

class HomeContentPage extends StatelessWidget {
  const HomeContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Text(
              "This is the actual Home Page Content!",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}