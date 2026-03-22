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
  
  List<City> cities = [];
  City? selectedCity;
  bool isLoading = true; // Per mostrar l'indicador de càrrega mentre fem la crida
  String? language; // Per guardar l'idioma seleccionat

  @override
  void initState() {
    super.initState();
    // Inicialitzem el controlador amb el nom d'usuari actual
    usernameController = TextEditingController(text: widget.profile.username);
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
          
          // Busquem la ciutat a la llista que coincideixi amb la del perfil de l'usuari.
          // Aquí suposem que profile.city guarda el 'name' o el 'code'. 
          // Ajusta-ho si profile.city guarda el codi de l'estació en comptes del nom.
          try {
            selectedCity = cities.firstWhere((city) => city.name == widget.profile.city);
          } catch (e) {
            // Si l'usuari té una ciutat que ja no existeix a l'API o està buida
            selectedCity = null; 
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modificar perfil')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Mostrem un carregant
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Usuari'),
                    controller: usernameController,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<City>(
                    initialValue: selectedCity,
                    decoration: const InputDecoration(labelText: 'Ciutat'),
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: language,
                    decoration: const InputDecoration(labelText: 'Idioma'),
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

                  
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      Provider.of<UserModel>(context, listen: false).
                      updateProfile(newUsername: usernameController.text,
                      newCity: selectedCity?.name, newLanguage: language);
                      Navigator.pop(context);
                    },
                    child: const Text('Guardar canvis'),
                  ),
                ],
              ),
            ),
    );
  }
}