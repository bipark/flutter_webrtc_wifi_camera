import 'dart:io';
import 'package:flutter/material.dart';

import 'views/main_view.dart';
import 'views/camera_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.pink,
        ),
        home: Platform.isMacOS ? MainView() : CameraView(),
      ),
    );

  }
}

