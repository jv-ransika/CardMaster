import 'package:flutter/material.dart';

class LogsView extends StatefulWidget {
  final LogsViewController controller;

  const LogsView({required this.controller, Key? key}) : super(key: key);

  @override
  State<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends State<LogsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    widget.controller.onUpdate = () {
      setState(() {});
      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Logs",
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: widget.controller.logs.length,
              itemBuilder: (context, index) {
                final log = widget.controller.logs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    log,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LogsViewController {
  final List<String> logs = [];
  Function? onUpdate;

  void addLog(String log) {
    logs.add(log);
    onUpdate?.call();
  }

  void clearLogs() {
    logs.clear();
    onUpdate?.call();
  }
}
