import 'dart:async';
import 'package:demo_ai_even/app.dart';
import 'package:demo_ai_even/services/ble.dart';
import 'package:demo_ai_even/services/evenai.dart';
import 'package:demo_ai_even/services/proto.dart';
import 'package:flutter/services.dart';

typedef SendResultParse = bool Function(Uint8List value);

class BleManager {
  Function()? onStatusChanged;
  BleManager._() {}

  static BleManager? _instance;
  static BleManager get() {
    if (_instance == null) {
      _instance ??= BleManager._();
      _instance!._init();
    }
    return _instance!;
  }

  static const methodSend = "send";
  static const _eventBleReceive = "eventBleReceive";
  static const _channel = MethodChannel('method.bluetooth');
  
  final eventBleReceive = const EventChannel(_eventBleReceive)
      .receiveBroadcastStream(_eventBleReceive)
      .map((ret) => BleReceive.fromMap(ret));

  Timer? beatHeartTimer;
  
  final List<Map<String, String>> pairedGlasses = [];
  bool isConnected = false;
  bool isLeftConnected = false;
  bool isRightConnected = false;
  String connectionStatus = 'Not connected';

  void _init() {
    print("🔧 BleManager: Initializing BLE Manager...");
  }

  void startListening() {
    print("👂 BleManager: Starting to listen for BLE events...");
    eventBleReceive.listen((res) {
      _handleReceivedData(res);
    });
  }

  Future<void> startScan() async {
    try {
      print("🔍 BleManager: Starting BLE scan...");
      await _channel.invokeMethod('startScan');
      print("✅ BleManager: BLE scan started successfully");
    } catch (e) {
      print('❌ BleManager: Error starting scan: $e');
    }
  }

  Future<void> stopScan() async {
    try {
      print("🛑 BleManager: Stopping BLE scan...");
      await _channel.invokeMethod('stopScan');
      print("✅ BleManager: BLE scan stopped successfully");
    } catch (e) {
      print('❌ BleManager: Error stopping scan: $e');
    }
  }

  Future<void> connectToGlasses(String deviceName) async {
    try {
      print("🔗 BleManager: Attempting to connect to device: $deviceName");
      await _channel.invokeMethod('connectToGlasses', {'deviceName': deviceName});
      connectionStatus = 'Connecting...';
      print("🔄 BleManager: Connection request sent, status: $connectionStatus");
    } catch (e) {
      print('❌ BleManager: Error connecting to device: $e');
      connectionStatus = 'Connection failed';
    }
  }

  void setMethodCallHandler() {
    print("📱 BleManager: Setting method call handler...");
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    print("📞 BleManager: Received method call: ${call.method} with arguments: ${call.arguments}");
    switch (call.method) {
      case 'glassesConnected':
        _onGlassesConnected(call.arguments);
        break;
      case 'glassesConnecting':
        _onGlassesConnecting();
        break;
      case 'glassesDisconnected':
        _onGlassesDisconnected();
        break;
      case 'foundPairedGlasses':
        _onPairedGlassesFound(Map<String, String>.from(call.arguments));
        break;
      default:
        print('⚠️ BleManager: Unknown method: ${call.method}');
    }
  }

  void _onGlassesConnected(dynamic arguments) {
    print("🎉 BleManager: Glasses connected! Arguments: $arguments");
    connectionStatus = 'Connected: \n${arguments['leftDeviceName']} \n${arguments['rightDeviceName']}';
    isConnected = true;
    isLeftConnected = true;
    isRightConnected = true;
    
    print("✅ BleManager: Connection state - isConnected: $isConnected, isLeftConnected: $isLeftConnected, isRightConnected: $isRightConnected");

    onStatusChanged?.call();
    startSendBeatHeart();
  }

  int tryTime = 0;
  void startSendBeatHeart() async {
    print("💓 BleManager: Starting heartbeat timer...");
    beatHeartTimer?.cancel();
    beatHeartTimer = null;

    beatHeartTimer = Timer.periodic(Duration(seconds: 8), (timer) async {
      print("💓 BleManager: Sending heartbeat (attempt ${tryTime + 1})...");
      bool isSuccess = await Proto.sendHeartBeat();
      print("💓 BleManager: Heartbeat result: $isSuccess");
      if (!isSuccess && tryTime < 2) {
        tryTime++;
        print("💓 BleManager: Heartbeat failed, retrying (attempt ${tryTime + 1})...");
        await Proto.sendHeartBeat();
      } else {
        tryTime = 0;
      }
    });
  }

