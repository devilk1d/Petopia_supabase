// lib/utils/datetime_utils.dart
import 'package:intl/intl.dart';

class DateTimeUtils {

  /// Format tanggal ke format Indonesia dengan timezone detection yang akurat
  static String formatIndonesianDateTime(dynamic dateTime) {
    try {
      DateTime targetDate;

      if (dateTime == null) {
        // Jika null, gunakan waktu device sekarang
        targetDate = DateTime.now();
      } else if (dateTime is String) {
        // Parse string date
        targetDate = DateTime.parse(dateTime);

        // Jika string sudah mengandung offset zona waktu, jangan .toLocal()
        final hasOffset = RegExp(r'([+-][0-9]{2}:[0-9]{2})').hasMatch(dateTime);
        if (!hasOffset) {
          targetDate = targetDate.toLocal();
        }
        // Cek apakah tanggal dari server masuk akal
        final now = DateTime.now();
        final diffInHours = now.difference(targetDate).inHours.abs();

        // Jika perbedaan lebih dari 24 jam, kemungkinan ada masalah timezone
        if (diffInHours > 24) {
          print('Server time seems incorrect (diff: ${diffInHours}h), using device time');
          targetDate = now;
        }
      } else if (dateTime is int) {
        // Timestamp
        targetDate = DateTime.fromMillisecondsSinceEpoch(dateTime).toLocal();
      } else if (dateTime is DateTime) {
        targetDate = dateTime.toLocal();
      } else {
        // Fallback ke waktu device
        targetDate = DateTime.now();
      }

      return _formatToIndonesian(targetDate);
    } catch (e) {
      print('Error formatting date: $e');
      // Ultimate fallback: gunakan waktu device sekarang
      return _formatToIndonesian(DateTime.now());
    }
  }

  /// Format DateTime ke string Indonesia
  static String _formatToIndonesian(DateTime date) {
    try {
      // Coba gunakan DateFormat dengan locale Indonesia
      final formatter = DateFormat('d MMMM yyyy, HH:mm', 'id_ID');
      return '${formatter.format(date)} WIB';
    } catch (e) {
      // Fallback manual
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

  /// Gunakan waktu device langsung (untuk order baru)
  static String getCurrentDeviceTime() {
    return _formatToIndonesian(DateTime.now());
  }

  /// Cek apakah waktu server masuk akal
  static bool isServerTimeReasonable(DateTime serverTime) {
    final now = DateTime.now();
    final difference = now.difference(serverTime).inHours.abs();

    // Anggap masuk akal jika perbedaan kurang dari 24 jam
    return difference < 24;
  }

  /// Konversi waktu dengan timezone correction untuk Indonesia
  static DateTime correctToIndonesianTime(DateTime dateTime) {
    // Jika waktu terlihat dalam UTC, tambahkan 7 jam untuk WIB
    final localTime = dateTime.toLocal();
    final now = DateTime.now();

    // Cek apakah hasil konversi masuk akal
    if (isServerTimeReasonable(localTime)) {
      return localTime;
    } else {
      // Jika tidak masuk akal, gunakan waktu device
      print('Time correction failed, using device time');
      return now;
    }
  }
}