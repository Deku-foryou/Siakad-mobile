import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_key_value_store.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../features/auth/data/auth_repository.dart';

/// Penyedia dependency inti. Semua provider di sini dapat di-override
/// pada widget test / unit test (mis. fake storage, fake Dio adapter).

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final secureKeyValueStoreProvider = Provider<SecureKeyValueStore>(
  (ref) => FlutterSecureKeyValueStore(),
);

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(ref.watch(secureKeyValueStoreProvider)),
);

final dioProvider = Provider<Dio>(
  (ref) => createDio(
    ref.watch(appConfigProvider),
    ref.watch(secureStorageServiceProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);
