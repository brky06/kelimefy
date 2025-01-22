import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GrupKelimeListesi extends StatefulWidget {
  final String grupAdi;

  const GrupKelimeListesi({Key? key, required this.grupAdi}) : super(key: key);

  @override
  State<GrupKelimeListesi> createState() => _GrupKelimeListesiState();
}

class _GrupKelimeListesiState extends State<GrupKelimeListesi> {
  List<String> _kelimeler = [];
  Map<String, Map<String, String>> _kelimeDetaylari = {};
  List<String> _gruplar = [];
  String _seciliGrup = '';

  @override
  void initState() {
    super.initState();
    _gruplariYukle();
    _kelimeleriYukle();
  }

  Future<void> _gruplariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final tumGruplar = prefs.getStringList('gruplar') ?? ['Tüm Kelimeler'];

    if (mounted) {
      setState(() {
        _gruplar = tumGruplar;
        _seciliGrup = widget.grupAdi.isNotEmpty ? widget.grupAdi : tumGruplar.first;
      });
    }
  }

  Future<void> _kelimeleriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> grupKelimeler = [];

    if (_seciliGrup == 'Tüm Kelimeler') {
      grupKelimeler = prefs.getStringList("tum_kelimeler-kelimeler") ?? [];
    } else {
      grupKelimeler = prefs.getStringList('${_seciliGrup}-kelimeler') ?? [];
    }

    Map<String, Map<String, String>> detaylar = {};

    for (var kelimeSirali in grupKelimeler) {
      final kelime = kelimeSirali.split('-').last;

      detaylar[kelime] = {
        'anlam': prefs.getString('${kelime}_anlam') ?? 'Anlam bulunamadı.',
        'ornek': prefs.getString('${kelime}_örnek') ?? 'Örnek bulunamadı.',
        'grup': prefs.getString('${kelime}_grup') ?? 'Grup bilgisi yok.',
      };
    }

    if (mounted) {
      setState(() {
        _kelimeler = grupKelimeler.map((k) => k.split('-').last).toList();
        _kelimeDetaylari = detaylar;
      });
    }
  }

  Future<void> _kelimeyiSil(String kelime) async {
    final prefs = await SharedPreferences.getInstance();

    // Kelimeyi ve detaylarını kaldır
    await prefs.remove('${kelime}_anlam');
    await prefs.remove('${kelime}_örnek');
    await prefs.remove('${kelime}_grup');

    // Grubu güncelle
    final key = _seciliGrup == 'Tüm Kelimeler'
        ? "tum_kelimeler-kelimeler"
        : "${_seciliGrup}-kelimeler";
    List<String> grupKelimeler = prefs.getStringList(key) ?? [];
    grupKelimeler.removeWhere((k) => k.split('-').last == kelime);
    await prefs.setStringList(key, grupKelimeler);

    // Ekranı güncelle
    _kelimeleriYukle();
  }

  void _kelimeyiDuzenle(String kelime) {
    final detay = _kelimeDetaylari[kelime] ?? {};
    String seciliGrup = detay['grup'] ?? (_gruplar.isNotEmpty ? _gruplar.first : 'Tüm Kelimeler');

    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController anlamController =
        TextEditingController(text: detay['anlam']);
        final TextEditingController ornekController =
        TextEditingController(text: detay['ornek']);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Kelimeyi Düzenle: $kelime'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: anlamController,
                      decoration: const InputDecoration(labelText: 'Anlam'),
                    ),
                    TextField(
                      controller: ornekController,
                      decoration: const InputDecoration(labelText: 'Örnek'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: seciliGrup,
                      items: _gruplar.map((grup) {
                        return DropdownMenuItem<String>(
                          value: grup,
                          child: Text(grup),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          seciliGrup = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();

                    // Eski gruptan kelimeyi kaldır
                    if (detay['grup'] != null && detay['grup'] != 'Tüm Kelimeler') {
                      final eskiGrupKey = "${detay['grup']}-kelimeler";
                      List<String> eskiGrupKelimeler = prefs.getStringList(eskiGrupKey) ?? [];
                      eskiGrupKelimeler.removeWhere((k) => k.split('-').last == kelime);
                      await prefs.setStringList(eskiGrupKey, eskiGrupKelimeler);
                    }

                    // Yeni gruba kelimeyi ekle
                    if (seciliGrup != 'Tüm Kelimeler') {
                      final yeniGrupKey = "${seciliGrup}-kelimeler";
                      List<String> yeniGrupKelimeler = prefs.getStringList(yeniGrupKey) ?? [];
                      if (!yeniGrupKelimeler.any((k) => k.split('-').last == kelime)) {
                        yeniGrupKelimeler.add(kelime);
                        await prefs.setStringList(yeniGrupKey, yeniGrupKelimeler);
                      }
                    }

                    // Tüm kelimeler listesine ekle
                    final tumKelimelerKey = "tum_kelimeler-kelimeler";
                    List<String> tumKelimeler = prefs.getStringList(tumKelimelerKey) ?? [];
                    if (!tumKelimeler.any((k) => k.split('-').last == kelime)) {
                      tumKelimeler.add(kelime);
                      await prefs.setStringList(tumKelimelerKey, tumKelimeler);
                    }

                    // Kelime detaylarını kaydet
                    await prefs.setString('${kelime}_anlam', anlamController.text);
                    await prefs.setString('${kelime}_örnek', ornekController.text);
                    await prefs.setString('${kelime}_grup', seciliGrup);

                    _kelimeleriYukle();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelime Listesi',
            style: theme.textTheme.titleLarge,
        ),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: _seciliGrup,
                isExpanded: true,
                items: _gruplar.map((grup) {
                  return DropdownMenuItem<String>(
                    value: grup,
                    child: Text(
                      grup,
                      style: TextStyle(color: colorScheme.onBackground),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _seciliGrup = value;
                    });
                    _kelimeleriYukle();
                  }
                },
                dropdownColor: colorScheme.surfaceVariant,
              ),
            ),
            Expanded(
              child: _kelimeler.isEmpty
                  ? Center(
                child: Text(
                  'Bu grupta henüz kelime yok.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onBackground,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: _kelimeler.length,
                itemBuilder: (context, index) {
                  final kelime = _kelimeler[index];
                  final detay = _kelimeDetaylari[kelime] ?? {};
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      title: Text(
                        kelime,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Anlam: ${detay['anlam'] ?? 'Bilinmiyor'}'),
                          Text('Örnek: ${detay['ornek'] ?? 'Bilinmiyor'}'),
                          Text('Grup: ${detay['grup'] ?? 'Bilinmiyor'}'),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: colorScheme.primary,
                            onPressed: () {
                              _kelimeyiDuzenle(kelime);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: colorScheme.error,
                            onPressed: () {
                              _kelimeyiSil(kelime);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
