import 'package:flutter/material.dart';
import 'package:jelajahin_apps/theme/colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  final Map<String, List<Map<String, String>>> faqData = const {
    'Aplikasi Perjalanan': [
      {
        'question': 'Bagaimana cara mengatur Aplikasi Perjalanan saya?',
        'answer': 'Untuk mengatur Aplikasi Perjalanan Anda, pertama-tama unduh dari App Store atau Google Play Store. Kemudian, ikuti petunjuk di layar untuk membuat akun Anda dan menyelesaikan proses pengaturan awal.',
      },
      {
        'question': 'Bagaimana cara melindungi akun saya dengan kata sandi?',
        'answer': 'Anda dapat mengatur kata sandi yang kuat selama pendaftaran. Untuk mengubah atau memperbarui kata sandi Anda, buka bagian "Edit Profil" di pengaturan Profil Anda dan cari opsi pengaturan ulang kata sandi.',
      },
    ],
    'Menghubungkan & Membuat Lingkaran': [
      {
        'question': 'Jika saya pihak ketiga, bagaimana cara saya terhubung?',
        'answer': 'Pihak ketiga dapat diundang ke dalam lingkaran oleh anggota yang sudah ada. Mereka akan menerima tautan undangan atau kode untuk bergabung dengan lingkaran tersebut.',
      },
      {
        'question': 'Bagaimana cara menghapus atau memutuskan koneksi dari anggota?',
        'answer': 'Untuk menghapus atau memutuskan koneksi dari anggota dalam suatu lingkaran, navigasikan ke pengaturan lingkaran dan pilih opsi untuk mengelola anggota. Anda akan menemukan pilihan untuk menghapus atau memutuskan koneksi individu.',
      },
      {
        'question': 'Bagaimana cara membuat akun saya?',
        'answer': 'Pembuatan akun dilakukan melalui opsi "Daftar" di halaman Login. Anda perlu memberikan email dan kata sandi untuk mendaftar.',
      },
      {
        'question': 'Bagaimana cara memverifikasi akun saya?',
        'answer': 'Verifikasi akun biasanya melibatkan konfirmasi alamat email Anda melalui tautan yang dikirimkan kepada Anda selama pendaftaran. Harap periksa kotak masuk dan folder spam Anda untuk email verifikasi.',
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
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bantuan',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...faqData.entries.map((entry) {
              String categoryTitle = entry.key;
              List<Map<String, String>> questions = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 10, top: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      categoryTitle,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                          iconColor: AppColors.darkTeal,
                          collapsedIconColor: AppColors.darkTeal,
                          title: Text(
                            questions[index]['question']!,
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                              child: Text(
                                questions[index]['answer']!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[800],
                                  height: 1.5,
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
          ],
        ),
      ),
    );
  }
}