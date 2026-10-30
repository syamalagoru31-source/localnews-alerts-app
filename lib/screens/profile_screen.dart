import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../database/database_helper.dart';
import '../services/user_session.dart';
import 'edit_profile_screen.dart';
import 'location_screen.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  String? profilePhoto;
  bool isPhotoLoading = false;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final name = await UserSession.getUserName();
    final email = await UserSession.getUserEmail();
    final userId = await UserSession.getUserId();

    String? photo;

    if (userId != null) {
      final db = await DatabaseHelper.instance.database;

      final users = await db.query(
        'users',
        columns: ['profile_photo'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (users.isNotEmpty) {
        photo = users.first['profile_photo'] as String?;
      }
    }

    if (!mounted) return;

    setState(() {
      userName = name ?? 'Local News User';
      userEmail = email ?? 'user@localnews.com';
      profilePhoto = photo;
    });
  }

  Future<void> pickProfilePhoto() async {
    setState(() {
      isPhotoLoading = true;
    });

    try {
      final picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 600,
      );

      if (image == null) {
        if (mounted) {
          setState(() {
            isPhotoLoading = false;
          });
        }
        return;
      }

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final userId = await UserSession.getUserId();

      if (userId == null) {
        throw Exception('User session not found');
      }

      final db = await DatabaseHelper.instance.database;

      await db.update(
        'users',
        {'profile_photo': base64Image},
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (!mounted) return;

      setState(() {
        profilePhoto = base64Image;
        isPhotoLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isPhotoLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update profile photo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),

              child: Column(
                children: [
                  GestureDetector(
                    onTap: isPhotoLoading ? null : pickProfilePhoto,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: profilePhoto != null
                              ? MemoryImage(base64Decode(profilePhoto!))
                              : null,
                          child: profilePhoto == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 55,
                                  color: Colors.blue.shade700,
                                )
                              : null,
                        ),

                        if (isPhotoLoading)
                          const SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),

                        if (!isPhotoLoading)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    userEmail,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _option(
              icon: Icons.person_outline_rounded,
              title: 'Edit Profile',
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );

                if (updated == true) {
                  loadUser();
                }
              },
            ),

            _option(
              icon: Icons.location_on_outlined,
              title: 'Location',
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationScreen(),
                  ),
                );

                if (updated == true) {
                  loadUser();
                }
              },
            ),

            _option(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () async {
                await NotificationService.showNotification(
                  title: 'Local News',
                  body: 'This is a test notification from your Local News app.',
                );
              },
            ),

            _option(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () async {
                await NotificationService.requestPermission();
              },
            ),

            _option(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              onTap: () {},
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,

              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
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

  Widget _option({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),

      child: ListTile(
        leading: Icon(icon, color: Colors.blue.shade700),

        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),

        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15),

        onTap: onTap,
      ),
    );
  }
}
