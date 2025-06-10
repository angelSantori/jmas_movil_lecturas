import 'package:flutter/material.dart';
import 'package:jmas_movil_lecturas/configs/controllers/orden_trabajo_controller.dart';
import 'package:jmas_movil_lecturas/configs/controllers/trabajo_realizado_controller.dart';
import 'package:jmas_movil_lecturas/configs/service/auth_service.dart';
import 'package:jmas_movil_lecturas/screens/general/login_screen.dart';
import 'package:jmas_movil_lecturas/screens/trabajos_realizados/trabajo_realizado_screen.dart';
import 'package:jmas_movil_lecturas/widgets/colores.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final TrabajoRealizadoController _trabajoRealizadoController =
      TrabajoRealizadoController();
  final OrdenTrabajoController _ordenTrabajoController =
      OrdenTrabajoController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? userName;
  int? userId;
  List<TrabajoRealizado> trabajos = [];
  bool isLoading = true;
  Map<int, OrdenTrabajo?> otCache = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final decodeToken = await _authService.decodeToken();
    setState(() {
      userName = decodeToken?['User_Name'];
      userId = int.tryParse(decodeToken?['Id_User']);
    });

    if (userId != null) {
      await _loadTrabajos(userId!);
    }
  }

  Future<void> _loadTrabajos(int userId) async {
    setState(() => isLoading = true);

    try {
      final listTrabajos = await _trabajoRealizadoController.getTRXUserID(
        userId,
      );

      otCache.clear();

      for (var trabajo in listTrabajos) {
        if (trabajo.idOrdenTrabajo != null &&
            !otCache.containsKey(trabajo.idOrdenTrabajo)) {
          final orden = await _ordenTrabajoController.getOrdenTrabajoXId(
            trabajo.idOrdenTrabajo!,
          );
          otCache[trabajo.idOrdenTrabajo!] = orden;
        }
      }

      setState(() {
        trabajos = listTrabajos;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error _loadTrabajos | HomeScreen: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Estás seguro de que quieres salir?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Salir'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _authService.clearAuthData();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Trabajos'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  if (userName != null)
                    Text(
                      userName ?? 'Usuario no disponible',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _logout(context);
              },
            ),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : trabajos.isEmpty
              ? const Center(child: Text('No tienes trabajos asignadas'))
              : RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    otCache.clear();
                  });
                  await _loadTrabajos(userId!);
                },
                child: ListView.builder(
                  itemCount: trabajos.length,
                  itemBuilder: (context, index) {
                    final trabajo = trabajos[index];
                    final ordenTrabajo =
                        trabajo.idOrdenTrabajo != null
                            ? otCache[trabajo.idOrdenTrabajo]
                            : null;

                    return Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(2, 4), // dirección de la sombra
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(4),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                getEstadoColor(ordenTrabajo?.estadoOT),
                                Colors.white,
                                Colors.white,
                                getPrioridadColor(ordenTrabajo!.prioridadOT),
                              ],
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              stops: [0.01, 0.4, 0.6, 0.95],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              'Trabajo: ${trabajo.folioTR ?? 'Sin folio'}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Orden de trabajo: ${ordenTrabajo.folioOT ?? 'Sin orden de trabajo'}',
                                  style: TextStyle(color: Colors.grey.shade900),
                                ),
                                const SizedBox(height: 4),

                                //Chip
                                if (ordenTrabajo.estadoOT != null &&
                                    ordenTrabajo.prioridadOT != null)
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          ordenTrabajo.prioridadOT!,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: getPrioridadColor(
                                          ordenTrabajo.prioridadOT,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          ordenTrabajo.estadoOT!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: getEstadoColor(
                                          ordenTrabajo.estadoOT,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final trabajoExistente = trabajos.firstWhere(
                                (t) =>
                                    t.idOrdenTrabajo ==
                                    ordenTrabajo.idOrdenTrabajo,
                                orElse: () => TrabajoRealizado(),
                              );
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TrabajoRealizadoScreen(
                                        ordenTrabajo: ordenTrabajo,
                                        trabajoRealizado:
                                            trabajoExistente
                                                        .idTrabajoRealizado !=
                                                    null
                                                ? trabajoExistente
                                                : null,
                                        isReadOnly:
                                            trabajoExistente.ubicacionTR != null
                                                ? false
                                                : true,
                                      ),
                                ),
                              );
                              if (result == true) {
                                await _loadTrabajos(userId!);
                                if (ordenTrabajo.idOrdenTrabajo != null) {
                                  final updateOrden =
                                      await _ordenTrabajoController
                                          .getOrdenTrabajoXId(
                                            ordenTrabajo.idOrdenTrabajo!,
                                          );
                                  setState(() {
                                    otCache[ordenTrabajo.idOrdenTrabajo!] =
                                        updateOrden;
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
