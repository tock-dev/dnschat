import 'dart:async';
import '/api/advertise.dart';
import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart' as mdns;
import 'package:web_socket/web_socket.dart';
import '/model/message.dart';
import '/pages/home.dart';

var _connectionStream = StreamController<bool>.broadcast();
bool _connectionCache = false;
set connected(bool v) {
  _connectionCache = v;
  _connectionStream.add(v);
  if (searchDialogCtx != null && v) {
    Navigator.pop(searchDialogCtx!);
    searchDialogCtx = null;
  }
}

bool get connected => _connectionCache;

WebSocket? socket;

Stream<List<mdns.Service>> scanForDevices() async* {
  final discovery = await mdns.startDiscovery(SERVICE_TYPE);
  final StreamController<List<mdns.Service>> controller = StreamController();

  void listener() {
    print(
      'Discovered devices: ${discovery.services.map((e) => e.name).toList()}',
    );
    controller.add(
      discovery.services.where((s) => s.name != deviceName).toList(),
    );
  }

  discovery.addListener(listener);

  _connectionStream.stream.firstWhere((v) => v == true).then((_) async {
    await controller.close();
    discovery.removeListener(listener);
    await mdns.stopDiscovery(discovery);
  });

  await for (final event in controller.stream) {
    yield event;
  }
}

Future<void> connectToDevice(mdns.Service service) async {
  await disconnectFromDevice();

  socket = await WebSocket.connect(
    Uri.parse('ws://${service.host}:${service.port}'),
  );
  wsClient = null;
  addMessage(
    ChatMessage("Connected to ${service.name}", 'system', DateTime.now()),
  );
  socket!.sendText(deviceName);

  await stopAdvertising();
  await stopServer();

  socket!.events.listen((event) async {
    switch (event) {
      case TextDataReceived(text: final text):
        addMessage(ChatMessage.fromJson(text));
        break;
      case BinaryDataReceived():
        break;
      case CloseReceived(code: _, reason: _):
        addMessage(
          ChatMessage(
            'Connection closed by the remote peer',
            'system',
            DateTime.now(),
          ),
        );
        await disconnectFromDevice();
        await startServer();
        await startAdvertising();
        break;
    }
  });

  refreshConnected();
  connecting = false;
}

void sendToServer(ChatMessage msg) {
  if (socket != null) socket!.sendText(msg.toJson());
}

Future<void> disconnectFromDevice() async {
  if (socket != null) {
    await socket!.close();
    addMessage(
      ChatMessage('Disconnected from remote peer', 'system', DateTime.now()),
    );
    socket = null;
  }

  refreshConnected();
}
