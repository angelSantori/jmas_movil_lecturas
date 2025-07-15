import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jmas_movil_lecturas/configs/controllers/orden_servicio_controller.dart';
import 'package:jmas_movil_lecturas/configs/controllers/salidas_controller.dart';
import 'package:jmas_movil_lecturas/configs/controllers/trabajo_realizado_controller.dart';
import 'package:jmas_movil_lecturas/configs/service/database_helper.dart';
import 'package:jmas_movil_lecturas/screens/trabajos_realizados/widgets_tr.dart';
import 'package:jmas_movil_lecturas/widgets/formularios.dart';
import 'package:jmas_movil_lecturas/widgets/mensajes.dart';
import 'package:path_provider/path_provider.dart';

class TrabajoRealizadoScreen extends StatefulWidget {
  final OrdenServicio ordenServicio;
  final TrabajoRealizado? trabajoRealizado;
  final bool isReadOnly;

  const TrabajoRealizadoScreen({
    super.key,
    required this.ordenServicio,
    this.trabajoRealizado,
    this.isReadOnly = false,
  });

  @override
  State<TrabajoRealizadoScreen> createState() => _TrabajoRealizadoScreenState();
}

class _TrabajoRealizadoScreenState extends State<TrabajoRealizadoScreen> {
  TextEditingController _comentarioController = TextEditingController();

