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

  // Modos de dígito: X (1), XX (2), XXX (3)
  String digitMode = 'XX';

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
      final sn = getFromLocalStorage('numbers');
      final ss = getFromLocalStorage('surface');
      final sw = getFromLocalStorage('weight');
      final sm = getFromLocalStorage('digitMode');
      if (sn != null) numbers = List<int>.from(json.decode(sn));
      if (ss != null) surface = double.tryParse(ss) ?? surface;
      if (sw != null) weight = double.tryParse(sw) ?? weight;
      if (['X', 'XX', 'XXX'].contains(sm)) digitMode = sm!;
    } else {
      try {
        final file = await _localFile;
        if (await file.exists()) {
          final data = json.decode(await file.readAsString());
          setState(() {
            numbers = List<int>.from(data['numbers']);
            surface = data['surface'] ?? surface;
            weight = data['weight'] ?? weight;
            if (['X', 'XX', 'XXX'].contains(data['digitMode'])) {
              digitMode = data['digitMode'];
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
      saveToLocalStorage('digitMode', digitMode);
    } else {
      final file = await _localFile;
      await file.writeAsString(json.encode({
        'numbers': numbers,
        'surface': surface,
        'weight': weight,
        'digitMode': digitMode,
      }));
    }
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
      Future.delayed(const Duration(milliseconds: 100), () => setState(() => buttonClicked = ''));
    }
  }

  void _handleNumberClick(String value) {
    final limit = digitMode == 'X' ? 1 : (digitMode == 'XX' ? 2 : 3);
    if (input.length < limit) {
      setState(() {
        input += value;
        buttonClicked = value.toLowerCase();
      });
      if (input.length == limit) _addValueFromInput();
      Future.delayed(const Duration(milliseconds: 100), () => setState(() => buttonClicked = ''));
    }
  }

  void _handleDelete() {
    setState(() {
      input = input.isNotEmpty ? input.substring(0, input.length - 1) : '';
      buttonClicked = 'del';
    });
    Future.delayed(const Duration(milliseconds: 100), () => setState(() => buttonClicked = ''));
  }

  void _handleAdd() {
    if (input.isEmpty) return;
    _addValueFromInput();
  }

  void _setDigitMode(String mode) {
    setState(() {
      digitMode = mode;
      input = '';
      buttonClicked = 'mode';
    });
    _saveData();
    Future.delayed(const Duration(milliseconds: 100), () => setState(() => buttonClicked = ''));
  }

  void _handleUndo() {
    if (deletedHistory.isNotEmpty) {
      setState(() {
        numbers.insert(0, deletedHistory.removeAt(0));
      });
      _saveData();
    }
  }

  // Limpia todos los datos guardados
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
      digitMode = 'XX';
      input = '';
    });
  }

  void _confirmDelete(int index) {
    setState(() => indexToDelete = index);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete value?', style: TextStyle(color: Colors.red)),
        content: Text('Are you sure you want to delete ${numbers[index]}?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              setState(() {
                deletedHistory.insert(0, numbers.removeAt(indexToDelete!));
              });
              _saveData();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _openConfigDialog() {
    bool localClassic = false;
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
                decoration: const InputDecoration(labelText: 'Surface (m²)', labelStyle: TextStyle(color: Colors.white)),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Specific Weight', labelStyle: TextStyle(color: Colors.white)),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  _wipeData();
                  Navigator.pop(ctx);
                },
                style: TextButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('WIPE', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                setState(() {
                  surface = double.tryParse(surfaceController.text.replaceAll(',', '.')) ?? surface;
                  weight = double.tryParse(weightController.text.replaceAll(',', '.')) ?? weight;
                });
                _saveData();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avg = numbers.isEmpty ? 0.0 : numbers.reduce((a, b) => a + b) / numbers.length;
    final cement = avg * surface * weight;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mode: $digitMode', style: const TextStyle(color: Colors.white, fontSize: 18)),
                  Row(
                    children: [
                      IconButton(onPressed: _handleUndo, icon: SvgPicture.asset('assets/undo.svg', width: 24, height:24)),
                      IconButton(onPressed: _openConfigDialog, icon: SvgPicture.asset('assets/settings.svg', width:24, height:24)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height:10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal:16),
                height:60,
                width:double.infinity,
                decoration: BoxDecoration(color:Colors.white12,borderRadius:BorderRadius.circular(10)),
                alignment: Alignment.centerRight,
                child: Text(input.isEmpty?'0':input,style:const TextStyle(color:Colors.white,fontSize:32,fontWeight:FontWeight.bold)),
              ),
              const SizedBox(height:20),
              GridView.count(
                shrinkWrap:true,
                physics:const NeverScrollableScrollPhysics(),
                crossAxisCount:3,
                mainAxisSpacing:10,
                crossAxisSpacing:10,
                childAspectRatio:2,
                children:[
                  ...List.generate(9,(i)=>_buildGridButton((i+1).toString())),
                  _buildGridButton('0'),
                  _buildGridButton('Del',isDel:true,onPressed:_handleDelete),
                  _buildGridButton('Add',color:Colors.green,onPressed:_handleAdd),
                ],
              ),
              const SizedBox(height:10),
              Row(
                mainAxisAlignment:MainAxisAlignment.spaceEvenly,
                children:[
                  Expanded(child:_buildGridButton('X',color:Colors.orange,onPressed:()=>_setDigitMode('X'))),
                  const SizedBox(width:8),
                  Expanded(child:_buildGridButton('XX',color:Colors.orange,onPressed:()=>_setDigitMode('XX'))),
                  const SizedBox(width:8),
                  Expanded(child:_buildGridButton('XXX',color:Colors.orange,onPressed:()=>_setDigitMode('XXX'))),
                ],
              ),
              const Divider(color:Colors.white24,height:30),
              Row(
                mainAxisAlignment:MainAxisAlignment.spaceBetween,
                children:[
                  Column(
                    crossAxisAlignment:CrossAxisAlignment.start,
                    children:[
                      const Text('AVERAGE',style:TextStyle(color:Colors.white54,fontSize:12)),
                      Text('${avg.toStringAsFixed(2)} mm',style:const TextStyle(color:Colors.white,fontSize:16)),
                    ],
                  ),
                  Text('${numbers.length}',style:const TextStyle(color:Colors.red,fontSize:16)),
                  Column(
                    crossAxisAlignment:CrossAxisAlignment.end,
                    children:[
                      const Text('CEMENT',style:TextStyle(color:Colors.white54,fontSize:12)),
                      Text('${cement.toStringAsFixed(2)} Kg',style:const TextStyle(color:Colors.white,fontSize:16)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height:10),
              Expanded(
                child:GridView.builder(
                  gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:4,
                    mainAxisSpacing:4,
                    crossAxisSpacing:4,
                    childAspectRatio:2.5,
                  ),
                  itemCount: numbers.length,
                  itemBuilder:(context,idx)=>GestureDetector(
                    onTap:()=>_confirmDelete(idx),
                    child:Container(
                      alignment:Alignment.center,
                      decoration:BoxDecoration(color:Colors.white12,borderRadius:BorderRadius.circular(8)),
                      child:Text(numbers[idx].toString(),style:const TextStyle(color:Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridButton(String label,{bool isDel=false,Color? color,VoidCallback? onPressed}){
    final clicked = buttonClicked.toLowerCase()==label.toLowerCase();
    return GestureDetector(
      onTap:onPressed??()=>_handleNumberClick(label),
      child:AnimatedContainer(
        duration:const Duration(milliseconds:100),
        decoration:BoxDecoration(
          color:isDel
            ?(clicked?Colors.red.shade700:Colors.red.shade500)
            :(color!=null
                ?(clicked?color.withOpacity(0.8):color)
                :(clicked?Colors.blue.shade700:Colors.blue.shade900)),
          borderRadius:BorderRadius.circular(14),
          boxShadow:const [BoxShadow(color:Colors.black45,blurRadius:4)],
        ),
        alignment:Alignment.center,
        child:Text(label,style:const TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.bold)),
      ),
    );
  }
}
