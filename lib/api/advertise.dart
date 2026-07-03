import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';

import '/main.dart';

import '/api/scan.dart';
import '/model/message.dart';
import '/pages/home.dart';
import 'package:nsd/nsd.dart' as mdns;

const PORT = 62889;
const SERVICE_TYPE = '_dnschatv2._tcp';

mdns.Registration? reg;
HttpServer? _http;
WebSocket? wsClient;
String? chattingWith;
String deviceName = 'DNSChat Default - you\'re not supposed to see this';

Future<void> startServer() async {
  _http = await HttpServer.bind(InternetAddress.anyIPv4, PORT);
  _http!.listen((req) {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      WebSocketTransformer.upgrade(req).then((ws) {
        wsClient = ws;
        socket = null;
        refreshConnected();
        ws.listen(
          (data) {
            if (chattingWith == null) {
              chattingWith = data;
              addMessage(
                ChatMessage(
                  'Received a connection from $chattingWith',
                  'system',
                  DateTime.now(),
                ),
              );
            } else {
              addMessage(ChatMessage.fromJson(data));
            }
          },
          onDone: () {
            wsClient = null;
            refreshConnected();
            chattingWith = null;
          },
        );
      });
    }
  });
}

Future<void> stopServer() async {
  if (_http != null) {
    await _http!.close();
    _http = null;
  }

  if (wsClient != null) {
    await wsClient!.close();
    wsClient = null;
  }

  refreshConnected();
}

Future<void> startAdvertising() async {
  if (deviceName == 'DNSChat Default - you\'re not supposed to see this') {
    var dip = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      var deviceInfo = await dip.androidInfo;
      deviceName = deviceInfo.name;
    } else if (Platform.isIOS) {
      var deviceInfo = await dip.iosInfo;
      deviceName = '${deviceInfo.name} / ${deviceInfo.modelName}';
    } else if (Platform.isLinux) {
      var deviceInfo = await dip.linuxInfo;
      deviceName = deviceInfo.prettyName;
    } else if (Platform.isMacOS) {
      var deviceInfo = await dip.macOsInfo;
      deviceName = deviceInfo.computerName;
    } else if (Platform.isWindows) {
      var deviceInfo = await dip.windowsInfo;
      deviceName =
          '${deviceInfo.userName}\'s ${deviceInfo.computerName} / ${deviceInfo.productName}';
    }
  }
  print('Current device name: $deviceName');

  reg = await mdns.register(
    mdns.Service(
      name: '@$username on $deviceName',
      type: SERVICE_TYPE,
      port: PORT,
    ),
  );
}

Future<void> stopAdvertising() async {
  if (reg != null) {
    await mdns.unregister(reg!);
    reg = null;
  }
}

void sendToClient(ChatMessage msg) {
  if (wsClient != null) wsClient!.add(msg.toJson());
}
