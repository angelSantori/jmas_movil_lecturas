import 'package:flutter/material.dart';
import 'package:jmas_movil_lecturas/configs/controllers/orden_servicio_controller.dart';
import 'package:jmas_movil_lecturas/configs/controllers/trabajo_realizado_controller.dart';
import 'package:jmas_movil_lecturas/configs/service/auth_service.dart';
import 'package:jmas_movil_lecturas/configs/service/database_helper.dart';
import 'package:jmas_movil_lecturas/widgets/mensajes.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final AuthService _authService = AuthService();
  final TrabajoRealizadoController _trabajoRealizadoCntr =
      TrabajoRealizadoController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final OrdenServicioController _ordenServicioController =
      OrdenServicioController();

  bool _isSyncing = false;
  int _pendingSyncs = 0;
  int _syncedItems = 0;
  bool _hasDownloadedData = false;

  @override
  void initState() {
    super.initState();
    _loadPendingSyncs();
  }

  Future<void> _loadPendingSyncs() async {
    final trabajos = await _dbHelper.getTrabajosNoSincronizados();
    setState(() {
      _pendingSyncs = trabajos.length;
    });
  }

  Future<void> _syncData() async {
    setState(() {
      _isSyncing = true;
      _syncedItems = 0;
    });

    try {
      final trabajos = await _dbHelper.getTrabajosNoSincronizados();
      final trabajosCompletos =
          trabajos
              .where(
                (t) =>
                    t.fotoAntes64TR != null &&
                    t.fotoAntes64TR!.isNotEmpty &&
                    t.fotoDespues64TR != null &&
                    t.fotoDespues64TR!.isNotEmpty &&
                    t.comentarioTR != null &&
                    t.comentarioTR!.isNotEmpty &&
                    t.encuenstaTR != null &&
                    t.encuenstaTR! > 0,
              )
              .toList();

      for (final trabajo in trabajosCompletos) {
        try {
          bool success;
          if (trabajo.idTrabajoRealizado == null ||
              trabajo.idTrabajoRealizado == 0) {
            success = await _trabajoRealizadoCntr.addTrabajoRealizado(trabajo);
          } else {
            success = await _trabajoRealizadoCntr.editTrabajoRealizado(trabajo);
          }

          if (success) {
            // Actualizar estado de la orden a "Revisión"
            if (trabajo.idOrdenServicio != null) {
              final orden = await _ordenServicioController.getOrdenServicioXId(
                trabajo.idOrdenServicio!,
              );
              if (orden != null) {
                final ordenActualizada = orden.copyWith(estadoOS: 'Revisión');
                await _ordenServicioController.editOrdenServicio(
                  ordenActualizada,
                );
                await _dbHelper.insertOrUpdateOrdenServicio(ordenActualizada);
              }
            }

            // Eliminar el trabajo localmente
            await _dbHelper.deleteTrabajo(trabajo.idTrabajoRealizado!);

            setState(() {
              _syncedItems++;
            });
          }
        } catch (e) {
          print('Error al sincronizar trabajo: $e');
        }
      }

      if (mounted) {
        final mensaje =
            trabajosCompletos.isEmpty
                ? 'No hay trabajos completos para sincronizar'
                : 'Sincronización completada: $_syncedItems de ${trabajosCompletos.length} items';

        showOk(context, mensaje);
        await _loadPendingSyncs();
      }
    } catch (e) {
      if (mounted) {
        showError(context, 'Error durante la sincronización: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _downloadData() async {
    setState(() {
      _isSyncing = true;
      _hasDownloadedData = false;
    });

    try {
      final user = await _authService.getUserData();
      if (user != null && user.id_User != null) {
        // Limpiar ambas tablas
        try {
          await _dbHelper.clearTrabajos();
        } catch (e) {
          print('Error al limpiar trabajos: $e');
        }

        try {
          await _dbHelper.clearOrdenesServicio();
        } catch (e) {
          print('Error al limpiar órdenes: $e');
          // Si la tabla no existe, no es un error crítico
        }

        // Descargar trabajos
        final trabajos = await _trabajoRealizadoCntr.getTRXUserEmptyID(
          user.id_User!,
        );

        // Descargar y guardar órdenes de trabajo
        for (final trabajo in trabajos) {
          if (trabajo.idOrdenServicio != null) {
            try {
              final orden = await _ordenServicioController.getOrdenServicioXId(
                trabajo.idOrdenServicio!,
              );
              if (orden != null) {
                await _dbHelper.insertOrUpdateOrdenServicio(orden);
              }
            } catch (e) {
              print('Error al descargar orden ${trabajo.idOrdenServicio}: $e');
            }
          }
          await _dbHelper.insertTrabajo(trabajo);
        }

        if (mounted) {
          setState(() {
            _hasDownloadedData = true;
          });
          await showOk(context, 'Datos descargados correctamente');
          await _loadPendingSyncs();
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        print('Error al descargar datos: $e');
        showAdvertence(
          context,
          'Error al descargar datos. Verifica tu conexión.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronización'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _hasDownloadedData);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.sync, size: 50, color: Colors.blue),
                    const SizedBox(height: 10),
                    Text(
                      'Pendientes por sincronizar: $_pendingSyncs',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_download),
              label: const Text('Descargar tareas del servidor'),
              onPressed: _isSyncing ? null : _downloadData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Subir tareas realizadas'),
              onPressed: _isSyncing || _pendingSyncs == 0 ? null : _syncData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (_isSyncing) ...[
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                _syncedItems > 0
                    ? 'Sincronizando... $_syncedItems items'
                    : 'Procesando...',
              ),
            ],
            if (_hasDownloadedData) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Volver a tareas'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
