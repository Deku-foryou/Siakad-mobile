import 'package:flutter_test/flutter_test.dart';
import 'package:siakad_mobile/core/storage/secure_storage_service.dart';

import '../../fakes/fake_secure_key_value_store.dart';

void main() {
  late FakeSecureKeyValueStore store;
  late SecureStorageService storage;

  setUp(() {
    store = FakeSecureKeyValueStore();
    storage = SecureStorageService(store);
  });

  test('save/read/delete token', () async {
    expect(await storage.readToken(), isNull);

    await storage.saveToken('1|abc123');
    expect(await storage.readToken(), '1|abc123');
    expect(store.data[SecureStorageService.tokenKey], '1|abc123');

    await storage.deleteToken();
    expect(await storage.readToken(), isNull);
  });

  test('session meta roundtrip', () async {
    final meta = SessionMeta(
      userId: 1280,
      userName: 'Siswa Uji',
      username: 'siswa01',
      level: 'siswa',
      wajibGantiPassword: true,
      tokenExpiresAt: DateTime.parse('2026-12-17T08:00:00+07:00'),
    );
    await storage.saveSessionMeta(meta);

    final restored = await storage.readSessionMeta();
    expect(restored, isNotNull);
    expect(restored!.userId, 1280);
    expect(restored.userName, 'Siswa Uji');
    expect(restored.username, 'siswa01');
    expect(restored.level, 'siswa');
    expect(restored.wajibGantiPassword, isTrue);
    expect(restored.tokenExpiresAt, isNotNull);
  });

  test('readSessionMeta korup -> null dan key dibersihkan', () async {
    store.data[SecureStorageService.sessionMetaKey] = '{bukan-json';
    expect(await storage.readSessionMeta(), isNull);
    expect(
      store.data.containsKey(SecureStorageService.sessionMetaKey),
      isFalse,
    );
  });

  test('clearSession menghapus token dan meta', () async {
    await storage.saveToken('1|abc');
    await storage.saveSessionMeta(
      const SessionMeta(
        userId: 1,
        userName: 'X',
        username: 'x',
        level: 'guru',
        wajibGantiPassword: false,
      ),
    );
    await storage.clearSession();
    expect(await storage.readToken(), isNull);
    expect(await storage.readSessionMeta(), isNull);
    expect(store.data, isEmpty);
  });
}
