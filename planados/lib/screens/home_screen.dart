import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/trip.dart';
import '../widgets/trip_card.dart';
import 'create_trip_screen.dart';
import 'trip_detail_screen.dart';
import 'settings_screen.dart';
import '../utils/user_session.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Trip> trips = [];
  final _database = FirebaseDatabase.instance.ref();
  bool _isLoading = true;

  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
    _loadTrips();
  }

  Future<void> _loadUserSettings() async {
    try {
      final userKey = UserSession().userKey;
      if (userKey == null) return;

      final snapshot = await _database.child('users').child(userKey).get();

      if (snapshot.exists && mounted) {
        final userData = snapshot.value as Map<dynamic, dynamic>;

        // Load theme setting
        if (userData['settings'] != null) {
          final settings = userData['settings'] as Map<dynamic, dynamic>;
          final themeName = settings['theme'] ?? 'light';

          AppTheme theme;
          switch (themeName) {
            case 'dark':
              theme = AppTheme.dark;
              break;
            case 'pink':
              theme = AppTheme.pink;
              break;
            case 'tropical':
              theme = AppTheme.tropical;
              break;
            default:
              theme = AppTheme.light;
          }

          // Apply the theme
          final themeProvider = Provider.of<ThemeProvider>(
            context,
            listen: false,
          );
          themeProvider.setTheme(theme);
        }
      }
    } catch (e) {
      print('Error loading user settings: $e');
    }
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);

    try {
      final userKey = UserSession().userKey;
      if (userKey == null) {
        setState(() => _isLoading = false);
        return;
      }

      final snapshot = await _database
          .child('users')
          .child(userKey)
          .child('trips')
          .get();

      if (snapshot.exists) {
        final tripsData = snapshot.value as Map<dynamic, dynamic>;
        final loadedTrips = <Trip>[];

        tripsData.forEach((key, value) {
          final tripData = value as Map<dynamic, dynamic>;
          loadedTrips.add(
            Trip(
              id: key as String,
              title: tripData['title'] as String,
              destination: tripData['destination'] as String,
              days: tripData['days'] as int,
              budget: (tripData['budget'] as num).toDouble(),
            ),
          );
        });

        setState(() {
          trips = loadedTrips;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading trips: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load trips: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Trip> get filteredTrips {
    if (_searchQuery.isEmpty) return trips;
    return trips.where((trip) {
      return trip.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          trip.destination.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _deleteTrip(int index) {
    final trip = trips[index];
    setState(() => trips.removeAt(index));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${trip.title} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => setState(() => trips.insert(index, trip)),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayTrips = filteredTrips;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search trips...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('Planados'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              final themeProvider = Provider.of<ThemeProvider>(
                context,
                listen: false,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(themeProvider: themeProvider),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : trips.isEmpty
          ? _buildEmptyState(context)
          : displayTrips.isEmpty
          ? _buildNoResultsState()
          : Column(
              children: [
                _buildSummaryCard(theme),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadTrips();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: displayTrips.length,
                      itemBuilder: (context, index) {
                        final trip = displayTrips[index];
                        final originalIndex = trips.indexOf(trip);

                        return Dismissible(
                          key: Key(trip.title + trip.destination),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Trip'),
                                content: Text('Delete "${trip.title}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) => _deleteTrip(originalIndex),
                          child: GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TripDetailScreen(trip: trip),
                                ),
                              );
                              if (result == true) setState(() {});
                            },
                            child: TripCard(trip: trip),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newTrip = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTripScreen()),
          );
          if (newTrip != null) {
            setState(() => trips.add(newTrip));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Plan Your Next Adventure'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_takeoff, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'No trips planned yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start planning your next adventure',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final newTrip = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTripScreen()),
              );
              if (newTrip != null) {
                setState(() => trips.add(newTrip));
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Trip'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No trips found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final totalBudget = trips.fold<double>(0, (sum, trip) => sum + trip.budget);
    final totalDays = trips.fold<int>(0, (sum, trip) => sum + trip.days);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat(
              icon: Icons.card_travel,
              label: 'Trips',
              value: trips.length.toString(),
              theme: theme,
            ),
            _buildStat(
              icon: Icons.calendar_today,
              label: 'Total Days',
              value: totalDays.toString(),
              theme: theme,
            ),
            _buildStat(
              icon: Icons.attach_money,
              label: 'Budget',
              value: '₱${(totalBudget / 1000).toStringAsFixed(0)}k',
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, color: theme.primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
