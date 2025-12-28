import 'package:intl/intl.dart';

/// Currency data with code, symbol, and display name
class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

/// Utility class for currency formatting
class CurrencyFormatter {
  /// All supported currencies (synced with account form)
  static const List<CurrencyInfo> supportedCurrencies = [
    CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar'),
    CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro'),
    CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound'),
    CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    CurrencyInfo(code: 'AUD', symbol: '\$', name: 'Australian Dollar'),
    CurrencyInfo(code: 'CAD', symbol: '\$', name: 'Canadian Dollar'),
    CurrencyInfo(code: 'CHF', symbol: 'F', name: 'Swiss Franc'),
    CurrencyInfo(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    CurrencyInfo(code: 'SEK', symbol: 'kr', name: 'Swedish Krona'),
    CurrencyInfo(code: 'KHR', symbol: '៛', name: 'Cambodian Riel'),
    CurrencyInfo(code: 'THB', symbol: '฿', name: 'Thai Baht'),
    CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    CurrencyInfo(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
    CurrencyInfo(code: 'SGD', symbol: '\$', name: 'Singapore Dollar'),
    CurrencyInfo(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
  ];

  /// Format a number as currency with the specified currency code
  static String format(double amount, {String currency = 'USD'}) {
    final formatter = NumberFormat.currency(
      symbol: getCurrencySymbol(currency),
      decimalDigits: getDecimalDigits(currency),
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

  /// Get appropriate decimal digits for currency (0 for KHR, JPY, KRW)
  static int getDecimalDigits(String currency) {
    switch (currency.toUpperCase()) {
      case 'KHR':
      case 'JPY':
      case 'KRW':
        return 0;
      default:
        return 2;
    }
  }

  /// Get currency symbol for a given currency code
  static String getCurrencySymbol(String currency) {
    final info = supportedCurrencies
        .where((c) => c.code.toUpperCase() == currency.toUpperCase())
        .firstOrNull;
    return info?.symbol ?? currency;
  }

  /// Get list of supported currency codes
  static List<String> getSupportedCurrencyCodes() {
    return supportedCurrencies.map((c) => c.code).toList();
  }

  /// Get currency display name
  static String getCurrencyName(String code) {
    final info = supportedCurrencies
        .where((c) => c.code.toUpperCase() == code.toUpperCase())
        .firstOrNull;
    return info?.name ?? code;
  }

  /// Get CurrencyInfo by code
  static CurrencyInfo? getCurrencyInfo(String code) {
    return supportedCurrencies
        .where((c) => c.code.toUpperCase() == code.toUpperCase())
        .firstOrNull;
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
