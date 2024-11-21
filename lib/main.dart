import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GenerativeModel geminiVisionProModel;
  late final ChatSession chatSession;
  final FocusNode _textFieldFocus = FocusNode();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    const apiKey = "";
    if (apiKey == 'key not found') {
      throw InvalidApiKey(
        'Key not found in environment. Please add an API key.',
      );
    }

    geminiVisionProModel = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.4,
        topK: 32,
        topP: 1,
        maxOutputTokens: 4096,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );

    chatSession = geminiVisionProModel.startChat();
    super.initState();
  }

  Future<void> _sendChatMessage(String message) async {
    setState(() {});
    try {
      final response = await chatSession.sendMessage(
        Content.text(message),
      );
      final text = response.text;
      if (text == null) {
        _showError('No response from API');
        return;
      } else {
        setState(() {
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {});
    } finally {
      _textController.clear();
      setState(() {});
      _textFieldFocus.requestFocus();
    }
  }

  Future<void> _showError(String message) async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Something went wrong'),
            content: SingleChildScrollView(
              child: SelectableText(message),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              )
            ],
          );
        });
  }

  Future<void> _scrollDown() async {
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(microseconds: 750),
            curve: Curves.easeOutCirc));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Chat'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
                controller: _scrollController,
                itemCount: chatSession.history.length,
                itemBuilder: (context, index) {
                  final Content content = chatSession.history.toList()[index];
                  final message = content.parts
                      .whereType<TextPart>()
                      .map<String>((e) => e.text)
                      .join('');

                  return Text(
                    '$message\nisUser: ${content.role}',
                  );
                }),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    focusNode: _textFieldFocus,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(15),
                      hintText: 'Enter a prompt...',
                      border: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.secondary)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.secondary)),
                    ),
                    controller: _textController,
                    onSubmitted: _sendChatMessage,
                  ),
                ),
                const SizedBox(height: 25)
              ],
            ),
          )
        ],
      ),
    );
  }
}
