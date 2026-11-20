import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';

/// Tidak ada auto-retry bawaan Riverpod: setiap provider data hanya fetch
/// saat diminta (build pertama / pull-to-refresh / tombol "Coba Lagi").
/// Mencegah request loop otomatis saat backend error/timeout — pengguna
/// selalu bisa retry manual, dan counter error tidak meledak di perangkat.
Duration? _noAutomaticRetry(int retryCount, Object error) => null;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(retry: _noAutomaticRetry, child: SiakadApp()));
}
