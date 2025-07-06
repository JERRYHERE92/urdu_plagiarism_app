import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  int? _id;
  String? _name, _email;
  String? _createdAtRaw;
  String? _createdAt;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      if (token.isEmpty) throw Exception('Not logged in');

      final response = await ApiService.getProfile(token: token);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final raw = data['created_at'] as String? ?? '';
        final dt = DateTime.parse(raw);
        final formatted = DateFormat('MMM d, yyyy  hh:mm a').format(dt);
        setState(() {
          _id = data['id'];
          _name = data['name'];
          _email = data['email'];
          _createdAtRaw = raw;
          _createdAt = formatted;
        });
      } else {
        Fluttertoast.showToast(
          msg: data['detail'] ?? data['message'] ?? 'Failed to load profile',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching profile');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.deepPurple),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Welcome Card like Home Screen
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2575FC), Color(0xFF6A11CB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: const [
                              Icon(Icons.person, size: 36, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Profile',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Profile Info Card
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 6,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildField('User ID', _id?.toString() ?? ''),
                              const Divider(height: 24),
                              _buildField('Name', _name ?? ''),
                              const Divider(height: 24),
                              _buildField('Email', _email ?? ''),
                              const Divider(height: 24),
                              _buildField('Joined On', _createdAt ?? ''),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Logout Button
                      ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text(
                          'Logout',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A11CB),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 6,
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
