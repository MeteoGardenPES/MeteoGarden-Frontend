import 'package:flutter/material.dart';
import 'package:meteo_garden/screens/home_shell.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:meteo_garden/models/dades_usr.dart';

class CreaNovaConta extends StatefulWidget {
  const CreaNovaConta({super.key});

  @override
  State<CreaNovaConta> createState() => _CreaNovaContaState();
}

class City {
  final String code;
  final String name;

  City({required this.code, required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(code: json['code'], name: json['name']);
  }
}

class _CreaNovaContaState extends State<CreaNovaConta> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  //final TextEditingController cityController = TextEditingController();
  String? city;
  //final TextEditingController languageController = TextEditingController();
  String? language;
  final TextEditingController nomjardiController = TextEditingController();
  List<dynamic> cities = [];
  City? selectedCity;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    emailController.dispose();
    //cityController.dispose();
    //languageController.dispose();
    nomjardiController.dispose();
    super.dispose();
  }

  void _submit() async {
    final url = Uri.parse("http://127.0.0.1:8000/api/register/");
    //en emulador es: 10.0.2.2:8000
    //en web es: 127.0.0.1:8000

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'username': usernameController.text,
        'password': passwordController.text,
        'email': emailController.text,
        //'city': cityController.text,
        'city': selectedCity?.name,
        //'language': languageController.text,
        'language': language,
        'stationCode': selectedCity?.code,
        'gardenName': nomjardiController.text,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      debugPrint("Cuenta creada");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Compte creat')));

      Provider.of<UserModel>(
        context,
        listen: false,
      ).setToken(jsonDecode(response.body)['token']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else {
      debugPrint("Error: ${response.body}");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error creant el compte')));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCities();
  }

  Future<void> fetchCities() async {
    //consulta de la uri per obtenir les ciuats: // $_baseUrl/api/stations/
    // retorna el codi i el nom de la ciutat
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/stations/'),
    );

    if (response.statusCode == 200) {
      setState(() {
        cities = (jsonDecode(response.body) as List)
            .map((e) => City.fromJson(e))
            .toList();
      });
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.green.withValues(alpha: 0.04),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Colors.green.withValues(alpha: 0.06),
        width: 1.4,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear compte')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: _inputDecoration('Nom d\'usuari'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration('Email'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _inputDecoration('Contrasenya'),
                  ),
                  const SizedBox(height: 16),
                  cities.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<City>(
                          initialValue: selectedCity,
                          decoration: _inputDecoration('Ciutat'),
                          items: cities.map((city) {
                            return DropdownMenuItem<City>(
                              value: city,
                              child: Text(city.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCity = value;
                            });
                          },
                        ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: language,
                    decoration: _inputDecoration('Idioma'),
                    items: ['Català', 'Castellano', 'English']
                        .map(
                          (lang) =>
                              DropdownMenuItem(value: lang, child: Text(lang)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        language = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  //const SizedBox(height: 24),
                  TextField(
                    controller: nomjardiController,
                    decoration: _inputDecoration('Nom del jardi'),
                  ),
                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14.0),
                      child: Text(
                        'Crear compte',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
