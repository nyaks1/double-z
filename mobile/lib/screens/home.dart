import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/audio.dart';
import '../services/wallet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _textController = TextEditingController();
  final AudioService _audioService = AudioService();
  final WalletService _walletService = WalletService();
  bool _isRecording = false;
  bool _isTypingMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _toggleRecording() async {
    if (_isRecording) {
      // Stop recording and process
      setState(() {
        _isRecording = false;
        _isLoading = true;
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
    } else {
      // Start recording
      setState(() => _isRecording = true);
      await _audioService.startRecording();
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
                      : (_isTypingMode ? "Type your intent" : (_isRecording ? "Listening..." : "Tap to Speak")),
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
                
                if (!_isTypingMode) ...[
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isRecording)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 150 + (_pulseController.value * 30),
                                height: 150 + (_pulseController.value * 30),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                ),
                              );
                            },
                          ),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isRecording 
                                  ? [Colors.redAccent, Colors.deepOrange]
                                  : [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isRecording ? Colors.redAccent.withValues(alpha: 0.5) : Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Icon(
                                  _isRecording ? Icons.stop : Icons.mic,
                                  size: 50,
                                  color: Colors.white,
                                ),
                        ),
                      ],
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
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
