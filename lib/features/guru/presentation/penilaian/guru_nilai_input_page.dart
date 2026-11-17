import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/guru_providers.dart';
import '../../data/models/penilaian.dart';

/// Form input nilai — batch seluruh siswa untuk satu penugasan.
///
/// Payload: {nilai: {siswaId: {komponenId: 0..100|null}}} — kosong = skip.
/// Backend menegakkan bobot=100 dan terkunci=true (input ditolak 422).
class GuruNilaiInputPage extends ConsumerStatefulWidget {
  const GuruNilaiInputPage({super.key, required this.penugasanId});

  final int penugasanId;

  @override
  ConsumerState<GuruNilaiInputPage> createState() => _GuruNilaiInputPageState();
}

class _InputState {
  final Map<int, TextEditingController> fields = {};

  TextEditingController controllerFor(int komponenId, String initial) {
    return fields.putIfAbsent(
      komponenId,
      () => TextEditingController(text: initial),
    );
  }

  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    fields.clear();
  }
}

class _GuruNilaiInputPageState extends ConsumerState<GuruNilaiInputPage> {
  final Map<int, _InputState> _controllers = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final s in _controllers.values) {
      s.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      guruPenugasanDetailProvider(widget.penugasanId),
    );
    final siswaAsync = ref.watch(
      guruPenugasanSiswaProvider(widget.penugasanId),
    );
    final scheme = Theme.of(context).colorScheme;

    if (detailAsync.isLoading || siswaAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Input Nilai')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (detailAsync.hasError || siswaAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Input Nilai')),
        body: AsyncValueView<void>(
          value: AsyncValue.error(
            detailAsync.error ?? siswaAsync.error ?? Exception('unknown'),
            StackTrace.current,
          ),
          onRetry: () {
            ref.invalidate(guruPenugasanDetailProvider(widget.penugasanId));
            ref.invalidate(guruPenugasanSiswaProvider(widget.penugasanId));
          },
          data: (_) => const SizedBox.shrink(),
        ),
      );
    }

    final d = detailAsync.value!;
    final siswaData = siswaAsync.value!;
    final terkunci = siswaData.terkunci || d.terkunci;
    final konfigurasiValid = d.konfigurasiValid;
    final bisaInput = !terkunci && konfigurasiValid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Nilai'),
        actions: [
          TextButton.icon(
            onPressed: !bisaInput || _saving ? null : _simpan,
            icon: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: const Text('Simpan'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (terkunci)
              _Banner(
                icon: Icons.lock_rounded,
                text: 'Nilai terkunci (rapor difinalisasi). Anda hanya dapat melihat.',
                color: scheme.errorContainer,
                onColor: scheme.onErrorContainer,
              )
            else if (!konfigurasiValid)
              _Banner(
                icon: Icons.warning_amber_rounded,
                text:
                    'Konfigurasi bobot belum valid (total ${d.totalBobotAktif.toStringAsFixed(2)}% - harus 100%). Input nilai diblokir.',
                color: scheme.errorContainer,
                onColor: scheme.onErrorContainer,
              )
            else
              _Banner(
                icon: Icons.edit_note_rounded,
                text: '${d.mapel.nama} - Kelas ${d.kelas.nama}',
                color: scheme.secondaryContainer,
                onColor: scheme.onSecondaryContainer,
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  for (final s in siswaData.siswa)
                    _SiswaNilaiCard(
                      siswa: s,
                      komponen: d.komponen,
                      bisaInput: bisaInput,
                      state: _controllers.putIfAbsent(s.id, _InputState.new),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simpan() async {
    final d = ref.read(guruPenugasanDetailProvider(widget.penugasanId)).value!;
    final siswaAsync = ref
        .read(guruPenugasanSiswaProvider(widget.penugasanId))
        .value!;

    final matriks = <int, Map<int, num?>>{};
    var adaIsi = false;
    for (final s in siswaAsync.siswa) {
      final ctrl = _controllers[s.id];
      if (ctrl == null) continue;
      for (final comp in d.komponen) {
        final text = ctrl.fields[comp.id]?.text.trim() ?? '';
        if (text.isEmpty) {
          matriks.putIfAbsent(s.id, () => {})[comp.id] = null;
          continue;
        }
        final value = double.tryParse(text.replaceAll(',', '.'));
        if (value == null || value < 0 || value > 100) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Nilai "$text" untuk ${s.nama} tidak valid (0-100).',
              ),
            ),
          );
          return;
        }
        adaIsi = true;
        matriks.putIfAbsent(s.id, () => {})[comp.id] = value;
      }
    }

    if (!adaIsi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada nilai yang diisi.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan Nilai'),
        content: Text('Simpan nilai ${d.mapel.nama} kelas ${d.kelas.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final result = await ref
          .read(guruRepositoryProvider)
          .simpanNilaiBatch(penugasanId: widget.penugasanId, matriks: matriks);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.tersimpan > 0
                ? '${result.tersimpan} nilai berhasil disimpan.'
                : 'Tidak ada nilai yang tersimpan (semua kosong).',
          ),
        ),
      );
      ref.invalidate(guruPenugasanSiswaProvider(widget.penugasanId));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SiswaNilaiCard extends StatelessWidget {
  const _SiswaNilaiCard({
    required this.siswa,
    required this.komponen,
    required this.bisaInput,
    required this.state,
  });

  final SiswaPenilaian siswa;
  final List<KomponenNilai> komponen;
  final bool bisaInput;
  final _InputState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(
                    siswa.nama.isEmpty ? '?' : siswa.nama[0].toUpperCase(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    siswa.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                ),
                Text(
                  siswa.nilaiDraft != null
                      ? 'Draft ${siswa.nilaiDraft!.toStringAsFixed(2)}'
                      : 'Draft -',
                  style: textTheme.bodySmall?.copyWith(
                    color: siswa.lengkap ? scheme.primary : scheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final comp in komponen)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${comp.nama} (${comp.bobot.toStringAsFixed(0)}%)',
                        style: textTheme.bodySmall,
                      ),
                    ),
                    SizedBox(
                      width: 84,
                      child: TextFormField(
                        controller: state.controllerFor(
                          comp.id,
                          _formatNilai(siswa.nilai[comp.id]),
                        ),
                        enabled: bisaInput,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        maxLength: 6,
                        decoration: InputDecoration(
                          isDense: true,
                          counterText: '',
                          hintText: siswa.nilai[comp.id] != null
                              ? siswa.nilai[comp.id]!.toStringAsFixed(2)
                              : '-',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatNilai(double? value) =>
      value == null ? '' : value.toStringAsFixed(2);
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.text,
    required this.color,
    required this.onColor,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: color,
      child: Row(
        children: [
          Icon(icon, color: onColor, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(text, style: TextStyle(color: onColor)),
          ),
        ],
      ),
    );
  }
}
