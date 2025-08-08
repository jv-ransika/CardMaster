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
  final Map<String, String?> deviceAddresses = {"Bot": null, "Outer Camera": null, "Inner Camera": null};
  final Map<String, BluetoothConnection?> deviceConnections = {"Bot": null, "Outer Camera": null, "Inner Camera": null};

  bool _isRefreshing = false;

  void _recheckPairedDevices() {
    setState(() {
      _isRefreshing = true;
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

          setState(() {});

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Scan Completed!")));
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Scan Failed!")));
        })
        .whenComplete(() {
          setState(() {
            _isRefreshing = false;
          });
        });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: Column(
        children: [
          _isRefreshing ? LinearProgressIndicator() : ElevatedButton(onPressed: _recheckPairedDevices, child: Text("Refresh")),
          SizedBox(height: 20),
          // List items
          ...deviceAddresses.entries.map(
            (entry) => DeviceItem(
              onConnect: (conn) {
                deviceConnections[entry.key] = conn;
              },
              name: entry.key,
              address: entry.value,
              inputHandler: widget.deviceInputHandlers[entry.key]!,
            ),
          ),
        ],
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
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(child: Text(widget.name, style: TextStyle(fontSize: 16))),
          if (conn != null) Text("Connected", style: TextStyle(color: Colors.green)) else if (widget.address == null) Text("Not Paired", style: TextStyle(color: Colors.red)) else ElevatedButton(onPressed: _isConnecting || conn != null ? null : _handleConnect, child: _isConnecting ? CircularProgressIndicator(strokeWidth: 2) : Text("Connect")),
        ],
      ),
    );
  }
}
