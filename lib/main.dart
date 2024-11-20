import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light; // Default to light mode

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: CurrencyConverterApp(toggleTheme: _toggleTheme),
    );
  }
}

class CurrencyConverterApp extends StatefulWidget {
  final VoidCallback toggleTheme;

  const CurrencyConverterApp({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _CurrencyConverterAppState createState() => _CurrencyConverterAppState();
}

class _CurrencyConverterAppState extends State<CurrencyConverterApp> {
  final TextEditingController accountController = TextEditingController();
  final String _apiKey = 'f88d6131fd75a3d0d5667982'; // Replace with your actual API key
  final String _baseUrl = 'https://v6.exchangerate-api.com/v6';
  Map<String, dynamic>? currencyRates;
  String? _selectedValue;
  double convertedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    final String url = '$_baseUrl/$_apiKey/latest/PKR';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['result'] == 'success') {
          setState(() {
            currencyRates = data['conversion_rates'];
            _selectedValue = currencyRates!.keys.first; // Set default dropdown value
          });
        } else {
          throw Exception('Error: ${data['error-type']}');
        }
      } else {
        throw Exception('Failed to fetch rates: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading exchange rates: $e')),
      );
    }
  }

  void _convertCurrency() {
    if (accountController.text.isEmpty || _selectedValue == null || currencyRates == null) return;

    final inputAmount = double.tryParse(accountController.text) ?? 0.0;
    final rate = currencyRates![_selectedValue!];

    setState(() {
      convertedAmount = inputAmount * rate;
    });
  }

  void _clearInput() {
    setState(() {
      accountController.clear();
      convertedAmount = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white24,
        title: const Text('Currency Converter App'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: accountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter amount in PKR',
              ),
            ),
            const SizedBox(height: 16),
            if (currencyRates != null)
              DropdownButton<String>(
                value: _selectedValue,
                isExpanded: true,
                items: currencyRates!.keys.map((currency) {
                  return DropdownMenuItem<String>(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedValue = value;
                  });
                },
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _convertCurrency,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text(
                'Convert',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Converted Amount: ${_selectedValue != null ? _selectedValue! : ''} ${convertedAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearInput,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shadowColor: Colors.black,
                elevation: 5,
              ),
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
