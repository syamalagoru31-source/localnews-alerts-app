import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../services/user_session.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final locationController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  final List<String> popularLocations = [
    'Kakinada',
    'Rajahmundry',
    'Visakhapatnam',
    'Vijayawada',
    'Hyderabad',
    'Warangal',
    'Chennai',
    'Bengaluru',
  ];

  @override
  void initState() {
    super.initState();
    loadLocation();
  }

  Future<void> loadLocation() async {
    final userId = await UserSession.getUserId();

    if (userId != null) {
      final db = await DatabaseHelper.instance.database;

      final users = await db.query(
        'users',
        columns: ['location'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (users.isNotEmpty) {
        locationController.text = (users.first['location'] as String?) ?? '';
      }
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveLocation() async {
    final location = locationController.text.trim();

    if (location.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a location')));
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final userId = await UserSession.getUserId();

      if (userId == null) {
        throw Exception('User session not found');
      }

      final db = await DatabaseHelper.instance.database;

      await db.update(
        'users',
        {'location': location},
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location saved successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save location: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Location',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 65,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Your Location',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Choose a location to receive relevant local news.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Search or enter city',
                      hintText: 'Example: Kakinada',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Popular Locations',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: popularLocations.map((location) {
                      return ActionChip(
                        avatar: const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                        ),
                        label: Text(location),
                        onPressed: () {
                          setState(() {
                            locationController.text = location;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : saveLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'SAVE LOCATION',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
