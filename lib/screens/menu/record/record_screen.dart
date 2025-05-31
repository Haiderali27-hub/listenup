import 'package:flutter/material.dart';
import 'package:sound_app/screens/home/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RecordScreen extends StatelessWidget {
  final bool fromBottomNav;

  const RecordScreen({
    super.key,
    this.fromBottomNav = false,
  });

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
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
      body: userId == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sound_detections')
                  .where('userId', isEqualTo: userId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No records found.'));
                }
                final records = snapshot.data!.docs;
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
                            final data = records[index].data() as Map<String, dynamic>;
                            final timestamp = data['timestamp'] as Timestamp?;
                            final dateTime = timestamp?.toDate();
                            final dateStr = dateTime != null ? DateFormat('dd-MMM-yyyy').format(dateTime) : '-';
                            final timeStr = dateTime != null ? DateFormat('h:mma').format(dateTime) : '-';
                            final label = data['label']?.toString() ?? '-';
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
                                      label,
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
