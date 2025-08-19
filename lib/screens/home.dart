import 'dart:io';

import 'package:card_master/screens/bot/bot.dart';
import 'package:card_master/screens/play/play.dart';
import 'package:card_master/screens/qr_scan/qr_scan.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String>? deviceAddresses = [];

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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('CardMaster', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 2,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Header
              Icon(Icons.style, size: 80, color: Colors.blue.shade600),
              const SizedBox(height: 40),

              // Connect Bot Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => BotScreen()));
                  },
                  icon: const Icon(Icons.smart_toy, size: 26),
                  label: const Text('Connect Bot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 20),

              // Play Remote Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PlayScreen()));
                  },
                  icon: const Icon(Icons.videogame_asset, size: 26),
                  label: const Text('Play Remote', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
