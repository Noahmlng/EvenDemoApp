import 'dart:convert';
import 'dart:typed_data';

import 'package:demo_ai_even/ble_manager.dart';
import 'package:demo_ai_even/services/evenai_proto.dart';
import 'package:demo_ai_even/utils/utils.dart';

class Proto {
  static String lR() {
    // todo
    if (BleManager.isBothConnected()) {
      print("🔍 Proto: Both sides connected, using 'R'");
      return "R";
    }
    //if (BleManager.isConnectedR()) return "R";
    print("🔍 Proto: Not both connected, using 'L'");
    return "L";
  }

  /// Returns the time consumed by the command and whether it is successful
  static Future<(int, bool)> micOn({
    String? lr,
  }) async {
    print("🎤 Proto: Starting microphone activation for side: ${lr ?? 'auto'}");
    var begin = Utils.getTimestampMs();
    var data = Uint8List.fromList([0x0E, 0x01]);
    print("🎤 Proto: Sending mic on command: $data");
    var receive = await BleManager.request(data, lr: lr);

    var end = Utils.getTimestampMs();
    var startMic = (begin + ((end - begin) ~/ 2));

    print("🎤 Proto: Mic command completed - Start time: $startMic, Duration: ${end - begin}ms");
    bool success = (!receive.isTimeout && receive.data[1] == 0xc9);
    print("🎤 Proto: Mic activation result: $success (timeout: ${receive.isTimeout}, response: ${receive.data})");
    return (startMic, success);
  }

  /// Even AI
  static int _evenaiSeq = 0;
  // AI result transmission (also compatible with AI startup and Q&A status synchronization)
  static Future<bool> sendEvenAIData(String text,
      {int? timeoutMs,
      required int newScreen,
      required int pos,
      required int current_page_num,
      required int max_page_num}) async {
    print("🤖 Proto: Starting Even AI data transmission");
    print("🤖 Proto: Text: '$text'");
    print("🤖 Proto: Parameters - newScreen: $newScreen, pos: $pos, current_page: $current_page_num, max_page: $max_page_num");
    
    var data = utf8.encode(text);
    var syncSeq = _evenaiSeq & 0xff;

    List<Uint8List> dataList = EvenaiProto.evenaiMultiPackListV2(0x4E,
        data: data,
        syncSeq: syncSeq,
        newScreen: newScreen,
        pos: pos,
        current_page_num: current_page_num,
        max_page_num: max_page_num);
    _evenaiSeq++;

    print("🤖 Proto: Created ${dataList.length} packets for transmission (seq: $syncSeq)");

    print("🤖 Proto: Sending to left side...");
    bool isSuccess = await BleManager.requestList(dataList,
        lr: "L", timeoutMs: timeoutMs ?? 2000);

    print("🤖 Proto: Left side result: $isSuccess");
    if (!isSuccess) {
      print("❌ Proto: Even AI data failed for left side");
      return false;
    } else {
      print("🤖 Proto: Sending to right side...");
      isSuccess = await BleManager.requestList(dataList,
          lr: "R", timeoutMs: timeoutMs ?? 2000);

      print("🤖 Proto: Right side result: $isSuccess");
      if (!isSuccess) {
        print("❌ Proto: Even AI data failed for right side");
        return false;
      }
      print("✅ Proto: Even AI data sent successfully to both sides");
      return true;
    }
  }

  static int _beatHeartSeq = 0;
  static Future<bool> sendHeartBeat() async {
    print("💓 Proto: Preparing heartbeat packet (seq: $_beatHeartSeq)");
    var length = 6;
    var data = Uint8List.fromList([
      0x25,
      length & 0xff,
      (length >> 8) & 0xff,
      _beatHeartSeq % 0xff,
      0x04,
      _beatHeartSeq % 0xff //0xff,
    ]);
    _beatHeartSeq++;

    print("💓 Proto: Sending heartbeat to left side - Data: $data");
    var ret = await BleManager.request(data, lr: "L", timeoutMs: 1500);

    print("💓 Proto: Left side heartbeat response: ${ret.data} (timeout: ${ret.isTimeout})");
    if (ret.isTimeout) {
      print("❌ Proto: Left side heartbeat timeout");
      return false;
    } else if (ret.data[0].toInt() == 0x25 &&
        ret.data.length > 5 &&
        ret.data[4].toInt() == 0x04) {
      print("✅ Proto: Left side heartbeat successful, sending to right side...");
      var retR = await BleManager.request(data, lr: "R", timeoutMs: 1500);
      print("💓 Proto: Right side heartbeat response: ${retR.data} (timeout: ${retR.isTimeout})");
      if (retR.isTimeout) {
        print("❌ Proto: Right side heartbeat timeout");
        return false;
      } else if (retR.data[0].toInt() == 0x25 &&
          retR.data.length > 5 &&
          retR.data[4].toInt() == 0x04) {
        print("✅ Proto: Both sides heartbeat successful");
        return true;
      } else {
        print("❌ Proto: Right side heartbeat invalid response: ${retR.data}");
        return false;
      }
    } else {
      print("❌ Proto: Left side heartbeat invalid response: ${ret.data}");
      return false;
    }
  }

