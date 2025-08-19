import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart' as services;

class QRScanScreen extends StatefulWidget {
  final Function(List<String> macAddresses) onPairingComplete;

  const QRScanScreen({Key? key, required this.onPairingComplete}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController cameraController = MobileScannerController(facing: CameraFacing.back, torchEnabled: false, detectionSpeed: DetectionSpeed.normal, detectionTimeoutMs: 250);

  Uint8List? lastScanned;
  bool isProcessing = false; // prevent duplicate processing

  Future<int> pairDevices(List<String> macAddresses) async {
    int successCount = 0;

    final bluetooth = FlutterBluetoothSerial.instance;

    bool? isEnabled = await bluetooth.isEnabled;
    if (!(isEnabled ?? false)) {
      await bluetooth.requestEnable();
    }

    final List<BluetoothDevice> alreadyPairedList = await bluetooth.getBondedDevices();

    for (String mac in macAddresses) {
      if (alreadyPairedList.any((device) => device.address == mac)) {
        successCount++;
        debugPrint("Already paired with $mac");
        continue;
      }

      try {
        debugPrint("Pairing with $mac ...");

        final state = await bluetooth.bondDeviceAtAddress(mac);

        if (state != null && state) {
          debugPrint("Successfully paired with $mac");
          successCount++;
        } else {
          debugPrint("Failed to pair with $mac (state: $state)");
        }
      } catch (e) {
        debugPrint("Error pairing with $mac: $e");
      }
    }

    return successCount;
  }

  Future<void> _showPairingDialog(List<String> macAddresses) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text("Pairing devices...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Text(
              macAddresses.join("\n"),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _onDetect(BarcodeCapture barcodes) async {
    if (isProcessing) return;
    final List<Barcode> codes = barcodes.barcodes;
    if (codes.isEmpty) return;

    final raw = codes.first;
    final Uint8List? code = raw.rawBytes;
    if (code == null || code.isEmpty) return;

    // card_master,<bot_mac>,<ic_mac>,<oc_mac>
    // Ex: 33,44,<68,25,DD,33,87,6E>,<08,B6,1F,8E,7A,4E>,<3C,8A,1F,D4,7C,1E>
    if (!(code.length == 20 && code[0] == 33 && code[1] == 44)) {
      return;
    }

    isProcessing = true;
    setState(() => lastScanned = code);

    try {
      await services.HapticFeedback.mediumImpact();
    } catch (_) {}

    debugPrint('QR code scanned: $code');

    final List<String> macAddresses = [String.fromCharCodes(code.sublist(2, 8)), String.fromCharCodes(code.sublist(8, 14)), String.fromCharCodes(code.sublist(14, 20))];

    if (macAddresses.isEmpty || macAddresses.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Addresses.")));
      isProcessing = false;
      return;
    }

    _showPairingDialog(macAddresses);

    final successCount = await pairDevices(macAddresses);

    if (mounted) Navigator.of(context).pop();

    if (mounted) {
      if (successCount == 3) {
        widget.onPairingComplete(macAddresses);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pairing finished")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pairing failed. Only $successCount devices paired.")));
      }
    }

    await Future.delayed(const Duration(seconds: 2));
    isProcessing = false;
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.yellow.withOpacity(0.8),
          padding: const EdgeInsets.all(8),
          child: const Text(
            "Align the camera with one of the bot's eyes.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              MobileScanner(controller: cameraController, onDetect: _onDetect),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  height: MediaQuery.of(context).size.width * 0.75,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: const Text('Pair Bot')),
  //     body: Column(
  //       children: [
  //         Container(
  //           width: double.infinity,
  //           color: Colors.yellow.withOpacity(0.8),
  //           padding: const EdgeInsets.all(8),
  //           child: const Text(
  //             "Align the camera with one of the bot's eyes.",
  //             textAlign: TextAlign.center,
  //             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //           ),
  //         ),
  //         Expanded(
  //           child: Stack(
  //             children: [
  //               MobileScanner(controller: cameraController, onDetect: _onDetect),
  //               Center(
  //                 child: Container(
  //                   width: MediaQuery.of(context).size.width * 0.75,
  //                   height: MediaQuery.of(context).size.width * 0.75,
  //                   decoration: BoxDecoration(
  //                     border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
