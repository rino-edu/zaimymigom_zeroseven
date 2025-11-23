import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../utils/locale_keys.dart';
import '../../models/calendar_event.dart';
import '../../services/calendar_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  bool _showWeekAhead = true;
  final Set<CalendarEventType> _filters = {
    CalendarEventType.loanPayment,
    CalendarEventType.subscription,
    CalendarEventType.bill,
    CalendarEventType.goalDeadline,
    CalendarEventType.other,
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CalendarProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final eventsForSelected = provider.eventsForDate(_focusedDay)
        .where((e) => _filters.contains(e.type))
        .toList();

    final upcoming = provider.events
        .where((e) {
          if (!_filters.contains(e.type)) return false;
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day);
          final end = _showWeekAhead
              ? start.add(const Duration(days: 7))
              : DateTime(start.year, start.month + 1, start.day);
          return e.dateTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
              e.dateTime.isBefore(end.add(const Duration(days: 1)));
        })
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocaleKeys.calendarTitle.tr(),
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _openFilters(),
            tooltip: LocaleKeys.actionsFilter.tr(),
          ),
          IconButton(
            icon: Icon(_showWeekAhead ? Icons.view_week : Icons.view_module),
            onPressed: () {
              setState(() {
                _showWeekAhead = !_showWeekAhead;
              });
            },
            tooltip: _showWeekAhead
                ? LocaleKeys.calendarViewMonth.tr()
                : LocaleKeys.calendarViewWeek.tr(),
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        bottom: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('dd.MM.yyyy').format(_focusedDay)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _focusedDay,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          helpText: LocaleKeys.calendarSelectDate.tr(),
                          locale: context.locale,
                        );
                        if (picked != null) {
                          setState(() {
                            _focusedDay = picked;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime.now();
                      });
                    },
                    tooltip: LocaleKeys.calendarToday.tr(),
                    icon: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _SectionHeader(
                    title: DateFormat.yMMMM(context.locale.toString()).format(_focusedDay),
                    icon: Icons.event,
                  ),
                  if (eventsForSelected.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        LocaleKeys.calendarNoTasksForDate.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    ...eventsForSelected.map((e) => _EventTile(
                          event: e,
                          onEdit: () => _openEventForm(existing: e),
                          onDelete: () => provider.remove(e.id),
                          onTogglePaid: () =>
                              provider.update(e.copyWith(isPaid: !e.isPaid)),
                        )),
                  const Divider(height: 24),
                  _SectionHeader(
                    title: _showWeekAhead
                        ? LocaleKeys.calendarUpcomingWeek.tr()
                        : LocaleKeys.calendarUpcomingMonth.tr(),
                    icon: Icons.upcoming,
                  ),
                  if (upcoming.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _showWeekAhead
                            ? LocaleKeys.calendarNoEventsWeek.tr()
                            : LocaleKeys.calendarNoEventsMonth.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    ...upcoming.map((e) => _EventTile(
                          event: e,
                          onEdit: () => _openEventForm(existing: e),
                          onDelete: () => provider.remove(e.id),
                          onTogglePaid: () =>
                              provider.update(e.copyWith(isPaid: !e.isPaid)),
                        )),
                  const SizedBox(height: 88),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEventForm,
        icon: const Icon(Icons.add),
        label: Text(LocaleKeys.actionsAdd.tr()),
      ),
    );
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<Set<CalendarEventType>>(
      context: context,
      builder: (ctx) {
        final temp = Set<CalendarEventType>.from(_filters);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.actionsFilter.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CalendarEventType.values.map((t) {
                    return FilterChip(
                      label: Text(_typeLabel(t)),
                      selected: temp.contains(t),
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            temp.add(t);
                          } else {
                            temp.remove(t);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(LocaleKeys.actionsCancel.tr()),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, temp),
                      child: Text(LocaleKeys.actionsApply.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) {
      setState(() {
        _filters
          ..clear()
          ..addAll(result);
      });
    }
  }

  Future<void> _openEventForm({CalendarEvent? existing}) async {
    final res = await showModalBottomSheet<CalendarEvent>(
      isScrollControlled: true,
      context: context,
      builder: (ctx) => _EventForm(
        initialDate: _focusedDay,
        existing: existing,
      ),
    );
    if (res != null) {
      final provider = context.read<CalendarProvider>();
      if (existing == null) {
        await provider.add(res);
      } else {
        await provider.update(res);
      }
    }
  }

  String _typeLabel(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.loanPayment:
        return LocaleKeys.calendarTypeLoan.tr();
      case CalendarEventType.subscription:
        return LocaleKeys.calendarTypeSubscription.tr();
      case CalendarEventType.bill:
        return LocaleKeys.calendarTypeBill.tr();
      case CalendarEventType.goalDeadline:
        return LocaleKeys.calendarTypeGoal.tr();
      case CalendarEventType.other:
        return LocaleKeys.calendarTypeOther.tr();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePaid;
  const _EventTile({
    required this.event,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(context, event.type);
    final time = DateFormat('HH:mm').format(event.dateTime);
    final date = DateFormat('dd.MM.yyyy').format(event.dateTime);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: color,
          child: Icon(_typeIcon(event.type)),
        ),
        title: Text(event.title),
        subtitle: Text('$date • $time'),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              tooltip: LocaleKeys.actionsEdit.tr(),
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              tooltip: event.isPaid
                  ? LocaleKeys.actionsMarkUnpaid.tr()
                  : LocaleKeys.actionsMarkPaid.tr(),
              onPressed: onTogglePaid,
              icon: Icon(
                event.isPaid ? Icons.check_circle : Icons.radio_button_unchecked,
                color: event.isPaid ? Colors.green : null,
              ),
            ),
            IconButton(
              tooltip: LocaleKeys.actionsDelete.tr(),
              onPressed: onDelete,
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.loanPayment:
        return Icons.payments;
      case CalendarEventType.subscription:
        return Icons.subscriptions;
      case CalendarEventType.bill:
        return Icons.receipt_long;
      case CalendarEventType.goalDeadline:
        return Icons.flag;
      case CalendarEventType.other:
        return Icons.event_note;
    }
  }

  Color _typeColor(BuildContext context, CalendarEventType type) {
    final scheme = Theme.of(context).colorScheme;
    switch (type) {
      case CalendarEventType.loanPayment:
        return scheme.primary;
      case CalendarEventType.subscription:
        return scheme.secondary;
      case CalendarEventType.bill:
        return scheme.tertiary;
      case CalendarEventType.goalDeadline:
        return Colors.orange;
      case CalendarEventType.other:
        return Colors.blueGrey;
    }
  }
}

class _EventForm extends StatefulWidget {
  final DateTime initialDate;
  final CalendarEvent? existing;
  const _EventForm({required this.initialDate, this.existing});

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtl;
  late TextEditingController _descriptionCtl;
  late DateTime _date;
  late TimeOfDay _time;
  CalendarEventType _type = CalendarEventType.loanPayment;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _titleCtl = TextEditingController(text: e.title);
      _descriptionCtl = TextEditingController(text: e.description ?? '');
      _date = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      _time = TimeOfDay(hour: e.dateTime.hour, minute: e.dateTime.minute);
      _type = e.type;
      _isPaid = e.isPaid;
    } else {
      _titleCtl = TextEditingController();
      _descriptionCtl = TextEditingController();
      _date = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day);
      _time = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _descriptionCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: insets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existing == null
                      ? LocaleKeys.calendarAddEvent.tr()
                      : LocaleKeys.calendarEditEvent.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleCtl,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.calendarEventTitle.tr(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? LocaleKeys.validationRequired.tr()
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CalendarEventType>(
                  value: _type,
                  items: CalendarEventType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabel(t)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                  decoration: InputDecoration(
                    labelText: LocaleKeys.actionsFilter.tr(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event),
                        label: Text(DateFormat('dd.MM.yyyy').format(_date)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            helpText: LocaleKeys.calendarSelectDate.tr(),
                            locale: context.locale,
                          );
                          if (picked != null) {
                            setState(() {
                              _date = picked;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(_time.format(context)),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _time,
                            helpText: LocaleKeys.calendarSelectTime.tr(),
                          );
                          if (picked != null) {
                            setState(() {
                              _time = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.calendarEventDescription.tr(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isPaid,
                  onChanged: (v) => setState(() => _isPaid = v ?? false),
                  title: Text(LocaleKeys.actionsMarkPaid.tr()),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(LocaleKeys.actionsCancel.tr()),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _save,
                      child: Text(LocaleKeys.actionsSave.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final dateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final id = widget.existing?.id ?? const Uuid().v4();
    final event = CalendarEvent(
      id: id,
      title: _titleCtl.text.trim(),
      dateTime: dateTime,
      type: _type,
      isPaid: _isPaid,
      description: _descriptionCtl.text.trim().isEmpty
          ? null
          : _descriptionCtl.text.trim(),
    );
    Navigator.pop(context, event);
  }

  String _typeLabel(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.loanPayment:
        return LocaleKeys.calendarTypeLoan.tr();
      case CalendarEventType.subscription:
        return LocaleKeys.calendarTypeSubscription.tr();
      case CalendarEventType.bill:
        return LocaleKeys.calendarTypeBill.tr();
      case CalendarEventType.goalDeadline:
        return LocaleKeys.calendarTypeGoal.tr();
      case CalendarEventType.other:
        return LocaleKeys.calendarTypeOther.tr();
    }
  }
}


