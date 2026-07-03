import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '/api/advertise.dart';
import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart' as mdns;
import 'package:web_socket/web_socket.dart';
import '/main.dart';
import '/model/message.dart';
import '/pages/home.dart';

var _connectionStream = StreamController<bool>.broadcast();
bool _connectionCache = false;
set connected(bool v) {
  _connectionCache = v;
  _connectionStream.add(v);
  if (searchDialogCtx != null && v) Navigator.pop(searchDialogCtx!);
}

bool get connected => _connectionCache;

WebSocket? socket;

Future<List<mdns.Service>> scanForDevices() async {
  final discovery = await mdns.startDiscovery(SERVICE_TYPE);
  final Completer<List<mdns.Service>> completer = Completer();

  void listener() {
    print(
      'Discovered devices: ${discovery.services.map((e) => e.name).toList()}',
    );
    completer.complete(
      discovery.services.where((s) => s.name != deviceName).toList(),
    );
  }

  discovery.addListener(listener);

  var f = await Future.any([
    completer.future,
    _connectionStream.stream
        .firstWhere((v) => v == true)
        .then((_) => <mdns.Service>[]),
  ]);
  discovery.removeListener(listener);

  return f;
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
  stopAdvertising();
  stopServer();

  socket?.events.listen((event) async {
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
        connected = false;
        startServer();
        startAdvertising();
        break;
    }
  });

  connected = true;
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

  connected = false;
}