  void _onGlassesConnecting() {
    print("🔄 BleManager: Glasses connecting...");
    connectionStatus = 'Connecting...';
    onStatusChanged?.call();
  }

  void _onGlassesDisconnected() {
    print("💔 BleManager: Glasses disconnected");
    connectionStatus = 'Not connected';
    isConnected = false;
    isLeftConnected = false;
    isRightConnected = false;
    
    print("❌ BleManager: Connection state - isConnected: $isConnected, isLeftConnected: $isLeftConnected, isRightConnected: $isRightConnected");

    onStatusChanged?.call();
  }

  void _onPairedGlassesFound(Map<String, String> deviceInfo) {
    final String channelNumber = deviceInfo['channelNumber']!;
    final isAlreadyPaired = pairedGlasses.any((glasses) => glasses['channelNumber'] == channelNumber);

    print("🔍 BleManager: Found paired glasses - Channel: $channelNumber, Already paired: $isAlreadyPaired");
    print("🔍 BleManager: Device info: $deviceInfo");

    if (!isAlreadyPaired) {
      pairedGlasses.add(deviceInfo);
      print("➕ BleManager: Added new paired glasses to list");
    }

    onStatusChanged?.call();
  }

  void _handleReceivedData(BleReceive res) {
    if (res.type == "VoiceChunk") {
      return;
    }

    String cmd = "${res.lr}${res.getCmd().toRadixString(16).padLeft(2, '0')}";
    if (res.getCmd() != 0xf1) {
      print(
        "📡 BleManager: Received data - Command: $cmd, Length: ${res.data.length}, Data: ${res.data.hexString}",
      );
    }

    if (res.data[0].toInt() == 0xF5) {
      final notifyIndex = res.data[1].toInt();
      print("👆 BleManager: TouchBar event received - Index: $notifyIndex, Side: ${res.lr}");
      
      switch (notifyIndex) {
        case 0:
          print("🚪 BleManager: Exit command received");
          App.get.exitAll();
          break;
        case 1: 
          if (res.lr == 'L') {
            print("⬅️ BleManager: Left touchbar - Last page");
            EvenAI.get.lastPageByTouchpad();
          } else {
            print("➡️ BleManager: Right touchbar - Next page");
            EvenAI.get.nextPageByTouchpad();
          }
          break;
        case 23: //BleEvent.evenaiStart:
          print("🤖 BleManager: Even AI start command received");
          EvenAI.get.toStartEvenAIByOS();
          break;
        case 24: //BleEvent.evenaiRecordOver:
          print("🛑 BleManager: Even AI record over command received");
          EvenAI.get.recordOverByOS();
          break;
        default:
          print("❓ BleManager: Unknown Ble Event: $notifyIndex");
      }
      return;
    }
      _reqListen.remove(cmd)?.complete(res);
      _reqTimeout.remove(cmd)?.cancel();
      if (_nextReceive != null) {
        _nextReceive?.complete(res);
        _nextReceive = null;
      }

  }

  String getConnectionStatus() {
    print("ℹ️ BleManager: Getting connection status: $connectionStatus");
    return connectionStatus;
  }

  List<Map<String, String>> getPairedGlasses() {
    print("ℹ️ BleManager: Getting paired glasses list (${pairedGlasses.length} devices)");
    return pairedGlasses;
  }


  static final _reqListen = <String, Completer<BleReceive>>{};
  static final _reqTimeout = <String, Timer>{};
  static Completer<BleReceive>? _nextReceive;

  static _checkTimeout(String cmd, int timeoutMs, Uint8List data, String lr) {
    _reqTimeout.remove(cmd);
    var cb = _reqListen.remove(cmd);
    print('⏰ BleManager: Timeout occurred - Command: $cmd, Timeout: ${timeoutMs}ms, Callback exists: ${cb != null}');
    if (cb != null) {
      var res = BleReceive();
      res.isTimeout = true;
      //var showData = data.length > 50 ? data.sublist(0, 50) : data;
      print("⏰ BleManager: Request timeout for command $cmd after ${timeoutMs}ms");
      cb.complete(res);
    }

    _reqTimeout[cmd]?.cancel();
    _reqTimeout.remove(cmd);
  }

