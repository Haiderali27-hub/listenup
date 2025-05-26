import 'package:flutter/material.dart';
import 'package:sound_app/screens/menu/menu_screen.dart'; // Add import for MenuScreen
import 'package:sound_app/screens/notification/notification_screen.dart';
import 'package:sound_app/widgets/app_bottom_nav_bar.dart';
import 'package:sound_app/widgets/mic_button.dart';
import 'package:sound_app/widgets/status_pill.dart';
import 'package:sound_app/widgets/wave_clip_path.dart';

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
      backgroundColor: Colors.white, // set white background globally
      bottomNavigationBar: const AppBottomNavBar(currentRoute: 'home'),

      // Remove drawer property since we're navigating to a separate screen

      body: Column(
        children: [
          // Custom top bar replacing AppBar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(
                top: 90.0,
                left: 20.0,
                right: 20.0,
                bottom: 0.0), // Modified padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Added crossAxisAlignment
              children: [
                Padding(
                  // Added Padding for menu icon
                  padding: const EdgeInsets.only(
                    top: 50.0,
                  ),
                  child: Builder(
                    builder: (context) => IconButton(
                      iconSize: 38.0, // increased from default
                      icon: const Icon(Icons.menu_open_sharp,
                          color: Color(0xFF0D2B55)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MenuScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(
                  height: 40, // Adjust height as needed
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      const Text(
                        'Listen Up!',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: Color(0xFF0D2B55),
                          fontWeight: FontWeight.w500,
                          fontSize: 30,
                        ),
                      ),
                      // Positioned underline under "Li"
                      Positioned(
                        left: 0, // start from text start
                        bottom: 0, // at bottom of text
                        child: Container(
                          width: 32, // width covering "Li"
                          height: 4, // thickness of underline
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D2B55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  // Added Padding for notification icon
                  padding: const EdgeInsets.only(top: 50.0),
                  child: IconButton(
                    iconSize: 38.0,
                    icon: const Icon(Icons.notifications_none,
                        color: Color(0xFF0D2B55)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 150,
            child: CustomPaint(
              size: Size(double.infinity, 150),
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                ClipPath(
                  clipper: WaveClipper(),
                  child: Container(
                    color: const Color(0xFFE5E5E5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: isListening
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedMicButton(
                                      isListening: isListening,
                                      onTap: toggleListening,
                                    ),
                                    const SizedBox(width: 120),
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
                              : AnimatedMicButton(
                                  isListening: isListening,
                                  onTap: toggleListening,
                                ),
                        ),
                        const SizedBox(height: 40),
                        StatusPill(listening: isListening),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
