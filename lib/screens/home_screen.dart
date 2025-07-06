import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/profile_screen.dart';
import '../screens/history_screen.dart';
import '../screens/setting_screen.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // --- file / API state ---
  PlatformFile? _pickedFile;
  bool _isLoading = false;
  String? _resultText;
  String? _reportUrl; // store the API’s report_url

  /// Pick a new file. Also clear any prior result/report.
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        _resultText = null;
        _reportUrl = null;
      });
      Fluttertoast.showToast(msg: 'Picked: ${_pickedFile!.name}');
    }
  }

  /// Call your /check-plagiarism/ endpoint.
  Future<void> _startPlagiarismCheck() async {
    if (_pickedFile == null) {
      Fluttertoast.showToast(msg: 'Please select a file first!');
      return;
    }

    // get JWT token
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    if (token.isEmpty) {
      Fluttertoast.showToast(msg: 'Not logged in');
      return;
    }

    setState(() {
      _isLoading = true;
      _resultText = null;
      _reportUrl = null;
    });

    try {
      final response = await ApiService.checkPlagiarism(
        file: File(_pickedFile!.path!),
        token: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Pretty-print the analysis:
        const jsonEncoder = JsonEncoder.withIndent('  ');
        setState(() {
          _resultText = jsonEncoder.convert(data['analysis']);
          _reportUrl = data['report_url']; // e.g. "/download-report/xxx.pdf"
        });
      } else {
        setState(() {
          _resultText = 'Failed (status ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _resultText = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Download & open the PDF report
  Future<void> _downloadReport() async {
    if (_reportUrl == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final dio = Dio();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/${_pickedFile!.name}_report.pdf';
      final fullUrl = ApiService.baseUrl + _reportUrl!;
      final resp = await dio.download(
        fullUrl,
        path,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (resp.statusCode == 200) {
        await OpenFilex.open(path);
      } else {
        Fluttertoast.showToast(msg: 'Download failed');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error downloading: $e');
    }
  }

  /// Build the “home” tab
  Widget _buildHomeBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2575FC), Color(0xFF6A11CB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: const Text(
                'WELCOME TO\nاردو PLAG CHECKER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Upload your document below to start the plagiarism check.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 24),

          // Pick file
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file),
            label: Text(
              _pickedFile == null
                  ? 'Select File to Upload'
                  : 'Selected: ${_pickedFile!.name}',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Start check
          ElevatedButton(
            onPressed: _startPlagiarismCheck,
            child: const Text('Start Check'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          // … above remains the same …

          // After the “Start Check” button:
          const SizedBox(height: 24),

          if (_isLoading)
            const CircularProgressIndicator()
          else if (_reportUrl != null) ...[
            const Text(
              'Download your plagiarism report:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _downloadReport,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Download Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build body based on bottom nav index
  Widget _buildBody() {
    switch (_currentIndex) {
      case 1:
        return const ProfileScreen();
      case 2:
        return const HistoryScreen();
      case 3:
        return const SettingsScreen();
      case 0:
      default:
        return _buildHomeBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (idx) {
          // clear any stale file/result when switching tabs
          setState(() {
            _currentIndex = idx;
            _pickedFile = null;
            _resultText = null;
            _reportUrl = null;
            _isLoading = false;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
