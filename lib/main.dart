import 'package:flutter/material.dart';
import 'package:movil_architect/app/architect_app.dart';
import 'package:movil_architect/core/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppServices.instance.init();
  runApp(const ArchitectApp());
}
