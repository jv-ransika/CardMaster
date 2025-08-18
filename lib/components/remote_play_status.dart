import 'package:card_master/handlers/remote_play_handler/remote_play_handler.dart';
import 'package:flutter/material.dart';

class RemotePlayStatusWidget extends StatelessWidget {
  final RemotePlayHandler handler;

  const RemotePlayStatusWidget({super.key, required this.handler});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.wifi, color: handler.myCode != null ? (handler.paired ? Colors.green : Colors.blue) : Colors.grey),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.grey[50],
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) {
            return AnimatedBuilder(
              animation: handler,
              builder: (context, _) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videogame_asset, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text("Remote Play", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Connection section
                      if (handler.connecting) ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        const Text("Connecting to server..."),
                      ] else if (handler.myCode == null) ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.link),
                          label: const Text("Connect & Host"),
                          onPressed: () => handler.connectAndHost(host: true),
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
                        ),
                      ] else ...[
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Game Code", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                    Text(
                                      handler.myCode!,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Paired Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                    Text(handler.paired ? "Paired ✅" : "Not Paired ❌", style: TextStyle(fontSize: 16, color: handler.paired ? Colors.green : Colors.red)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.link_off),
                          label: const Text("Disconnect"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size.fromHeight(45)),
                          onPressed: () {
                            handler.disconnect();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
