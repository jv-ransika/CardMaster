// import 'package:flutter/material.dart';

// class LogsView extends StatefulWidget {
//   final LogsViewController controller;

//   const LogsView({required this.controller, Key? key}) : super(key: key);

//   @override
//   State<LogsView> createState() => _LogsViewState();
// }

// class _LogsViewState extends State<LogsView> {
//   final ScrollController _scrollController = ScrollController();

//   @override
//   void initState() {
//     super.initState();

//     widget.controller.onUpdate = () {
//       setState(() {});
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (_scrollController.hasClients) {
//           _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
//         }
//       });
//     };
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: Colors.grey.shade700),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Bot Logs",
//             style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontFamily: 'Courier'),
//           ),
//           const SizedBox(height: 6),
//           Expanded(
//             child: ListView.builder(
//               controller: _scrollController,
//               itemCount: widget.controller.logs.length,
//               itemBuilder: (context, index) {
//                 final logEntry = widget.controller.logs[index];
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 2.0),
//                   child: Text(
//                     "[${logEntry.timestamp}] ${logEntry.message}",
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: Colors.white,
//                       fontFamily: 'Courier', // monospace
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class LogEntry {
//   final String message;
//   final String timestamp;

//   LogEntry(this.message) : timestamp = _getCurrentTime();

//   static String _getCurrentTime() {
//     final now = DateTime.now();
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     return "${twoDigits(now.hour)}:${twoDigits(now.minute)}:${twoDigits(now.second)}";
//   }
// }

// class LogsViewController {
//   final List<LogEntry> logs = [];
//   Function? onUpdate;

//   void addLog(String log) {
//     logs.add(LogEntry(log));
//     onUpdate?.call();
//   }

//   void clearLogs() {
//     logs.clear();
//     onUpdate?.call();
//   }
// }

import 'package:flutter/material.dart';

class LogsView extends StatefulWidget {
  final LogsViewController controller;

  const LogsView({required this.controller, Key? key}) : super(key: key);

  @override
  State<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends State<LogsView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    widget.controller.onUpdate = () {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    };
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.controller.onSendText?.call(text); // Trigger controller's callback
      widget.controller.addLog(text, LogType.sent); // Add as "sent"
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Command Prompt",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontFamily: 'Courier'),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: widget.controller.logs.length,
              itemBuilder: (context, index) {
                final logEntry = widget.controller.logs[index];
                final logColor = logEntry.type == LogType.sent ? Colors.cyan : Colors.greenAccent;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    "[${logEntry.timestamp}] ${logEntry.message}",
                    style: TextStyle(fontSize: 14, color: logColor, fontFamily: 'Courier'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    hintText: 'Enter command...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade700),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.greenAccent),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                onPressed: _sendMessage,
                child: const Text('Send', style: TextStyle(fontFamily: 'Courier')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum LogType { sent, received }

class LogEntry {
  final String message;
  final String timestamp;
  final LogType type;

  LogEntry(this.message, this.type) : timestamp = _getCurrentTime();

  static String _getCurrentTime() {
    final now = DateTime.now();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(now.hour)}:${twoDigits(now.minute)}:${twoDigits(now.second)}";
  }
}

class LogsViewController {
  final List<LogEntry> logs = [];
  Function? onUpdate;
  Function(String)? onSendText; // Callback for sending text

  void addLog(String log, LogType type) {
    logs.add(LogEntry(log, type));
    onUpdate?.call();
  }

  void clearLogs() {
    logs.clear();
    onUpdate?.call();
  }
}
