import 'dart:io';

import 'package:card_master/screens/bot/bot.dart';
import 'package:card_master/screens/play/play.dart';
import 'package:card_master/screens/qr_scan/qr_scan.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _getPermissions() async {
    await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.locationWhenInUse, Permission.camera].request();
  }

  @override
  void initState() {
    _getPermissions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CardMaster'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => BotScreen()));
              },
              child: Text('Connect Bot'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigator.push(context, MaterialPageRoute(builder: (context) => PlayScreen()));
                Navigator.push(context, MaterialPageRoute(builder: (context) => QRScanScreen()));
              },
              child: Text('Play Remote'),
            ),
          ],
        ),
      ),
    );
  }
}
