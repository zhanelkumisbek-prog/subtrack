import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/subscription.dart';
import '../models/user_model.dart';
import '../services/subscription_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class AddSubscriptionScreen extends StatefulWidget {
  final AppUser user;
  final Subscription? existing;

  const AddSubscriptionScreen({
    super.key,
    required this.user,
    this.existing,
  });

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _category = 'streaming';
  BillingCycle _billingCycle = BillingCycle.monthly;
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 30));
  bool _notificationsEnabled = true;
  bool _loading = false;

  PopularService? _selectedTemplate;

  final _subService = SubscriptionService();
  final _notifService = NotificationService();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final s = widget.existing!;
      _nameCtrl.text = s.name;
      _priceCtrl.text = s.price.toString();
      _notesCtrl.text = s.notes ?? '';
      _category = s.category;
      _billingCycle = s.billingCycle;
      _nextBillingDate = s.nextBillingDate;
      _notificationsEnabled = s.notificationsEnabled;
    } else {
      _notificationsEnabled = widget.user.notificationsEnabled;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _applyTemplate(PopularService service) {
    setState(() {
      _selectedTemplate = service;
      _nameCtrl.text = service.name;
      _priceCtrl.text = service.suggestedPrice.toStringAsFixed(2);
      _category = service.category;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final sub = Subscription(
        id: widget.existing?.id ?? const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        category: _category,
        price: double.parse(_priceCtrl.text),
        billingCycle: _billingCycle,
        nextBillingDate: _nextBillingDate,
        startDate: widget.existing?.startDate ?? DateTime.now(),
        notificationsEnabled: _notificationsEnabled,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (widget.existing != null) {
        await _subService.updateSubscription(widget.user.uid, sub);
      } else {
        await _subService.addSubscription(widget.user.uid, sub);
      }

      if (_notificationsEnabled) {
        await _notifService.scheduleBillingReminder(sub);
      } else {
        await _notifService.cancelSubscriptionNotification(sub.id);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.existing == null ? 'Новая подписка' : 'Редактировать'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accent,
                    ),
                  )
                : const Text(
                    'Сохранить',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.existing == null) ...[
                _buildTemplates(),
                const SizedBox(height: 28),
              ],
              _buildSection(
                'Основная информация',
                [
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Название сервиса',
                      prefixIcon:
                          Icon(Icons.label_outline, color: AppTheme.textMuted),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Введите название' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Цена',
                      prefixText: '\$ ',
                      prefixIcon:
                          Icon(Icons.attach_money, color: AppTheme.textMuted),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Введите цену';
                      if (double.tryParse(v) == null)
                        return 'Некорректное число';
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Категория',
                [_buildCategoryPicker()],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Периодичность',
                [_buildBillingCyclePicker()],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Дата следующего списания',
                [_buildDatePicker(context)],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Уведомления',
                [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Напоминания',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              'За 3 дня до списания',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _notificationsEnabled,
                        onChanged: (v) =>
                            setState(() => _notificationsEnabled = v),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Заметки (необязательно)',
                [
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Любые заметки о подписке...',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: Text(widget.existing == null
                      ? 'Добавить подписку'
                      : 'Сохранить изменения'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Популярные сервисы',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: popularServices.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final service = popularServices[i];
              final isSelected = _selectedTemplate?.name == service.name;
              return GestureDetector(
                onTap: () => _applyTemplate(service),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppTheme.accentGlow : AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppTheme.accent : AppTheme.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(service.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        service.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? AppTheme.accent
                              : AppTheme.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    const categories = [
      ('streaming', '🎬', 'Видео'),
      ('music', '🎵', 'Музыка'),
      ('gaming', '🎮', 'Игры'),
      ('productivity', '💼', 'Работа'),
      ('news', '📰', 'Новости'),
      ('fitness', '💪', 'Спорт'),
      ('cloud', '☁️', 'Облако'),
      ('other', '📦', 'Другое'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map(((String id, String emoji, String label) item) {
        final isSelected = _category == item.$1;
        return GestureDetector(
          onTap: () => setState(() => _category = item.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isSelected ? AppTheme.accentGlow : AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.accent : AppTheme.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.$2, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  item.$3,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isSelected ? AppTheme.accent : AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBillingCyclePicker() {
    return Row(
      children: BillingCycle.values.map((cycle) {
        final labels = {
          BillingCycle.weekly: 'Еженед.',
          BillingCycle.monthly: 'Ежемес.',
          BillingCycle.yearly: 'Ежегод.',
        };
        final isSelected = _billingCycle == cycle;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _billingCycle = cycle),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppTheme.accentGlow : AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.accent : AppTheme.border,
                ),
              ),
              child: Text(
                labels[cycle]!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _nextBillingDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 366)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.accent,
                surface: AppTheme.surfaceCard,
              ),
            ),
            child: child!,
          ),
        );
        if (date != null) setState(() => _nextBillingDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppTheme.textMuted, size: 20),
            const SizedBox(width: 12),
            Text(
              '${_nextBillingDate.day}.${_nextBillingDate.month.toString().padLeft(2, '0')}.${_nextBillingDate.year}',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
