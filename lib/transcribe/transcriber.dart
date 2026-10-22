/// نسخة بدون محرك تفريغ (النسخة الأساسية). النسخة الكاملة تستبدل هذا الملف أثناء البناء.
class Transcriber {
  static const available = false;
  static Future<String> transcribe(String wavPath) async => throw UnsupportedError('التفريغ غير مفعّل في هذه النسخة');
}
