import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/perfil_info.dart';
import 'package:provider/provider.dart';
import 'package:meteo_garden/models/dades_usr.dart';

class City {
  final String code;
  final String name;

  City({required this.code, required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(code: json['code'], name: json['name']);
  }

  // MOLT IMPORTANT: Afegim això perquè el Dropdown sàpiga comparar les ciutats
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class PerfilEditPage extends StatefulWidget {
  final PerfilInfo profile;

  const PerfilEditPage({super.key, required this.profile});

  @override
  State<PerfilEditPage> createState() => _PerfilEditPageState();
}

class _PerfilEditPageState extends State<PerfilEditPage> {
  late TextEditingController usernameController;
  final TextEditingController ciutatSearchController = TextEditingController();
  
  List<City> cities = [];
  City? selectedCity;
  bool isLoading = true; // Per mostrar l'indicador de càrrega mentre fem la crida
  String? language; // Per guardar l'idioma seleccionat

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.profile.username);
    language = widget.profile.language;
    fetchCities();
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  Future<void> fetchCities() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/stations/'),
      );

      if (response.statusCode == 200) {
        final List<City> fetchedCities = (jsonDecode(response.body) as List)
            .map((e) => City.fromJson(e))
            .toList();

        setState(() {
          cities = fetchedCities;
          
          selectedCity = null; // Per defecte ho deixem buit
          for (var c in cities) {
            if (c.name == widget.profile.city) {
              selectedCity = c;
              ciutatSearchController.text = c.name;
              break; // Hem trobat la ciutat, parem de buscar
            }
          }
          
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        debugPrint("Error a l'API: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error carregant ciutats: $e");
    }
  }

  void _actualitzar() async {
 
    
    final url = Uri.parse("http://127.0.0.1:8000/api/edit_profile/");
    //en emulador es: 10.0.2.2:8000
    //en web es: 127.0.0.1:8000

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json",
      "Authorization": "Token ${Provider.of<UserModel>(context, listen: false).token}"},
      body: jsonEncode({
        'username': usernameController.text,
        'city': selectedCity?.name,
        'language': language,
        'stationCode': selectedCity?.code,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      debugPrint("perfil actualitzat");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil actualitzat')));

      Provider.of<UserModel>(context, listen: false).updateProfile(
        newUsername: usernameController.text, newCity: selectedCity?.name,newLanguage: language);

      Navigator.pop(context);

    } else {
      debugPrint("Error: ${response.body}");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error actualitzant el perfil')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Creem l'estil base perquè tots els camps siguin iguals
    final defaultDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.green.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Modificar perfil')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Mostrem un carregant
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // CAMP 1: USUARI
                  TextField(
                    controller: usernameController,
                    // Apliquem l'estil i li afegim el text
                    decoration: defaultDecoration.copyWith(labelText: 'Usuari'),
                  ),
                  const SizedBox(height: 16),
                  
                  // CAMP 2: CIUTAT
                  DropdownMenu<City>(
                    initialSelection: selectedCity,
                    controller: ciutatSearchController,
                    requestFocusOnTap: true,
                    enableFilter: true,
                    expandedInsets: EdgeInsets.zero,
                    label: const Text('Ciutat'),
                    // El DropdownMenu fa servir un Theme en comptes d'InputDecoration, 
                    // però hi posem els mateixos valors
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: Colors.green.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    dropdownMenuEntries: cities.map<DropdownMenuEntry<City>>((City city) {
                      return DropdownMenuEntry<City>(
                        value: city,
                        label: city.name,
                      );
                    }).toList(),
                    onSelected: (City? city) {
                      setState(() {
                        selectedCity = city;
                      });
                      // HEM ELIMINAT L'UNFOCUS D'AQUÍ PER EVITAR L'ERROR
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // CAMP 3: IDIOMA
                  DropdownButtonFormField<String>(
                    value: language,
                    // Apliquem exactament el mateix estil
                    decoration: defaultDecoration.copyWith(labelText: 'Idioma'),
                    items: ['Català', 'Castellano', 'English']
                        .map(
                          (lang) => DropdownMenuItem(value: lang, child: Text(lang)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        language = value;
                      });
                    },
                  ),

                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      _actualitzar();
                    },
                    child: const Text('Guardar canvis'),
                  ),
                ],
              ),
            ),
    );
  }
}