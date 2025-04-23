import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';

// Importa el archivo de gestión de almacenamiento con condicional
import 'storage/storage_platform.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const CementCalcApp());
}

class CementCalcApp extends StatelessWidget {
  const CementCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cement Calc',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 22, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 20, color: Colors.white),
          bodySmall: TextStyle(fontSize: 18, color: Colors.white),
          titleMedium: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String input = '';
  String buttonClicked = '';
  List<int> numbers = [];
  int? indexToDelete;
  double surface = 1.0;
  double weight = 1.8;
  List<int> deletedHistory = [];

  bool classicMode = false;
  String digitMode = 'XX'; // opciones: 'XX' o 'XXX'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/cement_data.json');
  }

  Future<void> _loadData() async {
    if (kIsWeb) {
      final storedNumbers = getFromLocalStorage('numbers');
      final storedSurface = getFromLocalStorage('surface');
      final storedWeight = getFromLocalStorage('weight');
      final storedClassic = getFromLocalStorage('classicMode');
      final storedMode = getFromLocalStorage('digitMode');
      if (storedNumbers != null) numbers = List<int>.from(json.decode(storedNumbers));
      if (storedSurface != null) surface = double.tryParse(storedSurface) ?? 1.0;
      if (storedWeight != null) weight = double.tryParse(storedWeight) ?? 1.8;
      classicMode = storedClassic == 'true';
      if (storedMode == 'XX' || storedMode == 'XXX') digitMode = storedMode!;
    } else {
      try {
        final file = await _localFile;
        if (await file.exists()) {
          final content = json.decode(await file.readAsString());
          setState(() {
            numbers = List<int>.from(content['numbers']);
            surface = content['surface'] ?? 1.0;
            weight = content['weight'] ?? 1.8;
            classicMode = content['classicMode'] ?? false;
            if (content['digitMode'] == 'XX' || content['digitMode'] == 'XXX') {
              digitMode = content['digitMode'];
            }
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _saveData() async {
    if (kIsWeb) {
      saveToLocalStorage('numbers', json.encode(numbers));
      saveToLocalStorage('surface', surface.toString());
      saveToLocalStorage('weight', weight.toString());
      saveToLocalStorage('classicMode', classicMode.toString());
      saveToLocalStorage('digitMode', digitMode);
    } else {
      final file = await _localFile;
      final content = json.encode({
        'numbers': numbers,
        'surface': surface,
        'weight': weight,
        'classicMode': classicMode,
        'digitMode': digitMode,
      });
      await file.writeAsString(content);
    }
  }

  Future<void> _wipeData() async {
    if (kIsWeb) {
      clearLocalStorage();
    } else {
      final file = await _localFile;
      if (await file.exists()) await file.delete();
    }
    setState(() {
      numbers.clear();
      surface = 1.0;
      weight = 1.8;
      deletedHistory.clear();
      classicMode = false;
      digitMode = 'XX';
    });
  }

  void _addValueFromInput() {
    final parsed = int.tryParse(input);
    if (parsed != null) {
      setState(() {
        numbers.insert(0, parsed);
        input = '';
        buttonClicked = 'add';
      });
      _saveData();
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() => buttonClicked = '');
      });
    }
  }

  void _handleNumberClick(String value) {
    if (!classicMode) {
      final limit = digitMode == 'XX' ? 2 : 3;
      if (input.length < limit) {
        setState(() {
          input += value;
          buttonClicked = value;
        });
        if (input.length == limit) {
          _addValueFromInput();
        }
        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() => buttonClicked = '');
        });
      }
    } else {
      setState(() {
        input += value;
        buttonClicked = value;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() => buttonClicked = '');
      });
    }
  }

  void _handleDelete() {
    setState(() {
      input = input.isNotEmpty ? input.substring(0, input.length - 1) : '';
      buttonClicked = 'del';
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => buttonClicked = '');
    });
  }

  void _handleAdd() {
    if (input.isEmpty) return;
    _addValueFromInput();
  }

  void _handleUndo() {
    if (deletedHistory.isNotEmpty) {
      setState(() {
        numbers.insert(0, deletedHistory.removeAt(0));
      });
      _saveData();
    }
  }

  void _confirmDelete(int index) {
    setState(() => indexToDelete = index);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete value?', style: TextStyle(color: Colors.red)),
        content: Text('You are about to delete the value ${numbers[index]}. Are you sure?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              setState(() {
                deletedHistory.insert(0, numbers[indexToDelete!]);
                numbers.removeAt(indexToDelete!);
              });
              _saveData();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      // Alterna entre modos y limpia buffer
      digitMode = digitMode == 'XX' ? 'XXX' : 'XX';
      buttonClicked = 'mode';
      input = ''; // limpia buffer al cambiar de modo
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() => buttonClicked = '');
    });
    _saveData();
  }

  void _openConfigDialog() {
    // Animación live del switch con StatefulBuilder
    bool localClassic = classicMode;
    final surfaceController = TextEditingController(text: surface.toString());
    final weightController = TextEditingController(text: weight.toString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Settings', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: surfaceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Surface (m²)', labelStyle: TextStyle(color: Colors.white)),
              ),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Specific Weight', labelStyle: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Classic mode', style: TextStyle(color: Colors.white)),
                value: localClassic,
                onChanged: (val) => setStateDialog(() => localClassic = val),
                activeColor: Colors.green,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text('Confirm wipe', style: TextStyle(color: Colors.red)),
                      content: const Text('Are you sure you want to delete all data?', style: TextStyle(color: Colors.white)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), 
                        TextButton(onPressed: () { 
                          _wipeData(); 
                          Navigator.pop(context); 
                          Navigator.pop(context);
                        }, child: const Text('WIPE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: TextButton.styleFrom(backgroundColor: Colors.red)),
                      ],
                    ),
                  );
                },
                child: const Text('WIPE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
             TextButton(
              child: const Text('Save'),
              onPressed: () {
                setState(() {
                  classicMode = localClassic;
                  input = ''; // limpia buffer al cambiar Classic Mode
                });
                surface = double.tryParse(surfaceController.text.replaceAll(',', '.')) ?? surface;
                weight = double.tryParse(weightController.text.replaceAll(',', '.')) ?? weight;
                _saveData();
                Navigator.pop(ctx);
              },
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = numbers.isEmpty ? 0 : numbers.reduce((a, b) => a + b) / numbers.length;
    final result = media * surface * weight;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    classicMode ? 'Cement Calc' : (digitMode == 'XX' ? '2 digits mode' : '3 digits mode'),
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  Row(
                    children: [
                      IconButton(onPressed: _handleUndo, icon: SvgPicture.asset('assets/undo.svg', width: 24, height: 24)),
                      IconButton(onPressed: _openConfigDialog, icon: SvgPicture.asset('assets/settings.svg', width: 24, height: 24), tooltip: '⚙️ Settings'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 60,
                width: double.infinity,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                child: Text(input.isEmpty ? '0' : input, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 20),
              Expanded(
                flex: 0,
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2,
                  children: [
                    ...List.generate(9, (i) => _buildGridButton((i+1).toString())),
                    _buildGridButton('0'),
                    _buildGridButton('Del', isDel: true, onPressed: _handleDelete),
                    if (classicMode)
                      _buildGridButton('Add', color: Colors.green, onPressed: _handleAdd)
                    else
                      _buildGridButton('Mode', color: Colors.orange, onPressed: _toggleMode),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [const Text('AVERAGE', style: TextStyle(fontSize: 10, color: Colors.white)), Text('${media.toStringAsFixed(2)} mm', style: const TextStyle(fontSize: 16, color: Colors.white))],
                  ),
                  Text('${numbers.length}', style: const TextStyle(fontSize: 16, color: Colors.red)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [const Text('CEMENT', style: TextStyle(fontSize: 10, color: Colors.white)), Text('${result.toStringAsFixed(2)} Kg', style: const TextStyle(fontSize: 16, color: Colors.white))],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 2.5),
                  itemCount: numbers.length,
                  itemBuilder: (context, index) => GestureDetector(onTap: () => _confirmDelete(index), child: Container(alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)), child: Text(numbers[index].toString(), style: const TextStyle(color: Colors.white))))
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridButton(String label, {bool isDel = false, Color? color, VoidCallback? onPressed}) {
    final isClicked = buttonClicked == label.toLowerCase();
    return GestureDetector(
      onTap: onPressed ?? () => _handleNumberClick(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: isDel ? (isClicked ? Colors.red.shade700 : Colors.red.shade500) : (color != null ? (isClicked ? color.withOpacity(0.8) : color) : (isClicked ? Colors.blue.shade700 : Colors.blue.shade900)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
      ),
    );
  }
}
