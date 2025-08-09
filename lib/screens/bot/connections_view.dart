import 'dart:async';

import 'package:card_master/config.dart';
import 'package:card_master/handlers/conn_input_handler/handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ConnectionsView extends StatefulWidget {
  final Map<String, ConnectionInputHandler?> deviceInputHandlers = {"Bot": null, "Outer Camera": null, "Inner Camera": null};

  Map<String, ConnectionInputHandler> inputHandlers;

  ConnectionsView({super.key, required this.inputHandlers}) {
    deviceInputHandlers["Bot"] = inputHandlers["Bot"] ?? ConnectionInputHandler();
    deviceInputHandlers["Outer Camera"] = inputHandlers["Outer Camera"] ?? ConnectionInputHandler();
    deviceInputHandlers["Inner Camera"] = inputHandlers["Inner Camera"] ?? ConnectionInputHandler();
  }

  @override
  _ConnectionsViewState createState() => _ConnectionsViewState();
}

class _ConnectionsViewState extends State<ConnectionsView> {
  final Map<String, String?> deviceAddresses = {"Bot": null, "Outer Camera": "3C:8A:1F:D4:7C:1E", "Inner Camera": null};
  final Map<String, BluetoothConnection?> deviceConnections = {"Bot": null, "Outer Camera": null, "Inner Camera": null};

  bool _isRefreshing = false;

  Future<void> _recheckPairedDevices() async {
    Completer<void> completer = Completer<void>();

    FlutterBluetoothSerial.instance.startDiscovery().listen((BluetoothDiscoveryResult result) {
      print("Discovered device: ${result.device.name} (${result.device.address})");
    });

    FlutterBluetoothSerial.instance
        .getBondedDevices()
        .then((List<BluetoothDevice> devices) {
          for (BluetoothDevice device in devices) {
            if (device.name == Config.bleDeviceNameBot) {
              deviceAddresses["Bot"] = device.address;
            } else if (device.name == Config.bleDeviceNameOuterCamera) {
              deviceAddresses["Outer Camera"] = device.address;
            } else if (device.name == Config.bleDeviceNameInnerCamera) {
              deviceAddresses["Inner Camera"] = device.address;
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Scan Completed!")));
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Scan Failed!")));
        })
        .whenComplete(() {
          completer.complete();
        });

    return completer.future;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _recheckPairedDevices();
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          padding: EdgeInsets.all(8),
          child: Column(
            children: [
              SizedBox(height: 20),
              // Render items as a grid
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two items per row
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.9, // Adjust as needed for item size
                ),
                itemCount: deviceAddresses.length,
                itemBuilder: (context, index) {
                  String key = deviceAddresses.keys.elementAt(index);
                  return DeviceItem(
                    onConnect: (conn) {
                      deviceConnections[key] = conn;
                    },
                    name: key,
                    address: deviceAddresses[key],
                    inputHandler: widget.deviceInputHandlers[key]!,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeviceItem extends StatefulWidget {
  final String name;
  final String? address;
  final Function(BluetoothConnection? conn) onConnect;
  final ConnectionInputHandler inputHandler;

  const DeviceItem({Key? key, required this.name, required this.address, required this.onConnect, required this.inputHandler}) : super(key: key);

  @override
  _DeviceItemState createState() => _DeviceItemState();
}

class _DeviceItemState extends State<DeviceItem> {
  BluetoothConnection? conn;
  bool _isConnecting = false;

  void _handleConnect() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      conn = await BluetoothConnection.toAddress(widget.address);

      conn!.input!
          .listen((data) {
            // Handle incoming data
            widget.inputHandler.pushBytes(data);
          })
          .onDone(() {
            // Handle disconnection
            widget.inputHandler.notifyDisconnected();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Disconnected from ${widget.name}")));
              setState(() {
                conn = null;
              });
            }
          });

      await widget.onConnect(conn);

      widget.inputHandler.listenToOnSendCommand((command) {
        if (conn!.isConnected) {
          conn!.output.add(command);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Not connected to ${widget.name}")));
        }
      });

      widget.inputHandler.notifyConnected();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connected to ${widget.name}")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Connection failed!")));
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  @override
  void dispose() async {
    if (conn != null) {
      conn!.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            conn != null
                ? Icons.bluetooth_connected
                : widget.address == null
                ? Icons.bluetooth_disabled
                : Icons.bluetooth,
            size: 40,
            color: conn != null
                ? Colors.green.shade600
                : widget.address == null
                ? Colors.red.shade600
                : Colors.blue.shade600,
          ),
          const SizedBox(height: 8),
          Text(
            widget.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (conn != null)
            Text(
              "Connected",
              style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold),
            )
          else if (widget.address == null)
            Text(
              "Not Paired",
              style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold),
            )
          else
            ElevatedButton(
              onPressed: _isConnecting || conn != null ? null : _handleConnect,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isConnecting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Connect"),
            ),
        ],
      ),
    );
  }
}
