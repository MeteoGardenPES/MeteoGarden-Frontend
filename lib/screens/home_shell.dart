import 'package:flutter/material.dart';

import 'garden_page.dart';
import 'album_page.dart';
import 'missions_page.dart';
import 'perfil_page.dart';
import 'photo_page.dart';
import 'inventory_page.dart';
import 'friends_page.dart';

import 'package:provider/provider.dart';
import '../models/dades_usr.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final username = Provider.of<UserModel>(context).username;

    final List<Widget> pages = [
      GardenPage(username: "laia", gardenName: "jardin1"),
      FriendsPage(),
      PhotoPage(),
      MissionsPage(),
      PerfilPage(),
      InventoryPage(baseUrl: "http://127.0.0.1:8000", username: username),
      AlbumPage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_florist),
            label: 'Jardí',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Amics'),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Camera'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Missions'),
          BottomNavigationBarItem(icon: Icon(Icons.person_2), label: 'Perfil'),
        ],
      ),
    );
  }
}
