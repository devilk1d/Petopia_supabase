// lib/utils/datetime_utils.dart
import 'package:intl/intl.dart';

class DateTimeUtils {

  /// Format tanggal ke format Indonesia dengan preserving waktu asli dari database
  static String formatIndonesianDateTime(dynamic dateTime) {
    try {
      DateTime targetDate;

      if (dateTime == null) {
        // Jika null, gunakan waktu device sekarang
        targetDate = DateTime.now();
      } else if (dateTime is String) {
        // Parse string date dan JANGAN UBAH timezone-nya
        targetDate = DateTime.parse(dateTime);

        // Jika string tidak mengandung timezone info, anggap sebagai UTC dan convert ke local
        final hasOffset = RegExp(r'([+-][0-9]{2}:[0-9]{2}|Z)$').hasMatch(dateTime);
        if (!hasOffset) {
          // Jika tidak ada timezone info, anggap sebagai UTC dan convert
          targetDate = DateTime.parse(dateTime + 'Z').toLocal();
        } else if (dateTime.endsWith('Z')) {
          // Jika berakhir dengan Z (UTC), convert ke local time
          targetDate = targetDate.toLocal();
        }
        // Jika sudah ada offset timezone, biarkan apa adanya

      } else if (dateTime is int) {
        // Timestamp in milliseconds
        targetDate = DateTime.fromMillisecondsSinceEpoch(dateTime).toLocal();
      } else if (dateTime is DateTime) {
        // Gunakan DateTime langsung tanpa modifikasi timezone
        targetDate = dateTime;
      } else {
        // Fallback ke waktu device
        targetDate = DateTime.now();
      }

      return _formatToIndonesian(targetDate);
    } catch (e) {
      print('Error formatting date: $e for input: $dateTime');
      // Jika ada error, coba parse ulang dengan cara yang lebih sederhana
      try {
        if (dateTime is String) {
          final parsedDate = DateTime.parse(dateTime);
          return _formatToIndonesian(parsedDate);
        }
      } catch (e2) {
        print('Secondary parse also failed: $e2');
      }

      // Ultimate fallback: gunakan waktu device sekarang
      return _formatToIndonesian(DateTime.now());
    }
  }

  /// Format DateTime ke string Indonesia tanpa mengubah waktu
  static String _formatToIndonesian(DateTime date) {
    try {
      // Coba gunakan DateFormat dengan locale Indonesia
      final formatter = DateFormat('d MMMM yyyy, HH:mm', 'id_ID');
      return '${formatter.format(date)} WIB';
    } catch (e) {
      // Fallback manual jika DateFormat gagal
      return _manualFormat(date);
    }
  }

  /// Manual format jika DateFormat gagal
  static String _manualFormat(DateTime date) {
    const monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final day = date.day;
    final month = monthNames[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute WIB';
  }

  /// Format untuk database (UTC)
  static String formatForDatabase(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Parse dari database dan convert ke local time
  static DateTime parseFromDatabase(String dateTimeString) {
    try {
      final utcDateTime = DateTime.parse(dateTimeString);
      return utcDateTime.toLocal();
    } catch (e) {
      print('Error parsing database datetime: $e');
      return DateTime.now();
    }
  }

  /// Gunakan waktu device langsung (untuk order baru)
  static String getCurrentDeviceTime() {
    return _formatToIndonesian(DateTime.now());
  }

  /// Format tanggal sederhana (tanpa jam)
  static String formatDateOnly(dynamic dateTime) {
    try {
      DateTime targetDate;

      if (dateTime == null) {
        targetDate = DateTime.now();
      } else if (dateTime is String) {
        targetDate = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        targetDate = dateTime;
      } else {
        targetDate = DateTime.now();
      }

      const monthNames = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];

      final day = targetDate.day;
      final month = monthNames[targetDate.month - 1];
      final year = targetDate.year;

      return '$day $month $year';
    } catch (e) {
      print('Error formatting date only: $e');
      return 'Format tanggal tidak valid';
    }
  }

  /// Format jam saja
  static String formatTimeOnly(dynamic dateTime) {
    try {
      DateTime targetDate;

      if (dateTime == null) {
        targetDate = DateTime.now();
      } else if (dateTime is String) {
        targetDate = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        targetDate = dateTime;
      } else {
        targetDate = DateTime.now();
      }

      final hour = targetDate.hour.toString().padLeft(2, '0');
      final minute = targetDate.minute.toString().padLeft(2, '0');

      return '$hour:$minute WIB';
    } catch (e) {
      print('Error formatting time only: $e');
      return 'Format jam tidak valid';
    }
  }

  /// Cek apakah tanggal hari ini
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Cek apakah tanggal kemarin
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Format relative time (Hari ini, Kemarin, atau tanggal lengkap)
  static String formatRelativeDateTime(dynamic dateTime) {
    try {
      DateTime targetDate;

      if (dateTime == null) {
        targetDate = DateTime.now();
      } else if (dateTime is String) {
        targetDate = DateTime.parse(dateTime);
        if (!dateTime.contains('T') && !dateTime.contains('Z')) {
          targetDate = DateTime.parse(dateTime + 'Z').toLocal();
        }
      } else if (dateTime is DateTime) {
        targetDate = dateTime;
      } else {
        targetDate = DateTime.now();
      }

      if (isToday(targetDate)) {
        return 'Hari ini, ${formatTimeOnly(targetDate)}';
      } else if (isYesterday(targetDate)) {
        return 'Kemarin, ${formatTimeOnly(targetDate)}';
      } else {
        return formatIndonesianDateTime(targetDate);
      }
    } catch (e) {
      print('Error formatting relative datetime: $e');
      return formatIndonesianDateTime(dateTime);
    }
  }
}