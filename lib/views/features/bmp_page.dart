// ignore_for_file: library_private_types_in_public_api

import 'package:demo_ai_even/ble_manager.dart';
import 'package:demo_ai_even/services/features_services.dart';
import 'package:flutter/material.dart';

class BmpPage extends StatefulWidget {
  const BmpPage({super.key});

  @override
  _BmpState createState() => _BmpState();
}

class _BmpState extends State<BmpPage> {
  bool _isSendingBmp1 = false;
  bool _isSendingBmp2 = false;
  bool _isExiting = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('BMP'),
        ),
        body: Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 44),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Connection Status Display
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: BleManager.get().isConnected ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: BleManager.get().isConnected ? Colors.green : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Connection Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      BleManager.get().getConnectionStatus(),
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text('Connected:', style: TextStyle(fontSize: 12)),
                            Text('${BleManager.get().isConnected}', 
                                 style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            Text('Both Connected:', style: TextStyle(fontSize: 12)),
                            Text('${BleManager.isBothConnected()}', 
                                 style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  print("🖼️ BmpPage: BMP 1 button tapped");
                  print("🔍 BmpPage: Checking connection status...");
                  print("🔍 BmpPage: isConnected = ${BleManager.get().isConnected}");
                  print("🔍 BmpPage: isBothConnected = ${BleManager.isBothConnected()}");
                  print("🔍 BmpPage: connectionStatus = ${BleManager.get().getConnectionStatus()}");
                  
                  if (BleManager.get().isConnected == false) {
                    print("❌ BmpPage: Cannot send BMP 1 - Not connected to glasses");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Not connected to glasses. Please connect first.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (_isSendingBmp1) {
                    print("⚠️ BmpPage: BMP 1 already sending, ignoring tap");
                    return;
                  }

                  setState(() {
                    _isSendingBmp1 = true;
                  });

                  try {
                    print("🖼️ BmpPage: Starting to send BMP 1 image...");
                    await FeaturesServices().sendBmp("assets/images/image_1.bmp");
                    print("✅ BmpPage: BMP 1 sent successfully");
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('BMP 1 sent successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print("❌ BmpPage: Error sending BMP 1: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send BMP 1: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    setState(() {
                      _isSendingBmp1 = false;
                    });
                  }
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: _isSendingBmp1 ? Colors.grey.shade300 : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: BleManager.get().isConnected ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _isSendingBmp1 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text("Sending BMP 1...", style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : Text(
                        "BMP 1", 
                        style: TextStyle(
                          fontSize: 16,
                          color: BleManager.get().isConnected ? Colors.black : Colors.grey,
                        )
                      ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  print("🖼️ BmpPage: BMP 2 button tapped");
                  print("🔍 BmpPage: Checking connection status...");
                  print("🔍 BmpPage: isConnected = ${BleManager.get().isConnected}");
                  print("🔍 BmpPage: isBothConnected = ${BleManager.isBothConnected()}");
                  print("🔍 BmpPage: connectionStatus = ${BleManager.get().getConnectionStatus()}");
                  
                  if (BleManager.get().isConnected == false) {
                    print("❌ BmpPage: Cannot send BMP 2 - Not connected to glasses");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Not connected to glasses. Please connect first.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (_isSendingBmp2) {
                    print("⚠️ BmpPage: BMP 2 already sending, ignoring tap");
                    return;
                  }

                  setState(() {
                    _isSendingBmp2 = true;
                  });

                  try {
                    print("🖼️ BmpPage: Starting to send BMP 2 image...");
                    await FeaturesServices().sendBmp("assets/images/image_2.bmp");
                    print("✅ BmpPage: BMP 2 sent successfully");
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('BMP 2 sent successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print("❌ BmpPage: Error sending BMP 2: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send BMP 2: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    setState(() {
                      _isSendingBmp2 = false;
                    });
                  }
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: _isSendingBmp2 ? Colors.grey.shade300 : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: BleManager.get().isConnected ? Colors.blue : Colors.grey,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _isSendingBmp2 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text("Sending BMP 2...", style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : Text(
                        "BMP 2", 
                        style: TextStyle(
                          fontSize: 16,
                          color: BleManager.get().isConnected ? Colors.black : Colors.grey,
                        )
                      ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  print("🚪 BmpPage: Exit button tapped");
                  print("🔍 BmpPage: Checking connection status...");
                  print("🔍 BmpPage: isConnected = ${BleManager.get().isConnected}");
                  print("🔍 BmpPage: isBothConnected = ${BleManager.isBothConnected()}");
                  
                  if (BleManager.get().isConnected == false) {
                    print("❌ BmpPage: Cannot exit - Not connected to glasses");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Not connected to glasses.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  if (_isExiting) {
                    print("⚠️ BmpPage: Exit already in progress, ignoring tap");
                    return;
                  }

                  setState(() {
                    _isExiting = true;
                  });

                  try {
                    print("🚪 BmpPage: Sending exit command...");
                    await FeaturesServices().exitBmp();
                    print("✅ BmpPage: Exit command sent successfully");
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Exit command sent successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print("❌ BmpPage: Error sending exit command: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to send exit command: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    setState(() {
                      _isExiting = false;
                    });
                  }
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: _isExiting ? Colors.grey.shade300 : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: BleManager.get().isConnected ? Colors.red : Colors.grey,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _isExiting 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text("Exiting...", style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : Text(
                        "Exit", 
                        style: TextStyle(
                          fontSize: 16,
                          color: BleManager.get().isConnected ? Colors.black : Colors.grey,
                        )
                      ),
                ),
              ),
            ],
          ),
        ),
      );
}
