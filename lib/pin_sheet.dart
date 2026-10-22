import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'annotations.dart';
import 'model.dart';
import 'store.dart';
import 'theme.dart';
import 'transcribe/transcriber.dart';

Future<void> showPinSheet(BuildContext context, Annotations ann, Pin pin, {bool isNew = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: HC.green,
    builder: (c) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
      child: _PinSheet(ann: ann, pin: pin, isNew: isNew),
    ),
  );
}

class _PinSheet extends StatefulWidget {
  const _PinSheet({required this.ann, required this.pin, required this.isNew});
  final Annotations ann;
  final Pin pin;
  final bool isNew;
  @override
  State<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<_PinSheet> {
  late final text = TextEditingController(text: widget.pin.text);
  final rec = AudioRecorder();
  final player = AudioPlayer();
  bool recording = false, playing = false, busy = false;
  Pin get pin => widget.pin;

  @override
  void initState() {
    super.initState();
    player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playing = false);
    });
  }

  @override
  void dispose() {
    rec.dispose();
    player.dispose();
    text.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _toggleRec() async {
    if (recording) {
      final path = await rec.stop();
      setState(() {
        recording = false;
        if (path != null) pin.audio = path;
      });
      return;
    }
    if (!await rec.hasPermission()) {
      _snack('لازم تسمح للتطبيق باستخدام الميكروفون');
      return;
    }
    final dir = Directory('${Store.dir.path}/audio');
    await dir.create(recursive: true);
    final path = '${dir.path}/${pin.id}_${DateTime.now().millisecondsSinceEpoch}.wav';
    await rec.start(const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1), path: path);
    setState(() => recording = true);
  }

  Future<void> _togglePlay() async {
    if (pin.audio == null) return;
    if (playing) {
      await player.stop();
      setState(() => playing = false);
    } else {
      await player.play(DeviceFileSource(pin.audio!));
      setState(() => playing = true);
    }
  }

  Future<void> _transcribe() async {
    setState(() => busy = true);
    try {
      final r = await Transcriber.transcribe(pin.audio!);
      text.text = text.text.isEmpty ? r : '${text.text}\n$r';
    } catch (e) {
      _snack('تعذّر التفريغ: $e');
    }
    if (mounted) setState(() => busy = false);
  }

  void _save() {
    pin.text = text.text;
    widget.ann.touch();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('تعليق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(controller: text, minLines: 3, maxLines: 6, decoration: const InputDecoration(hintText: 'اكتب ملاحظتك هنا', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
            FilledButton.icon(
              onPressed: _toggleRec,
              icon: Icon(recording ? Icons.stop_rounded : Icons.mic_rounded),
              label: Text(recording ? 'إيقاف التسجيل' : (pin.audio == null ? 'تسجيل صوت' : 'إعادة التسجيل')),
            ),
            if (pin.audio != null && !recording)
              OutlinedButton.icon(onPressed: _togglePlay, icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded), label: Text(playing ? 'إيقاف' : 'تشغيل')),
            if (pin.audio != null && !recording)
              Transcriber.available
                  ? OutlinedButton.icon(
                      onPressed: busy ? null : _transcribe,
                      icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.subtitles_rounded),
                      label: Text(busy ? 'جاري التفريغ (أول مرة ينزّل النموذج)...' : 'تفريغ إلى نص'),
                    )
                  : Chip(label: const Text('التفريغ الصوتي: في النسخة الكاملة')),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            FilledButton(onPressed: _save, child: const Text('حفظ')),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () {
                widget.ann.removePin(pin);
                Navigator.pop(context);
              },
              child: const Text('حذف التعليق'),
            ),
          ]),
        ]),
      );
}
