import 'package:intl/intl.dart';

class FormatUtils {
  // 시간 포맷 (HH:MM:SS)
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return '$hours:$minutes:$seconds';
  }

  // 날짜 및 시간 포맷 (YYYY-MM-DD HH:MM)
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(dateTime);
  }

  // 시간만 포맷 (HH:MM)
  static String formatTime(DateTime dateTime) {
    final formatter = DateFormat('HH:mm');
    return formatter.format(dateTime);
  }

  // 날짜만 포맷 (YYYY-MM-DD)
  static String formatDate(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(dateTime);
  }

  // 한국어 날짜 포맷 (YYYY년 MM월 DD일)
  static String formatKoreanDate(DateTime dateTime) {
    final formatter = DateFormat('yyyy년 MM월 dd일');
    return formatter.format(dateTime);
  }

  // 요일 포함 한국어 날짜 포맷 (YYYY년 MM월 DD일 (요일))
  static String formatKoreanDateWithWeekday(DateTime dateTime) {
    final weekday = _getKoreanWeekday(dateTime.weekday);
    final formatter = DateFormat('yyyy년 MM월 dd일');
    return '${formatter.format(dateTime)} ($weekday)';
  }

  // 한국어 요일 변환
  static String _getKoreanWeekday(int weekday) {
    switch (weekday) {
      case 1:
        return '월';
      case 2:
        return '화';
      case 3:
        return '수';
      case 4:
        return '목';
      case 5:
        return '금';
      case 6:
        return '토';
      case 7:
        return '일';
      default:
        return '';
    }
  }
}