  static Future<T?> invokeMethod<T>(String method, [dynamic params]) {
    print("📱 BleManager: Invoking platform method: $method with params: $params");
    return _channel.invokeMethod(method, params);
  }

  static Future<BleReceive> requestRetry(
    Uint8List data, {
    String? lr,
    Map<String, dynamic>? other,
    int timeoutMs = 200,
    bool useNext = false,
    int retry = 3,
  }) async {
    print("🔄 BleManager: Request with retry - LR: $lr, Timeout: ${timeoutMs}ms, Retries: $retry");
    BleReceive ret;
    for (var i = 0; i <= retry; i++) {
      print("🔄 BleManager: Retry attempt ${i + 1}/${retry + 1}");
      ret = await request(data,
          lr: lr, other: other, timeoutMs: timeoutMs, useNext: useNext);
      if (!ret.isTimeout) {
        print("✅ BleManager: Request succeeded on attempt ${i + 1}");
        return ret;
      }
      if (!BleManager.isBothConnected()) {
        print("❌ BleManager: Both devices not connected, stopping retries");
        break;
      }
    }
    ret = BleReceive();
    ret.isTimeout = true;
    print("❌ BleManager: All retry attempts failed for LR: $lr, timeout: ${timeoutMs}ms");
    return ret;
  }

  static Future<bool> sendBoth(
    data, {
    int timeoutMs = 250,
    SendResultParse? isSuccess,
    int? retry,
  }) async {
    print("📡 BleManager: Sending to both devices - Timeout: ${timeoutMs}ms, Retry: $retry");

    var ret = await BleManager.requestRetry(data,
        lr: "L", timeoutMs: timeoutMs, retry: retry ?? 0);
    if (ret.isTimeout) {
      print("❌ BleManager: Left device timeout in sendBoth");
      return false;
    } else if (isSuccess != null) {
      final success = isSuccess.call(ret.data);
      print("📡 BleManager: Left device response success: $success");
      if (!success) return false;
      var retR = await BleManager.requestRetry(data,
          lr: "R", timeoutMs: timeoutMs, retry: retry ?? 0);
      if (retR.isTimeout) {
        print("❌ BleManager: Right device timeout in sendBoth");
        return false;
      }
      final rightSuccess = isSuccess.call(retR.data);
      print("📡 BleManager: Right device response success: $rightSuccess");
      return rightSuccess;
    } else if (ret.data[1].toInt() == 0xc9) {
      print("✅ BleManager: Left device acknowledged, sending to right...");
      var ret = await BleManager.requestRetry(data,
          lr: "R", timeoutMs: timeoutMs, retry: retry ?? 0);
      if (ret.isTimeout) {
        print("❌ BleManager: Right device timeout in sendBoth");
        return false;
      }
      print("✅ BleManager: Both devices responded successfully");
    }
    return true;
  }

  static Future sendData(Uint8List data,
      {String? lr, Map<String, dynamic>? other, int secondDelay = 100}) async {
    print("📤 BleManager: Sending data - LR: $lr, Data length: ${data.length}, Data: ${data.hexString}");

    var params = <String, dynamic>{
      'data': data,
    };
    if (other != null) {
      params.addAll(other);
    }
    dynamic ret;
    if (lr != null) {
      params["lr"] = lr;
      print("📤 BleManager: Sending to specific side: $lr");
      ret = await BleManager.invokeMethod(methodSend, params);
      print("📤 BleManager: Send result for $lr: $ret");
      return ret;
    } else {
      print("📤 BleManager: Sending to both sides (L first, then R)");
      params["lr"] = "L"; // get().slave; 
      var ret = await _channel
          .invokeMethod(methodSend, params); //ret is true or false or null
      print("📤 BleManager: Left side send result: $ret");
      if (ret == true) {
        params["lr"] = "R"; // get().master;
        ret = await BleManager.invokeMethod(methodSend, params);
        print("📤 BleManager: Right side send result: $ret");
        return ret;
      }
      if (secondDelay > 0) {
        print("⏳ BleManager: Waiting ${secondDelay}ms before sending to right...");
        await Future.delayed(Duration(milliseconds: secondDelay));
      }
      params["lr"] = "R"; // get().master;
      ret = await BleManager.invokeMethod(methodSend, params);
      print("📤 BleManager: Right side send result (after delay): $ret");
      return ret;
    }
  }

