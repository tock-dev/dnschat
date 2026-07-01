import 'package:dnschat/api/advertise.dart';
import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart' as mdns;
import 'package:oktoast/oktoast.dart';
import '../api/scan.dart';
import '/model/message.dart';

List<ChatMessage> messages = [];
String username = 'default';
BuildContext? searchDialogCtx;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController _chatInputCtrl;

  @override
  void initState() async {
    _chatInputCtrl = TextEditingController();
    await startServer();
    await startAdvertising();
    super.initState();
  }

  @override
  void dispose() async {
    _chatInputCtrl.dispose();
    if (connected) {
      if (wsClient != null) {
        await wsClient!.close();
      }

      await stopAdvertising();
      await stopServer();

      await disconnectFromDevice();
    }
    super.dispose();
  }

  void _sendMessage() {
    if (!connected) return;

    final text = _chatInputCtrl.text;
    if (text.isEmpty) return;

    print('Sending message: $text');
    _chatInputCtrl.clear();

    final msg = ChatMessage(text, username, DateTime.now());
    messages.add(msg);
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
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) {
              searchDialogCtx = context;
              return AlertDialog(
                icon: Icon(Icons.search),
                title: Text('Search for devices...'),
                content: FutureBuilder(
                  future: scanForDevices(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return Text('Error: ${snapshot.error}');
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const CircularProgressIndicator();
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final service = snapshot.data![index];
                        return ListTile(
                          title: Text(service.name ?? 'No name specified'),
                          onTap: () {
                            connectToDevice(service);
                          },
                        );
                      },
                    );
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                ],
              );
            },
          );
          searchDialogCtx = null;
        },
        child: Icon(Icons.search),
      ),
      body: Column(
        children: [
          ListView.builder(
            itemBuilder: (context, index) => Align(
              alignment: messages[index].isMine
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Card(
                child: Container(
                  margin: EdgeInsets.only(
                    top: 8,
                    bottom: 8,
                    left: messages[index].isMine ? 64 : 0,
                    right: messages[index].isMine ? 0 : 64,
                  ),
                  child: ListTile(
                    title: Text(messages[index].text),
                    subtitle: Text(
                      "${messages[index].sender == username ? 'Me' : messages[index].sender}"
                      "at ${messages[index].timestamp}",
                    ),
                  ),
                ),
              ),
            ),
            itemCount: messages.length,
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
    );
  }
}
