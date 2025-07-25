import 'package:flutter/material.dart';
import 'package:jmas_movil_lecturas/configs/controllers/orden_servicio_controller.dart';
import 'package:jmas_movil_lecturas/configs/controllers/trabajo_realizado_controller.dart';
import 'package:jmas_movil_lecturas/configs/service/auth_service.dart';
import 'package:jmas_movil_lecturas/configs/service/database_helper.dart';
import 'package:jmas_movil_lecturas/screens/general/login_screen.dart';
import 'package:jmas_movil_lecturas/screens/general/sync_screen.dart';
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
  final OrdenServicioController _ordenServicioController =
      OrdenServicioController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? userName;
  int? userId;
  List<TrabajoRealizado> trabajos = [];
  bool isLoading = true;
  Map<int, OrdenServicio?> otCache = {};
  bool _hasDataDownloaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkDataDownloaded();
  }

  Future<void> _loadUserData() async {
    final decodeToken = await _authService.decodeToken();
    setState(() {
      userName = decodeToken?['User_Name'];
      userId = int.tryParse(decodeToken?['Id_User']);
    });

    if (userId != null) {
      await _loadLocalTrabajos();
    }
  }

  Future<void> _checkDataDownloaded() async {
    final trabajos = await _dbHelper.getTrabajosNoSincronizados();
    final trabajosPendientes =
        trabajos
            .where(
              (t) =>
                  (t.fechaTR == null || t.fechaTR!.isEmpty) &&
                  (t.ubicacionTR == null || t.ubicacionTR!.isEmpty),
            )
            .toList();

    setState(() {
      _hasDataDownloaded = trabajosPendientes.isNotEmpty;
    });
  }

  Future<void> _loadLocalTrabajos() async {
    setState(() {
      isLoading = true;
      trabajos.clear();
      otCache.clear();
    });

    try {
      final listTrabajos = await _trabajoRealizadoController.getLocalTrabajos();
      final tempCache = <int, OrdenServicio>{};

      // Primero cargar todas las órdenes necesarias
      for (var trabajo in listTrabajos) {
        if (trabajo.idOrdenServicio != null &&
            !tempCache.containsKey(trabajo.idOrdenServicio)) {
          try {
            final orden = await _dbHelper.getOrdenServicio(
              trabajo.idOrdenServicio!,
            );
            if (orden != null) {
              tempCache[trabajo.idOrdenServicio!] = orden;
            } else {
              final ordenServidor = await _ordenServicioController
                  .getOrdenServicioXId(trabajo.idOrdenServicio!);
              if (ordenServidor != null) {
                await _dbHelper.insertOrUpdateOrdenServicio(ordenServidor);
                tempCache[trabajo.idOrdenServicio!] = ordenServidor;
              }
            }
          } catch (e) {
            print('Error al cargar orden ${trabajo.idOrdenServicio}: $e');
          }
        }
      }

      // Filtra solo trabajos pendientes (sin fechaTR o sin ubicaciónTR)
      final trabajosPendientes =
          listTrabajos
              .where(
                (t) =>
                    (t.fechaTR == null || t.fechaTR!.isEmpty) &&
                    (t.ubicacionTR == null || t.ubicacionTR!.isEmpty) &&
                    t.idOrdenServicio != null,
              )
              .toList();

      if (mounted) {
        setState(() {
          trabajos = trabajosPendientes;
          otCache = tempCache;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error en _loadLocalTrabajos: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
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
                onPressed: () async {
                  await _dbHelper.clearTrabajos();
                  await _dbHelper.clearOrdenesServicio();
                  Navigator.pop(context, true);
                },
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
        title: const Text('Tareas'),
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
              leading: const Icon(Icons.sync),
              title: const Text('Sincronización'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SyncScreen()),
                );
                if (result == true) {
                  await _checkDataDownloaded();
                  await _loadLocalTrabajos();
                }
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
          !_hasDataDownloaded
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No hay tareas descargadas'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SyncScreen(),
                          ),
                        );
                        if (result == true) {
                          await _checkDataDownloaded();
                          await _loadLocalTrabajos();
                        }
                      },
                      child: const Text('Descargar tareas'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadLocalTrabajos,
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : trabajos.isEmpty
                        ? const Center(
                          child: Text('No tienes trabajos asignadas'),
                        )
                        : ListView.builder(
                          itemCount: trabajos.length,
                          itemBuilder: (context, index) {
                            final trabajo = trabajos[index];
                            final ordenTrabajo =
                                trabajo.idOrdenServicio != null
                                    ? otCache[trabajo.idOrdenServicio]
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
                                    offset: Offset(
                                      2,
                                      4,
                                    ), // dirección de la sombra
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadiusGeometry.circular(4),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        getEstadoColor(ordenTrabajo?.estadoOS),
                                        Colors.white,
                                        Colors.white,
                                        getPrioridadColor(
                                          ordenTrabajo?.prioridadOS,
                                        ),
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Orden de trabajo: ${ordenTrabajo?.folioOS ?? 'Cargado...'}',
                                          style: TextStyle(
                                            color: Colors.grey.shade900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),

                                        //Chip
                                        if (ordenTrabajo != null &&
                                            ordenTrabajo.estadoOS != null &&
                                            ordenTrabajo.prioridadOS != null)
                                          Row(
                                            children: [
                                              Chip(
                                                label: Text(
                                                  ordenTrabajo.prioridadOS!,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    getPrioridadColor(
                                                      ordenTrabajo.prioridadOS,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Chip(
                                                label: Text(
                                                  ordenTrabajo.estadoOS!,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                backgroundColor: getEstadoColor(
                                                  ordenTrabajo.estadoOS,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () async {
                                      if (ordenTrabajo == null) return;
                                      final trabajoEspecifico = trabajo;

                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  TrabajoRealizadoScreen(
                                                    ordenServicio: ordenTrabajo,
                                                    trabajoRealizado:
                                                        trabajoEspecifico,
                                                    isReadOnly:
                                                        ordenTrabajo.estadoOS ==
                                                                'Revisión'
                                                            ? true
                                                            : false,
                                                  ),
                                        ),
                                      );
                                      if (result == true) {
                                        await _loadLocalTrabajos();
                                        if (ordenTrabajo.idOrdenServicio !=
                                            null) {
                                          final updateOrden =
                                              await _ordenServicioController
                                                  .getOrdenServicioXId(
                                                    ordenTrabajo
                                                        .idOrdenServicio!,
                                                  );
                                          setState(() {
                                            otCache[ordenTrabajo
                                                    .idOrdenServicio!] =
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
