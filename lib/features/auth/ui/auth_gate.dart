import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lane_keeper/features/auth/data/auth_repository.dart';
import 'package:lane_keeper/features/auth/ui/login_screen.dart';
import 'package:lane_keeper/features/auth/ui/city_onboarding_screen.dart';
import 'package:lane_keeper/ui/home_screen.dart'; // We will create this later

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        
        // User is logged in, check for their profile to see if city is set
        final userProfileAsync = ref.watch(currentUserProvider);
        
        return userProfileAsync.when(
          data: (userModel) {
            if (userModel == null) {
              // This might happen momentarily during creation
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            
            if (userModel.city == null || userModel.city!.isEmpty) {
              return const CityOnboardingScreen();
            }
            
            return const HomeScreen();
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (err, stack) => Scaffold(
            body: Center(child: Text('Error loading profile: $err')),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }
}