  static Future<BleReceive> request(Uint8List data,
      {String? lr,
      Map<String, dynamic>? other,
      int timeoutMs = 1000, //500,
      bool useNext = false}) async {

    var lr0 = lr ?? Proto.lR();
    var completer = Completer<BleReceive>();
    String cmd = "$lr0${data[0].toRadixString(16).padLeft(2, '0')}";

    print("📨 BleManager: Making request - Command: $cmd, LR: $lr0, Timeout: ${timeoutMs}ms, UseNext: $useNext");

    if (useNext) {
      _nextReceive = completer;
      print("📨 BleManager: Using next receive for command: $cmd");
    } else {
      if (_reqListen.containsKey(cmd)) {
        var res = BleReceive();
        res.isTimeout = true;
        _reqListen[cmd]?.complete(res);
        print("⚠️ BleManager: Command already exists, completing with timeout: $cmd");

        _reqTimeout[cmd]?.cancel();
      }
      _reqListen[cmd] = completer;
    }
    print("📨 BleManager: Request registered for command: $cmd");

    if (timeoutMs > 0) {
      _reqTimeout[cmd] = Timer(Duration(milliseconds: timeoutMs), () {
        _checkTimeout(cmd, timeoutMs, data, lr0);
      });
    }

    completer.future.then((result) {
      _reqTimeout.remove(cmd)?.cancel();
      print("📨 BleManager: Request completed for command: $cmd, Timeout: ${result.isTimeout}");
    });

    await sendData(data, lr: lr, other: other).timeout(
      Duration(seconds: 2),
      onTimeout: () {
        print("⏰ BleManager: Send data timeout (2s) for command: $cmd");
        _reqTimeout.remove(cmd)?.cancel();
        var ret = BleReceive();
        ret.isTimeout = true;
        _reqListen.remove(cmd)?.complete(ret);
      },
    );

    return completer.future;
  }

  static bool isBothConnected() {
    // Fix: Actually check the connection state instead of always returning true
    final instance = BleManager.get();
    bool bothConnected = instance.isLeftConnected && instance.isRightConnected;
    print("🔍 BleManager: Checking connection state - Left: ${instance.isLeftConnected}, Right: ${instance.isRightConnected}, Both: $bothConnected");
    return bothConnected;
  }

  static Future<bool> requestList(
    List<Uint8List> sendList, {
    String? lr,
    int? timeoutMs,
  }) async {
    print("📋 BleManager: Sending request list - Items: ${sendList.length}, LR: $lr, Timeout: ${timeoutMs}ms");

    if (lr != null) {
      return await _requestList(sendList, lr, timeoutMs: timeoutMs);
    } else {
      var rets = await Future.wait([
        _requestList(sendList, "L", keepLast: true, timeoutMs: timeoutMs),
        _requestList(sendList, "R", keepLast: true, timeoutMs: timeoutMs),
      ]);
      print("📋 BleManager: Both sides results - Left: ${rets[0]}, Right: ${rets[1]}");
      if (rets.length == 2 && rets[0] && rets[1]) {
        var lastPack = sendList[sendList.length - 1];
        print("📋 BleManager: Sending final packet to both sides");
        return await sendBoth(lastPack, timeoutMs: timeoutMs ?? 250);
      } else {
        print("❌ BleManager: Error in request list for both sides");
      }
    }
    return false;
  }

  static Future<bool> _requestList(List sendList, String lr,
      {bool keepLast = false, int? timeoutMs}) async {
    int len = sendList.length;
    if (keepLast) len = sendList.length - 1;
    print("📋 BleManager: Processing request list for $lr - Items: $len/${sendList.length}");
    
    for (var i = 0; i < len; i++) {
      var pack = sendList[i];
      print("📋 BleManager: Sending packet ${i + 1}/$len to $lr");
      var resp = await request(pack, lr: lr, timeoutMs: timeoutMs ?? 350);
      if (resp.isTimeout) {
        print("❌ BleManager: Timeout on packet ${i + 1} to $lr");
        return false;
      } else if (resp.data[1].toInt() != 0xc9 && resp.data[1].toInt() != 0xcB) {
        print("❌ BleManager: Invalid response on packet ${i + 1} to $lr: ${resp.data[1].toInt()}");
        return false;
      } else {
        print("✅ BleManager: Packet ${i + 1} to $lr successful");
      }
    }
    return true;
  }

}

extension Uint8ListEx on Uint8List {
  String get hexString {
    return map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
  }
}
