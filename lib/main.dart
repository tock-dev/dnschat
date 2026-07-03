import 'package:get_storage/get_storage.dart';
import 'package:oktoast/oktoast.dart';

import '/pages/home.dart';
import 'package:flutter/material.dart';

const BOX_NAME = 'dev.tock.dnschat';
final GetStorage box = GetStorage(BOX_NAME);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init(BOX_NAME);
  if (!box.hasData('erased')) {
    box.erase();
    box.write('erased', true);
  }

  if (box.hasData('username')) {
    username = box.read('username');
    print('Loaded username: $username');
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
