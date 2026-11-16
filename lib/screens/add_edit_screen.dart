import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/catalog.dart';
import '../models/subscription.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/ui.dart';
import 'reminder_setup_screen.dart';

class AddEditScreen extends StatefulWidget {
  const AddEditScreen({super.key, this.existing, this.template});

  /// Editing an existing subscription.
  final Subscription? existing;

  /// Pre-fill from the popular-services list when adding.
  final CatalogItem? template;

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _notes;
  late final TextEditingController _cancelUrl;

  late String _currency;
  late BillingCycle _cycle;
  late DateTime _next;
  late bool _isTrial;
  late String _category;
  late int _color;
  late int _remindDays;
  bool _initialized = false;

  bool get _editing => widget.existing != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final state = AppScope.read(context);
    final e = widget.existing;
    final t = widget.template;

    _name = TextEditingController(text: e?.name ?? t?.name ?? '');
    _price = TextEditingController(
        text: e == null ? '' : e.price.toStringAsFixed(2));
    _notes = TextEditingController(text: e?.notes ?? '');
    // The "app store" marker isn't a real link: leave the field empty;
    // Cancel still finds the store page through the catalog.
    final templateUrl =
        t?.cancelUrl == storeSubscriptions ? null : t?.cancelUrl;
    final ownUrl = e?.cancelUrl == storeSubscriptions ? null : e?.cancelUrl;
    _cancelUrl = TextEditingController(text: ownUrl ?? templateUrl ?? '');
    _currency = e?.currency ?? state.defaultCurrency;
    _cycle = e?.cycle ?? BillingCycle.monthly;
    _next = e?.nextBillingDate ?? dateOnly(DateTime.now()).add(const Duration(days: 30));
    _isTrial = e?.isTrial ?? false;
    _category = e?.category ?? t?.category ?? 'Other';
    if (!categories.contains(_category)) _category = 'Other';
    _color = e?.colorValue ?? t?.color ?? palette[DateTime.now().second % palette.length];
    _remindDays = e?.remindDaysBefore ?? state.defaultRemindDays;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _notes.dispose();
    _cancelUrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _next,
      // Up to a year back: older dates would fill History with guesses.
      firstDate: _next.isBefore(_oldestDate) ? _next : _oldestDate,
      lastDate: DateTime(2100),
      helpText: _isTrial ? 'Trial ends on' : 'Renewal date',
    );
    if (picked != null) setState(() => _next = picked);
  }

  DateTime get _oldestDate =>
      dateOnly(DateTime.now()).subtract(const Duration(days: 365));

  bool _saving = false;

  Future<void> _save() async {
    // A quick double tap must not add the same subscription twice.
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _saveNow();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveNow() async {
    final e = widget.existing;
    final url = _cancelUrl.text.trim();
    final link = webLink(url);
    final sub = Subscription(
      id: e?.id ?? Subscription.newId(),
      name: _name.text.trim(),
      price: parsePrice(_price.text)!,
      currency: _currency,
      cycle: _cycle,
      nextBillingDate: dateOnly(_next),
      anchorDay: _next.day,
      isTrial: _isTrial,
      category: _category,
      colorValue: _color,
      cancelUrl: link?.toString(),
      notes: _notes.text.trim(),
      remindDaysBefore: _remindDays,
      createdAt: e?.createdAt ?? DateTime.now(),
    );
    // A past start date is fine: AppState logs those charges as history.
    final state = AppScope.read(context);
    await state.upsert(sub);
    if (!state.reminderSetupDone &&
        await ReminderSetupScreen.everythingAllowed()) {
      await state.markReminderSetupDone();
    }
    if (!mounted) return;
    if (!state.reminderSetupDone) {
      // First time: make sure this phone will really deliver reminders.
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
          builder: (_) => const ReminderSetupScreen()));
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${widget.existing!.name}?'),
        content: const Text(
            'This only removes it from SubGuard. Remember to cancel it with the company too.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AppScope.read(context).delete(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openCancelPage() async {
    final uri = webLink(_cancelUrl.text);
    final ok = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  InputDecoration _bare(String label) => InputDecoration(
        labelText: label,
        border: InputBorder.none,
        isDense: true,
      );

  /// One white rounded row with a purple icon on the left.
  Widget _field(IconData icon, Widget child, {VoidCallback? onTap}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SoftCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              IconBadge(icon, size: 38),
              const SizedBox(width: 14),
              Expanded(child: child),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final price = parsePrice(_price.text);
    final yearly = price == null
        ? null
        : Subscription(
            id: '', name: '', price: price, currency: _currency, cycle: _cycle,
            nextBillingDate: _next, anchorDay: _next.day, isTrial: false,
            category: '', colorValue: 0, cancelUrl: null, notes: '',
            remindDaysBefore: 0, createdAt: DateTime.now(),
          ).yearlyCost;
    final label = Theme.of(context).textTheme.bodySmall;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit Subscription' : 'Add Subscription'),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Remove',
              icon: Icon(Icons.delete_outline_rounded, color: cs.error),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
          children: [
            // Preview of the service
            Center(
              child: Column(
                children: [
                  ServiceAvatar(
                    name: _name.text.trim().isEmpty ? '?' : _name.text.trim(),
                    color: _color,
                    size: 76,
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            _field(
              Icons.label_rounded,
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: _bare('Service name'),
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    Icons.attach_money_rounded,
                    TextFormField(
                      controller: _price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _bare(_isTrial ? 'Price after trial' : 'Price'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          parsePrice(v ?? '') == null ? 'Enter a price' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 112,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SoftCard(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: DropdownButtonFormField<String>(
                        initialValue: _currency,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            border: InputBorder.none, isDense: true),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface),
                        items: [
                          for (final c in {...currencies, _currency})
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (v) =>
                            setState(() => _currency = v ?? _currency),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SoftCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconBadge(Icons.event_repeat_rounded, size: 38),
                        const SizedBox(width: 14),
                        Text('Billing Cycle', style: label),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<BillingCycle>(
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: cs.primary,
                          selectedForegroundColor: Colors.white,
                          side: BorderSide(color: cs.primary.withValues(alpha: 0.2)),
                          textStyle: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        segments: [
                          for (final c in BillingCycle.values)
                            ButtonSegment(value: c, label: Text(c.label)),
                        ],
                        selected: {_cycle},
                        onSelectionChanged: (s) => setState(() => _cycle = s.first),
                      ),
                    ),
                    if (yearly != null) ...[
                      const SizedBox(height: 10),
                      Pill('= ${formatMoney(yearly, _currency)} per year'),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SoftCard(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: const Color(0xFFFF8A00).withValues(alpha: 0.10),
                child: SwitchListTile(
                  value: _isTrial,
                  onChanged: (v) => setState(() => _isTrial = v),
                  secondary: const IconBadge(Icons.timer_rounded,
                      size: 38, color: Color(0xFFE07000)),
                  title: const Text('This is a free trial',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('We warn you before it starts charging'),
                ),
              ),
            ),
            _field(
              Icons.calendar_month_rounded,
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isTrial ? 'Trial ends on' : 'Renewal Date', style: label),
                        Text(formatDate(_next),
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_calendar_rounded, color: cs.primary),
                ],
              ),
              onTap: _pickDate,
            ),
            _field(
              Icons.notifications_active_rounded,
              DropdownButtonFormField<int>(
                initialValue: _remindDays,
                isExpanded: true,
                decoration: _bare('Reminder'),
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('On the day of renewal')),
                  DropdownMenuItem(value: 1, child: Text('1 day before renewal')),
                  DropdownMenuItem(value: 2, child: Text('2 days before renewal')),
                  DropdownMenuItem(value: 3, child: Text('3 days before renewal')),
                  DropdownMenuItem(value: 7, child: Text('1 week before renewal')),
                ],
                onChanged: (v) => setState(() => _remindDays = v ?? 1),
              ),
            ),
            _field(
              Icons.category_rounded,
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: _bare('Category'),
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'Other'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SoftCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconBadge(Icons.palette_rounded, size: 38),
                        const SizedBox(width: 14),
                        Text('Color', style: label),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in {_color, ...palette})
                          GestureDetector(
                            onTap: () => setState(() => _color = c),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Color(c),
                                borderRadius: BorderRadius.circular(10),
                                border: c == _color
                                    ? Border.all(color: cs.primary, width: 3)
                                    : null,
                              ),
                              child: c == _color
                                  ? const Icon(Icons.check_rounded,
                                      size: 18, color: Colors.white)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _field(
              Icons.link_rounded,
              TextFormField(
                controller: _cancelUrl,
                keyboardType: TextInputType.url,
                decoration: _bare('Cancel page link (optional)'),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty || webLink(t) != null) return null;
                  return 'Enter a web link, like netflix.com/cancel';
                },
              ),
            ),
            if (_cancelUrl.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: _openCancelPage,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open cancel page'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            _field(
              Icons.sticky_note_2_rounded,
              TextFormField(
                controller: _notes,
                maxLines: 3,
                minLines: 1,
                decoration: _bare('Notes (optional)'),
              ),
            ),
            SoftCard(
              color: cs.primary.withValues(alpha: 0.08),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFB300)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We\'ll send you a notification before your payment date, '
                      'even when the app is closed.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            GradientButton(
              label: _editing ? 'Save Changes' : 'Add Subscription',
              icon: Icons.check_rounded,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
