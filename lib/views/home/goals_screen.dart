import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../utils/locale_keys.dart';
import '../../services/goals_provider.dart';
import '../../models/goals_models.dart';
import 'goal_form_screen.dart';
import 'goal_contribution_form.dart';
import '../../utils/helpers.dart';

/// Экран финансовых целей (список с прогрессом)
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<GoalsProvider>().initialize());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: true,
      child: Consumer<GoalsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final goals = provider.goals;
          return Column(
            children: [
              if (goals.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, size: 72, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          LocaleKeys.goalsEmpty.tr(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      return _GoalCard(
                        goal: goal,
                        onAddContribution: () => _openAddContribution(context, goal),
                        onEdit: () => _openEditGoal(context, goal),
                        onDelete: () => _confirmDelete(context, goal),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.center,
                  child: FloatingActionButton.extended(
                    onPressed: () => _openCreateGoal(context),
                    icon: const Icon(Icons.add),
                    label: Text(LocaleKeys.goalsAddGoal.tr()),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openCreateGoal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GoalFormScreen()),
    );
  }

  void _openEditGoal(BuildContext context, Goal goal) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GoalFormScreen(goal: goal)),
    );
  }

  void _openAddContribution(BuildContext context, Goal goal) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GoalContributionForm(goal: goal)),
    );
  }

  void _confirmDelete(BuildContext context, Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.goalsDeleteConfirm.tr()),
        content: Text(LocaleKeys.goalsDeleteConfirmMessage.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleKeys.actionsCancel.tr()),
          ),
          TextButton(
            onPressed: () async {
              await context.read<GoalsProvider>().deleteGoal(goal.id!);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(LocaleKeys.actionsDelete.tr()),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onAddContribution;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onAddContribution,
    required this.onEdit,
    required this.onDelete,
  });

  Color _priorityColor(BuildContext context) {
    switch (goal.priority) {
      case GoalPriority.high:
        return Colors.red;
      case GoalPriority.medium:
        return Colors.orange;
      case GoalPriority.low:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (goal.progress * 100).round();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: _priorityColor(context).withValues(alpha: 0.15),
                  child: Icon(Icons.flag, color: _priorityColor(context)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _Chip(
                            icon: Icons.savings,
                            label:
                                '${Helpers.formatNumber(goal.currentAmount, decimals: 0)} / ${Helpers.formatNumber(goal.targetAmount, decimals: 0)} ₽',
                          ),
                          if (goal.deadline != null)
                            _Chip(
                              icon: Icons.calendar_today,
                              label: Helpers.formatDate(goal.deadline!),
                            ),
                          _Chip(
                            icon: Icons.priority_high,
                            label: _priorityLabel(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'add':
                        onAddContribution();
                        break;
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'add',
                      child: Row(
                        children: [
                          const Icon(Icons.add, size: 18),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.goalsAddContribution.tr()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 18),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.actionsEdit.tr()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 18),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.actionsDelete.tr()),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$progressPercent%'),
                if (goal.suggestedMonthlySaving != null)
                  Text(
                    '${LocaleKeys.goalsSuggestedMonthly.tr()}: ${Helpers.formatNumber(goal.suggestedMonthlySaving!, decimals: 0)} ₽',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onAddContribution,
                  icon: const Icon(Icons.add),
                  label: Text(LocaleKeys.goalsAddContribution.tr()),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: Text(LocaleKeys.actionsEdit.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _priorityLabel(BuildContext context) {
    switch (goal.priority) {
      case GoalPriority.high:
        return LocaleKeys.goalsPriorityHigh.tr();
      case GoalPriority.medium:
        return LocaleKeys.goalsPriorityMedium.tr();
      case GoalPriority.low:
        return LocaleKeys.goalsPriorityLow.tr();
    }
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

