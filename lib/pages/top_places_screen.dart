import 'package:flutter/material.dart';
import 'package:jelajahin_apps/main.dart';
import 'package:jelajahin_apps/pages/destination_detail_page.dart'
    as DetailPage;

class TopPlacesScreen extends StatefulWidget {
  const TopPlacesScreen({super.key});

  @override
  State<TopPlacesScreen> createState() => _TopPlacesScreenState();
}

class _TopPlacesScreenState extends State<TopPlacesScreen> {
  String selectedPeriod = 'This Month';

  final List<String> timePeriods = [
    'This Week',
    'This Month',
    'This Year',
    'All Time',
  ];

  final List<Map<String, dynamic>> topDestinations = [
    {
      'rank': 1,
      'name': 'Bali Paradise Beach',
      'location': 'Bali, Indonesia',
      'image': 'images/bali.jpg',
      'rating': 4.9,
      'totalRatings': 15420,
      'visitors': '2.3M',
      'trend': 'up',
      'trendPercent': '+15%',
      'category': 'Beach',
      'price': '\$85',
      'highlights': ['Sunset Views', 'Crystal Water', 'Local Culture'],
      'isNew': false,
    },
    {
      'rank': 2,
      'name': 'Dubai Marina District',
      'location': 'Dubai, UAE',
      'image': 'images/dubai.jpg',
      'rating': 4.8,
      'totalRatings': 12890,
      'visitors': '1.9M',
      'trend': 'up',
      'trendPercent': '+8%',
      'category': 'City',
      'price': '\$180',
      'highlights': ['Luxury Shopping', 'Skyscrapers', 'Nightlife'],
      'isNew': false,
    },
    {
      'rank': 3,
      'name': 'Paris City of Love',
      'location': 'Paris, France',
      'image': 'images/france.jpg',
      'rating': 4.7,
      'totalRatings': 18567,
      'visitors': '3.1M',
      'trend': 'stable',
      'trendPercent': '+2%',
      'category': 'City',
      'price': '\$160',
      'highlights': ['Eiffel Tower', 'Art Museums', 'Cuisine'],
      'isNew': false,
    },
    {
      'rank': 4,
      'name': 'Taj Mahal Heritage',
      'location': 'Agra, India',
      'image': 'images/india.jpg',
      'rating': 4.6,
      'totalRatings': 9876,
      'visitors': '1.2M',
      'trend': 'up',
      'trendPercent': '+22%',
      'category': 'Cultural',
      'price': '\$45',
      'highlights': ['World Wonder', 'Architecture', 'History'],
      'isNew': true,
    },
    {
      'rank': 5,
      'name': 'Mexico City Vibrant',
      'location': 'Mexico City, Mexico',
      'image': 'images/mexico.jpg',
      'rating': 4.5,
      'totalRatings': 7654,
      'visitors': '980K',
      'trend': 'up',
      'trendPercent': '+12%',
      'category': 'City',
      'price': '\$65',
      'highlights': ['Street Food', 'Colorful Culture', 'Markets'],
      'isNew': true,
    },
    {
      'rank': 6,
      'name': 'New York Skyline',
      'location': 'New York, USA',
      'image': 'images/profile.jpg',
      'rating': 4.4,
      'totalRatings': 11234,
      'visitors': '2.5M',
      'trend': 'down',
      'trendPercent': '-3%',
      'category': 'City',
      'price': '\$220',
      'highlights': ['Broadway', 'Central Park', 'Museums'],
      'isNew': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(textTheme),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(textTheme),
            _buildChampionSection(textTheme),
            _buildPodiumSection(textTheme),
            _buildRankingsList(textTheme),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(TextTheme textTheme) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.primaryDark),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Top Places',
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.share, color: AppColors.primaryDark),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover the World\'s\nMost Popular Destinations',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  timePeriods.map((period) {
                    final isSelected = period == selectedPeriod;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedPeriod = period;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.lightTeal
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          period,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChampionSection(TextTheme textTheme) {
    final champion = topDestinations[0];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    DetailPage.DestinationDetailPage(destination: champion),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.lightTeal, AppColors.darkTeal],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.lightTeal.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                champion['image'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '#${champion['rank']} Champion',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      champion['trendPercent'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    champion['name'],
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    champion['location'],
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${champion['rating']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${champion['totalRatings']} reviews)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${champion['visitors']} visitors',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumSection(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 3 This Month',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPodiumCard(
                  topDestinations[1],
                  2,
                  Colors.grey[400]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPodiumCard(
                  topDestinations[0],
                  1,
                  Colors.amber,
                  isWinner: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPodiumCard(
                  topDestinations[2],
                  3,
                  Colors.orange[300]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(
    Map<String, dynamic> destination,
    int rank,
    Color medalColor, {
    bool isWinner = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    DetailPage.DestinationDetailPage(destination: destination),
          ),
        );
      },
      child: Container(
        height: isWinner ? 180 : 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.asset(
                      destination['image'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: medalColor,
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    destination['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${destination['rating']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingsList(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Full Rankings',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          ...topDestinations.skip(3).map((destination) {
            return _buildRankingItem(destination);
          }),
        ],
      ),
    );
  }

  Widget _buildRankingItem(Map<String, dynamic> destination) {
    final trendColor =
        destination['trend'] == 'up'
            ? Colors.green
            : destination['trend'] == 'down'
            ? Colors.red
            : Colors.grey;

    final trendIcon =
        destination['trend'] == 'up'
            ? Icons.trending_up
            : destination['trend'] == 'down'
            ? Icons.trending_down
            : Icons.trending_flat;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    DetailPage.DestinationDetailPage(destination: destination),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.lightTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '#${destination['rank']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightTeal,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                destination['image'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          destination['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      if (destination['isNew'])
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    destination['location'],
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${destination['rating']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${destination['visitors']} visitors',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: trendColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(trendIcon, size: 12, color: trendColor),
                            const SizedBox(width: 2),
                            Text(
                              destination['trendPercent'],
                              style: TextStyle(
                                fontSize: 10,
                                color: trendColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  destination['price'],
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.lightTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.bookmark_border,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
