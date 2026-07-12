/// مدة التوصيل من ربع ساعة إلى 48 ساعة، بخطوات 15 دقيقة.
class DeliveryDurationUtils {
  static const int minMinutes = 15;
  static const int maxMinutes = 48 * 60;
  static const int stepMinutes = 15;

  static int clampMinutesRaw(int minutes) {
    if (minutes < minMinutes) return minMinutes;
    if (minutes > maxMinutes) return maxMinutes;
    return minutes;
  }

  static String formatArabic(int totalMinutes) {
    final m = clampMinutesRaw(totalMinutes);
    final hours = m ~/ 60;
    final mins = m % 60;
    if (hours == 0) return '$mins دقيقة';
    if (mins == 0) {
      if (hours == 1) return 'ساعة';
      if (hours == 2) return 'ساعتين';
      return '$hours ساعات';
    }
    final hourPart = hours == 1
        ? 'ساعة'
        : hours == 2
            ? 'ساعتين'
            : '$hours ساعات';
    return '$hourPart و $mins دقيقة';
  }

  static String formatCountdown(Duration remaining) {
    final totalSec = remaining.inSeconds < 0 ? 0 : remaining.inSeconds;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}
