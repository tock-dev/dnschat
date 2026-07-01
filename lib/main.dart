import 'package:get_storage/get_storage.dart';
import 'package:oktoast/oktoast.dart';
import 'package:uuid/uuid.dart';

import '/pages/home.dart';
import 'package:flutter/material.dart';

final SESSION_ID = const Uuid().v8();

final GetStorage box = GetStorage('dnschat');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  if (!box.hasData('erased')) {
    box.erase();
    box.write('erased', true);
  }

  if (box.hasData('username')) {
    username = box.read('username');
  }

  runApp(const Application());
}

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: const MaterialApp(title: 'DNSChat', home: HomePage()),
    );
  }
}
