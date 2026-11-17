import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../../application/guru_providers.dart';
import '../../../data/guru_repository.dart';
import '../../../data/models/absensi.dart';

/// Grid pengisian absensi pertemuan — `GET /guru/absensi/perjam/pertemuan/{id}`.
class GuruPerjamGridPage extends ConsumerStatefulWidget {
  const GuruPerjamGridPage({super.key, required this.pertemuanId});

  final int pertemuanId;

  @override
  ConsumerState<GuruPerjamGridPage> createState() => _GuruPerjamGridPageState();
}

class _RowState {
  _RowState({
    required this.siswaId,
    required this.nama,
    this.nisn,
    this.existingStatus,
    this.keteranganController,
  });

  final int siswaId;
  final String nama;
  final String? nisn;
  final String? existingStatus;
  final TextEditingController? keteranganController;

  String status = 'hadir';
}

class _GuruPerjamGridPageState extends ConsumerState<GuruPerjamGridPage> {
  final List<_RowState> _rows = [];
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final row in _rows) {
      row.keteranganController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gridAsync = ref.watch(
      guruPertemuanDetailProvider(widget.pertemuanId),
    );
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Pertemuan'),
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
            onRetry: () =>
                ref.invalidate(guruPertemuanDetailProvider(widget.pertemuanId)),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (grid) {
            _initRows(grid);
            return Column(
              children: [
                // ---------------------------------- Info pertemuan
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${grid.mapel.nama} — Kelas ${grid.kelas.nama}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          [
                            'Tanggal ${grid.tanggal}',
                            if (grid.jamKe != null) 'Jam ke-${grid.jamKe}',
                            if (grid.waktuMulai != null)
                              '${grid.waktuMulai}–${grid.waktuSelesai ?? ''}',
                            'Status: ${grid.status}',
                          ].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (!grid.bisaDiabsen) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Pertemuan ini tidak dapat diabsen (bukan status terjadwal '
                            'atau tanggal masa depan).',
                            style: TextStyle(color: scheme.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
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

  void _initRows(AbsensiPerjamGrid grid) {
    if (_initialized) return;
    _initialized = true;
    for (final siswa in grid.siswa) {
      _rows.add(
        _RowState(
          siswaId: siswa.id,
          nama: siswa.nama,
          nisn: siswa.nisn,
          keteranganController: TextEditingController(
            text: siswa.absensiCatatan ?? '',
          ),
          existingStatus: siswa.absensiStatus,
        )..status = siswa.absensiStatus ?? 'hadir',
      );
    }
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
                        child: Text(
                          row.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: TextField(
                controller: row.keteranganController,
                maxLength: 255,
                decoration: const InputDecoration(
                  labelText: 'Keterangan (opsional)',
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
    // Konfirmasi
    final grid = ref
        .read(guruPertemuanDetailProvider(widget.pertemuanId))
        .value;
    if (grid != null && !grid.bisaDiabsen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pertemuan ini tidak dapat diabsen (belum terjadwal atau masa depan).',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan Absensi'),
        content: Text('Simpan absensi ${_rows.length} siswa?'),
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
          .simpanAbsensiPerjam(
            jadwalPertemuanId: widget.pertemuanId,
            records: _rows
                .map(
                  (r) => AbsensiPerjamRecordInput(
                    siswaId: r.siswaId,
                    status: r.status,
                    keterangan:
                        (r.keteranganController?.text.trim().isEmpty ?? true)
                        ? null
                        : r.keteranganController!.text.trim(),
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
      ref.invalidate(guruPertemuanDetailProvider(widget.pertemuanId));
      ref.invalidate(guruAbsensiPerjamProvider);
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
