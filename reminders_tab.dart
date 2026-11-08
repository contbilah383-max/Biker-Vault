import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _typeLabels = {
  'oil': 'الفيدانج',
  'insurance': 'التأمين',
  'inspection': 'الكونترول التقني',
  'vignette': 'الفينييت',
  'other': 'آخر',
};

class RemindersTab extends StatefulWidget {
  const RemindersTab({super.key});

  @override
  State<RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<RemindersTab> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _db
          .from('reminders')
          .select('*, bikes(brand, model)')
          .order('due_date', ascending: true);
      _items = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _toast('خطأ: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _add() async {
    List<Map<String, dynamic>> bikes;
    try {
      bikes = List<Map<String, dynamic>>.from(await _db.from('bikes').select());
    } catch (e) {
      _toast('خطأ: $e');
      return;
    }
    if (bikes.isEmpty) {
      _toast('زيد دراجة فالأول من قسم الكراج');
      return;
    }

    String bikeId = bikes.first['id'] as String;
    String type = 'oil';
    DateTime due = DateTime.now().add(const Duration(days: 30));
    final note = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('تذكير جديد'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                value: bikeId,
                decoration: const InputDecoration(labelText: 'الدراجة'),
                items: [
                  for (final b in bikes)
                    DropdownMenuItem(
                        value: b['id'] as String,
                        child: Text('${b['brand']} ${b['model']}')),
                ],
                onChanged: (v) => setS(() => bikeId = v!),
              ),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'النوع'),
                items: [
                  for (final e in _typeLabels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setS(() => type = v!),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text(due.toString().split(' ').first),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: due,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setS(() => due = d);
                },
              ),
              TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)')),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حفظ')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    try {
      await _db.from('reminders').insert({
        'bike_id': bikeId,
        'type': type,
        'due_date': due.toIso8601String().split('T').first,
        'note': note.text.trim().isEmpty ? null : note.text.trim(),
      });
      await _load();
    } catch (e) {
      _toast('خطأ: $e');
    }
  }

  Future<void> _toggle(Map<String, dynamic> r) async {
    try {
      await _db
          .from('reminders')
          .update({'done': !(r['done'] == true)}).eq('id', r['id']);
      await _load();
    } catch (e) {
      _toast('خطأ: $e');
    }
  }

  Future<void> _delete(String id) async {
    try {
      await _db.from('reminders').delete().eq('id', id);
      await _load();
    } catch (e) {
      _toast('خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_alert),
        label: const Text('زيد تذكير'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('ما كاين حتى تذكير.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final r = _items[i];
                      final due = DateTime.parse(r['due_date'] as String);
                      final done = r['done'] == true;
                      final daysLeft = due
                          .difference(DateTime(today.year, today.month, today.day))
                          .inDays;
                      final bike = r['bikes'] as Map<String, dynamic>?;
                      final overdue = !done && daysLeft < 0;
                      final soon = !done && daysLeft >= 0 && daysLeft <= 7;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: Checkbox(
                              value: done, onChanged: (_) => _toggle(r)),
                          title: Text(
                            _typeLabels[r['type']] ?? '',
                            style: TextStyle(
                                decoration:
                                    done ? TextDecoration.lineThrough : null),
                          ),
                          subtitle: Text(
                            '${bike != null ? '${bike['brand']} ${bike['model']} • ' : ''}'
                            '${r['due_date']}'
                            '${r['note'] != null ? '\n${r['note']}' : ''}',
                          ),
                          isThreeLine: r['note'] != null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (overdue)
                                const Text('فات الوقت',
                                    style: TextStyle(color: Colors.red))
                              else if (soon)
                                Text('$daysLeft ي',
                                    style:
                                        const TextStyle(color: Colors.orange)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(r['id'] as String),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
