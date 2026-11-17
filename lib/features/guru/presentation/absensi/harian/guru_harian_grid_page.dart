import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../../application/guru_providers.dart';
import '../../../data/guru_repository.dart';
import '../../../data/models/absensi.dart';

/// Grid pengisian absensi harian — `GET /guru/kelas/{id}/absensi`.
///
/// Status default: nilai tercatat bila ada, selain itu `hadir`.
/// Guru dapat mengubah status & catatan per siswa lalu menyimpan seluruh
/// kelas dalam satu batch (`POST /guru/absensi/harian`, upsert).
class GuruHarianGridPage extends ConsumerStatefulWidget {
  const GuruHarianGridPage({super.key, required this.kelasId});

  final int kelasId;

  @override
  ConsumerState<GuruHarianGridPage> createState() => _GuruHarianGridPageState();
}

class _RowState {
  _RowState({
    required this.siswaId,
    required this.nama,
    this.nisn,
    this.catatanController,
    this.existingStatus,
    this.existingCatatan,
  });

  final int siswaId;
  final String nama;
  final String? nisn;
  final TextEditingController? catatanController;
  final String? existingStatus;
  final String? existingCatatan;

  String status = 'hadir';
  bool get hasExisting => existingStatus != null;
}

class _GuruHarianGridPageState extends ConsumerState<GuruHarianGridPage> {
  final List<_RowState> _rows = [];
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final row in _rows) {
      row.catatanController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tanggal = GoRouterState.of(context).uri.queryParameters['tanggal'];
    final gridAsync = ref.watch(
      guruAbsensiHarianGridProvider((widget.kelasId, tanggal)),
    );
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Isi Absensi Harian'),
        actions: [
          TextButton.icon(
            onPressed: _rows.isEmpty || _saving ? null : _simpan,
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
        child: gridAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncValueView<void>(
            value: AsyncValue.error(error, StackTrace.current),
            onRetry: () => ref.invalidate(
              guruAbsensiHarianGridProvider((widget.kelasId, tanggal)),
            ),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (grid) {
            _initRows(grid);
            return Column(
              children: [
                // ---------------------------------- Info
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(Icons.event_rounded, color: scheme.primary),
                      Text('Tanggal ${grid.tanggal}'),
                      OutlinedButton(
                        onPressed: _setAllHadir,
                        child: const Text('Semua Hadir'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // ---------------------------------- Header kolom
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('Siswa')),
                      Expanded(
                        flex: 4,
                        child: Text('Status', textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 8),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      for (var i = 0; i < _rows.length; i++) _buildRow(i),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _initRows(AbsensiHarianGrid grid) {
    if (_initialized) return;
    _initialized = true;
    for (final siswa in grid.siswa) {
      _rows.add(
        _RowState(
          siswaId: siswa.id,
          nama: siswa.nama,
          nisn: siswa.nisn,
          catatanController: TextEditingController(
            text: siswa.absensiCatatan ?? '',
          ),
          existingStatus: siswa.absensiStatus,
          existingCatatan: siswa.absensiCatatan,
        )..status = siswa.absensiStatus ?? 'hadir',
      );
    }
  }

  void _setAllHadir() {
    setState(() {
      for (final row in _rows) {
        row.status = 'hadir';
      }
    });
  }

  Widget _buildRow(int index) {
    final row = _rows[index];
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text(
                          row.nama.isEmpty ? '?' : row.nama[0].toUpperCase(),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (row.hasExisting)
                              Text(
                                'Tercatat',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final s in const [
                        ('hadir', 'Hadir'),
                        ('sakit', 'Sakit'),
                        ('izin', 'Izin'),
                        ('alpha', 'Alpha'),
                      ])
                        ChoiceChip(
                          label: Text(s.$2),
                          selected: row.status == s.$1,
                          onSelected: (_) => setState(() => row.status = s.$1),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (row.status != 'hadir')
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: TextField(
                  controller: row.catatanController,
                  maxLength: 255,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    isDense: true,
                    counterText: '',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _simpan() async {
    final tanggal =
        GoRouterState.of(context).uri.queryParameters['tanggal'] ??
        DateTime.now().toIso8601String().substring(0, 10);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan Absensi'),
        content: Text(
          'Simpan absensi ${_rows.length} siswa untuk tanggal $tanggal?',
        ),
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
          .simpanAbsensiHarian(
            tanggal: tanggal,
            kelasId: widget.kelasId,
            records: _rows
                .map(
                  (r) => AbsensiRecordInput(
                    siswaId: r.siswaId,
                    status: r.status,
                    catatan: (r.catatanController?.text.trim().isEmpty ?? true)
                        ? null
                        : r.catatanController!.text.trim(),
                  ),
                )
                .toList(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Absensi tersimpan: ${result.created} dibuat, ${result.updated} diubah.',
          ),
        ),
      );
      ref.invalidate(guruAbsensiHarianGridProvider((widget.kelasId, tanggal)));
      ref.invalidate(guruAbsensiHarianProvider);
      context.pop();
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
