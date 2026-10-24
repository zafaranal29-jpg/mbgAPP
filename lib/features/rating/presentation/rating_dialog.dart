import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:mbg_app/core/models/models.dart';
import 'package:mbg_app/core/network/api_client.dart';
import 'package:mbg_app/core/theme/app_colors.dart';
import 'package:mbg_app/core/widgets/app_widgets.dart';
import 'package:provider/provider.dart';

Future<bool?> showRatingDialog(BuildContext context, {required TodayMenu menu}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => RatingDialog(menu: menu),
  );
}

/// Rating 1-5 bintang + ulasan (POST /api/review/submit).
class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key, required this.menu});
  final TodayMenu menu;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final _reviewC = TextEditingController();
  double _score = 0;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _reviewC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_score < 1) {
      setState(() => _error = 'Pilih minimal 1 bintang.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final text = _reviewC.text.trim();
      await context.read<ApiClient>().submitReview(
            scheduleId: widget.menu.scheduleId,
            score: _score.round(),
            reviewText: text.isEmpty ? null : text,
          );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Beri Penilaian',
        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.menu.nama,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Center(
              child: RatingBar.builder(
                initialRating: 0,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 38,
                itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                itemBuilder: (context, _) =>
                    const Icon(Icons.star_rounded, color: AppColors.star),
                onRatingUpdate: (r) => setState(() {
                  _score = r;
                  _error = null;
                }),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _reviewC,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Tulis ulasan Anda (opsional)',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        SizedBox(
          width: 130,
          child: PrimaryButton(
            label: 'Kirim',
            loading: _loading,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
