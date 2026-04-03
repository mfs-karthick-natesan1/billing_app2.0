import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _indianCurrency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  static final _indianCurrencyNoDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  static final _timeFormat = DateFormat('hh:mm a');
  static final _dateFormat = DateFormat('dd MMM yyyy');

  static String currency(double amount) {
    if (amount == amount.roundToDouble()) {
      return _indianCurrencyNoDecimal.format(amount);
    }
    return _indianCurrency.format(amount);
  }

  static String time(DateTime dateTime) => _timeFormat.format(dateTime);
  static String date(DateTime dateTime) => _dateFormat.format(dateTime);

  static String qty(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
