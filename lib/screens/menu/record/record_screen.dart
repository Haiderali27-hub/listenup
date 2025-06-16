import 'package:flutter/material.dart';
import 'package:sound_app/screens/home/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sound_app/services/auth_service.dart';

class RecordScreen extends StatelessWidget {
  final bool fromBottomNav;

  const RecordScreen({
    super.key,
    this.fromBottomNav = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (fromBottomNav) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Record',
          style: TextStyle(color: Colors.black87),
        ),
      ),
      body: FutureBuilder<http.Response>(
        future: AuthService.authenticatedRequest((token) => http.get(
          Uri.parse('http://13.61.5.249:8000/auth/user/records/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
          if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
            return const Center(child: Text('No records found.'));
          }
          final List records = jsonDecode(snapshot.data!.body);
          if (records.isEmpty) {
                  return const Center(child: Text('No records found.'));
                }
                return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Voice',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Time',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: records.length,
                itemBuilder: (context, index) {
                      final data = records[index] as Map<String, dynamic>;
                      final dateTime = (DateTime.tryParse(data['timestamp'] ?? '')?.toLocal()) ?? DateTime.now();
                      final dateStr = DateFormat('dd-MMM-yyyy').format(dateTime);
                      final timeStr = DateFormat('h:mma').format(dateTime);
                      String displayLabel = data['label']?.toString() ?? '-';
                      // Parse the label to remove ID and path if present
                      if (displayLabel.contains(',')) {
                        final parts = displayLabel.split(',');
                        if (parts.length >= 3) {
                          displayLabel = parts[2];
                        }
                      }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                                      dateStr,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(
                          child: Text(
                                      displayLabel,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(
                          child: Text(
                                      timeStr,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                        ),
              ),
            ],
          ),
                );
              },
      ),
    );
  }
}
