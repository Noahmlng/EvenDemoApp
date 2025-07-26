
import 'package:demo_ai_even/ble_manager.dart';
import 'package:demo_ai_even/controllers/evenai_model_controller.dart';
import 'package:demo_ai_even/views/home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


void main() {
  print("🚀 Main: Starting Even AI Demo App...");
  
  try {
    print("🔧 Main: Initializing BLE Manager...");
    BleManager.get();
    print("✅ Main: BLE Manager initialized successfully");
    
    print("🔧 Main: Registering EvenAI Model Controller...");
    Get.put(EvenaiModelController());
    print("✅ Main: EvenAI Model Controller registered successfully");
    
    print("🔧 Main: Starting Flutter app...");
    runApp(MyApp());
    print("✅ Main: Flutter app started successfully");
    
  } catch (e) {
    print("❌ Main: Error during app initialization: $e");
    print("❌ Main: Error type: ${e.runtimeType}");
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("🏗️ MyApp: Building main application widget...");
    
    return MaterialApp(
      title: 'Even AI Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(), 
    );
  }
}
