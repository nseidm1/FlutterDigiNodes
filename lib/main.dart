import 'package:diginodes/app.dart';
import 'package:diginodes/backend/backend.dart';
import 'package:flutter/material.dart';

Future main() async {
  await NodeService.instance.init();
  runApp(App());
}
