import 'package:flutter/material.dart';
import 'package:chashew/widgets/budget_progress_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Progress Bar Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BudgetProgressBarTestPage(),
    );
  }
}

class BudgetProgressBarTestPage extends StatelessWidget {
  const BudgetProgressBarTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Progress Bar Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Progress Bar Examples',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            
            // Under Budget Examples (< 80%)
            _buildSection(
              context,
              'Under Budget (< 80%) - Green',
              [
                _buildExample(context, '25%', 0.25),
                _buildExample(context, '50%', 0.50),
                _buildExample(context, '75%', 0.75),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Warning Examples (80-100%)
            _buildSection(
              context,
              'Warning (80-100%) - Yellow',
              [
                _buildExample(context, '80%', 0.80),
                _buildExample(context, '90%', 0.90),
                _buildExample(context, '100%', 1.00),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Over Budget Examples (> 100%)
            _buildSection(
              context,
              'Over Budget (> 100%) - Red',
              [
                _buildExample(context, '110%', 1.10),
                _buildExample(context, '125%', 1.25),
                _buildExample(context, '150%', 1.50),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Edge Cases
            _buildSection(
              context,
              'Edge Cases',
              [
                _buildExample(context, '0%', 0.0),
                _buildExample(context, '5%', 0.05),
                _buildExample(context, '79.9%', 0.799),
                _buildExample(context, '200%', 2.0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> examples) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 12),
        ...examples,
      ],
    );
  }

  Widget _buildExample(BuildContext context, String label, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          BudgetProgressBar(
            percentage: percentage,
            height: 12.0,
          ),
        ],
      ),
    );
  }
}
