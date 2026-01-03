// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appTitle => 'CashChew';

  @override
  String get settings => 'ការកំណត់';

  @override
  String get settingsAndCustomization => 'ការកំណត់ និងការប្ដូរតាមបំណង';

  @override
  String get theme => 'រចនាប័ទ្ម';

  @override
  String get accentColor => 'ពណ៌សំខាន់';

  @override
  String get accentColorDescription => 'ជ្រើសរើសពណ៌សម្រាប់ចំណុចប្រទាក់';

  @override
  String get selectAccentColor => 'ជ្រើសរើសពណ៌សំខាន់';

  @override
  String get preferences => 'ចំណូលចិត្ត';

  @override
  String get language => 'ភាសា';

  @override
  String get languageDescription => 'ជ្រើសរើសភាសាដែលអ្នកចូលចិត្ត';

  @override
  String get selectLanguage => 'ជ្រើសរើសភាសា';

  @override
  String get systemLanguage => 'ប្រព័ន្ធ';

  @override
  String get home => 'ទំព័រដើម';

  @override
  String get transactions => 'ប្រតិបត្តិការ';

  @override
  String get budgets => 'ថវិកា';

  @override
  String get more => 'ច្រើនទៀត';

  @override
  String get save => 'រក្សាទុក';

  @override
  String get cancel => 'បោះបង់';

  @override
  String get delete => 'លុប';

  @override
  String get edit => 'កែសម្រួល';

  @override
  String get add => 'បន្ថែម';

  @override
  String get done => 'រួចរាល់';

  @override
  String get confirm => 'បញ្ជាក់';

  @override
  String get retry => 'ព្យាយាមម្ដងទៀត';

  @override
  String get reset => 'កំណត់ឡើងវិញ';

  @override
  String get action => 'សកម្មភាព';

  @override
  String get restore => 'ស្ដារឡើងវិញ';

  @override
  String get archive => 'ទុកក្នុងប័ណ្ណសារ';

  @override
  String get renew => 'បន្តថ្មី';

  @override
  String get income => 'ចំណូល';

  @override
  String get expense => 'ចំណាយ';

  @override
  String get balance => 'សមតុល្យ';

  @override
  String get total => 'សរុប';

  @override
  String get all => 'ទាំងអស់';

  @override
  String get noTransactions => 'មិនទាន់មានប្រតិបត្តិការ';

  @override
  String get noBudgets => 'មិនទាន់មានថវិកា';

  @override
  String get noAccounts => 'មិនទាន់មានគណនី';

  @override
  String get account => 'គណនី';

  @override
  String get accounts => 'គណនី​នានា';

  @override
  String get category => 'ប្រភេទ';

  @override
  String get categories => 'ប្រភេទ​នានា';

  @override
  String get budget => 'ថវិកា';

  @override
  String get amount => 'ចំនួនប្រាក់';

  @override
  String get date => 'កាលបរិច្ឆេទ';

  @override
  String get notes => 'កំណត់ចំណាំ';

  @override
  String get title => 'ចំណងជើង';

  @override
  String get whatsUp => 'សួស្តី';

  @override
  String get totalBalance => 'សមតុល្យសរុប';

  @override
  String get friend => 'មិត្តភ័ក្ត្រ';

  @override
  String get addAccount => 'បន្ថែមគណនី';

  @override
  String transactionsCount(int count) {
    return '$count ប្រតិបត្តិការ';
  }

  @override
  String get setUpBudget => 'បង្កើតថវិកា';

  @override
  String get trackSpendingHabits => 'តាមដានទម្លាប់ការចំណាយរបស់អ្នក';

  @override
  String get allAccounts => 'គណនីទាំងអស់';

  @override
  String get specificAccount => 'គណនីជាក់លាក់';

  @override
  String categoryCount(int count) {
    return '$count ប្រភេទ';
  }

  @override
  String leftOf(String amount) {
    return 'នៅសល់ពី $amount';
  }

  @override
  String get today => 'ថ្ងៃនេះ';

  @override
  String get yesterday => 'ម្សិលមិញ';

  @override
  String budgetExpired(String name) {
    return '\"$name\" បានផុតកំណត់';
  }

  @override
  String budgetsExpired(int count) {
    return '$count ថវិកាបានផុតកំណត់';
  }

  @override
  String get renewOrArchive => 'បន្តថ្មី ឬទុកក្នុងប័ណ្ណសារ';

  @override
  String get expired => 'ផុតកំណត់';

  @override
  String get spent => 'បានចំណាយ';

  @override
  String get overBy => 'លើសដោយ';

  @override
  String get saved => 'បានសន្សំ';

  @override
  String get budgetArchived => 'ថវិកាបានទុកក្នុងប័ណ្ណសារ';

  @override
  String get budgetRenewed => 'ថវិកាបានបន្តថ្មីសម្រាប់រយៈពេលថ្មី';

  @override
  String get newPeriod => 'រយៈពេលថ្មី';

  @override
  String overBudgetBy(String amount) {
    return 'លើសថវិកាដោយ $amount';
  }

  @override
  String get budgetPeriodEnded => 'រយៈពេលថវិកាបានបញ្ចប់';

  @override
  String dailySpendingAllowance(String amount, int days) {
    return 'អ្នកអាចចំណាយ $amount/ថ្ងៃ សម្រាប់ $days ថ្ងៃទៀត';
  }

  @override
  String moreBudgets(int count) {
    return '+$count ថវិកាទៀត';
  }

  @override
  String get seeAllTransactions => 'មើលប្រតិបត្តិការទាំងអស់';

  @override
  String get spendingOverview => 'ទិដ្ឋភាពទូទៅនៃការចំណាយ';

  @override
  String get noSpendingData => 'មិនទាន់មានទិន្នន័យការចំណាយ';

  @override
  String get addExpenseToSeeTrends =>
      'បន្ថែមប្រតិបត្តិការចំណាយដើម្បីមើលនិន្នាការ';

  @override
  String get searchTransactions => 'ស្វែងរកប្រតិបត្តិការ...';

  @override
  String get filterTransactions => 'តម្រងប្រតិបត្តិការ';

  @override
  String get transactionType => 'ប្រភេទប្រតិបត្តិការ';

  @override
  String get noCategoriesAvailable => 'មិនមានប្រភេទ';

  @override
  String get applyFilters => 'អនុវត្តតម្រង';

  @override
  String get errorLoadingTransactions => 'កំហុសក្នុងការផ្ទុកប្រតិបត្តិការ';

  @override
  String get noTransactionsFound => 'រកមិនឃើញប្រតិបត្តិការ';

  @override
  String noTransactionsFor(String month) {
    return 'គ្មានប្រតិបត្តិការសម្រាប់ $month';
  }

  @override
  String get addTransaction => 'បន្ថែមប្រតិបត្តិការ';

  @override
  String get active => 'សកម្ម';

  @override
  String get archived => 'ប័ណ្ណសារ';

  @override
  String get createBudgetPrompt =>
      'បង្កើតថវិកាដើម្បីចាប់ផ្តើមតាមដាន\nទម្លាប់ការចំណាយរបស់អ្នក';

  @override
  String get createBudget => 'បង្កើតថវិកា';

  @override
  String get noArchivedBudgets => 'គ្មានថវិកាក្នុងប័ណ្ណសារ';

  @override
  String get archivedBudgetsHint =>
      'ថវិកាដែលបានបញ្ចប់ ឬផុតកំណត់\nនឹងបង្ហាញនៅទីនេះបន្ទាប់ពីទុកក្នុងប័ណ្ណសារ';

  @override
  String get expiredBudgets => 'ថវិកាផុតកំណត់';

  @override
  String get renewOrArchiveBudgets => 'បន្តថ្មី ឬទុកក្នុងប័ណ្ណសារថវិកាទាំងនេះ';

  @override
  String get upcomingBudgets => 'ថវិកានាពេលខាងមុខ';

  @override
  String get archiveBudget => 'ទុកថវិកាក្នុងប័ណ្ណសារ';

  @override
  String archiveConfirmMessage(String name) {
    return 'ទុក \"$name\" ក្នុងប័ណ្ណសារ? អ្នកអាចស្ដារវាឡើងវិញពីផ្ទាំងប័ណ្ណសារ។';
  }

  @override
  String budgetArchivedMessage(String name) {
    return '$name បានទុកក្នុងប័ណ្ណសារ';
  }

  @override
  String budgetRestored(String name) {
    return '$name បានស្ដារឡើងវិញ';
  }

  @override
  String get editBudget => 'កែសម្រួលថវិកា';

  @override
  String get deleteBudget => 'លុបថវិកា';

  @override
  String deleteConfirmMessage(String name) {
    return 'តើអ្នកប្រាកដថាចង់លុប \"$name\"? សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។';
  }

  @override
  String get renewBudget => 'បន្តថវិកាថ្មី';

  @override
  String renewBudgetPrompt(String name) {
    return 'បង្កើតថវិកា \"$name\" ថ្មីសម្រាប់រយៈពេលបន្ទាប់?';
  }

  @override
  String get limit => 'កំណត់';

  @override
  String get budgetRenewedSuccess => 'ថវិកាបានបន្តថ្មីដោយជោគជ័យ';
}
