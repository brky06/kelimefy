import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KelimeEkle extends StatefulWidget {
  const KelimeEkle({Key? key}) : super(key: key);

  @override
  State<KelimeEkle> createState() => _KelimeEkleState();
}

class _KelimeEkleState extends State<KelimeEkle> {
  final _formKey = GlobalKey<FormState>();
  String _selectedGroup = 'Tüm Kelimeler';
  List<String> _gruplar = ['Tüm Kelimeler'];

  late TextEditingController _kelimeController;
  late TextEditingController _kelimeAnlamiController;
  late TextEditingController _ornekCumleController;

  @override
  void initState() {
    super.initState();
    _kelimeController = TextEditingController();
    _kelimeAnlamiController = TextEditingController();
    _ornekCumleController = TextEditingController();
    _loadGruplar();
  }

  @override
  void dispose() {
    _kelimeController.dispose();
    _kelimeAnlamiController.dispose();
    _ornekCumleController.dispose();
    super.dispose();
  }

  Future<void> _loadGruplar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gruplar = prefs.getStringList('gruplar') ?? ['Tüm Kelimeler'];
      _selectedGroup = _gruplar[0];
    });
  }

  Future<void> _addWord() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final kelime = _kelimeController.text.trim();

      final tumKelimeler = prefs.getStringList('tum_kelimeler-kelimeler') ?? [];
      if (tumKelimeler.any((k) => k.split('-').last == kelime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kelime "$kelime" zaten mevcut!')),
        );
        return;
      }

      final tumKelimelerSira = (prefs.getInt('tum_kelimeler-sira') ?? 0) + 1;
      tumKelimeler.add('$tumKelimelerSira-$kelime');
      await prefs.setStringList('tum_kelimeler-kelimeler', tumKelimeler);
      await prefs.setInt('tum_kelimeler-sira', tumKelimelerSira);

      if (_selectedGroup != 'Tüm Kelimeler') {
        final grupKelimeler = prefs.getStringList('$_selectedGroup-kelimeler') ?? [];
        final grupKelimelerSira = (prefs.getInt('$_selectedGroup-sira') ?? 0) + 1;
        grupKelimeler.add('$grupKelimelerSira-$kelime');
        await prefs.setStringList('$_selectedGroup-kelimeler', grupKelimeler);
        await prefs.setInt('$_selectedGroup-sira', grupKelimelerSira);
      }

      await prefs.setString('${kelime}_anlam', _kelimeAnlamiController.text.trim());
      await prefs.setString('${kelime}_örnek', _ornekCumleController.text.trim());
      await prefs.setString('${kelime}_grup', _selectedGroup);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kelime "$kelime" eklendi! Grup: $_selectedGroup')),
      );

      _kelimeController.clear();
      _kelimeAnlamiController.clear();
      _ornekCumleController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Kelime Ekle',
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.background, theme.colorScheme.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.8),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      TextFormField(
                        controller: _kelimeController,
                        decoration: InputDecoration(
                          labelText: 'Kelime',
                          labelStyle: theme.textTheme.bodyLarge
                              ?.copyWith(color: theme.colorScheme.primary),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Kelime alanı boş bırakılamaz'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _kelimeAnlamiController,
                        decoration: InputDecoration(
                          labelText: 'Kelime Anlamı',
                          labelStyle: theme.textTheme.bodyLarge
                              ?.copyWith(color: theme.colorScheme.primary),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Kelime anlamı alanı boş bırakılamaz'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ornekCumleController,
                        decoration: InputDecoration(
                          labelText: 'Örnek Cümle',
                          labelStyle: theme.textTheme.bodyLarge
                              ?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGroup,
                        decoration: InputDecoration(
                          labelText: 'Grup Adı',
                          labelStyle: theme.textTheme.bodyLarge,
                        ),
                        items: _gruplar.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: theme.textTheme.bodyLarge),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGroup = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _addWord,
                        style: theme.elevatedButtonTheme.style?.copyWith(
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 16)),
                          backgroundColor:
                          MaterialStateProperty.all(theme.colorScheme.primary),
                          foregroundColor:
                          MaterialStateProperty.all(theme.colorScheme.onPrimary),
                        ),
                        child: const Text('Kelimeyi Ekle'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
