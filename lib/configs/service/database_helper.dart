import 'package:jmas_movil_lecturas/configs/controllers/orden_servicio_controller.dart';
import 'package:jmas_movil_lecturas/configs/controllers/trabajo_realizado_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return openDatabase(
      join(path, 'trabajos_realizados.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trabajos_realizados(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            idTrabajoRealizado INTEGER,
            folioTR TEXT,
            fechaTR TEXT,
            ubicacionTR TEXT,
            comentarioTR TEXT,
            fotoAntes64TR TEXT,
            fotoDespues64TR TEXT,
            fotoRequiereMaterial64TR TEXT,
            encuenstaTR INTEGER,
            idUserTR INTEGER,
            idOrdenServicio INTEGER,
            folioOS TEXT,
            padronNombre TEXT,
            padronDireccion TEXT,
            problemaNombre TEXT,
            idSalida INTEGER,
            sincronizado INTEGER DEFAULT 0,
            fechaModificacion TEXT
          )
        ''');

        //  Ordenes de Servicio
        await db.execute('''
        CREATE TABLE orden_servicio(
          idOrdenServicio INTEGER PRIMARY KEY,
          folioOS TEXT,
          fechaOS TEXT,
          materialOS INTEGER,
          estadoOS TEXT,
          prioridadOS TEXT,
          contactoOS INTEGER,
          idUser INTEGER,
          idPadron INTEGER,
          idTipoProblema INTEGER,
          idMedio INTEGER
        )
      ''');
      },
      version: 15,
    );
  }

  Future<bool> _ensureOrdenesTrabajoTableExists() async {
    final db = await database;
    try {
      await db.rawQuery('SELECT 1 FROM orden_servicio LIMIT 1');
      return true;
    } catch (e) {
      // Si falla, crear la tabla
      await db.execute('''
      CREATE TABLE IF NOT EXISTS orden_servicio(
        idOrdenServicio INTEGER PRIMARY KEY,
        folioOS TEXT,
        fechaOS TEXT,
        medioOS TEXT,
        materialOS INTEGER,
        estadoOS TEXT,
        prioridadOS TEXT,
        contactoOS INTEGER,
        idUser INTEGER,
        idPadron INTEGER,
        idTipoProblema INTEGER,
        idMedio INTEGER
      )
    ''');
      return false;
    }
  }

  Future<int> insertOrUpdateOrdenServicio(OrdenServicio orden) async {
    final db = await database;
    return await db.insert('orden_servicio', {
      'idOrdenServicio': orden.idOrdenServicio,
      'folioOS': orden.folioOS,
      'fechaOS': orden.fechaOS,
      'materialOS': orden.materialOS == true ? 1 : 0,
      'estadoOS': orden.estadoOS,
      'prioridadOS': orden.prioridadOS,
      'contactoOS': orden.contactoOS,
      'idUser': orden.idUser,
      'idPadron': orden.idPadron,
      'idTipoProblema': orden.idTipoProblema,
      'idMedio': orden.idMedio,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Obtener orden de trabajo por ID
  Future<OrdenServicio?> getOrdenServicio(int idOrdenServicio) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'orden_servicio',
        where: 'idOrdenServicio = ?',
        whereArgs: [idOrdenServicio],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return OrdenServicio.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error al obtener orden de servicio: $e');
      return null;
    }
  }

  Future<Map<int, OrdenServicio>> getOrdenesServicioCache() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('orden_servicio');
      final cache = <int, OrdenServicio>{};
      for (var map in maps) {
        try {
          final orden = OrdenServicio.fromMap(map);
          if (orden.idOrdenServicio != null) {
            cache[orden.idOrdenServicio!] = orden;
          }
        } catch (e) {
          print('Error al parsear orden de trabajo: $e');
        }
      }
      return cache;
    } catch (e) {
      print('Error al obtener órdenes de trabajo: $e');
      return {};
    }
  }

  Future<int> insertTrabajo(TrabajoRealizado trabajo) async {
    final db = await database;
    return await db.insert(
      'trabajos_realizados',
      trabajo.toMap()..addAll({
        'sincronizado': 0,
        'fechaModificacion': DateTime.now().toIso8601String(),
      }),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TrabajoRealizado>> getTrabajosNoSincronizados() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'trabajos_realizados',
      where: 'sincronizado = ?',
      whereArgs: [0],
      columns: [
        'idTrabajoRealizado',
        'folioTR',
        'fechaTR',
        'ubicacionTR',
        'comentarioTR',
        'fotoAntes64TR',
        'fotoDespues64TR',
        'fotoRequiereMaterial64TR',
        'encuenstaTR',
        'idUserTR',
        'idOrdenServicio',
        'folioOS',
        'padronNombre',
        'padronDireccion',
        'problemaNombre',
        'idSalida',
        'sincronizado',
        'fechaModificacion',
      ], // Excluye fotoAntes64TR y fotoDespues64TR
    );
    return List.generate(maps.length, (i) {
      return TrabajoRealizado.fromMap(maps[i]);
    });
  }

  Future<int> updateSincronizado(int id, bool sincronizado) async {
    final db = await database;
    return await db.update(
      'trabajos_realizados',
      {
        'sincronizado': sincronizado ? 1 : 0,
        'fechaModificacion': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTrabajo(int id) async {
    final db = await database;
    return await db.delete(
      'trabajos_realizados',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Future<int> clearTrabajos() async {
  //   final db = await database;
  //   return await db.delete('trabajos_realizados');
  // }

  Future<int> clearTrabajos() async {
    final db = await database;
    // Eliminar también los archivos de borradores
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    for (var file in files) {
      if (file.path.contains('trabajo_draft_')) {
        await file.delete();
      }
    }
    return await db.delete('trabajos_realizados');
  }

  Future<int> clearOrdenesServicio() async {
    final db = await database;
    try {
      final exists = await _ensureOrdenesTrabajoTableExists();
      if (exists) {
        return await db.delete('orden_servicio');
      }
      return 0;
    } catch (e) {
      print('Error clearing orden_servicio: $e');
      return 0;
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
