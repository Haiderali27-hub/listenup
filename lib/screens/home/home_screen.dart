import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
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
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

  bool _recorderInitialized = false;

  bool isListening = false;
  bool voiceDetected = false;

  void toggleListening() async {
    if (!_recorderInitialized) {
      try {
        // Check current permission status first
        PermissionStatus status = await Permission.microphone.status;

        // Only request if not already granted
        if (status.isDenied) {
          status = await Permission.microphone.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Microphone permission is required to use this feature'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } else if (status.isPermanentlyDenied) {
          // Show dialog to open settings if permanently denied
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Microphone Permission'),
              content: const Text(
                  'Microphone permission is required to use this feature. Please enable it in settings.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => openAppSettings(),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          return;
        }

        // Initialize recorder only after permission is granted
        await _audioRecorder.openRecorder();
        _recorderInitialized = true;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing microphone: $e')),
        );
        return;
      }
    }

    if (isListening) {
      // stop
      final path = await _stopRecording();
      print('Recorded file saved at: $path');
      setState(() {
        isListening = false;
        voiceDetected = false;
      });
    } else {
      // start
      await _startRecording();
      setState(() {
        isListening = true;
        voiceDetected = false;
      });
    }
  }

  void stopListening() async {
    if (isListening) {
      await _stopRecording();
    }
    setState(() {
      isListening = false;
      voiceDetected = false;
    });
  }

  Future<void> _startRecording() async {
    if (!_recorderInitialized) return;
    await _audioRecorder.startRecorder(
      toFile: 'audio.aac', // local temporary file
      codec: Codec.aacADTS,
    );
  }

  Future<String?> _stopRecording() async {
    if (!_recorderInitialized) return null;
    return await _audioRecorder.stopRecorder();
  }

  @override
  void dispose() {
    if (_recorderInitialized) {
      _audioRecorder.closeRecorder();
    }
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
