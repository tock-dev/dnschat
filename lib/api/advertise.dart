import 'dart:io';
import 'dart:typed_data';
import '/main.dart';

import '/api/scan.dart';
import '/model/message.dart';
import '/pages/home.dart';
import 'package:nsd/nsd.dart' as mdns;

const PORT = 62889;

mdns.Registration? reg;
HttpServer? _http;
WebSocket? wsClient;

Future<void> startServer() async {
  _http = await HttpServer.bind(InternetAddress.anyIPv4, PORT);
  _http!.listen((req) {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      WebSocketTransformer.upgrade(req).then((ws) {
        wsClient = ws;
        socket = null;
        connected = true;
        addMessage(
          ChatMessage('Received a new connection', 'system', DateTime.now()),
        );
        ws.listen(
          (data) {
            addMessage(ChatMessage.fromJson(data));
          },
          onDone: () {
            wsClient = null;
            connected = false;
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

  connected = false;
}

Future<void> startAdvertising() async {
  reg = await mdns.register(
    mdns.Service(
      name: '@$username on ${Platform.operatingSystem}',
      type: '_dnschat._tcp',
      port: PORT,
      txt: {'session_id': Uint8List.fromList(SESSION_ID.codeUnits)},
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
