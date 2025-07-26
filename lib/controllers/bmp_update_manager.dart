import 'dart:io';
import 'dart:typed_data';

import 'package:crclib/catalog.dart';
import 'package:demo_ai_even/ble_manager.dart';
import 'package:demo_ai_even/utils/utils.dart';

class BmpUpdateManager {
  
  static bool isTransfering = false;

  Future<bool> updateBmp(String lr, Uint8List image, {int? seq}) async {
    print("🖼️ BmpUpdateManager: Starting BMP update for side '$lr' with image size ${image.length} bytes");

    // check if has error sending package
    bool isOldSendPackError(int? currentSeq) {
      bool oldSendError = (seq == null && currentSeq != null);
      if (oldSendError) {
        print("❌ BmpUpdateManager: Old pack send error detected for side '$lr', seq = $currentSeq");
      }
      return oldSendError;
    }

    const int packLen = 194; //198;
    List<Uint8List> multiPacks = [];
    print("📦 BmpUpdateManager: Splitting image into packets of $packLen bytes each");
    
    for (int i = 0; i < image.length; i += packLen) { 
      int end = (i + packLen < image.length) ? i + packLen : image.length;
      final singlePack = image.sublist(i, end);
      multiPacks.add(singlePack);
    }

    print("📦 BmpUpdateManager: Created ${multiPacks.length} packets for transmission to side '$lr'");

    for (int index = 0; index < multiPacks.length; index++) { 
      if (isOldSendPackError(seq)) {
        print("❌ BmpUpdateManager: Stopping transmission due to old send error");
        return false;
      }
      if (seq != null && index < seq) {
        print("⏭️ BmpUpdateManager: Skipping packet $index (already sent)");
        continue;
      }

      final pack = multiPacks[index];  
      // address in glasses [0x00, 0x1c, 0x00, 0x00] , taken in the first package
      Uint8List data = index == 0 ? 
        Utils.addPrefixToUint8List([0x15, index & 0xff, 0x00, 0x1c, 0x00, 0x00], pack) : 
        Utils.addPrefixToUint8List([0x15, index & 0xff], pack);
      
      print("📤 BmpUpdateManager: Sending packet ${index + 1}/${multiPacks.length} to '$lr' - Size: ${data.length} bytes, Data: ${data.take(20).toList()}...");

      try {
        await BleManager.sendData(data, lr: lr);
        print("✅ BmpUpdateManager: Packet ${index + 1} sent successfully to '$lr'");
      } catch (e) {
        print("❌ BmpUpdateManager: Failed to send packet ${index + 1} to '$lr': $e");
        return false;
      }

      // Platform-specific delay
      if (Platform.isIOS) {
        await Future.delayed(Duration(milliseconds: 8)); // 4 6 10 14  30
        print("⏳ BmpUpdateManager: iOS delay - 8ms");
      } else {
        await Future.delayed(Duration(milliseconds: 5));  // 5
        print("⏳ BmpUpdateManager: Android delay - 5ms");
      }

      var offset = index * packLen;
      if (offset > image.length - packLen) {
        offset = image.length - pack.length;
      }
      _onProgressCall(lr, offset, index, image.length);
    }
    
    print("📦 BmpUpdateManager: All packets sent for side '$lr', starting finish process...");

    if (isOldSendPackError(seq)) {
      print("❌ BmpUpdateManager: Old send error detected during finish process");
      return false;
    }

    const maxRetryTime = 10;
    int currentRetryTime = 0;
    
    Future<bool> finishUpdate() async {
      print("🏁 BmpUpdateManager: Attempting to finish update for '$lr' (attempt ${currentRetryTime + 1}/$maxRetryTime)");
      
      if (currentRetryTime >= maxRetryTime) {
        print("❌ BmpUpdateManager: Max retry attempts reached for finishing update on '$lr'");
        return false;
      }
      
      try {
        // notice the finish sending
        print("📋 BmpUpdateManager: Sending finish command [0x20, 0x0d, 0x0e] to '$lr'");
        var ret = await BleManager.request(
          Uint8List.fromList([0x20, 0x0d, 0x0e]),
          lr: lr,
          timeoutMs: 3000,
        );
        
        print("📋 BmpUpdateManager: Finish command response from '$lr': ${ret.data}");
        
        if (ret.isTimeout) {
          print("⏰ BmpUpdateManager: Finish command timeout for '$lr', retrying...");
          currentRetryTime++;
          await Future.delayed(Duration(seconds: 1));
          return finishUpdate();
        }
        
        bool success = ret.data.length > 1 && ret.data[1].toInt() == 0xc9;
        print("🏁 BmpUpdateManager: Finish command result for '$lr': $success (response code: ${ret.data.length > 1 ? ret.data[1].toInt() : 'none'})");
        return success;
        
      } catch (e) {
        print("❌ BmpUpdateManager: Error in finish command for '$lr': $e");
        currentRetryTime++;
        if (currentRetryTime < maxRetryTime) {
          await Future.delayed(Duration(seconds: 1));
          return finishUpdate();
        }
        return false;
      }
    }

    print("🏁 BmpUpdateManager: Starting finish update process for '$lr'");
    var isSuccess = await finishUpdate();
    print("🏁 BmpUpdateManager: Finish update result for '$lr': $isSuccess");

    if (!isSuccess) {
      print("❌ BmpUpdateManager: Finish update failed for '$lr'");
      return false;
    } else {
      print("✅ BmpUpdateManager: Finish update successful for '$lr'");
    }

    // CRC Check Process
    print("🔍 BmpUpdateManager: Starting CRC check process for '$lr'");
    
    // take address in the first package
    Uint8List result = prependAddress(image);
    var crc32 = Crc32Xz().convert(result); 
    var val = crc32.toBigInt().toInt();
    var crc = Uint8List.fromList([
      val >> 8 * 3 & 0xff,
      val >> 8 * 2 & 0xff,
      val >> 8 & 0xff,
      val & 0xff,
    ]);
    
    print("🔍 BmpUpdateManager: Calculated CRC32 for '$lr': $crc (value: $val)");
    
    try {
      final ret = await BleManager.request(
          Utils.addPrefixToUint8List([0x16], crc),
          lr: lr);

      print("🔍 BmpUpdateManager: CRC check response from '$lr': ${ret.data}");

      if (ret.data.length > 4 && ret.data[5] != 0xc9) {
        print("❌ BmpUpdateManager: CRC check failed for '$lr' - Response code: ${ret.data.length > 5 ? ret.data[5] : 'none'}");
        return false;
      }

      print("✅ BmpUpdateManager: CRC check passed for '$lr'");
      print("🎉 BmpUpdateManager: BMP update completed successfully for '$lr'");
      return true;
      
    } catch (e) {
      print("❌ BmpUpdateManager: CRC check error for '$lr': $e");
      return false;
    }
  }

  Uint8List prependAddress(Uint8List image) {
    print("🔍 BmpUpdateManager: Prepending address to image for CRC calculation");
    // Prepend the address [0x00, 0x1c, 0x00, 0x00] to the image data
    Uint8List result = Uint8List(4 + image.length);
    result[0] = 0x00;
    result[1] = 0x1c;
    result[2] = 0x00;
    result[3] = 0x00;
    result.setRange(4, 4 + image.length, image);
    print("🔍 BmpUpdateManager: Address prepended, total size: ${result.length} bytes");
    return result;
  }

  Function(String lr, int offset, int currentIndex, int total)? onProgress;
  void _onProgressCall(String lr, int offset, int currentIndex, int total) {
    double progress = (offset / total * 100);
    print("📊 BmpUpdateManager: Progress for '$lr': ${progress.toStringAsFixed(1)}% (${currentIndex + 1} packets sent)");
    onProgress?.call(lr, offset, currentIndex, total);
  }
}