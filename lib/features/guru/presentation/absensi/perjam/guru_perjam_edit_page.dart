import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/errors/api_exception.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../../application/guru_providers.dart';

/// Edit satu record absensi per jam — `PATCH /guru/absensi/perjam/{id}` (H+1).
class GuruPerjamEditPage extends ConsumerStatefulWidget {
  const GuruPerjamEditPage({super.key, required this.id});

  final int id;

  @override
  ConsumerState<GuruPerjamEditPage> createState() => _GuruPerjamEditPageState();
}

class _GuruPerjamEditPageState extends ConsumerState<GuruPerjamEditPage> {
  String? _status;
  final _keteranganController = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(guruAbsensiPerjamDetailProvider(widget.id));
    final scheme = Theme.of(context).colorScheme;

    if (!_loaded && detail.value != null) {
      _status = detail.value!.status;
      _keteranganController.text = detail.value!.keterangan ?? '';
      _loaded = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Absensi Per Jam')),
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => AsyncValueView<void>(
            value: AsyncValue.error(error, StackTrace.current),
            onRetry: () =>
                ref.invalidate(guruAbsensiPerjamDetailProvider(widget.id)),
            data: (_) => const SizedBox.shrink(),
          ),
          data: (item) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                item.siswa.nama,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${item.mapel.nama} · Kelas ${item.kelas.nama} · '
                '${item.tanggal ?? ''}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'hadir', label: Text('Hadir')),
                  ButtonSegment(value: 'sakit', label: Text('Sakit')),
                  ButtonSegment(value: 'izin', label: Text('Izin')),
                  ButtonSegment(value: 'alpha', label: Text('Alpha')),
                ],
                selected: {_status ?? 'hadir'},
                onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _keteranganController,
                maxLines: 3,
                maxLength: 255,
                decoration: const InputDecoration(
                  labelText: 'Keterangan (opsional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _saving ? null : _simpan,
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Menyimpan…' : 'Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _simpan() async {
    if (_status == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(guruRepositoryProvider)
          .ubahAbsensiPerjam(
            id: widget.id,
            status: _status!,
            keterangan: _keteranganController.text.trim().isEmpty
                ? null
                : _keteranganController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absensi per jam berhasil diperbarui.')),
      );
      ref.invalidate(guruAbsensiPerjamDetailProvider(widget.id));
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
