import 'package:flutter/material.dart';
import 'package:background_service/background_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  // ... (existing code)
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BackgroundService _backgroundService = BackgroundService();
  bool _isListening = false;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _backgroundService.initialize();
      _backgroundService.onProcessingStateChanged = _handleProcessingState;
      _backgroundService.onShowMessage = _showMessage;
    } catch (e) {
      print('Error initializing service: $e');
      if (mounted) {
        _showMessage('Failed to initialize service');
      }
    }
  }

  void _handleProcessingState(bool isProcessing) {
    if (mounted) {
      setState(() {
        _isProcessing = isProcessing;
      });
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      setState(() {
        _message = message;
      });
      // Clear message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _message = null;
          });
        }
      });
    }
  }

  Future<void> _toggleListening() async {
    if (_isLoading) {
      return;  // Prevent multiple clicks
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (!_isListening) {
        await _backgroundService.startListening();
        if (mounted) {
          setState(() {
            _isListening = true;
            _isLoading = false;
          });
        }
      } else {
        await _backgroundService.stopListening();
        if (mounted) {
          setState(() {
            _isListening = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error toggling listening: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showMessage('Failed to ${_isListening ? 'stop' : 'start'} listening');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_message != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _message!,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            IconButton(
              iconSize: 64,
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_off,
                color: _isListening ? Colors.red : Colors.grey,
              ),
              onPressed: _isProcessing ? null : _toggleListening,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Text(
                _isListening ? 'Listening...' : 'Tap to Start',
                style: const TextStyle(fontSize: 18),
              ),
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Processing audio...',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 