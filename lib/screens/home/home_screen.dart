import 'package:flutter/material.dart';
import 'package:sound_app/widgets/WaveformPainter.dart';
import 'package:sound_app/widgets/mic_button.dart';
import 'package:sound_app/widgets/status_pill.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isListening = false;
  bool voiceDetected = false;

  void toggleListening() {
    setState(() {
      isListening = !isListening;
      voiceDetected = false;
    });
  }

  void stopListening() {
    setState(() {
      isListening = false;
      voiceDetected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF0D2B55)),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Listen Up!',
          style: TextStyle(
            color: Color(0xFF0D2B55),
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
            decorationThickness: 2,
            decorationColor: Color(0xFF0D2B55),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 150,
            child: CustomPaint(
              size: Size(double.infinity, 150),
              painter: WaveformPainter(),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // This AnimatedAlign will keep the Row centered when not listening,
                // then slide it left when listening starts.
                // inside your Column:
                Center(
                  child: isListening
                      //  Live state: mic + gap + cancel, all centered
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedMicButton(
                              isListening: isListening,
                              onTap: toggleListening,
                            ),
                            const SizedBox(
                                width: 120), // the exact gap you want
                            GestureDetector(
                              onTap: stopListening,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.black87),
                              ),
                            ),
                          ],
                        )
                      //  Idle state: just the mic, centered
                      : AnimatedMicButton(
                          isListening: isListening,
                          onTap: toggleListening,
                        ),
                ),

                const SizedBox(height: 40),

                const SizedBox(height: 40),
                StatusPill(listening: isListening),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
