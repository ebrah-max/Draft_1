/// Currency formatting utility for Tanzanian Shillings (TSh)
/// 
/// This utility provides consistent currency formatting throughout the app.
/// All amounts should be formatted using these utilities to ensure
/// proper display of Tanzanian Shillings.

class CurrencyFormatter {
  static const String currency = 'TSh';
  static const String currencySymbol = 'TSh';
  
  /// Format amount as Tanzanian Shillings with proper formatting
  /// 
  /// Examples:
  /// - formatAmount(1000) -> "TSh 1,000"
  /// - formatAmount(1500.50) -> "TSh 1,500.50"
  /// - formatAmount(1000000) -> "TSh 1,000,000"
  static String formatAmount(double amount) {
    if (amount.abs() >= 1000000) {
      // For millions, show as TSh 1.2M
      double millions = amount / 1000000;
      return '${currency} ${millions.toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      // For thousands, show with comma separator
      return '${currency} ${_addCommas(amount.toStringAsFixed(0))}';
    } else {
      // For amounts less than 1000
      return '${currency} ${amount.toStringAsFixed(0)}';
    }
  }
  
  /// Format amount with decimal places when necessary
  static String formatAmountWithDecimals(double amount) {
    if (amount % 1 == 0) {
      // No decimal places needed
      return formatAmount(amount);
    } else {
      // Show decimal places
      if (amount.abs() >= 1000000) {
        double millions = amount / 1000000;
        return '${currency} ${millions.toStringAsFixed(2)}M';
      } else if (amount.abs() >= 1000) {
        return '${currency} ${_addCommas(amount.toStringAsFixed(2))}';
      } else {
        return '${currency} ${amount.toStringAsFixed(2)}';
      }
    }
  }
  
  /// Format amount in compact form for analytics/charts
  /// 
  /// Examples:
  /// - formatCompact(1500) -> "1.5K"
  /// - formatCompact(2500000) -> "2.5M"
  static String formatCompact(double amount) {
    if (amount.abs() >= 1000000) {
      double millions = amount / 1000000;
      return '${millions.toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      double thousands = amount / 1000;
      return '${thousands.toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
  
  /// Format amount with full currency name for formal documents
  static String formatFormal(double amount) {
    return 'Tanzanian Shillings ${_addCommas(amount.toStringAsFixed(2))}';
  }
  
  /// Parse amount from string (removes currency symbols)
  static double parseAmount(String amountStr) {
    // Remove currency symbols and commas
    String cleanStr = amountStr
        .replaceAll('TSh', '')
        .replaceAll('Tanzanian Shillings', '')
        .replaceAll(',', '')
        .replaceAll('M', '000000')
        .replaceAll('K', '000')
        .trim();
    
    try {
      return double.parse(cleanStr);
    } catch (e) {
      return 0.0;
    }
  }
  
  /// Helper method to add commas for thousands separator
  static String _addCommas(String numberStr) {
    // Split by decimal point if it exists
    List<String> parts = numberStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';
    
    // Add commas to integer part
    String result = '';
    int count = 0;
    
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result = ',' + result;
      }
      result = integerPart[i] + result;
      count++;
    }
    
    return result + decimalPart;
  }
  
  /// Check if an amount is considered high value in Tanzanian context
  static bool isHighValue(double amount) {
    return amount.abs() > 500000; // TSh 500,000
  }
  
  /// Check if an amount is considered very high value in Tanzanian context
  static bool isVeryHighValue(double amount) {
    return amount.abs() > 1000000; // TSh 1,000,000 (1M)
  }
  
  /// Get appropriate amount ranges for different transaction limits
  static Map<String, double> getTransactionLimits() {
    return {
      'daily_limit': 3000000.0,     // TSh 3M daily limit
      'monthly_limit': 30000000.0,  // TSh 30M monthly limit
      'single_max': 5000000.0,      // TSh 5M single transaction
      'micro_threshold': 10000.0,    // TSh 10K micro payment
      'high_value': 500000.0,        // TSh 500K high value
      'very_high_value': 1000000.0,  // TSh 1M very high value
    };
  }
}
