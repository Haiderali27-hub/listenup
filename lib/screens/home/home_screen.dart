import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_app/screens/menu/menu_screen.dart'; // Add import for MenuScreen
import 'package:sound_app/screens/notification/notification_screen.dart';
import 'package:sound_app/widgets/app_bottom_nav_bar.dart';
import 'package:sound_app/widgets/mic_button.dart';
import 'package:sound_app/widgets/status_pill.dart';
import 'package:sound_app/widgets/wave_clip_path.dart';
import 'package:sound_app/services/sound_service.dart';
import 'package:sound_app/services/background_service.dart';
import 'package:sound_app/services/notification_service.dart';
import 'package:sound_app/services/mic_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  String? detectedLabel;

  @override
  void initState() {
    super.initState();
    // Add a small delay before initializing services
    Future.delayed(const Duration(milliseconds: 1000), () {
      _initializeServices();
    });
    micListening.addListener(_micListener);
  }

  void _micListener() {
    setState(() {}); // Rebuild when micListening changes
  }

  Future<void> _initializeServices() async {
    try {
      print('🔑 Initializing services...');
      await _notificationService.initialize();
      print('✅ NotificationService initialized.');

      await BackgroundService().initialize();
      print('✅ BackgroundService initialized.');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing services: $e')),
        );
      }
    }
  }

  void toggleListening() async {
    print('UI: toggleListening called. Current micListening.value: ${micListening.value}');
    try {
      if (micListening.value) {
        print('UI: Toggling OFF - Calling BackgroundService().stopListening()');
        await BackgroundService().stopListening();
        micListening.value = false;
      } else {
        print('UI: Toggling ON - Requesting microphone permission...');
        // Request microphone permission before starting
        final status = await Permission.microphone.request();
        if (status.isGranted) {
          print('UI: Microphone permission granted. Calling BackgroundService().startListening()');
          await BackgroundService().startListening();
          micListening.value = true;
        } else {
          print('UI: Microphone permission denied.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Microphone permission is required to start listening'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('UI: Error toggling listening: $e');
      micListening.value = false; // Reset state on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling listening: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void stopListening() async {
    print('UI: Explicit stopListening() called (from close button).');
    try {
      await BackgroundService().stopListening();
      micListening.value = false;
    } catch (e) {
      print('UI: Error stopping listening (from close button): $e');
      micListening.value = false; // Reset state on error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping listening: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    micListening.removeListener(_micListener);
    BackgroundService().dispose();
    super.dispose();
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
                          child: micListening.value
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedMicButton(
                                      isListening: micListening.value,
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
                                  isListening: micListening.value,
                                  onTap: toggleListening,
                                ),
                        ),
                        const SizedBox(height: 40),
                        StatusPill(listening: micListening.value),
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

  Future<void> requestMicrophonePermission(BuildContext context) async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        // Show error/snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone permission is required.')),
        );
        return;
      }
    } else if (status.isPermanentlyDenied) {
      // Show dialog to open app settings
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Microphone Permission'),
          content: Text('Microphone permission is permanently denied. Please enable it in app settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: Text('Open Settings'),
            ),
          ],
        ),
      );
      return;
    }
  }

  Future<void> _syncMicrophonePermission() async {
    var status = await Permission.microphone.status;
    // Only update the UI, don't start/stop listening
    setState(() {}); // This will rebuild and show the correct toggle state
  }
}
