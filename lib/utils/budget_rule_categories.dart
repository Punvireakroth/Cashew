import '../models/category.dart';

/// Budget rule types for the 50/30/20 rule
enum BudgetRuleType { needs, wants, savings }

/// Default category mappings for the 50/30/20 budget rule
/// Maps category names to their default budget rule type
const Map<String, BudgetRuleType> defaultCategoryMappings = {
  // Needs (50%) - Essential expenses
  'Housing': BudgetRuleType.needs,
  'Bills & Utilities': BudgetRuleType.needs,
  'Healthcare': BudgetRuleType.needs,
  'Transportation': BudgetRuleType.needs,
  'Food & Dining': BudgetRuleType.needs,
  'Education': BudgetRuleType.needs,

  // Wants (30%) - Non-essential spending
  'Entertainment': BudgetRuleType.wants,
  'Shopping': BudgetRuleType.wants,
  'Travel': BudgetRuleType.wants,
  'Personal Care': BudgetRuleType.wants,
  'Fitness & Sports': BudgetRuleType.wants,
  'Other Expenses': BudgetRuleType.wants,

  // Savings (20%) - Money set aside
  'Savings Transfer': BudgetRuleType.savings,
};

/// Budget rule percentages
class BudgetRulePercentages {
  static const double needs = 0.50;
  static const double wants = 0.30;
  static const double savings = 0.20;
}

/// Helper class to categorize expense categories by budget rule type
class BudgetRuleCategorizer {
  /// Categorize a list of expense categories into needs, wants, and savings
  static Map<BudgetRuleType, List<Category>> categorizeExpenses(
    List<Category> expenseCategories,
  ) {
    final result = <BudgetRuleType, List<Category>>{
      BudgetRuleType.needs: [],
      BudgetRuleType.wants: [],
      BudgetRuleType.savings: [],
    };

    for (final category in expenseCategories) {
      final ruleType = defaultCategoryMappings[category.name];
      if (ruleType != null) {
        result[ruleType]!.add(category);
      } else {
        // Default uncategorized expenses to "wants"
        result[BudgetRuleType.wants]!.add(category);
      }
    }

    return result;
  }

  /// Get the display name for a budget rule type
  static String getDisplayName(BudgetRuleType type) {
    switch (type) {
      case BudgetRuleType.needs:
        return 'Needs';
      case BudgetRuleType.wants:
        return 'Wants';
      case BudgetRuleType.savings:
        return 'Savings';
    }
  }

  /// Get the percentage for a budget rule type
  static double getPercentage(BudgetRuleType type) {
    switch (type) {
      case BudgetRuleType.needs:
        return BudgetRulePercentages.needs;
      case BudgetRuleType.wants:
        return BudgetRulePercentages.wants;
      case BudgetRuleType.savings:
        return BudgetRulePercentages.savings;
    }
  }

  /// Get the percentage as integer (50, 30, 20)
  static int getPercentageInt(BudgetRuleType type) {
    return (getPercentage(type) * 100).round();
  }

  /// Calculate amount based on total and rule type
  static double calculateAmount(double totalAmount, BudgetRuleType type) {
    return totalAmount * getPercentage(type);
  }
}
