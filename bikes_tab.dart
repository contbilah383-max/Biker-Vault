import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BikesTab extends StatefulWidget {
  const BikesTab({super.key});

  @override
  State<BikesTab> createState() => _BikesTabState();
}

class _BikesTabState extends State<BikesTab> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _bikes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data =
          await _db.from('bikes').select().order('created_at', ascending: false);
      _bikes = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _toast('خطأ: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addBike() async {
    final brand = TextEditingController();
    final model = TextEditingController();
    final year = TextEditingController();
    final mileage = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('زيد دراجة'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: brand,
                decoration: const InputDecoration(labelText: 'الماركة (Yamaha...)')),
            TextField(
                controller: model,
                decoration: const InputDecoration(labelText: 'الموديل (MT-07...)')),
            TextField(
                controller: year,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السنة')),
            TextField(
                controller: mileage,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'الكيلومترات')),
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
    );

    if (ok != true) return;
    if (brand.text.trim().isEmpty || model.text.trim().isEmpty) {
      _toast('الماركة والموديل ضروريين');
      return;
    }
    try {
      await _db.from('bikes').insert({
        'brand': brand.text.trim(),
        'model': model.text.trim(),
        'year': int.tryParse(year.text),
        'mileage': int.tryParse(mileage.text) ?? 0,
      });
      await _load();
    } catch (e) {
      _toast('خطأ: $e');
    }
  }

  Future<void> _delete(String id) async {
    try {
      await _db.from('bikes').delete().eq('id', id);
      await _load();
    } catch (e) {
      _toast('خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBike,
        icon: const Icon(Icons.add),
        label: const Text('زيد دراجة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bikes.isEmpty
              ? const Center(child: Text('ما عندك حتى دراجة. زيد الأولى!'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: _bikes.length,
                    itemBuilder: (context, i) {
                      final b = _bikes[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.two_wheeler,
                              color: Colors.deepOrange),
                          title: Text('${b['brand']} ${b['model']}'),
                          subtitle: Text(
                              '${b['year'] ?? '-'} • ${b['mileage'] ?? 0} كلم'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(b['id'] as String),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
