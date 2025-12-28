import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lane_keeper/core/constants/app_constants.dart';
import 'package:lane_keeper/core/theme/app_theme.dart';
import 'package:lane_keeper/features/auth/data/auth_repository.dart';

class CityOnboardingScreen extends ConsumerStatefulWidget {
  const CityOnboardingScreen({super.key});

  @override
  ConsumerState<CityOnboardingScreen> createState() => _CityOnboardingScreenState();
}

class _CityOnboardingScreenState extends ConsumerState<CityOnboardingScreen> {
  String? _selectedCity;
  bool _isLoading = false;

  Future<void> _saveCity() async {
    if (_selectedCity == null) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        await ref
            .read(authRepositoryProvider)
            .updateUserCity(user.uid, _selectedCity!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save city: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select your City")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Where do you drive?",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              "This helps us compare your driving metrics with others in your city.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "City",
                border: OutlineInputBorder(),
              ),
              value: _selectedCity,
              items: AppConstants.indianCities.map((city) {
                return DropdownMenuItem(value: city, child: Text(city));
              }).toList(),
              onChanged: (val) => setState(() => _selectedCity = val),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: (_selectedCity == null || _isLoading) ? null : _saveCity,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
