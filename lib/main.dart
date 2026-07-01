import 'package:oktoast/oktoast.dart';

import '/pages/home.dart';
import 'package:flutter/material.dart';

void main() => runApp(const Application());

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: const MaterialApp(title: 'DNSChat', home: HomePage()),
    );
  }
}
