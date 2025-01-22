import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Gruplar extends StatefulWidget {
  const Gruplar({Key? key}) : super(key: key);

  @override
  State<Gruplar> createState() => _GruplarState();
}

class _GruplarState extends State<Gruplar> {
  final TextEditingController _groupNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<String> _gruplar = ['Tüm Kelimeler'];
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadGruplar();
  }

  void _loadGruplar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gruplar = prefs.getStringList('gruplar') ?? ['Tüm Kelimeler'];
    });
  }

  void _saveGruplar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('gruplar', _gruplar);
  }

  void _addGrup() {
    if (!_formKey.currentState!.validate()) return;

    String yeniGrup = _groupNameController.text.trim();
    if (_gruplar.contains(yeniGrup)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu grup zaten mevcut.')),
      );
      return;
    }

    setState(() {
      _gruplar.add(yeniGrup);
      _groupNameController.clear();
      _isButtonEnabled = false;
      _saveGruplar();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grup başarıyla eklendi!')),
    );
  }

  void _deleteGrup(int index) async {
    if (_gruplar[index] == 'Tüm Kelimeler') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm Kelimeler grubunu silemezsiniz.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String silinecekGrup = _gruplar[index];

    setState(() {
      _gruplar.removeAt(index);
      _saveGruplar();
    });

    prefs.remove('$silinecekGrup-kelimeler');

    final tumKelimeler = prefs.getStringList('Tüm Kelimeler-kelimeler') ?? [];
    final updatedKelimeler = tumKelimeler
        .where((kelime) => prefs.getString('${kelime}_grup') != silinecekGrup)
        .toList();
    await prefs.setStringList('Tüm Kelimeler-kelimeler', updatedKelimeler);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grup başarıyla silindi!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gruplar'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.surface, colorScheme.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.4, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    labelText: 'Grup Adı',
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                  style: TextStyle(color: colorScheme.onSurface),
                  onChanged: (value) {
                    setState(() {
                      _isButtonEnabled = value.trim().isNotEmpty;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Grup adı boş olamaz.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isButtonEnabled ? _addGrup : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Grup Ekle'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _gruplar.length,
                  itemBuilder: (context, index) {
                    return Dismissible(
                      key: Key(_gruplar[index]),
                      confirmDismiss: (direction) async {
                        if (_gruplar[index] == 'Tüm Kelimeler') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tüm Kelimeler grubunu silemezsiniz.')),
                          );
                          return false;
                        }
                        return true;
                      },
                      onDismissed: (direction) {
                        _deleteGrup(index);
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary,
                            child: Text(
                              _gruplar[index][0],
                              style: TextStyle(color: colorScheme.onPrimary),
                            ),
                          ),
                          title: Text(
                            _gruplar[index],
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                          trailing: _gruplar[index] == 'Tüm Kelimeler'
                              ? null
                              : const Icon(Icons.delete, color: Colors.red),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
