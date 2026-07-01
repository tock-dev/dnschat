import '/api/advertise.dart';
import '/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nsd/nsd.dart' as mdns;
import 'package:oktoast/oktoast.dart';
import '/api/scan.dart';
import '/model/message.dart';

Function? _setState;
List<ChatMessage> messages = [];
String username = 'default';
BuildContext? searchDialogCtx;

void addMessage(ChatMessage msg) {
  messages.add(msg);

  if (_setState != null) _setState!(() {});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController _chatInputCtrl;

  @override
  void initState() {
    (() async {
      await startServer();
      await startAdvertising();
    })();

    _chatInputCtrl = TextEditingController();

    _setState = setState;

    super.initState();
  }

  @override
  void dispose() {
    (() async {
      if (connected) {
        if (wsClient != null) {
          await wsClient!.close();
        }

        await stopAdvertising();
        await stopServer();

        await disconnectFromDevice();
      }
    })();

    _chatInputCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (!connected) return;

    final text = _chatInputCtrl.text;
    if (text.isEmpty) return;

    print('Sending message: $text');
    _chatInputCtrl.clear();

    final msg = ChatMessage(text, username, DateTime.now());
    addMessage(msg);
    if (socket != null) {
      sendToServer(msg);
    } else if (wsClient != null) {
      sendToClient(msg);
    } else {
      print('No connection');
      showToast('Not connected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DNSChat'),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Settings'),
                  content: Column(
                    children: [
                      TextField(
                        controller: TextEditingController(text: username),
                        onChanged: (value) => username = value,
                        onSubmitted: (value) {
                          username = value;
                          setState(() {
                            box.write('username', username);
                            Navigator.pop(context);
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          box.write('username', username);
                          Navigator.pop(context);
                        });
                      },
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return Align(
                          alignment: message.isSystem
                              ? Alignment.center
                              : message.isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: message.isSystem
                              ? Padding(
                                  padding: EdgeInsetsGeometry.all(5),
                                  child: Text(
                                    message.text,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : Container(
                                  // Constrains the max width to 75% of screen to prevent text overflow
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: message.isMine
                                        ? Colors.blue
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: message.isMine
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    mainAxisSize:
                                        MainAxisSize.min, // Shrinks vertically
                                    children: [
                                      Text(
                                        message.text,
                                        style: TextStyle(
                                          color: message.isMine
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${message.sender == username ? 'Me' : '@${message.sender}'}, ${DateFormat('HH:mm, MMM d, yyyy').format(message.timestamp.toLocal())}",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: message.isMine
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: FloatingActionButton(
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (context) {
                            searchDialogCtx = context;
                            bool loadedData = false;
                            return StatefulBuilder(
                              builder: (context, setStateJr) {
                                return FutureBuilder(
                                  future: scanForDevices(),
                                  builder: (context, snapshot) {
                                    print(
                                      'Future building, ${snapshot.connectionState}, ${snapshot.hasData}, $loadedData',
                                    );
                                    if (snapshot.hasError)
                                      return Text('Error: ${snapshot.error}');
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      loadedData = false;
                                      return AlertDialog(
                                        icon: Icon(Icons.search),
                                        title: Text('Search for devices...'),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          child:
                                              const CircularProgressIndicator(),
                                        ),
                                      );
                                    } else {
                                      loadedData = true;
                                      return AlertDialog(
                                        icon: Icon(Icons.search),
                                        title: Text('Search for devices...'),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: snapshot.data!.length,
                                            itemBuilder: (context, index) {
                                              final service =
                                                  snapshot.data![index];
                                              return ListTile(
                                                title: Text(
                                                  service.name ??
                                                      'No name specified',
                                                ),
                                                onTap: () async {
                                                  await connectToDevice(
                                                    service,
                                                  );
                                                  setState(() {});
                                                },
                                              );
                                            },
                                          ),
                                        ),

                                        actions: [
                                          TextButton(
                                            onPressed: loadedData
                                                ? () => setStateJr(() {
                                                    loadedData = false;
                                                  })
                                                : null,
                                            child: Text('Refresh'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                Navigator.pop(context);
                                              });
                                            },
                                            child: Text('Close'),
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                );
                              },
                            );
                          },
                        );
                        searchDialogCtx = null;
                      },
                      shape: CircleBorder(),
                      child: Icon(Icons.search),
                    ),
                  ),
                ],
              ),
            ),
            TextField(
              controller: _chatInputCtrl,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: connected ? _sendMessage : null,
                  icon: Icon(Icons.send),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
