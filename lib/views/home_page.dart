// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:demo_ai_even/ble_manager.dart';
import 'package:demo_ai_even/services/evenai.dart';
import 'package:demo_ai_even/views/even_list_page.dart';
import 'package:demo_ai_even/views/features_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? scanTimer;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    print("🏠 HomePage: Initializing home page...");
    
    print("🏠 HomePage: Setting up BLE method call handler...");
    BleManager.get().setMethodCallHandler();
    
    print("🏠 HomePage: Starting BLE event listening...");
    BleManager.get().startListening();
    
    print("🏠 HomePage: Setting up status change callback...");
    BleManager.get().onStatusChanged = _refreshPage;
    
    print("✅ HomePage: Home page initialization complete");
  }

  void _refreshPage() {
    print("🔄 HomePage: Page refresh triggered by BLE status change");
    if (mounted) {
      setState(() {});
    } else {
      print("⚠️ HomePage: Widget not mounted, skipping refresh");
    }
  }

  Future<void> _startScan() async {
    print("🔍 HomePage: Starting BLE scan...");
    setState(() => isScanning = true);
    
    try {
      await BleManager.get().startScan();
      print("✅ HomePage: BLE scan started successfully");
      
      scanTimer?.cancel();
      print("⏰ HomePage: Setting 15-second scan timeout...");
      scanTimer = Timer(15.seconds, () {
        print("⏰ HomePage: Scan timeout reached, stopping scan");
        _stopScan();
      });
    } catch (e) {
      print("❌ HomePage: Error starting scan: $e");
      setState(() => isScanning = false);
    }
  }

  Future<void> _stopScan() async {
    print("🛑 HomePage: Stopping BLE scan...");
    if (isScanning) {
      try {
        await BleManager.get().stopScan();
        print("✅ HomePage: BLE scan stopped successfully");
        setState(() => isScanning = false);
      } catch (e) {
        print("❌ HomePage: Error stopping scan: $e");
      }
    } else {
      print("ℹ️ HomePage: Scan not running, nothing to stop");
    }
  }

  Widget blePairedList() {
    print("📱 HomePage: Building paired glasses list (${BleManager.get().getPairedGlasses().length} devices)");
    
    return Expanded(
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 5),
        itemCount: BleManager.get().getPairedGlasses().length,
        itemBuilder: (context, index) {
          final glasses = BleManager.get().getPairedGlasses()[index];
          return GestureDetector(
            onTap: () async {
              String channelNumber = glasses['channelNumber']!;
              String deviceName = "Pair_$channelNumber";
              
              print("👆 HomePage: User tapped on device: $deviceName");
              print("👆 HomePage: Device info: $glasses");
              
              try {
                await BleManager.get().connectToGlasses(deviceName);
                print("🔗 HomePage: Connection request sent for $deviceName");
                _refreshPage();
              } catch (e) {
                print("❌ HomePage: Error connecting to $deviceName: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to connect to $deviceName: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Container(
              height: 72,
              padding: const EdgeInsets.only(left: 16, right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Colors.blue.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Channel: ${glasses['channelNumber']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Left: ${glasses['leftDeviceName']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Right: ${glasses['rightDeviceName']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.bluetooth,
                    color: Colors.blue,
                    size: 24,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("🏠 HomePage: Building home page UI...");
    print("🏠 HomePage: Current connection status: ${BleManager.get().getConnectionStatus()}");
    print("🏠 HomePage: Is connected: ${BleManager.get().isConnected}");
    print("🏠 HomePage: Paired devices count: ${BleManager.get().getPairedGlasses().length}");
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Even AI Demo'),
        actions: [
          InkWell(
            onTap: () {
              print("🎛️ HomePage: Features menu button tapped");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeaturesPage()),
              );
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: const Padding(
              padding: EdgeInsets.only(left: 16, top: 12, bottom: 14, right: 16),
              child: Icon(Icons.menu),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 44),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                print("📡 HomePage: Connection status container tapped");
                String currentStatus = BleManager.get().getConnectionStatus();
                print("📡 HomePage: Current status: $currentStatus");
                
                if (currentStatus == 'Not connected') {
                  print("📡 HomePage: Starting scan because not connected");
                  _startScan();
                } else {
                  print("📡 HomePage: Already connected or connecting, no action needed");
                }
              },
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: BleManager.get().isConnected ? Colors.green.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: BleManager.get().isConnected ? Colors.green : Colors.blue,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isScanning) ...[
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(),
                      ),
                      const SizedBox(height: 8),
                      Text("Scanning for glasses...", style: TextStyle(fontSize: 14)),
                    ] else ...[
                      Icon(
                        BleManager.get().isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                        color: BleManager.get().isConnected ? Colors.green : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        BleManager.get().getConnectionStatus(),
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (BleManager.get().getConnectionStatus() == 'Not connected') ...[
              if (BleManager.get().getPairedGlasses().isEmpty && !isScanning) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'No glasses found.\nTap the connection status above to scan for devices.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              blePairedList(),
            ],
            if (BleManager.get().isConnected)
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    print("📝 HomePage: AI history button tapped");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EvenAIListPage(),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      child: StreamBuilder<String>(
                        stream: EvenAI.textStream,
                        initialData: "Press and hold left TouchBar to engage Even AI.",
                        builder: (context, snapshot) => Obx(
                          () => EvenAI.isEvenAISyncing.value
                              ? const SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(),
                                ) // Color(0xFFFEF991)
                              : Text(
                                  snapshot.data ?? "Loading...",
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: BleManager.get().isConnected
                                          ? Colors.black
                                          : Colors.grey.withOpacity(0.5)),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    print("🏠 HomePage: Disposing home page...");
    scanTimer?.cancel();
    isScanning = false;
    BleManager.get().onStatusChanged = null;
    print("✅ HomePage: Home page disposed successfully");
    super.dispose();
  }
}
