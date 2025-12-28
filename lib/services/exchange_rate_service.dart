import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for fetching and caching exchange rates
class ExchangeRateService {
  static final ExchangeRateService _instance = ExchangeRateService._internal();
  factory ExchangeRateService() => _instance;
  ExchangeRateService._internal();

  static const String _baseUrl = 'https://open.er-api.com/v6/latest';
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Cache: key = "FROM_TO", value = (rate, timestamp)
  final Map<String, _CachedRate> _cache = {};

  /// Fetch exchange rate from one currency to another
  /// Returns the rate (1 unit of [from] = rate units of [to])
  Future<ExchangeRateResult> fetchExchangeRate(String from, String to) async {
    final fromUpper = from.toUpperCase();
    final toUpper = to.toUpperCase();

    // Same currency - no conversion needed
    if (fromUpper == toUpper) {
      return ExchangeRateResult.success(1.0);
    }

    final cacheKey = '${fromUpper}_$toUpper';

    // Check cache first
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return ExchangeRateResult.success(cached.rate);
    }

    try {
      // Fetch rates with base currency = from
      final uri = Uri.parse('$_baseUrl/$fromUpper');
      debugPrint('Fetching exchange rate: $uri');

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Request timed out'),
          );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Check if request was successful
        final result = data['result'] as String?;
        if (result != 'success') {
          final errorType = data['error-type'] as String? ?? 'Unknown error';
          debugPrint('API error: $errorType');
          return ExchangeRateResult.error('API error: $errorType');
        }

        final rates = data['rates'] as Map<String, dynamic>?;

        if (rates != null && rates.containsKey(toUpper)) {
          final rate = (rates[toUpper] as num).toDouble();
          debugPrint('Got rate: 1 $fromUpper = $rate $toUpper');

          // Cache the rate
          _cache[cacheKey] = _CachedRate(rate: rate, timestamp: DateTime.now());

          return ExchangeRateResult.success(rate);
        } else {
          debugPrint('Rate not found for $toUpper in response');
          return ExchangeRateResult.error(
            'Rate not available for $fromUpper to $toUpper',
          );
        }
      } else if (response.statusCode == 404) {
        return ExchangeRateResult.error('Currency $fromUpper not supported');
      } else {
        debugPrint('Server error: ${response.statusCode} - ${response.body}');
        return ExchangeRateResult.error('Server error: ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('Request timed out');
      // Try to return cached rate even if expired
      if (cached != null) {
        return ExchangeRateResult.success(cached.rate, isStale: true);
      }
      return ExchangeRateResult.error(
        'Connection timed out. Please check your internet.',
      );
    } catch (e) {
      debugPrint('Exception: $e');
      // Try to return cached rate even if expired
      if (cached != null) {
        return ExchangeRateResult.success(cached.rate, isStale: true);
      }
      return ExchangeRateResult.error(
        'Unable to fetch rates. Please check your connection.',
      );
    }
  }

  /// Convert an amount from one currency to another
  Future<ConversionResult> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    final rateResult = await fetchExchangeRate(from, to);

    if (rateResult.isSuccess) {
      final convertedAmount = amount * rateResult.rate!;
      return ConversionResult.success(
        originalAmount: amount,
        convertedAmount: convertedAmount,
        rate: rateResult.rate!,
        isStale: rateResult.isStale,
      );
    } else {
      return ConversionResult.error(rateResult.error!);
    }
  }

  /// Clear the cache
  void clearCache() {
    _cache.clear();
  }

  /// Get cached rate if available (even if stale)
  double? getCachedRate(String from, String to) {
    final cacheKey = '${from.toUpperCase()}_${to.toUpperCase()}';
    return _cache[cacheKey]?.rate;
  }
}

class _CachedRate {
  final double rate;
  final DateTime timestamp;

  _CachedRate({required this.rate, required this.timestamp});

  bool get isExpired =>
      DateTime.now().difference(timestamp) > ExchangeRateService._cacheExpiry;
}

/// Result class for exchange rate fetching
class ExchangeRateResult {
  final double? rate;
  final String? error;
  final bool isStale;

  ExchangeRateResult._({this.rate, this.error, this.isStale = false});

  factory ExchangeRateResult.success(double rate, {bool isStale = false}) {
    return ExchangeRateResult._(rate: rate, isStale: isStale);
  }

  factory ExchangeRateResult.error(String error) {
    return ExchangeRateResult._(error: error);
  }

  bool get isSuccess => rate != null;
}

/// Result class for currency conversion
class ConversionResult {
  final double? originalAmount;
  final double? convertedAmount;
  final double? rate;
  final String? error;
  final bool isStale;

  ConversionResult._({
    this.originalAmount,
    this.convertedAmount,
    this.rate,
    this.error,
    this.isStale = false,
  });

  factory ConversionResult.success({
    required double originalAmount,
    required double convertedAmount,
    required double rate,
    bool isStale = false,
  }) {
    return ConversionResult._(
      originalAmount: originalAmount,
      convertedAmount: convertedAmount,
      rate: rate,
      isStale: isStale,
    );
  }

  factory ConversionResult.error(String error) {
    return ConversionResult._(error: error);
  }

  bool get isSuccess => convertedAmount != null;
}
