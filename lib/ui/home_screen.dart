import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lane_keeper/features/auth/data/auth_repository.dart';
import 'package:lane_keeper/features/telemetry/ui/telemetry_manager.dart';
import 'package:lane_keeper/features/telemetry/data/location_service.dart';
import 'package:lane_keeper/ui/driving_mode_screen.dart';
import 'package:lane_keeper/core/theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize telemetry on Home load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(telemetryManagerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final telemetryState = ref.watch(telemetryManagerProvider);

    // If driving, show partial over-screen? 
    // Actually request specified "No distraction". 
    // We should push the DrivingScreen if status is driving.
    // However, pushing inside build is bad.
    // Better to return the DrivingScreen widget directly if state is driving.
    
    if (telemetryState.status == TripStatus.driving) {
      return const DrivingModeScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("LaneKeeper"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
           final stats = user?.weeklyStats ?? {};
           final score = (stats['weeklyScore'] ?? 0.0) as double;
           final distance = (stats['totalDistance'] ?? 0.0) as double;
           final trips = (stats['tripCount'] ?? 0) as int;

           return SingleChildScrollView(
             padding: const EdgeInsets.all(24.0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 // Score Card
                 Container(
                   decoration: BoxDecoration(
                     color: AppTheme.primaryGreen,
                     borderRadius: BorderRadius.circular(24),
                   ),
                   padding: const EdgeInsets.all(24),
                   child: Column(
                     children: [
                       const Text(
                         "Weekly Rule Integrity",
                         style: TextStyle(color: Colors.white70),
                       ),
                       const SizedBox(height: 8),
                       Text(
                         score.toStringAsFixed(0),
                         style: const TextStyle(
                           color: Colors.white,
                           fontSize: 64,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const Text(
                         "/ 100",
                         style: TextStyle(color: Colors.white70),
                       ),
                       const SizedBox(height: 24),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceAround,
                         children: [
                           _StatItem(
                             label: "Distance",
                             value: "${distance.toStringAsFixed(1)} km",
                           ),
                           _StatItem(
                             label: "Trips",
                             value: "$trips",
                           ),
                         ],
                       )
                     ],
                   ),
                 ),
                 
                 const SizedBox(height: 32),
                 
                 // Manual Controls for Testing
                 const Text("Developer Controls", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                 const SizedBox(height: 8),
                 Row(
                   children: [
                     Expanded(
                       child: OutlinedButton(
                         onPressed: () => ref.read(locationServiceProvider).simulateDrive(),
                         child: const Text("Simulate Trip"),
                       ),
                     ),
                   ],
                 ),
                 
                 if (telemetryState.status == TripStatus.processing)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text("Processing last trip...")),
                    ),
                 
                 const SizedBox(height: 32),
                 
                 // Quick Actions
                 ElevatedButton.icon(
                   onPressed: () {
                     // Navigate to Trips List (Todo)
                   },
                   icon: const Icon(Icons.list),
                   label: const Text("View Trips History"),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.white,
                     foregroundColor: AppTheme.primaryGreen,
                     side: const BorderSide(color: AppTheme.primaryGreen),
                   ),
                 ),
                 const SizedBox(height: 12),
                 ElevatedButton.icon(
                   onPressed: () {
                     // Navigate to Leaderboard (Todo)
                   },
                   icon: const Icon(Icons.leaderboard),
                   label: const Text("City Leaderboard"),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.white,
                     foregroundColor: AppTheme.primaryGreen,
                     side: const BorderSide(color: AppTheme.primaryGreen),
                   ),
                 ),
               ],
             ),
           );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, 
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
