import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Command Executor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CommandScreen(),
    );
  }
}

class CommandScreen extends StatefulWidget {
  const CommandScreen({Key? key}) : super(key: key);

  @override
  State<CommandScreen> createState() => _CommandScreenState();
}

class _CommandScreenState extends State<CommandScreen> {
  final TextEditingController _commandController = TextEditingController();
  final FocusNode _commandFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isLoading = false;

  final String apiUrl =
      "https://skye-2xsolution.vercel.app/command"; // Replace with your API URL

  Future<void> _sendCommand(String command) async {
    if (command.isEmpty) return;

    setState(() {
      _isLoading = true;
      _chatHistory.add({"role": "user", "message": command});
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2NzQwNWY3NGZhNTQxN2FlOWMxZWFmNDQiLCJpYXQiOjE3MzIyNzE5ODgsImV4cCI6MTczMjg3Njc4OH0.ehG_Ct02PzoKCpiefExII5HOaXh0nM4AJPQ1SIVsU1Q',
        },
        body: jsonEncode({"command": command}),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        setState(() {
          _chatHistory.add({"role": "api", "message": responseBody});
        });
      } else {
        setState(() {
          _chatHistory.add({
            "role": "api",
            "message": "Error: ${response.statusCode} - ${response.body}"
          });
        });
      }
    } catch (e) {
      setState(() {
        _chatHistory.add({"role": "api", "message": "Error: $e"});
      });
    } finally {
      _commandController.clear();
      _scrollToBottom();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Executor'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final chat = _chatHistory[index];
                final isUser = chat["role"] == "user";

                return Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blueAccent.withOpacity(0.8)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      chat["message"]!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    focusNode: _commandFocus,
                    decoration: const InputDecoration(
                      hintText: "Enter your command...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    onSubmitted: _sendCommand,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendCommand(_commandController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
