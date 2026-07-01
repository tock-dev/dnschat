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
  final discovery = await mdns.startDiscovery('_dnschat._tcp');
  final Completer<List<mdns.Service>> completer = Completer();

  discovery.addListener(() {
    completer.complete(
      discovery.services
          .where((s) => s.name != '@$username on ${Platform.operatingSystem}')
          .toList(),
    );
  });

  return Future.any([
    completer.future,
    _connectionStream.stream.firstWhere((v) => v == true).then((_) => []),
  ]);
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
