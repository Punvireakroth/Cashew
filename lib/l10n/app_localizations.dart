import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CashChew'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsAndCustomization.
  ///
  /// In en, this message translates to:
  /// **'Settings & Customization'**
  String get settingsAndCustomization;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @accentColorDescription.
  ///
  /// In en, this message translates to:
  /// **'Select a color theme for the interface'**
  String get accentColorDescription;

  /// No description provided for @selectAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Select Accent Color'**
  String get selectAccentColor;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageDescription;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemLanguage;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @renew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get renew;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @noBudgets.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get noBudgets;

  /// No description provided for @noAccounts.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get noAccounts;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @whatsUp.
  ///
  /// In en, this message translates to:
  /// **'What\'s up'**
  String get whatsUp;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friend;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// No description provided for @transactionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String transactionsCount(int count);

  /// No description provided for @setUpBudget.
  ///
  /// In en, this message translates to:
  /// **'Set up a budget'**
  String get setUpBudget;

  /// No description provided for @trackSpendingHabits.
  ///
  /// In en, this message translates to:
  /// **'Track your spending habits'**
  String get trackSpendingHabits;

  /// No description provided for @allAccounts.
  ///
  /// In en, this message translates to:
  /// **'All Accounts'**
  String get allAccounts;

  /// No description provided for @specificAccount.
  ///
  /// In en, this message translates to:
  /// **'Specific Account'**
  String get specificAccount;

  /// No description provided for @categoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{category} other{categories}}'**
  String categoryCount(int count);

  /// No description provided for @leftOf.
  ///
  /// In en, this message translates to:
  /// **'left of {amount}'**
  String leftOf(String amount);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @budgetExpired.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" has expired'**
  String budgetExpired(String name);

  /// No description provided for @budgetsExpired.
  ///
  /// In en, this message translates to:
  /// **'{count} budgets have expired'**
  String budgetsExpired(int count);

  /// No description provided for @renewOrArchive.
  ///
  /// In en, this message translates to:
  /// **'Renew or archive to keep things tidy'**
  String get renewOrArchive;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @overBy.
  ///
  /// In en, this message translates to:
  /// **'Over by'**
  String get overBy;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @budgetArchived.
  ///
  /// In en, this message translates to:
  /// **'Budget archived'**
  String get budgetArchived;

  /// No description provided for @budgetRenewed.
  ///
  /// In en, this message translates to:
  /// **'Budget renewed for new period'**
  String get budgetRenewed;

  /// No description provided for @newPeriod.
  ///
  /// In en, this message translates to:
  /// **'New period'**
  String get newPeriod;

  /// No description provided for @overBudgetBy.
  ///
  /// In en, this message translates to:
  /// **'Over budget by {amount}'**
  String overBudgetBy(String amount);

  /// No description provided for @budgetPeriodEnded.
  ///
  /// In en, this message translates to:
  /// **'Budget period ended'**
  String get budgetPeriodEnded;

  /// No description provided for @dailySpendingAllowance.
  ///
  /// In en, this message translates to:
  /// **'You can spend {amount}/day for {days} more days'**
  String dailySpendingAllowance(String amount, int days);

  /// No description provided for @moreBudgets.
  ///
  /// In en, this message translates to:
  /// **'+{count} more {count, plural, =1{budget} other{budgets}}'**
  String moreBudgets(int count);

  /// No description provided for @seeAllTransactions.
  ///
  /// In en, this message translates to:
  /// **'See all transactions'**
  String get seeAllTransactions;

  /// No description provided for @spendingOverview.
  ///
  /// In en, this message translates to:
  /// **'Spending Overview'**
  String get spendingOverview;

  /// No description provided for @noSpendingData.
  ///
  /// In en, this message translates to:
  /// **'No spending data yet'**
  String get noSpendingData;

  /// No description provided for @addExpenseToSeeTrends.
  ///
  /// In en, this message translates to:
  /// **'Add expense transactions to see trends'**
  String get addExpenseToSeeTrends;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search transactions...'**
  String get searchTransactions;

  /// No description provided for @filterTransactions.
  ///
  /// In en, this message translates to:
  /// **'Filter Transactions'**
  String get filterTransactions;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @noCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategoriesAvailable;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @errorLoadingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Error loading transactions'**
  String get errorLoadingTransactions;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFound;

  /// No description provided for @noTransactionsFor.
  ///
  /// In en, this message translates to:
  /// **'No transactions for {month}'**
  String noTransactionsFor(String month);

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @createBudgetPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create a budget to start tracking\nyour spending habits'**
  String get createBudgetPrompt;

  /// No description provided for @createBudget.
  ///
  /// In en, this message translates to:
  /// **'Create Budget'**
  String get createBudget;

  /// No description provided for @noArchivedBudgets.
  ///
  /// In en, this message translates to:
  /// **'No archived budgets'**
  String get noArchivedBudgets;

  /// No description provided for @archivedBudgetsHint.
  ///
  /// In en, this message translates to:
  /// **'Completed or expired budgets\nwill appear here after archiving'**
  String get archivedBudgetsHint;

  /// No description provided for @expiredBudgets.
  ///
  /// In en, this message translates to:
  /// **'Expired Budgets'**
  String get expiredBudgets;

  /// No description provided for @renewOrArchiveBudgets.
  ///
  /// In en, this message translates to:
  /// **'Renew or archive these budgets'**
  String get renewOrArchiveBudgets;

  /// No description provided for @upcomingBudgets.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Budgets'**
  String get upcomingBudgets;

  /// No description provided for @archiveBudget.
  ///
  /// In en, this message translates to:
  /// **'Archive Budget'**
  String get archiveBudget;

  /// No description provided for @archiveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Archive \"{name}\"? You can restore it later from the Archived tab.'**
  String archiveConfirmMessage(String name);

  /// No description provided for @budgetArchivedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} archived'**
  String budgetArchivedMessage(String name);

  /// No description provided for @budgetRestored.
  ///
  /// In en, this message translates to:
  /// **'{name} restored'**
  String budgetRestored(String name);

  /// No description provided for @editBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get editBudget;

  /// No description provided for @deleteBudget.
  ///
  /// In en, this message translates to:
  /// **'Delete Budget'**
  String get deleteBudget;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This cannot be undone.'**
  String deleteConfirmMessage(String name);

  /// No description provided for @renewBudget.
  ///
  /// In en, this message translates to:
  /// **'Renew Budget'**
  String get renewBudget;

  /// No description provided for @renewBudgetPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create a new \"{name}\" budget for the next period?'**
  String renewBudgetPrompt(String name);

  /// No description provided for @limit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get limit;

  /// No description provided for @budgetRenewedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Budget renewed successfully'**
  String get budgetRenewedSuccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
