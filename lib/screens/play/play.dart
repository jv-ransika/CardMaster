import 'package:card_master/handlers/remote_play_handler/remote_play_handler.dart';
import 'package:flutter/material.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({Key? key}) : super(key: key);

  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late RemotePlayHandler remotePlayHandler;

  @override
  void initState() {
    super.initState();
    remotePlayHandler = RemotePlayHandler(
      onConnected: () {
        setState(() {});
        debugPrint("Connected to Remote Play");
      },
      onCodeReceived: (code) {
        setState(() {});
        debugPrint("Remote Play Code Received: $code");
      },
      onPaired: () {
        setState(() {});
        debugPrint("Remote Play Paired");
      },
      onMessageReceived: (message) {
        debugPrint("Remote Play Message Received: $message");
      },
      onPairLost: () {
        setState(() {});
        debugPrint("Remote Play Unpaired");
      },
      onErrorReceived: (msg) {
        setState(() {});
        debugPrint("Remote Play Error: $msg");
      },
      onDisconnected: () {
        setState(() {});
        debugPrint("Disconnected from Remote Play");
      },
    );

    // connect immediately when screen opens
    remotePlayHandler.connectAndHost();
  }

  @override
  void dispose() {
    remotePlayHandler.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (remotePlayHandler.connecting) {
      // loading while connecting
      body = const _StatusView(title: "Connecting...", subtitle: "Please wait while we connect you to the server", showLoader: true);
    } else if (remotePlayHandler.myCode != null && !remotePlayHandler.paired) {
      // show the 6-digit code
      body = _CodeView(code: remotePlayHandler.myCode!);
    } else if (remotePlayHandler.paired) {
      // show paired screen
      body = const Center(
        child: Text("Implement here...", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      );
    } else {
      // fallback
      body = const _StatusView(title: "Disconnected", subtitle: "Please try again", showLoader: false);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Play Screen')),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: body),
    );
  }
}

/// Status view with optional loader
class _StatusView extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showLoader;

  const _StatusView({required this.title, required this.subtitle, this.showLoader = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showLoader) const CircularProgressIndicator(),
            if (showLoader) const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// View for showing 6-digit code
class _CodeView extends StatelessWidget {
  final String code;

  const _CodeView({required this.code});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Share this code with your friend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.blue.shade50),
            child: Text(code, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 6)),
          ),
          const SizedBox(height: 20),
          const _StatusView(title: "Waiting for opponent...", subtitle: "Tell your friend to enter the above code", showLoader: true),
        ],
      ),
    );
  }
}
