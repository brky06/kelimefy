import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flip_card/flip_card.dart';

class KelimeCalis extends StatefulWidget {
  const KelimeCalis({Key? key}) : super(key: key);

  @override
  State<KelimeCalis> createState() => _KelimeCalisState();
}

class _KelimeCalisState extends State<KelimeCalis> {
  String _gosterilecekKelime = '';
  String _anlam = '';
  String _ornek = '';
  String _grup = '';
  int _sira = 0;
  String _seciliGrup = 'Tüm Kelimeler';
  List<String> _gruplar = ['Tüm Kelimeler'];

  @override
  void initState() {
    super.initState();
    _loadGruplar();
    _kelimeGetir();
  }

  Future<void> _loadGruplar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gruplar = prefs.getStringList('gruplar') ?? ['Tüm Kelimeler'];
      _seciliGrup = _gruplar[0];
    });
  }

  Future<void> _kelimeGetir() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> grupKelimeler = [];

    if (_seciliGrup == 'Tüm Kelimeler') {
      grupKelimeler = prefs.getStringList('tum_kelimeler-kelimeler') ?? [];
    } else {
      grupKelimeler = prefs.getStringList('${_seciliGrup}-kelimeler') ?? [];
    }

    if (grupKelimeler.isNotEmpty) {
      final kelimeSirali = grupKelimeler[_sira % grupKelimeler.length];
      final kelime = kelimeSirali.split('-').last;

      setState(() {
        _gosterilecekKelime = kelime;
        _anlam = prefs.getString('${kelime}_anlam') ?? 'Anlam bulunamadı.';
        _ornek = prefs.getString('${kelime}_örnek') ?? 'Örnek bulunamadı.';
        _grup = prefs.getString('${kelime}_grup') ?? 'Grup bilgisi yok.';
      });
    } else {
      setState(() {
        _gosterilecekKelime = 'Bu grupta henüz kelime yok.';
        _anlam = '';
        _ornek = '';
        _grup = '';
      });
    }
  }

  void _sonrakiKelime() {
    setState(() {
      _sira++;
      _kelimeGetir();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelime Çalış'),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButton<String>(
                isExpanded: true,
                value: _seciliGrup,
                items: _gruplar.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _seciliGrup = newValue!;
                    _sira = 0;
                    _kelimeGetir();
                  });
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FlipCard(
                  flipOnTouch: true,
                  direction: FlipDirection.HORIZONTAL,
                  front: _buildCardFace(
                    colorScheme.surfaceVariant,
                    _gosterilecekKelime,
                    colorScheme.onSurface,
                    32.0,
                  ),
                  back: _buildCardFace(
                    colorScheme.primaryContainer,
                    _kartArkaYuzContent(),
                    colorScheme.onPrimaryContainer,
                    16.0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _sonrakiKelime,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Sonraki Kelime'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardFace(Color backgroundColor, dynamic content, Color textColor, double fontSize) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: content is String
              ? Text(
            content,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          )
              : content,
        ),
      ),
    );
  }

  Widget _kartArkaYuzContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _infoText('Anlam', _anlam),
        const SizedBox(height: 10),
        _infoText('Örnek', _ornek),
        const SizedBox(height: 10),
        _infoText('Grup', _grup),
      ],
    );
  }

  Widget _infoText(String title, String content) {
    return RichText(
      text: TextSpan(
        text: "$title: ",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        children: [
          TextSpan(
            text: content,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
