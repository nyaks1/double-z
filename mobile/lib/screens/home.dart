import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _textController = TextEditingController();
  bool _isRecording = false;
  bool _isTypingMode = false;

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

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    
    // TODO: Integrate actual audio recording service and API call
    if (!_isRecording) {
      // Simulate sending to backend and navigating to confirm screen
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushNamed(context, '/confirm', arguments: {
            'amount': 5.0,
            'recipient_name': 'Nyaks',
            'transaction_payload': 'mock_base64_tx',
          });
        }
      });
    }
  }

  void _sendTextIntent() {
    if (_textController.text.trim().isEmpty) return;
    
    // TODO: Integrate actual text sending service and API call
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushNamed(context, '/confirm', arguments: {
          'amount': 5.0,
          'recipient_name': 'Nyaks',
          'transaction_payload': 'mock_base64_tx',
        });
        _textController.clear();
      }
    });
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
                  _isTypingMode ? "Type your intent" : (_isRecording ? "Listening..." : "Tap to Speak"),
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
                          child: Icon(
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
