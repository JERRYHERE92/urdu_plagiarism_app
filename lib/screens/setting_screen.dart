import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  void _showAboutUs() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("About Us"),
            content: const Text(
              "This app provides reliable Urdu plagiarism detection. "
              "Built with care to help students and professionals ensure originality.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Privacy Policy"),
            content: const Text(
              "Your privacy matters. Uploaded files are only used for plagiarism checks "
              "and are never shared with third parties.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  void _showRateUs() {
    showDialog(
      context: context,
      builder: (ctx) {
        int stars = 0;
        return StatefulBuilder(
          builder:
              (ctx, setDlg) => AlertDialog(
                title: const Text("Rate Us"),
                content: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      return IconButton(
                        iconSize: 32,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          i < stars ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () => setDlg(() => stars = i + 1),
                      );
                    }),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Fluttertoast.showToast(
                        msg: "Thanks for rating $stars star(s) ⭐",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    },
                    child: const Text("Submit"),
                  ),
                ],
              ),
        );
      },
    );
  }

  void _showChangePassword() {
    bool visOld = false, visNew = false;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDlg) => AlertDialog(
                  title: const Text("Change Password"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPasswordField(
                          label: 'Old Password',
                          controller: _oldPassController,
                          obscure: !visOld,
                          toggleVisibility:
                              () => setDlg(() => visOld = !visOld),
                          visible: visOld,
                        ),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                          label: 'New Password',
                          controller: _newPassController,
                          obscure: !visNew,
                          toggleVisibility:
                              () => setDlg(() => visNew = !visNew),
                          visible: visNew,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (_oldPassController.text.isEmpty ||
                            _newPassController.text.isEmpty) {
                          Fluttertoast.showToast(msg: "Both fields required");
                          return;
                        }

                        // Simulate change password API call
                        await changePassword(
                          _oldPassController.text,
                          _newPassController.text,
                        );

                        Navigator.pop(ctx);
                        _oldPassController.clear();
                        _newPassController.clear();
                      },
                      child: const Text("Submit"),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggleVisibility,
    required bool visible,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
          onPressed: toggleVisibility,
        ),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> changePassword(String oldPass, String newPass) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    if (token.isEmpty) throw Exception('Not logged in');

    try {
      final response = await ApiService.changePassword(
        token: token,
        oldPassword: oldPass,
        newPassword: newPass,
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Password changed successfully.");
      } else {
        final body = jsonDecode(response.body);
        Fluttertoast.showToast(
          msg: body['message'] ?? 'Password change failed',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Fluttertoast.showToast(msg: "Logged out successfully");

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2575FC), Color(0xFF6A11CB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.settings, size: 36, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: "Change Password",
                      onTap: _showChangePassword,
                    ),
                    _buildSettingsTile(
                      icon: Icons.star_rate_outlined,
                      title: "Rate Us",
                      onTap: _showRateUs,
                    ),
                    _buildSettingsTile(
                      icon: Icons.info_outline,
                      title: "About Us",
                      onTap: _showAboutUs,
                    ),
                    _buildSettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: "Privacy Policy",
                      onTap: _showPrivacyPolicy,
                    ),
                    _buildSettingsTile(
                      icon: Icons.logout,
                      title: "Logout",
                      onTap: _logout,
                      trailing: null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
