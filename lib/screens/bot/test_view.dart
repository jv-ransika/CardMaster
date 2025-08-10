import 'package:flutter/material.dart';

class TestView extends StatefulWidget {
  final TestViewController controller;

  const TestView({Key? key, required this.controller}) : super(key: key);

  @override
  _TestViewState createState() => _TestViewState();
}

class _TestViewState extends State<TestView> {
  final TextEditingController emotionController = TextEditingController();
  final TextEditingController stackGoController = TextEditingController();

  // Command groups
  final List<String> cardOutCommands = ["cardOutDcOn", "goToGetCard", "goToOutCard", "outACard", "cardOutDcHigh", "cardOutDcLow", "cardPush", "cardPushInitPos", "isAppReady"];

  final List<String> cardStackHandlerCommands = ["cardStackCardInAlign", "cardStackUp1", "cardStackDown1"];

  final List<String> cardInCommands = ["cardInDcOn"];

  Widget _buildSection({required String title, required List<String> commands}) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: commands.map((cmd) => ElevatedButton(onPressed: () => widget.controller.callTestCommand(cmd), child: Text(cmd))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicSection({required String title, required String hint, required String commandPrefix, required TextEditingController controller, TextInputType? keyboardType}) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    widget.controller.callTestCommand("$commandPrefix${controller.text.trim()}");
                  }
                },
                child: const Text("Send"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestModeButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: widget.controller.testModeEnabled ? Colors.red : Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: () {
          if (widget.controller.testModeEnabled) {
            widget.controller.callTestCommand("exit");
          } else {
            widget.controller.callTestCommand("cmd-test");
          }
          widget.controller.update();
        },
        child: Text(widget.controller.testModeEnabled ? "Disable Test Mode" : "Enable Test Mode", style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  @override
  void initState() {
    widget.controller.onUpdate = () {
      setState(() {});
    };

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTestModeButton(),
          if (widget.controller.testModeEnabled) ...[
            _buildSection(title: "CardOut Commands", commands: cardOutCommands),
            _buildSection(title: "CardStackHandler Commands", commands: cardStackHandlerCommands),
            _buildSection(title: "CardIn Commands", commands: cardInCommands),
            _buildDynamicSection(title: "Set Emotion", hint: "Enter emotion (e.g. happy)", commandPrefix: "setEmotion-", controller: emotionController),
            _buildDynamicSection(title: "Card Stack Go", hint: "Enter stack number", commandPrefix: "cardStackGo", controller: stackGoController, keyboardType: TextInputType.number),
          ] else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.yellow.shade100, borderRadius: BorderRadius.circular(8)),
              child: const Text("Test mode is disabled. Enable it to access test controls.", style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
  }
}

class TestViewController {
  final Function(String) onTestCommand;
  bool testModeEnabled;

  Function? onUpdate;

  TestViewController({required this.onTestCommand, this.testModeEnabled = false});

  void callTestCommand(String command) {
    onTestCommand.call(command);
  }

  void update() {
    onUpdate?.call();
  }
}
