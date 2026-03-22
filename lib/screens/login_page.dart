import 'package:flutter/material.dart';
import 'package:meteo_garden/screens/home_shell.dart';
import 'package:meteo_garden/screens/crea_nova_conta.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:meteo_garden/models/dades_usr.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  void _login() async {
    final url = Uri.parse(
      "http://127.0.0.1:8000/api/login/",
    ); // url del endpoint de login al backend

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": usernameController.text,
        "password": passwordController.text,
      }),
    );
    if (!mounted) return;
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Provider.of<UserModel>(context, listen: false).setToken(data['token']);
      await _fetchAndSaveProfile(data['token']);
      if (!mounted) return;
      _goToHome();
    } else {
      debugPrint("Error: ${response.body}");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error de login')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.withValues(alpha: 0.12), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withValues(alpha: 0.92),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          color: Colors.black.withValues(alpha: 0.05),
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _LoginHeader(),
                        const SizedBox(height: 24),
                        _InputField(
                          controller: usernameController,
                          label: "Nom d'usuari",
                          hint: "Introdueix el teu nom d'usuari",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _InputField(
                          controller: passwordController,
                          label: "Contrasenya",
                          hint: "Introdueix la teva contrasenya",
                          icon: Icons.lock_outline,
                          obscureText: true,
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _login, // _goToHome,//
                            icon: const Icon(Icons.login),
                            label: const Text("Iniciar sessió"),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // login with social providers and link to create account
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'o continuar amb',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // TODO: implementar login amb Google
                                    },
                                    icon: const Icon(Icons.g_mobiledata),
                                    label: const Text('Google'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // TODO: implementar login amb Facebook
                                    },
                                    icon: const Icon(Icons.facebook),
                                    label: const Text('Facebook'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1877F2),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CreaNovaConta(),
                                    ),
                                  );
                                },
                                child: const Text('Crear compte'),
                              ),
                            ],
                          ),
                        ),

                        Center(
                          child: TextButton(
                            onPressed: () {},
                            child: const Text("Has oblidat la contrasenya?"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchAndSaveProfile(String token) async {
    final url = Uri.parse("http://127.0.0.1:8000/api/get_profile/");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Token $token",
      },
    );

    if (!mounted) return;

    debugPrint("PROFILE STATUS: ${response.statusCode}");
    debugPrint("PROFILE BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      Provider.of<UserModel>(context, listen: false).setProfile(
        newUsername: data['username'] ?? '',
        newEmail: data['email'] ?? '',
        newCity: data['city'] ?? '',
        newLanguage: data['language'] ?? '',
        newLastEntry: data['lastEntry'] ?? '',
        newNumPlantsCollected: data['numPlantsCollected'] ?? 0,
        newMonedes: data['coins'] ?? 0,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No s\'ha pogut carregar el perfil')),
      );
    }
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(5),
          child: Image.asset('assets/images/logo.png', width: 150),
        ),
        const SizedBox(height: 18),
        const Text(
          "Benvinguda a MeteoGarden",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          "Inicia sessió per continuar cuidant el teu jardí.",
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  //final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    //this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          //keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.green.withValues(alpha: 0.04),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.green.withValues(alpha: 0.6),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
