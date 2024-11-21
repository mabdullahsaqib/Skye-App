import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  String _botResponse = "Hi, I'm Skye! Start chatting with me.";
  bool _isListening = false;

  // Gemini API details
  final String _apiKey = "";
  final String _modelConfig = "";
  final String _endpoint =
      "https://api.generativeai.google.com/chat"; // Adjust based on API docs

  Future<void> _sendMessage(String userInput) async {
    setState(() {
      _botResponse = "Thinking...";
    });

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gemini-1.5-flash",
          "instruction": _modelConfig,
          "messages": [
            {"role": "user", "content": userInput}
          ],
          "temperature": 1.0,
          "top_p": 0.95,
          "top_k": 40,
          "max_output_tokens": 8192,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _botResponse = data["choices"][0]["message"]["content"];
        });
        _tts.speak(_botResponse);
      } else {
        setState(() {
          _botResponse = "Oops! Something went wrong. Try again later.";
        });
      }
    } catch (e) {
      setState(() {
        _botResponse = "An error occurred: $e";
      });
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(onResult: (result) {
          _controller.text = result.recognizedWords;
          if (result.hasConfidenceRating && result.confidence > 0.8) {
            _sendMessage(result.recognizedWords);
            _speech.stop();
            setState(() {
              _isListening = false;
            });
          }
        });
      }
    } else {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat with Skye")),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Text(_botResponse),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        InputDecoration(hintText: "Type your message..."),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_controller.text);
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
            onPressed: _listen,
          ),
        ],
      ),
    );
  }
}
