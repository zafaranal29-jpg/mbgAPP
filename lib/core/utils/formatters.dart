const List<String> _hari = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
];
const List<String> _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
  'Agustus', 'September', 'Oktober', 'November', 'Desember'
];
const List<String> _bulanPendek = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt',
  'Nov', 'Des'
];

String two(int n) => n.toString().padLeft(2, '0');

String namaHari(DateTime d) => _hari[d.weekday - 1];

String formatTanggal(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';

String formatTanggalPendek(DateTime d) =>
    '${d.day} ${_bulanPendek[d.month - 1]}';

String formatJam(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

String isoDate(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

String formatDurasi(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  return '${two(h)}:${two(m)}:${two(s)}';
}
