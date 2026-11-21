import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceTextInput extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String labelText;
  final String hintText;

  const VoiceTextInput({
    super.key,
    this.controller,
    this.onChanged,
    this.labelText = 'Emergency Description',
    this.hintText =
        'Describe your situation or tap the mic to speak (BM / EN)...',
  });

  @override
  State<VoiceTextInput> createState() => _VoiceTextInputState();
}

class _VoiceTextInputState extends State<VoiceTextInput> {
  late final TextEditingController _textController;
  final SpeechToText _speechToText = SpeechToText();

  bool _ownsController = false;
  bool _speechAvailable = false;
  bool _isListening = false;

  String _selectedLocaleId = 'ms_MY'; // Default BM; switchable to en_US
  String _baseTextBeforeSpeech = '';
  String _livePartialTranscript = '';
  String? _statusMessage;
  bool _isError = false;

  static const Map<String, String> _supportedLocales = {
    'ms_MY': 'BM (Bahasa Melayu)',
    'en_US': 'EN (English)',
  };

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _textController = widget.controller!;
    } else {
      _textController = TextEditingController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    if (_ownsController) {
      _textController.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
      return;
    }

    // Re-check initialize() if previously denied so Android re-prompts or updates hasPermission
    if (!_speechAvailable) {
      _speechAvailable = await _speechToText.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
    }

    final hasPermission = await _speechToText.hasPermission;
    if (!mounted) return;
    if (!hasPermission || !_speechAvailable) {
      _speechAvailable =
          false; // Allow retry if user grants permission in settings
      setState(() {
        _isError = true;
        _statusMessage = 'Microphone permission denied or speech service unavailable. Please enable mic access in Settings or type manually.';
      });
      return;
    }

    // Preserve any text the user already typed or edited
    _baseTextBeforeSpeech = _textController.text.trim();

    setState(() {
      _isListening = true;
      _isError = false;
      _livePartialTranscript = '';
      _statusMessage =
          'Listening (${_selectedLocaleId == 'ms_MY' ? 'BM' : 'EN'})... Speak now.';
    });

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        localeId: _selectedLocaleId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    if (!mounted) return;
    setState(() {
      _isListening = false;
      if (_livePartialTranscript.isEmpty &&
          _statusMessage?.startsWith('Listening') == true) {
        _isError = true;
        _statusMessage =
            'No speech detected. Please tap the mic and speak clearly.';
      } else if (!_isError) {
        _statusMessage = null;
      }
      _livePartialTranscript = '';
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    final spoken = result.recognizedWords.trim();

    final combined = _baseTextBeforeSpeech.isEmpty
        ? spoken
        : (spoken.isEmpty
              ? _baseTextBeforeSpeech
              : '$_baseTextBeforeSpeech $spoken');

    setState(() {
      _livePartialTranscript = spoken;
      _textController.value = TextEditingValue(
        text: combined,
        selection: TextSelection.collapsed(offset: combined.length),
      );
      _isError = false;
      if (result.finalResult) {
        _isListening = false;
        _livePartialTranscript = '';
        if (spoken.isEmpty) {
          _isError = true;
          _statusMessage = 'No speech detected. Tap the mic to try again.';
        } else {
          _statusMessage = null;
        }
      }
    });

    widget.onChanged?.call(combined);
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      setState(() {
        if (_isListening && _livePartialTranscript.isEmpty) {
          _isError = true;
          _statusMessage = 'No speech detected. Tap the mic to try again.';
        } else if (!_isError) {
          _statusMessage = null;
        }
        _isListening = false;
        _livePartialTranscript = '';
      });
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    final msg = error.errorMsg.toLowerCase();
    final isPermissionDenied = msg.contains('permission');
    final isNoSpeech =
        msg.contains('no_match') ||
        msg.contains('speech_timeout') ||
        msg.contains('no_speech');

    if (isPermissionDenied) {
      _speechAvailable = false;
    }

    setState(() {
      _isListening = false;
      _livePartialTranscript = '';
      _isError = true;
      if (isPermissionDenied) {
        _statusMessage = 'Microphone permission denied. Please allow mic access in Android Settings or type manually.';
      } else if (isNoSpeech) {
        _statusMessage =
            'No speech detected. Please speak closer to the microphone.';
      } else {
        _statusMessage =
            'Speech error (${error.errorMsg}). You can type your message directly.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // BM / EN Language Selector
        Row(
          children: [
            const Icon(Icons.language, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Voice Language:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              key: const Key('locale_bm_chip'),
              label: const Text('BM'),
              selected: _selectedLocaleId == 'ms_MY',
              onSelected: _isListening
                  ? null
                  : (_) => setState(() => _selectedLocaleId = 'ms_MY'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              key: const Key('locale_en_chip'),
              label: const Text('EN'),
              selected: _selectedLocaleId == 'en_US',
              onSelected: _isListening
                  ? null
                  : (_) => setState(() => _selectedLocaleId = 'en_US'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Editable Text Box + Mic Button
        TextFormField(
          key: const Key('sos_voice_text_field'),
          controller: _textController,
          maxLines: 4,
          minLines: 3,
          readOnly: false,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: IconButton(
                key: const Key('sos_mic_button'),
                tooltip: _isListening
                    ? 'Stop recording'
                    : 'Record voice (${_supportedLocales[_selectedLocaleId]})',
                onPressed: _toggleListening,
                icon: CircleAvatar(
                  backgroundColor: _isListening
                      ? Colors.red
                      : theme.colorScheme.primaryContainer,
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: _isListening
                        ? Colors.white
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Live Transcript Banner while Speaking
        if (_isListening) ...[
          const SizedBox(height: 8),
          Container(
            key: const Key('live_transcript_banner'),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _livePartialTranscript.isEmpty
                        ? 'Listening... speak now'
                        : 'Live: "$_livePartialTranscript"',
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Error / Status Message (Permission Denied & No Speech)
        if (_statusMessage != null && !_isListening) ...[
          const SizedBox(height: 8),
          Text(
            _statusMessage!,
            key: const Key('voice_status_message'),
            style: TextStyle(
              fontSize: 13,
              color: _isError ? Colors.red.shade700 : Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );
  }
}
