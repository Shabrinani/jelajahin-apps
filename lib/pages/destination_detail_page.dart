import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart'; // for AppColors.primaryDark

class DestinationDetailPage extends StatefulWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailPage({super.key, required this.destination});

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  late bool isFavorite;
  late ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.destination['isFavorite'] ?? false;
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 0;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
      widget.destination['isFavorite'] = isFavorite;
    });
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(isFavorite);
    return false; // prevent default pop as we already popped manually
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.destination['latitude'] as double?;
    final lng = widget.destination['longitude'] as double?;
    final LatLng? destinationLatLng =
        (lat != null && lng != null) ? LatLng(lat, lng) : null;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor:
              _isScrolled ? AppColors.darkTeal : AppColors.white,
          elevation: 0,
          leading: BackButton(
            color: _isScrolled ? AppColors.white : AppColors.primaryDark,
          ),
          title: Text(
            '',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _isScrolled ? Colors.white : AppColors.primaryDark,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                widget.destination['image'],
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 16.0,
                  left: 16.0,
                  right: 16.0,
                  bottom: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            widget.destination['name'],
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: toggleFavorite,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 18,
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.destination['location'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text('${widget.destination['rating'] ?? '4.5'}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.destination['description'] ??
                          'No description provided.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    if (destinationLatLng != null) ...[
                      const Text(
                        "Location",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlutterMap(
                            options: MapOptions(
                              center: destinationLatLng,
                              zoom: 15,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.example.jelajahin_apps',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    width: 40,
                                    height: 40,
                                    point: destinationLatLng,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: AppColors.primaryDark,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
