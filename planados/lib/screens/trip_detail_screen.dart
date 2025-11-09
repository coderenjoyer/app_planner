import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/trip.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  Map<int, List<String>> dayActivities = {};
  final _database = FirebaseDatabase.instance.ref();
  String? _tripId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tripId = widget.trip.id;
    _loadOrInitializeActivities();
  }

  Future<void> _loadOrInitializeActivities() async {
    // Initialize empty activity lists first
    for (int i = 1; i <= widget.trip.days; i++) {
      dayActivities[i] = [];
    }

    print('DEBUG: Loading activities for trip ID: ${widget.trip.id}');
    print('DEBUG: Trip title: ${widget.trip.title}');

    if (_tripId == null) {
      print('DEBUG: No trip ID found');
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Load existing activities if available
      final snapshot = await _database.child('trips').child(_tripId!).get();

      print('DEBUG: Snapshot exists: ${snapshot.exists}');

      if (snapshot.exists) {
        final tripData = snapshot.value as Map<dynamic, dynamic>;
        print('DEBUG: Trip data: $tripData');

        if (tripData['activities'] != null) {
          final activitiesData = tripData['activities'];
          print('DEBUG: Activities data type: ${activitiesData.runtimeType}');
          print('DEBUG: Activities data: $activitiesData');

          // Handle both Map and List formats
          if (activitiesData is Map) {
            activitiesData.forEach((dayKey, activities) {
              final day = int.parse(dayKey.toString());
              if (activities != null) {
                dayActivities[day] = List<String>.from(activities as List);
              }
            });
          } else if (activitiesData is List) {
            for (int i = 0; i < activitiesData.length; i++) {
              if (activitiesData[i] != null) {
                dayActivities[i] = List<String>.from(activitiesData[i] as List);
              }
            }
          }
          print('DEBUG: Loaded activities: $dayActivities');
        } else {
          print('DEBUG: No activities found in database');
        }
      }
    } catch (e, stackTrace) {
      print('Error loading activities: $e');
      print('Stack trace: $stackTrace');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveActivities() async {
    if (_tripId == null) return;

    try {
      await _database
          .child('trips')
          .child(_tripId!)
          .child('activities')
          .set(
            dayActivities.map((key, value) => MapEntry(key.toString(), value)),
          );
    } catch (e) {
      print('Error saving activities: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save activities: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addActivity(int day) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Activity for Day $day'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter activity',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  dayActivities[day]!.add(controller.text.trim());
                });
                await _saveActivities();
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Activity added'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeActivity(int day, int index) async {
    setState(() {
      dayActivities[day]!.removeAt(index);
    });
    await _saveActivities();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity removed'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.trip.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trip.destination,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.trip.days} ${widget.trip.days == 1 ? 'day' : 'days'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.attach_money,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      Text(
                        '₱${widget.trip.budget.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Daily Itinerary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.trip.days,
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        final activities = dayActivities[day] ?? [];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Day $day',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: () => _addActivity(day),
                                      tooltip: 'Add activity',
                                    ),
                                  ],
                                ),
                                if (activities.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      'No activities planned',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                else
                                  ...activities.asMap().entries.map((entry) {
                                    final activityIndex = entry.key;
                                    final activity = entry.value;
                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 0,
                                            vertical: 0,
                                          ),
                                      leading: const Icon(
                                        Icons.check_circle_outline,
                                        size: 20,
                                      ),
                                      title: Text(activity),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _removeActivity(day, activityIndex),
                                      ),
                                    );
                                  }).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