  String? _ubicacion;
  String? _fotoAntesPath;
  String? _fotoDespuesPath;
  String? _nombreCalle;
  String? _nombreColonia;
  bool _isLoading = false;
  Salidas? _salida;
  final _formKey = GlobalKey<FormState>();
  bool _hasExistingData = false;

  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _comentarioController = TextEditingController();
    _getCurrentLocation();
    _loadInitialData();
    _comentarioController.addListener(_saveDraftData);
    _loadDraftData();
  }

  Future<void> _loadDraftData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/trabajo_draft_${widget.trabajoRealizado?.idTrabajoRealizado ?? widget.ordenServicio.idOrdenServicio}.json',
      );

      if (await file.exists()) {
        final draftData = json.decode(await file.readAsString());

        // Solo cargar si el borrador corresponde a esta tarea
        if (draftData['idOrdenServicio'] ==
                widget.ordenServicio.idOrdenServicio &&
            (draftData['idTrabajoRealizado'] ==
                    widget.trabajoRealizado?.idTrabajoRealizado ||
                widget.trabajoRealizado?.idTrabajoRealizado == null)) {
          setState(() {
            _comentarioController.text = draftData['comentario'] ?? '';
            _ubicacion = draftData['ubicacion'] ?? _ubicacion;
            _fotoAntesPath = draftData['fotoAntesPath'];
            _fotoDespuesPath = draftData['fotoDespuesPath'];
            _rating = draftData['rating'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error cargando borrador: $e');
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    _comentarioController.clear();

    // Cargar datos existentes si hay un trabajo realizado
    if (widget.trabajoRealizado != null) {
      setState(() {
        _comentarioController.text =
            widget.trabajoRealizado!.comentarioTR ?? '';
        _ubicacion = widget.trabajoRealizado!.ubicacionTR;
        _rating = widget.trabajoRealizado!.encuenstaTR ?? 0;
        _fotoAntesPath = widget.trabajoRealizado!.fotoAntes64TR;
        _fotoDespuesPath = widget.trabajoRealizado!.fotoDespues64TR;
      });
    }

    // Obtener ubicación si no hay datos existentes
    if (_ubicacion == null || _ubicacion!.isEmpty) {
      await _getCurrentLocation();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Los servicios de ubicación están desactivados';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permisos de ubicación denegados';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Permisos de ubicación denegados permanentemente';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _ubicacion = '${position.latitude}, ${position.longitude}';
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
    }
  }

  Future<void> _takePhoto(bool isBefore) async {
    if (_hasExistingData || widget.isReadOnly) return;

    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024, // Limitar tamaño para evitar problemas de memoria
      );

      if (pickedFile != null) {
        setState(() => _isLoading = true);

        // Convertir a base64
        final bytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        // Actualizar estado
        setState(() {
          if (isBefore) {
            _fotoAntesPath = base64Image;
          } else {
            _fotoDespuesPath = base64Image;
          }
          _isLoading = false;
        });

        // Guardar borrador
        await _saveDraftData();

        print(
          'Foto ${isBefore ? 'antes' : 'después'} guardada (tamaño: ${base64Image.length} caracteres)',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error al tomar foto: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al tomar foto: $e')));
    }
  }

  Future<void> _submitForm() async {
    if (widget.isReadOnly) return;

    setState(() => _isLoading = true);

    try {
      // Validar solo comentario como requerido
      if (_comentarioController.text.isEmpty) {
        showAdvertence(context, 'Debes agregar un comentario');
        return;
      }

      // Obtener ubicación actual
      await _getCurrentLocation();
      if (_ubicacion == null) {
        throw 'No se pudo obtener la ubicación actual';
      }

      // Crear objeto TrabajoRealizado
      var trabajo = TrabajoRealizado(
        idTrabajoRealizado: widget.trabajoRealizado?.idTrabajoRealizado ?? 0,
        folioTR: widget.trabajoRealizado?.folioTR,
        fechaTR: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
        ubicacionTR: _ubicacion!,
        comentarioTR: _comentarioController.text,
        fotoAntes64TR: _fotoAntesPath, // Puede ser null
        fotoDespues64TR: _fotoDespuesPath, // Puede ser null
        encuenstaTR: _rating,
        idUserTR:
            widget.trabajoRealizado?.idUserTR ?? _salida?.id_User_Asignado,
        idOrdenServicio: widget.ordenServicio.idOrdenServicio,
        idSalida: _salida?.id_Salida,
        // Mantener campos adicionales
        folioOS: widget.trabajoRealizado?.folioOS,
        padronNombre: widget.trabajoRealizado?.padronNombre,
        padronDireccion: widget.trabajoRealizado?.padronDireccion,
        problemaNombre: widget.trabajoRealizado?.problemaNombre,
      );

      // Guardar en base de datos local
      final dbHelper = DatabaseHelper();
      final id = await dbHelper.insertTrabajo(trabajo);

      // Actualizar el trabajo con el ID generado
      trabajo = trabajo.copyWith(idTrabajoRealizado: id);

      // Eliminar borrador usando el ID correcto
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/trabajo_draft_${widget.trabajoRealizado?.idTrabajoRealizado ?? id}.json',
      );
      if (await file.exists()) await file.delete();

      // Actualizar el estado local
      setState(() {
        _fotoAntesPath = trabajo.fotoAntes64TR;
        _fotoDespuesPath = trabajo.fotoDespues64TR;
        _comentarioController.text = trabajo.comentarioTR ?? '';
        _rating = trabajo.encuenstaTR ?? 0;
      });

      if (!mounted) return;
      showOk(context, 'Progreso guardado correctamente');
      Navigator.pop(context, true);
    } catch (e) {
      print('Error al guardar trabajo: $e');
      if (mounted) {
        showError(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveDraftData() async {
    if (widget.isReadOnly) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/trabajo_draft_${widget.trabajoRealizado?.idTrabajoRealizado}.json',
      );

      final draftData = {
        'idTrabajoRealizado': widget.trabajoRealizado?.idTrabajoRealizado,
        'idOrdenServicio': widget.ordenServicio.idOrdenServicio,
        'comentario': _comentarioController.text,
        'ubicacion': _ubicacion,
        'fotoAntesPath': _fotoAntesPath,
        'fotoDespuesPath': _fotoDespuesPath,
        'rating': _rating,
      };

      await file.writeAsString(json.encode(draftData));
    } catch (e) {
      print('Error saving draft data: $e');
    }
  }

  bool get _isTrabajoCompleto {
    // Solo considerar completo si tiene ambas fotos
    return widget.isReadOnly ||
        (widget.trabajoRealizado?.fotoAntes64TR != null &&
            widget.trabajoRealizado?.fotoDespues64TR != null);
  }

  @override
  void dispose() {
    _comentarioController.removeListener(_saveDraftData);
    _comentarioController.dispose();
    _saveDraftData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditable = !widget.isReadOnly && !_isTrabajoCompleto;
    final showRating =
        (_fotoAntesPath != null &&
            _fotoDespuesPath != null &&
            _comentarioController.text.isNotEmpty) ||
        widget.isReadOnly;

    return Scaffold(
      appBar: AppBar(
        title: Text('TR: ${widget.trabajoRealizado!.folioTR ?? 'Sin Folio'}'),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.trabajoRealizado != null) ...[
                        //  Padron
                        buildSectionCard('Padron', [
                          buildInfoItem(
                            'Nombre',
                            widget.trabajoRealizado?.padronNombre ?? 'N/A',
                          ),
                          const SizedBox(height: 8),
                          buildInfoItem(
                            'Dirección',
                            widget.trabajoRealizado?.padronDireccion ?? 'N/A',
                          ),
                        ]),
                        const SizedBox(height: 8),

                        //  Orden Trabajo
                        buildSectionCard('Orden de Trabajo', [
                          buildInfoItem(
                            'Folio',
                            widget.trabajoRealizado?.folioOS ?? 'N/A',
                          ),
                          const SizedBox(height: 8),
                          buildInfoItem(
                            'Problema',
                            widget.trabajoRealizado?.problemaNombre ?? 'N/A',
                          ),
                        ]),
                      ],

                      if (_salida != null) ...[
                        //Info Salida
                        buildSectionCard(
                          'Salida: ${_salida?.salida_CodFolio ?? 'N/A'}',
                          [
                            buildInfoItem(
                              'Colonia',
                              '${_salida?.idColonia ?? 'N/A'} - ${_nombreColonia ?? 'N/A'}',
                            ),
                            const SizedBox(height: 8),
                            buildInfoItem(
                              'Calle',
                              '${_salida?.idCalle ?? 'N/A'} - ${_nombreCalle ?? 'N/A'}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 16),

                      // Fotos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                            child: buildPhotoSection(
                              'Foto Antes',
                              _fotoAntesPath,
                              isEditable ? () => _takePhoto(true) : null,
                              isEditable: isEditable,
                              //() => _takePhoto(true),
                            ),
                          ),

                          if (_fotoAntesPath != null)
                            // Foto después
                            Flexible(
                              child: buildPhotoSection(
                                'Foto Después',
                                _fotoDespuesPath,
                                isEditable && _fotoAntesPath != null
                                    ? () => _takePhoto(false)
                                    : null,
                                isEditable: isEditable,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Divider(),
                      const SizedBox(height: 10),

                      // Comentario
                      CustomCommentField(
                        controller: _comentarioController,
                        labelText: 'Comentario',
                        maxLines: 4,
                        validator:
                            isEditable
                                ? (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa un comentario';
                                  }
                                  return null;
                                }
                                : null,
                        readOnly: !isEditable,
                      ),
                      const SizedBox(height: 24),

                      //  Rating
                      if (showRating || widget.isReadOnly)
                        Column(
                          children: [
                            const Text(
                              'Calificación del trabajo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StarRating(
                              rating: _rating,
                              onRatingChanged:
                                  isEditable
                                      ? ((rating) {
                                        setState(() {
                                          _rating = rating;
                                        });
                                      })
                                      : null,
                              interactive: isEditable,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Botón de enviar
                      Center(
                        child: SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade900,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 4,
                              shadowColor: Colors.blue.shade900,
                            ),
                            child: const Text(
                              'Guardar Localmente',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
    );
  }
}
