import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'profile_setup.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  void _fetchProfileData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _profileFuture = authService.getUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E8B82),
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
              ).then((_) => _fetchProfileData()); // Refresh data after returning
            },
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final currentUser = authService.currentUser;
          if (currentUser == null) {
            return const Center(child: Text('User not signed in.'));
          }

          return FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B82)));
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                final userProfile = snapshot.data;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFF2E8B82).withOpacity(0.1),
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF2E8B82),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              userProfile?['name'] ?? currentUser.displayName ?? 'User',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A5A54),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentUser.email ?? 'user@example.com',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Profile Details Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.cake, color: Color(0xFF2E8B82)),
                              title: const Text('Age', style: TextStyle(fontWeight: FontWeight.w600)),
                              trailing: Text(userProfile?['age']?.toString() ?? 'Not set'),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.wc, color: Color(0xFF2E8B82)),
                              title: const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600)),
                              trailing: Text(userProfile?['gender'] ?? 'Not set'),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.phone, color: Color(0xFF2E8B82)),
                              title: const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600)),
                              trailing: Text(userProfile?['phone'] ?? 'Not set'),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Sign Out Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Sign Out',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          onTap: () async {
                            await authService.signOut();
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
