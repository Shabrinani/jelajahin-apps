import 'package:flutter/material.dart';
import 'package:jelajahin_apps/main.dart'; // Import AppColors

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  // Data FAQ dibagi berdasarkan kategori
  final Map<String, List<Map<String, String>>> faqData = const {
    'Trip App for Co-parents.': [ // Kategori 1
      {
        'question': 'How do I set up my Trip App?',
        'answer': 'To set up your Trip App, first download it from the App Store or Google Play Store. Then, follow the on-screen instructions to create your account and complete the initial setup process.',
      },
      {
        'question': 'How do I password protect my account?',
        'answer': 'You can set up a strong password during registration. To change or update your password, go to the "Edit Profile" section in your Profile settings and look for the password reset option.',
      },
      {
        'question': 'How do I set up my Trip App?', // Pertanyaan duplikat di UI, tapi disertakan sesuai permintaan
        'answer': 'Please refer to the first question for the setup process. If you encounter specific issues, contact support.',
      },
    ],
    'Connecting Co-parent & Creating a circle': [ // Kategori 2
      {
        'question': 'If I\'m a third party, how do I connect?',
        'answer': 'Third parties can be invited to a circle by an existing member. They will receive an invitation link or code to join the circle.',
      },
      {
        'question': 'How do I delete or disconnect from a member?',
        'answer': 'To delete or disconnect from a member within a circle, navigate to the circle settings and select the option to manage members. You will find choices to remove or disconnect individuals.',
      },
      {
        'question': 'How do I create my account?',
        'answer': 'Creating an account is done through the "Sign Up" option on the Login page. You will need to provide an email and password to register.',
      },
      {
        'question': 'How do I verify my account?',
        'answer': 'Account verification typically involves confirming your email address through a link sent to you during registration. Please check your inbox and spam folder for the verification email.',
      },
    ],
  };

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
          'Help',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loop melalui setiap kategori FAQ
            ...faqData.entries.map((entry) {
              String categoryTitle = entry.key;
              List<Map<String, String>> questions = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Kategori
                  Container(
                    margin: const EdgeInsets.only(bottom: 10, top: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // Warna background untuk kategori
                      borderRadius: BorderRadius.circular(10), // Sudut membulat
                    ),
                    child: Text(
                      categoryTitle,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  // Daftar Pertanyaan dalam Kategori
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // Agar bisa di-scroll dengan SingleChildScrollView
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10), // Spasi antar pertanyaan
                        decoration: BoxDecoration(
                          color: Colors.grey[100], // Warna background untuk setiap pertanyaan
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0), // Padding disesuaikan
                          iconColor: AppColors.darkTeal,
                          collapsedIconColor: AppColors.darkTeal,
                          title: Text(
                            questions[index]['question']!,
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w500, // Sedikit lebih tebal
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                              child: Text(
                                questions[index]['answer']!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),
            // Bottom navigation bar (jika ini adalah bagian dari Home yang memiliki bottom nav bar)
            // Saya sertakan lagi, tapi ingat ini perlu dikelola di parent widget.
            BottomNavigationBar(
              type: BottomNavigationBarType.fixed, // Fixed type agar semua item terlihat
              backgroundColor: AppColors.white,
              selectedItemColor: AppColors.lightTeal, // Warna icon aktif
              unselectedItemColor: Colors.grey[400], // Warna icon tidak aktif
              showSelectedLabels: true,
              showUnselectedLabels: false, // Label hanya tampil di yang terpilih
              currentIndex: 0, // Index default, sesuaikan jika Help Page adalah bagian dari tab
              onTap: (index) {
                // TODO: Handle navigation to different tabs if this is part of Home
                // If this page is a standalone route, this BottomNavBar might not be needed
                // or needs to be managed by the parent Navigator (e.g., Home page)
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
          ],
        ),
      ),
    );
  }
}