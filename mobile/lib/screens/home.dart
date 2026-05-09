import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:record/record.dart';
import '../services/audio.dart';
import '../services/wallet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final AudioService _audioService = AudioService();
  final WalletService _walletService = WalletService();
  
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isTypingMode = false;
  bool _isLoading = false;

  StreamSubscription<Amplitude>? _amplitudeSub;
  double _currentAmplitude = -50.0;

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    _textController.dispose();
    super.dispose();
  }

  double get _normalizedAmplitude {
    // Amplitude is usually between -50 and 0. Normalize to 0.0 - 1.0
    double minAmp = -50.0;
    double maxAmp = 0.0;
    if (_currentAmplitude < minAmp) return 0.0;
    if (_currentAmplitude > maxAmp) return 1.0;
    return (_currentAmplitude - minAmp) / (maxAmp - minAmp);
  }

  void _startRecording() async {
    setState(() {
      _isRecording = true;
      _isPaused = false;
    });
    await _audioService.startRecording();
    
    _amplitudeSub = _audioService.getAmplitudeStream().listen((amp) {
      if (mounted) {
        setState(() {
          _currentAmplitude = amp.current;
        });
      }
    });
  }

  void _pauseOrResumeRecording() async {
    if (_isPaused) {
      await _audioService.resumeRecording();
      setState(() => _isPaused = false);
    } else {
      await _audioService.pauseRecording();
      setState(() => _isPaused = true);
      // When paused, stop the visualizer movement
      setState(() => _currentAmplitude = -50.0);
    }
  }

  void _cancelRecording() async {
    _amplitudeSub?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _currentAmplitude = -50.0;
    });
    await _audioService.cancelRecording();
  }

  void _sendRecording() async {
    _amplitudeSub?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _isLoading = true;
      _currentAmplitude = -50.0;
    });
    
    try {
      final walletPubkey = await _walletService.getWalletPubkey();
      final contactsJson = jsonEncode({"Nyaks": "4Nd1m1aCGcgKpzRyVDcw1XpYwJvL6o8k3sQ1QXZz9N3X"}); // Mock contacts
      final response = await _audioService.stopAndProcess(walletPubkey, contactsJson);
      
      if (response != null && mounted) {
         Navigator.pushNamed(context, '/confirm', arguments: {
           'amount': response['parsed']['amount'],
           'recipient_name': response['parsed']['recipient_name'],
           'transaction_payload': response['transaction_payload'],
         });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendTextIntent() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final walletPubkey = await _walletService.getWalletPubkey();
      final contactsJson = jsonEncode({"Nyaks": "4Nd1m1aCGcgKpzRyVDcw1XpYwJvL6o8k3sQ1QXZz9N3X"}); // Mock contacts
      
      final response = await _audioService.sendTextIntent(walletPubkey, contactsJson, text);
      
      if (response != null && mounted) {
         Navigator.pushNamed(context, '/confirm', arguments: {
           'amount': response['parsed']['amount'],
           'recipient_name': response['parsed']['recipient_name'],
           'transaction_payload': response['transaction_payload'],
         });
         _textController.clear();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF2A2B4A), Color(0xFF0D0E15)],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  _isLoading 
                      ? "Processing..." 
                      : (_isTypingMode ? "Type your intent" : (_isRecording ? (_isPaused ? "Paused" : "Recording...") : "Tap to Speak")),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  "\"Send 5 SOL to Nyaks\"",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.white54,
                  ),
                ),
                const Spacer(),
                
                if (_isLoading) ...[
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 80),
                ] else if (!_isTypingMode) ...[
                  if (!_isRecording) ...[
                    GestureDetector(
                      onTap: _startRecording,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.mic, size: 50, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 32.0),
                        child: IconButton(
                          icon: const Icon(Icons.keyboard, color: Colors.white70, size: 32),
                          onPressed: () => setState(() => _isTypingMode = true),
                          tooltip: "Type your intent",
                        ),
                      ),
                    ),
                  ] else ...[
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 50),
                          width: 280 + (_normalizedAmplitude * 60),
                          height: 80 + (_normalizedAmplitude * 30),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15 + (_normalizedAmplitude * 0.2)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              )
                            ]
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
                                onPressed: _cancelRecording,
                                tooltip: "Delete",
                              ),
                              const SizedBox(width: 24),
                              IconButton(
                                icon: Icon(_isPaused ? Icons.mic : Icons.pause, color: Colors.white, size: 32),
                                onPressed: _pauseOrResumeRecording,
                                tooltip: _isPaused ? "Resume" : "Pause",
                              ),
                              const SizedBox(width: 24),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.send, color: Colors.white, size: 26),
                                  onPressed: _sendRecording,
                                  tooltip: "Send",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.mic, color: Colors.white70),
                            onPressed: () => setState(() => _isTypingMode = false),
                            tooltip: "Use Voice",
                          ),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: "Send 5 SOL to Nyaks",
                                hintStyle: TextStyle(color: Colors.white30),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (value) => _sendTextIntent(),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _sendTextIntent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
