import 'package:flutter/material.dart';
import 'package:meteo_garden/screens/album_page.dart';

import '../../models/garden.dart';
import '../../models/weather_info.dart';
import '../../services/garden_service.dart';
import '../../services/weather_service.dart';
import '../../widgets/pot_widget.dart';
import '../../widgets/weather_card.dart';
import 'botiga_page.dart';
import 'inventory_page.dart';
import '../../widgets/pot_info_sheet.dart';
import '../../widgets/seed_selection_sheet.dart';
import '../../models/seed_option.dart';

import 'package:provider/provider.dart';
import '../models/dades_usr.dart';

class GardenPage extends StatefulWidget {
  final String username;
  final String gardenName;

  const GardenPage({
    super.key,
    required this.username,
    required this.gardenName,
  });

  @override
  State<GardenPage> createState() => _GardenPageState();
}

class _GardenPageState extends State<GardenPage> {
  late final GardenService _gardenService;
  Future<WeatherInfo>? _weatherFuture;
  late Future<List<GardenPot>> _potsFuture;

  @override
  void initState() {
    super.initState();

    _gardenService = GardenService(baseUrl: "http://127.0.0.1:8000");

    _potsFuture = _gardenService.fetchGardenPlants(
      username: widget.username,
      gardenName: widget.gardenName,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserModel>(context, listen: false);

      setState(() {
        _weatherFuture = WeatherService.fetchCurrent(city: user.city);
      });
    });
  }

  void _refreshWeather() {
    final user = Provider.of<UserModel>(context, listen: false);
    //print("CIUTAT: ${user.city}"); // continuar aqui
    setState(() {
      _weatherFuture = WeatherService.fetchCurrent(city: user.city);
    });
  }

  void _refreshGarden() {
    setState(() {
      _potsFuture = _gardenService.fetchGardenPlants(
        username: widget.username,
        gardenName: widget.gardenName,
      );
    });
  }

  void onTapPot(GardenPot pot) {
    if (!pot.occupied || pot.plant == null) {
      _showSeedSelection(pot);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => PotInfoSheet(
        pot: pot,
        onWater: () async {
          try {
            final missatge = await _gardenService.waterPlant(
              username: widget.username,
              gardenName: widget.gardenName,
              potNumber: pot.potNumber,
            );

            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(missatge)));
            _refreshGarden();
          } catch (e) {
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceFirst('Exception: ', '')),
              ),
            );
          }
        },
        onCollect: () async {
          try {
            final missatge = await _gardenService.collectPlant(
              username: widget.username,
              gardenName: widget.gardenName,
              potNumber: pot.potNumber,
              scientificName: pot.plant!.scientificName,
            );

            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(missatge)));
            _refreshGarden();
          } catch (e) {
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceFirst('Exception: ', '')),
              ),
            );
          }
        },
      ),
    );
  }

  void _showSeedSelection(GardenPot pot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return FutureBuilder<List<SeedOption>>(
          future: _gardenService.fetchSeeds(widget.username),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snap.hasError) {
              return Container(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Text(
                  "Error carregant llavors:\n${snap.error}",
                  textAlign: TextAlign.center,
                ),
              );
            }

            final seeds = snap.data ?? [];

            return SeedSelectionSheet(
              pot: pot,
              seeds: seeds,
              username: widget.username,
              gardenName: widget.gardenName,
              gardenService: _gardenService,
              onPlantingSuccess: _refreshGarden,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    final username = user.username;
    final monedes = user.monedes;
    final h = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/imatge_fondo1.png',
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 120,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/coin.png',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$monedes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_weatherFuture != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            right: 12,
            child: FutureBuilder<WeatherInfo>(
              future: _weatherFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return WeatherCard(
                    nomEstacio: "",
                    title: "Carregant meteo...",
                    subtitle: "Espera un moment",
                    trailing: const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    onRefresh: _refreshWeather,
                  );
                }

                if (snap.hasError) {
                  return WeatherCard(
                    nomEstacio: "",
                    title: "No s'ha pogut carregar la meteo",
                    subtitle: " ",
                    trailing: const Icon(Icons.warning_amber_rounded),
                    onRefresh: _refreshWeather,
                  );
                }

                final w = snap.data!;
                return WeatherCard(
                  nomEstacio: w.stationName,
                  title:
                      "Temperatura: ${w.temp.toStringAsFixed(1)}°C · Precipitació: ${w.precipitation}",
                  subtitle: "Vent: ${w.wind.toStringAsFixed(1)} m/s",
                  trailing: const Icon(Icons.refresh),
                  onRefresh: _refreshWeather,
                );
              },
            ),
          ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SizedBox(
            height: h * 0.50,
            child: FutureBuilder<List<GardenPot>>(
              future: _potsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.hasError) {
                  return Center(
                    child: Text(
                      "Error carregant els tests:\n${snap.error}",
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final pots = snap.data!;

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 32,
                    mainAxisSpacing: 32,
                    childAspectRatio: 1,
                  ),
                  itemCount: pots.length,
                  itemBuilder: (context, index) {
                    final pot = pots[index];
                    return PotWidget(pot: pot, onTap: () => onTapPot(pot));
                  },
                );
              },
            ),
          ),
        ),

        Positioned(
          right: 0,
          top: MediaQuery.of(context).size.height * 0.24,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const BotigaPage()));
              },
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Image.asset('assets/images/botiga.png', width: 150),
              ),
            ),
          ),
        ),

        Positioned(
          left: 2,
          top: MediaQuery.of(context).size.height * 0.14,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InventoryPage(
                    baseUrl: "http://127.0.0.1:8000",
                    username: username,
                  ),
                ),
              );
            },
            child: Image.asset('assets/images/inventory_imagen.png', width: 80),
          ),
        ),

        Positioned(
          left: 2,
          top: MediaQuery.of(context).size.height * 0.225,
          child: GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AlbumPage()));
            },
            child: Image.asset('assets/images/album_image.png', width: 80),
          ),
        ),
      ],
    );
  }
}
