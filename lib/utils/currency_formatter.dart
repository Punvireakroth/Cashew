import 'package:intl/intl.dart';

/// Utility class for currency formatting
class CurrencyFormatter {
  /// Format a number as currency with the specified currency code
  static String format(double amount, {String currency = 'USD'}) {
    final formatter = NumberFormat.currency(
      symbol: getCurrencySymbol(currency),
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format a number as currency with compact notation (e.g., $1.2K, $3.4M)
  static String formatCompact(double amount, {String currency = 'USD'}) {
    final formatter = NumberFormat.compactCurrency(
      symbol: getCurrencySymbol(currency),
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }

  /// Get currency symbol for a given currency code
  static String getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'INR':
        return '₹';
      case 'KHR':
        return '៛';
      case 'THB':
        return '฿';
      default:
        return currency;
    }
  }

  /// Get list of supported currencies
  static List<String> getSupportedCurrencies() {
    return ['USD', 'EUR', 'GBP', 'JPY', 'CNY', 'INR', 'KHR', 'THB'];
  }

  /// Get currency display name
  static String getCurrencyName(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return 'US Dollar';
      case 'EUR':
        return 'Euro';
      case 'GBP':
        return 'British Pound';
      case 'JPY':
        return 'Japanese Yen';
      case 'CNY':
        return 'Chinese Yuan';
      case 'INR':
        return 'Indian Rupee';
      case 'KHR':
        return 'Cambodian Riel';
      case 'THB':
        return 'Thai Baht';
      default:
        return code;
    }
  }

  /// Parse a string to double, returns null if invalid
  static double? parse(String value) {
    try {
      // Remove currency symbols and commas
      final cleaned = value.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }
}
