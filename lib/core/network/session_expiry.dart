import 'dart:async';

/// Sinyal internal: server menjawab 401 (token kedaluwarsa/tidak valid)
/// pada request non-login.
///
/// AuthInterceptor memanggil [notify] setelah membersihkan token lokal;
/// AuthController mendengarkan sinyal ini via [stream] agar sesi berakhir
/// DENGAN BENAR (state → unauthenticated) walau 401 terjadi di tengah
/// memakai aplikasi — bukan hanya saat restore sesi di splash.
class SessionExpiry {
  SessionExpiry._();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  static void notify() => _controller.add(null);
}
