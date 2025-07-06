import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  String extractFinalVerdict(String result) {
    if (result == null || result.isEmpty) return 'Result: Unknown';
    final lines = result.split('\n');
    final verdictLine = lines.firstWhere(
      (line) => line.contains('Final Verdict:'),
      orElse: () => 'Result: Not Available',
    );
    final cleaned = verdictLine.split('Final Verdict:').last.trim();
    return 'Result: $cleaned';
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      if (token.isEmpty) throw Exception('Not logged in');

      final response = await ApiService.getHistory(token: token);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() => _history = data['history']);
      } else {
        Fluttertoast.showToast(
          msg: data['detail'] ?? data['message'] ?? 'Failed to load history',
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching history');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadAndOpenFile(String endpoint, String filename) async {
    try {
      final baseUrl =
          ApiService.baseUrl.endsWith('/')
              ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1)
              : ApiService.baseUrl;

      final url = '$baseUrl$endpoint';
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$filename';

      final dio = Dio();
      final response = await dio.download(
        url,
        filePath,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Download complete');
        await OpenFilex.open(filePath);
      } else {
        Fluttertoast.showToast(msg: 'Failed to download file');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Download error: $e');
    }
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
                : Padding(
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
                            Icon(Icons.history, size: 36, color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              'History',
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
                        child:
                            _history.isEmpty
                                ? const Center(
                                  child: Text("No history available"),
                                )
                                : ListView.builder(
                                  itemCount: _history.length,
                                  itemBuilder: (context, index) {
                                    final item =
                                        _history[_history.length - 1 - index];
                                    final uploadFileName =
                                        item["upload_file_url"].split('/').last;
                                    final reportFileName =
                                        item["report_url"].split('/').last;
                                    final raw = item["timestamp"] as String;
                                    final dt = DateTime.parse(raw);
                                    // Format to, e.g., "May 29, 2025 05:58 PM"
                                    final formatted = DateFormat(
                                      'MMM d, yyyy  hh:mm a',
                                    ).format(dt);

                                    return Card(
                                      elevation: 4,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '📄 ${item["file_name"]}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              extractFinalVerdict(
                                                item["plagiarism_result"],
                                              ),
                                              style: const TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Parse the ISO timestamp string

                                            // Then in the widget tree:
                                            Text(
                                              'Date: $formatted',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),

                                            const Divider(height: 20),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: () {
                                                    _downloadAndOpenFile(
                                                      '/download-upload/$uploadFileName',
                                                      item["file_name"],
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.download,
                                                  ),
                                                  label: const Text(
                                                    "Upload File",
                                                  ),
                                                ),
                                                TextButton.icon(
                                                  onPressed: () {
                                                    _downloadAndOpenFile(
                                                      '/download-report/$reportFileName',
                                                      'report_${item["file_name"]}.pdf',
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.download,
                                                  ),
                                                  label: const Text("Report"),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
