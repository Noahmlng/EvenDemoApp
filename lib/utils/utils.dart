
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';


class Utils {
  Utils._();

  static int getTimestampMs() {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    print("⏰ Utils: Current timestamp: $timestamp");
    return timestamp;
  }

  static Uint8List addPrefixToUint8List(List<int> prefix, Uint8List data) {
    print("🔧 Utils: Adding prefix ${prefix.take(5).toList()}${prefix.length > 5 ? '...' : ''} to data (${data.length} bytes)");
    var newData = Uint8List(data.length + prefix.length);
    for (var i = 0; i < prefix.length; i++) {
      newData[i] = prefix[i];
    }
    for (var i = prefix.length, j = 0;
        i < prefix.length + data.length;
        i++, j++) {
      newData[i] = data[j];
    }
    print("🔧 Utils: Created combined data (${newData.length} bytes)");
    return newData;
  }

  /// Convert binary array to hexadecimal string
  static String bytesToHexStr(Uint8List data, [String join = '']) {
    print("🔧 Utils: Converting ${data.length} bytes to hex string");
    List<String> hexList =
        data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).toList();
    String hexResult = hexList.join(join);
    print("🔧 Utils: Hex conversion complete (${hexResult.length} chars)");
    return hexResult;
  }

  static Future<Uint8List> loadBmpImage(String imageUrl) async {
    print("📁 Utils: Starting to load BMP image from: $imageUrl");
    
    try {
      print("📁 Utils: Requesting asset bundle for: $imageUrl");
      final ByteData data = await rootBundle.load(imageUrl);
      
      print("📁 Utils: Asset loaded successfully - Size: ${data.lengthInBytes} bytes");
      
      Uint8List imageData = data.buffer.asUint8List();
      
      // Log some image information for debugging
      if (imageData.length >= 54) {
        // BMP header information
        String signature = String.fromCharCodes(imageData.sublist(0, 2));
        int fileSize = imageData[2] | (imageData[3] << 8) | (imageData[4] << 16) | (imageData[5] << 24);
        int dataOffset = imageData[10] | (imageData[11] << 8) | (imageData[12] << 16) | (imageData[13] << 24);
        int width = imageData[18] | (imageData[19] << 8) | (imageData[20] << 16) | (imageData[21] << 24);
        int height = imageData[22] | (imageData[23] << 8) | (imageData[24] << 16) | (imageData[25] << 24);
        int bitsPerPixel = imageData[28] | (imageData[29] << 8);
        
        print("📁 Utils: BMP Info - Signature: $signature, File Size: $fileSize, Width: $width, Height: $height, BPP: $bitsPerPixel");
        print("📁 Utils: BMP Info - Data Offset: $dataOffset, Actual Size: ${imageData.length}");
        
        if (signature != "BM") {
          print("⚠️ Utils: Warning - File signature is '$signature', expected 'BM'");
        }
        
        if (width != 576 || height != 136) {
          print("⚠️ Utils: Warning - Image dimensions ${width}x${height}, expected 576x136");
        }
        
        if (bitsPerPixel != 1) {
          print("⚠️ Utils: Warning - Bits per pixel is $bitsPerPixel, expected 1");
        }
      } else {
        print("⚠️ Utils: Warning - Image too small to be valid BMP (${imageData.length} bytes)");
      }
      
      print("✅ Utils: BMP image loaded successfully - Total bytes: ${imageData.length}");
      return imageData;
      
    } catch (e) {
      print("❌ Utils: Error loading BMP file '$imageUrl': $e");
      print("❌ Utils: Error type: ${e.runtimeType}");
      
      // Try to provide more specific error information
      if (e is FlutterError) {
        print("❌ Utils: FlutterError details: ${e.message}");
      }
      
      return Uint8List(0);
    }
  }
}