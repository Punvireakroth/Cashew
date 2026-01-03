import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/account_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/currency_formatter.dart';

class WelcomeSection extends ConsumerWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountProvider);
    final l10n = AppLocalizations.of(context)!;
    final totalBalance = accountState.accounts.fold<double>(
      0.0,
      (sum, acc) => sum + acc.balance,
    );

    return FutureBuilder<String>(
      future: SharedPreferences.getInstance().then(
        (prefs) => prefs.getString('user_display_name') ?? l10n.friend,
      ),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? l10n.friend;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.totalBalance}: ${CurrencyFormatter.format(totalBalance)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
          ],
        );
      },
    );
  }
}

