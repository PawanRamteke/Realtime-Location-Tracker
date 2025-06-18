import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/home_controller.dart';

class TrackingHistorySheet extends StatelessWidget {
  final HomeController controller;
  final ScrollController scrollController;

  const TrackingHistorySheet({
    super.key,
    required this.controller,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tracking History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: controller.getTrackingSessions(),
              builder: (context, snapshot) {
                debugPrint('FutureBuilder state: ${snapshot.connectionState}');
                if (snapshot.hasError) {
                  debugPrint('FutureBuilder error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sessions = snapshot.data ?? [];
                debugPrint('Received ${sessions.length} sessions from database');

                if (sessions.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No tracking history available',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Start tracking to see your history',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    debugPrint('Building session card for index $index');
                    return _TrackingSessionCard(
                      session: sessions[index],
                      controller: controller,
                      onViewMap: () async {
                        final locations = await controller.getLocationHistory(sessions[index]['id']);
                        debugPrint('Retrieved ${locations.length} locations for session ${sessions[index]['id']}');
                        if (locations.isNotEmpty) {
                          controller.showHistoricalRoute(locations);
                          Navigator.pop(context);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingSessionCard extends StatefulWidget {
  final Map<String, dynamic> session;
  final HomeController controller;
  final VoidCallback onViewMap;

  const _TrackingSessionCard({
    required this.session,
    required this.controller,
    required this.onViewMap,
  });

  @override
  State<_TrackingSessionCard> createState() => _TrackingSessionCardState();
}

class _TrackingSessionCardState extends State<_TrackingSessionCard> {
  bool isExpanded = false;
  List<Map<String, dynamic>>? locationPoints;
  bool isLoading = false;

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    } else {
      return '${meters.toStringAsFixed(0)} m';
    }
  }

  String _formatSpeed(double metersPerSecond) {
    final kmPerHour = metersPerSecond * 3.6;
    return '${kmPerHour.toStringAsFixed(1)} km/h';
  }

  Future<void> _loadLocationPoints() async {
    if (locationPoints != null) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      locationPoints = await widget.controller.getLocationHistory(widget.session['id']);
    } catch (e) {
      debugPrint('Error loading location points: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final startTime = DateTime.parse(widget.session['start_time']);
    final endTime = widget.session['end_time'] != null 
      ? DateTime.parse(widget.session['end_time'])
      : null;
    final distance = widget.session['distance'] ?? 0.0;
    final averageSpeed = widget.session['average_speed'] ?? 0.0;
    final duration = endTime?.difference(startTime);
    final locationCount = widget.session['location_count'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(startTime),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('HH:mm:ss').format(startTime),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: locationCount > 0 ? widget.onViewMap : null,
                  tooltip: locationCount > 0 ? 'View on map' : 'No location data',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (duration != null)
                      _InfoItem(
                        icon: Icons.timer,
                        label: 'Duration',
                        value: _formatDuration(duration),
                      ),
                    _InfoItem(
                      icon: Icons.straighten,
                      label: 'Distance',
                      value: _formatDistance(distance),
                    ),
                    _InfoItem(
                      icon: Icons.speed,
                      label: 'Avg Speed',
                      value: _formatSpeed(averageSpeed),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$locationCount location points',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    IconButton(
                      icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                      onPressed: () {
                        setState(() {
                          isExpanded = !isExpanded;
                          if (isExpanded) {
                            _loadLocationPoints();
                          }
                        });
                      },
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const Divider(height: 24),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (locationPoints != null && locationPoints!.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: locationPoints!.length,
                        itemBuilder: (context, index) {
                          final point = locationPoints![index];
                          final pointTime = DateTime.parse(point['timestamp']);
                          return ListTile(
                            dense: true,
                            title: Text(
                              'Point ${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat('HH:mm:ss').format(pointTime)),
                                Text(
                                  'Lat: ${point['latitude'].toStringAsFixed(6)}, '
                                  'Lng: ${point['longitude'].toStringAsFixed(6)}',
                                ),
                                if (point['speed'] != null)
                                  Text('Speed: ${(point['speed'] * 3.6).toStringAsFixed(1)} km/h'),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const Text('No location points available'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 