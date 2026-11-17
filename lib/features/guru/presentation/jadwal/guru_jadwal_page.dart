import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../application/guru_providers.dart';
import '../../data/models/guru.dart';

/// Jadwal mengajar guru: filter hari / tanggal.
class GuruJadwalPage extends ConsumerStatefulWidget {
  const GuruJadwalPage({super.key});

  @override
  ConsumerState<GuruJadwalPage> createState() => _GuruJadwalPageState();
}

class _GuruJadwalPageState extends ConsumerState<GuruJadwalPage> {
  int? _hari;
  String? _tanggal;

  @override
  Widget build(BuildContext context) {
    final jadwal = ref.watch(guruJadwalProvider((_tanggal, _hari)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Mengajar'),
        actions: [TextButton(onPressed: _today, child: const Text('Hari Ini'))],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                children: [
                  _chip(null, 'Semua'),
                  for (var h = 1; h <= 7; h++) _chip(h, Formatters.namaHari(h)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickTanggal,
                    icon: const Icon(Icons.event_rounded, size: 18),
                    label: Text(
                      _tanggal == null
                          ? 'Tanggalâ€¦'
                          : Formatters.tanggalPendek(_tanggal),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (_tanggal != null)
                    TextButton(
                      onPressed: () => setState(() => _tanggal = null),
                      child: const Text('Hapus tanggal'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(guruJadwalProvider((_tanggal, _hari)));
                  await ref.read(guruJadwalProvider((_tanggal, _hari)).future);
                },
                child: jadwal.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ListView(
                    children: [
                      AsyncValueView<void>(
                        value: AsyncValue.error(error, StackTrace.current),
                        onRetry: () => ref.invalidate(
                          guruJadwalProvider((_tanggal, _hari)),
                        ),
                        data: (_) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  data: (data) => _JadwalList(data: data),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(int? hari, String label) {
    final selected = _hari == hari && _tanggal == null;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() {
          _hari = hari;
          _tanggal = null;
        }),
      ),
    );
  }

  void _today() {
    final now = DateTime.now();
    setState(() {
      _tanggal =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _hari = null;
    });
  }

  Future<void> _pickTanggal() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal != null ? DateTime.parse(_tanggal!) : now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _tanggal =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        _hari = null;
      });
    }
  }
}

class _JadwalList extends StatelessWidget {
  const _JadwalList({required this.data});

  final JadwalGuruResponse data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final konteksLine = [
      if (data.konteks.tahunAjaranNama != null)
        'TA ${data.konteks.tahunAjaranNama}',
      if (data.konteks.semesterNama != null)
        'Semester ${data.konteks.semesterNama}',
    ].join(' Â· ');

    if (data.jadwal.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 64),
          AppEmptyView(
            icon: Icons.event_available_rounded,
            title: 'Tidak Ada Jadwal',
            message: 'Tidak ada jadwal mengajar untuk filter ini.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: data.jadwal.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              [
                if (data.namaHari != null) data.namaHari!,
                if (data.tanggal != null)
                  Formatters.tanggalPendek(data.tanggal),
                if (konteksLine.isNotEmpty) konteksLine,
              ].join(' Â· '),
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final item = data.jadwal[index - 1];
        return Card(
          child: ListTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.jamKe != null ? 'Jam ${item.jamKe}' : 'â€”',
                  style: textTheme.titleMedium?.copyWith(color: scheme.primary),
                ),
                if (item.mulai != null)
                  Text(
                    '${item.mulai}\n${item.selesai ?? ''}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            title: Text('${item.mapel.nama} â€” Kelas ${item.kelas.nama}'),
            subtitle: Text(
              [
                if (item.kelas.tingkat != null) 'Tingkat ${item.kelas.tingkat}',
                if (item.semesterNama != null) 'Semester ${item.semesterNama}',
              ].join(' Â· '),
            ),
          ),
        );
      },
    );
  }
}
