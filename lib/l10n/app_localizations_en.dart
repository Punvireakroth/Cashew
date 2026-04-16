// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CashChew';

  @override
  String get settings => 'Settings';

  @override
  String get settingsAndCustomization => 'Settings & Customization';

  @override
  String get theme => 'Theme';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get accentColorDescription => 'Select a color theme for the interface';

  @override
  String get selectAccentColor => 'Select Accent Color';

  @override
  String get preferences => 'Preferences';

  @override
  String get language => 'Language';

  @override
  String get languageDescription => 'Choose your preferred language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get systemLanguage => 'System';

  @override
  String get home => 'Home';

  @override
  String get transactions => 'Transactions';

  @override
  String get budgets => 'Budgets';

  @override
  String get more => 'More';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get done => 'Done';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Retry';

  @override
  String get reset => 'Reset';

  @override
  String get action => 'Action';

  @override
  String get restore => 'Restore';

  @override
  String get archive => 'Archive';

  @override
  String get renew => 'Renew';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get balance => 'Balance';

  @override
  String get total => 'Total';

  @override
  String get all => 'All';

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get noBudgets => 'No budgets yet';

  @override
  String get noAccounts => 'No accounts yet';

  @override
  String get account => 'Account';

  @override
  String get accounts => 'Accounts';

  @override
  String get category => 'Category';

  @override
  String get categories => 'Categories';

  @override
  String get budget => 'Budget';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get notes => 'Notes';

  @override
  String get title => 'Title';

  @override
  String get whatsUp => 'What\'s up';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get friend => 'Friend';

  @override
  String get addAccount => 'Add Account';

  @override
  String transactionsCount(int count) {
    return '$count transactions';
  }

  @override
  String get setUpBudget => 'Set up a budget';

  @override
  String get trackSpendingHabits => 'Track your spending habits';

  @override
  String get allAccounts => 'All Accounts';

  @override
  String get specificAccount => 'Specific Account';

  @override
  String categoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'categories',
      one: 'category',
    );
    return '$count $_temp0';
  }

  @override
  String leftOf(String amount) {
    return 'left of $amount';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String budgetExpired(String name) {
    return '\"$name\" has expired';
  }

  @override
  String budgetsExpired(int count) {
    return '$count budgets have expired';
  }

  @override
  String get renewOrArchive => 'Renew or archive to keep things tidy';

  @override
  String get expired => 'Expired';

  @override
  String get spent => 'Spent';

  @override
  String get overBy => 'Over by';

  @override
  String get saved => 'Saved';

  @override
  String get budgetArchived => 'Budget archived';

  @override
  String get budgetRenewed => 'Budget renewed for new period';

  @override
  String get newPeriod => 'New period';

  @override
  String overBudgetBy(String amount) {
    return 'Over budget by $amount';
  }

  @override
  String get budgetPeriodEnded => 'Budget period ended';

  @override
  String dailySpendingAllowance(String amount, int days) {
    return 'You can spend $amount/day for $days more days';
  }

  @override
  String moreBudgets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'budgets',
      one: 'budget',
    );
    return '+$count more $_temp0';
  }

  @override
  String get seeAllTransactions => 'See all transactions';

  @override
  String get spendingOverview => 'Spending Overview';

  @override
  String get noSpendingData => 'No spending data yet';

  @override
  String get addExpenseToSeeTrends => 'Add expense transactions to see trends';

  @override
  String get searchTransactions => 'Search transactions...';

  @override
  String get filterTransactions => 'Filter Transactions';

  @override
  String get transactionType => 'Transaction Type';

  @override
  String get noCategoriesAvailable => 'No categories available';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get errorLoadingTransactions => 'Error loading transactions';

  @override
  String get noTransactionsFound => 'No transactions found';

  @override
  String noTransactionsFor(String month) {
    return 'No transactions for $month';
  }

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get active => 'Active';

  @override
  String get archived => 'Archived';

  @override
  String get createBudgetPrompt =>
      'Create a budget to start tracking\nyour spending habits';

  @override
  String get createBudget => 'Create Budget';

  @override
  String get noArchivedBudgets => 'No archived budgets';

  @override
  String get archivedBudgetsHint =>
      'Completed or expired budgets\nwill appear here after archiving';

  @override
  String get expiredBudgets => 'Expired Budgets';

  @override
  String get renewOrArchiveBudgets => 'Renew or archive these budgets';

  @override
  String get upcomingBudgets => 'Upcoming Budgets';

  @override
  String get archiveBudget => 'Archive Budget';

  @override
  String archiveConfirmMessage(String name) {
    return 'Archive \"$name\"? You can restore it later from the Archived tab.';
  }

  @override
  String budgetArchivedMessage(String name) {
    return '$name archived';
  }

  @override
  String budgetRestored(String name) {
    return '$name restored';
  }

  @override
  String get editBudget => 'Edit Budget';

  @override
  String get deleteBudget => 'Delete Budget';

  @override
  String deleteConfirmMessage(String name) {
    return 'Are you sure you want to delete \"$name\"? This cannot be undone.';
  }

  @override
  String get renewBudget => 'Renew Budget';

  @override
  String renewBudgetPrompt(String name) {
    return 'Create a new \"$name\" budget for the next period?';
  }

  @override
  String get limit => 'Limit';

  @override
  String get budgetRenewedSuccess => 'Budget renewed successfully';

  @override
  String get budgetWizardTitle => '50/30/20 Budget Setup';

  @override
  String get quickSetup503020 => 'Quick Setup (50/30/20)';

  @override
  String get wizardStep1Title => 'Setup';

  @override
  String get wizardStep1Subtitle => 'Enter your total budget';

  @override
  String get wizardStep2Title => 'Preview Split';

  @override
  String get wizardStep2Subtitle => 'Review the 50/30/20 allocation';

  @override
  String get wizardStep3Title => 'Categories';

  @override
  String get wizardStep3Subtitle => 'Assign categories to each budget';

  @override
  String get wizardStep4Title => 'Confirm';

  @override
  String get wizardStep4Subtitle => 'Review and create budgets';

  @override
  String get totalMonthlyBudget => 'Total Monthly Budget';

  @override
  String get trackAccount => 'Track Account';

  @override
  String get budgetPeriod => 'Budget Period';

  @override
  String get thisMonth => 'This Month';

  @override
  String get nextMonth => 'Next Month';

  @override
  String get continueText => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get createBudgets => 'Create Budgets';

  @override
  String get budgetRuleExplanation =>
      'The 50/30/20 rule suggests allocating 50% for needs, 30% for wants, and 20% for savings.';

  @override
  String get needs => 'Needs';

  @override
  String get wants => 'Wants';

  @override
  String get savings => 'Savings';

  @override
  String get needsDescription => 'Essential expenses like housing, bills, food';

  @override
  String get wantsDescription => 'Non-essential spending like entertainment';

  @override
  String get savingsDescription => 'Money set aside for future goals';

  @override
  String get assignCategoriesHint =>
      'Drag categories between sections or tap to move them';

  @override
  String get moveTo => 'Move to';

  @override
  String get removeFromBudget => 'Remove from budget';

  @override
  String get reviewBudgetsSummary => 'Review the budgets that will be created:';

  @override
  String get needsBudget => 'Needs Budget';

  @override
  String get wantsBudget => 'Wants Budget';

  @override
  String get savingsBudget => 'Savings Budget';

  @override
  String get pleaseEnterAmount => 'Please enter an amount';

  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';
}
