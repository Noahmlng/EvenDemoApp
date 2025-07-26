import 'dart:typed_data';
import 'package:demo_ai_even/ble_manager.dart';
import 'package:demo_ai_even/controllers/bmp_update_manager.dart';
import 'package:demo_ai_even/services/proto.dart';
import 'package:demo_ai_even/utils/utils.dart';

class FeaturesServices {
  final bmpUpdateManager = BmpUpdateManager();
  
  Future<void> sendBmp(String imageUrl) async {
    print("🖼️ FeaturesServices: Starting BMP send process for: $imageUrl");
    
    try {
      // Check connection first
      if (!BleManager.get().isConnected) {
        print("❌ FeaturesServices: Cannot send BMP - not connected to glasses");
        throw Exception("Not connected to glasses");
      }
      
      if (!BleManager.isBothConnected()) {
        print("⚠️ FeaturesServices: Warning - both sides not connected, but proceeding anyway");
      }
      
      print("📁 FeaturesServices: Loading BMP image from: $imageUrl");
      Uint8List bmpData = await Utils.loadBmpImage(imageUrl);
      
      if (bmpData.isEmpty) {
        print("❌ FeaturesServices: BMP data is empty - failed to load image");
        throw Exception("Failed to load BMP image from $imageUrl");
      }
      
      print("✅ FeaturesServices: BMP image loaded successfully - Size: ${bmpData.length} bytes");
      
      int initialSeq = 0;
      print("💓 FeaturesServices: Sending initial heartbeat...");
      bool isSuccess = await Proto.sendHeartBeat();
      print("💓 FeaturesServices: Heartbeat result: $isSuccess");
      
      if (!isSuccess) {
        print("⚠️ FeaturesServices: Heartbeat failed, but continuing with BMP transmission");
      }
      
      print("💓 FeaturesServices: Starting heartbeat timer...");
      BleManager.get().startSendBeatHeart();

      print("📡 FeaturesServices: Starting parallel BMP transmission to both sides...");
      print("📡 FeaturesServices: Left side transmission starting...");
      print("📡 FeaturesServices: Right side transmission starting...");
      
      final results = await Future.wait([
        bmpUpdateManager.updateBmp("L", bmpData, seq: initialSeq),
        bmpUpdateManager.updateBmp("R", bmpData, seq: initialSeq)
      ]);

      bool successL = results[0];
      bool successR = results[1];

      print("📡 FeaturesServices: Transmission results - Left: $successL, Right: $successR");

      if (successL) {
        print("✅ FeaturesServices: Left side BMP transmission successful");
      } else {
        print("❌ FeaturesServices: Left side BMP transmission failed");
      }

      if (successR) {
        print("✅ FeaturesServices: Right side BMP transmission successful");
      } else {
        print("❌ FeaturesServices: Right side BMP transmission failed");
      }
      
      if (!successL || !successR) {
        throw Exception("BMP transmission failed - Left: $successL, Right: $successR");
      }
      
      print("🎉 FeaturesServices: BMP transmission completed successfully on both sides!");
      
    } catch (e) {
      print("❌ FeaturesServices: Error in sendBmp: $e");
      rethrow;
    }
  }

  Future<void> exitBmp() async {
    print("🚪 FeaturesServices: Starting BMP exit process...");
    
    try {
      // Check connection first
      if (!BleManager.get().isConnected) {
        print("❌ FeaturesServices: Cannot exit BMP - not connected to glasses");
        throw Exception("Not connected to glasses");
      }
      
      print("🚪 FeaturesServices: Sending exit command via Proto.exit()...");
      bool isSuccess = await Proto.exit();
      print("🚪 FeaturesServices: Exit command result: $isSuccess");
      
      if (isSuccess) {
        print("✅ FeaturesServices: BMP exit successful");
      } else {
        print("❌ FeaturesServices: BMP exit failed");
        throw Exception("Exit command failed");
      }
      
    } catch (e) {
      print("❌ FeaturesServices: Error in exitBmp: $e");
      rethrow;
    }
  }
}