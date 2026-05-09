import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final AudioRecorder _record = AudioRecorder();
  String? _audioPath;

  // Change this to your backend IP if running on device, or 10.0.2.2 for emulator
  final String _backendUrl = 'https://double-z-up63.onrender.com/process_intent';

  Future<void> startRecording() async {
    if (await _record.hasPermission()) {
      final Directory tempDir = await getTemporaryDirectory();
      _audioPath = '${tempDir.path}/voice_intent.m4a';

      // Start recording to file
      await _record.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _audioPath!,
      );
    }
  }

  Future<void> pauseRecording() async {
    await _record.pause();
  }

  Future<void> resumeRecording() async {
    await _record.resume();
  }

  Future<void> cancelRecording() async {
    final path = await _record.stop();
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  Stream<Amplitude> getAmplitudeStream() {
    return _record.onAmplitudeChanged(const Duration(milliseconds: 50));
  }

  Future<Map<String, dynamic>?> stopAndProcess(String walletPubkey, String contactsJson) async {
    final path = await _record.stop();
    if (path == null) return null;

    final file = File(path);
    if (!file.existsSync()) return null;

    // Send multipart request
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_backendUrl));
      
      request.fields['wallet_pubkey'] = walletPubkey;
      request.fields['contacts'] = contactsJson;
      
      request.files.add(await http.MultipartFile.fromPath('audio', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint("Backend error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Network error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendTextIntent(String walletPubkey, String contactsJson, String textIntent) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_backendUrl));
      
      request.fields['wallet_pubkey'] = walletPubkey;
      request.fields['contacts'] = contactsJson;
      request.fields['text_intent'] = textIntent;
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint("Backend error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Network error: $e");
      return null;
    }
  }
}
