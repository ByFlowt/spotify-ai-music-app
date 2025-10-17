import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Web Audio Recorder Service
/// Handles browser-based microphone recording for audio recognition
class WebAudioRecorder extends ChangeNotifier {
  html.MediaStream? _mediaStream;
  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _recordedChunks = [];
  bool _isRecording = false;
  bool _isInitialized = false;
  String? _error;

  bool get isRecording => _isRecording;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  /// Initialize the audio recorder and request microphone permission
  Future<bool> initialize() async {
    if (!kIsWeb) {
      _error = 'Audio recording is only supported on web platform';
      notifyListeners();
      return false;
    }

    try {
      // Request microphone access
      final constraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'sampleRate': 44100,
        },
      };

      _mediaStream = await html.window.navigator.mediaDevices!
          .getUserMedia(constraints);

      _isInitialized = true;
      _error = null;
      notifyListeners();

      if (kDebugMode) {
        print('🎤 [WEB AUDIO] Microphone initialized successfully');
      }

      return true;
    } catch (e) {
      _error = 'Failed to access microphone: ${e.toString()}';
      _isInitialized = false;
      notifyListeners();

      if (kDebugMode) {
        print('🎤 [WEB AUDIO] Error: $_error');
      }

      return false;
    }
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    if (!_isInitialized || _mediaStream == null) {
      _error = 'Microphone not initialized. Call initialize() first.';
      notifyListeners();
      return false;
    }

    try {
      _recordedChunks = [];

      // Create MediaRecorder with webm/opus format
      _mediaRecorder = html.MediaRecorder(_mediaStream!, {
        'mimeType': 'audio/webm;codecs=opus',
      });

      // Listen for data available
      _mediaRecorder!.addEventListener('dataavailable', (event) {
        final blobEvent = event as html.BlobEvent;
        if (blobEvent.data != null && blobEvent.data!.size > 0) {
          _recordedChunks.add(blobEvent.data!);
        }
      });

      // Start recording
      _mediaRecorder!.start();
      _isRecording = true;
      _error = null;
      notifyListeners();

      if (kDebugMode) {
        print('🎤 [WEB AUDIO] Recording started');
      }

      return true;
    } catch (e) {
      _error = 'Failed to start recording: ${e.toString()}';
      _isRecording = false;
      notifyListeners();

      if (kDebugMode) {
        print('🎤 [WEB AUDIO] Error: $_error');
      }

      return false;
    }
  }

  /// Stop recording and return the audio data as base64
  Future<String?> stopRecording() async {
    if (!_isRecording || _mediaRecorder == null) {
      _error = 'Not currently recording';
      notifyListeners();
      return null;
    }

    try {
      final completer = Completer<String?>();

      // Listen for stop event
      _mediaRecorder!.addEventListener('stop', (event) async {
        try {
          if (_recordedChunks.isEmpty) {
            completer.complete(null);
            return;
          }

          // Create a blob from recorded chunks
          final blob = html.Blob(_recordedChunks, 'audio/webm;codecs=opus');

          // Convert blob to base64
          final reader = html.FileReader();
          reader.readAsArrayBuffer(blob);

          await reader.onLoadEnd.first;

          if (reader.result != null) {
            final bytes = reader.result as Uint8List;
            final base64Audio = base64Encode(bytes);
            completer.complete(base64Audio);

            if (kDebugMode) {
              print('🎤 [WEB AUDIO] Recording stopped, size: ${bytes.length} bytes');
            }
          } else {
            completer.complete(null);
          }
        } catch (e) {
          if (kDebugMode) {
            print('🎤 [WEB AUDIO] Error converting audio: $e');
          }
          completer.complete(null);
        }
      });

      // Stop the recorder
      _mediaRecorder!.stop();
      _isRecording = false;
      notifyListeners();

      return await completer.future;
    } catch (e) {
      _error = 'Failed to stop recording: ${e.toString()}';
      _isRecording = false;
      notifyListeners();

      if (kDebugMode) {
        print('🎤 [WEB AUDIO] Error: $_error');
      }

      return null;
    }
  }

  /// Cancel recording without saving
  void cancelRecording() {
    if (_mediaRecorder != null && _isRecording) {
      _mediaRecorder!.stop();
      _recordedChunks = [];
      _isRecording = false;
      notifyListeners();

      if (kDebugMode) {
        print('🎤 [WEB AUDIO] Recording cancelled');
      }
    }
  }

  /// Clean up resources
  @override
  void dispose() {
    if (_mediaStream != null) {
      _mediaStream!.getTracks().forEach((track) => track.stop());
      _mediaStream = null;
    }
    if (_mediaRecorder != null) {
      if (_isRecording) {
        _mediaRecorder!.stop();
      }
      _mediaRecorder = null;
    }
    _recordedChunks = [];
    _isInitialized = false;
    _isRecording = false;
    super.dispose();
  }
}

/// Helper function to convert Uint8List to base64
String base64Encode(Uint8List bytes) {
  const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  final List<int> output = [];

  for (int i = 0; i < bytes.length; i += 3) {
    final int b1 = bytes[i];
    final int b2 = i + 1 < bytes.length ? bytes[i + 1] : 0;
    final int b3 = i + 2 < bytes.length ? bytes[i + 2] : 0;

    final int n = (b1 << 16) | (b2 << 8) | b3;

    output.add(chars.codeUnitAt((n >> 18) & 63));
    output.add(chars.codeUnitAt((n >> 12) & 63));
    output.add(i + 1 < bytes.length ? chars.codeUnitAt((n >> 6) & 63) : 61); // 61 is '='
    output.add(i + 2 < bytes.length ? chars.codeUnitAt(n & 63) : 61);
  }

  return String.fromCharCodes(output);
}