  static Future<String> getLegSn(String lr) async {
    print("📋 Proto: Getting leg serial number for side: $lr");
    var cmd = Uint8List.fromList([0x34]);
    var resp = await BleManager.request(cmd, lr: lr);
    var sn = String.fromCharCodes(resp.data.sublist(2, 18).toList());
    print("📋 Proto: Serial number for $lr: $sn");
    return sn;
  }

  // tell the glasses to exit function to dashboard
  static Future<bool> exit() async {
    print("🚪 Proto: Sending exit command to return to dashboard");
    var data = Uint8List.fromList([0x18]);

    print("🚪 Proto: Sending exit command to left side...");
    var retL = await BleManager.request(data, lr: "L", timeoutMs: 1500);
    print("🚪 Proto: Left side exit response: ${retL.data} (timeout: ${retL.isTimeout})");
    
    if (retL.isTimeout) {
      print("❌ Proto: Left side exit timeout");
      return false;
    } else if (retL.data.isNotEmpty && retL.data[1].toInt() == 0xc9) {
      print("✅ Proto: Left side exit successful, sending to right side...");
      var retR = await BleManager.request(data, lr: "R", timeoutMs: 1500);
      print("🚪 Proto: Right side exit response: ${retR.data} (timeout: ${retR.isTimeout})");
      
      if (retR.isTimeout) {
        print("❌ Proto: Right side exit timeout");
        return false;
      } else if (retR.data.isNotEmpty && retR.data[1].toInt() == 0xc9) {
        print("✅ Proto: Both sides exit successful");
        return true;
      } else {
        print("❌ Proto: Right side exit invalid response: ${retR.data}");
        return false;
      }
    } else {
      print("❌ Proto: Left side exit invalid response: ${retL.data}");
      return false;
    }
  }

  static List<Uint8List> _getPackList(int cmd, Uint8List data,
      {int count = 20}) {
    print("📦 Proto: Creating packet list for command 0x${cmd.toRadixString(16)} with ${data.length} bytes");
    final realCount = count - 3;
    List<Uint8List> send = [];
    int maxSeq = data.length ~/ realCount;
    if (data.length % realCount > 0) {
      maxSeq++;
    }
    print("📦 Proto: Will create $maxSeq packets with max $realCount bytes each");
    
    for (var seq = 0; seq < maxSeq; seq++) {
      var start = seq * realCount;
      var end = start + realCount;
      if (end > data.length) {
        end = data.length;
      }
      var itemData = data.sublist(start, end);
      var pack = Utils.addPrefixToUint8List([cmd, maxSeq, seq], itemData);
      send.add(pack);
    }
    print("📦 Proto: Created ${send.length} packets");
    return send;
  }

  static Future<void> sendNewAppWhiteListJson(String whitelistJson) async {
    print("📋 Proto: Sending app whitelist JSON (${whitelistJson.length} chars)");
    final whitelistData = utf8.encode(whitelistJson);
    //  2、转换为接口格式
    final dataList = _getPackList(0x04, whitelistData, count: 180);
    print("📋 Proto: Whitelist split into ${dataList.length} packets");
    
    for (var i = 0; i < 3; i++) {
      print("📋 Proto: Sending whitelist attempt ${i + 1}/3...");
      final isSuccess =
          await BleManager.requestList(dataList, timeoutMs: 300, lr: "L");
      if (isSuccess) {
        print("✅ Proto: Whitelist sent successfully");
        return;
      }
      print("❌ Proto: Whitelist attempt ${i + 1} failed");
    }
    print("❌ Proto: All whitelist attempts failed");
  }

  /// 发送通知
  ///
  /// - app [Map] 通知消息数据
  static Future<void> sendNotify(Map appData, int notifyId,
      {int retry = 6}) async {
    print("📢 Proto: Sending notification (ID: $notifyId, retries: $retry)");
    print("📢 Proto: Notification data: $appData");
    
    final notifyJson = jsonEncode({
      "ncs_notification": appData,
    });
    final dataList =
        _getNotifyPackList(0x4B, notifyId, utf8.encode(notifyJson));
    print("📢 Proto: Notification JSON (${notifyJson.length} chars) split into ${dataList.length} packets");
    
    for (var i = 0; i < retry; i++) {
      print("📢 Proto: Notification attempt ${i + 1}/$retry...");
      final isSuccess =
          await BleManager.requestList(dataList, timeoutMs: 1000, lr: "L");
      if (isSuccess) {
        print("✅ Proto: Notification sent successfully");
        return;
      }
      print("❌ Proto: Notification attempt ${i + 1} failed");
    }
    print("❌ Proto: All notification attempts failed");
  }

  static List<Uint8List> _getNotifyPackList(
      int cmd, int msgId, Uint8List data) {
    print("📢 Proto: Creating notification packet list for command 0x${cmd.toRadixString(16)}, msgId: $msgId");
    List<Uint8List> send = [];
    int maxSeq = data.length ~/ 176;
    if (data.length % 176 > 0) {
      maxSeq++;
    }
    print("📢 Proto: Will create $maxSeq notification packets");
    
    for (var seq = 0; seq < maxSeq; seq++) {
      var start = seq * 176;
      var end = start + 176;
      if (end > data.length) {
        end = data.length;
      }
      var itemData = data.sublist(start, end);
      var pack =
          Utils.addPrefixToUint8List([cmd, msgId, maxSeq, seq], itemData);
      send.add(pack);
    }
    print("📢 Proto: Created ${send.length} notification packets");
    return send;
  }
}
