import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/activity_repository.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openBashoDatabase();
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const BashoApp(),
    ),
  );
}
