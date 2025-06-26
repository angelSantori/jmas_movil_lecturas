import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jmas_movil_lecturas/configs/controllers/calles_controller.dart';
import 'package:jmas_movil_lecturas/configs/controllers/colonias_controller.dart';
import 'package:jmas_movil_lecturas/configs/controllers/orden_trabajo_controller.dart';
import 'package:jmas_movil_lecturas/configs/controllers/salidas_controller.dart';
import 'package:jmas_movil_lecturas/configs/controllers/trabajo_realizado_controller.dart';
import 'package:jmas_movil_lecturas/screens/trabajos_realizados/widgets_tr.dart';
import 'package:jmas_movil_lecturas/widgets/formularios.dart';
import 'package:jmas_movil_lecturas/widgets/mensajes.dart';
import 'package:path_provider/path_provider.dart';

class TrabajoRealizadoScreen extends StatefulWidget {
  final OrdenTrabajo ordenTrabajo;
  final TrabajoRealizado? trabajoRealizado;
  final bool isReadOnly;

  const TrabajoRealizadoScreen({
    super.key,
    required this.ordenTrabajo,
    this.trabajoRealizado,
    this.isReadOnly = false,
  });

  @override
  State<TrabajoRealizadoScreen> createState() => _TrabajoRealizadoScreenState();
}

class _TrabajoRealizadoScreenState extends State<TrabajoRealizadoScreen> {
  final TrabajoRealizadoController _trabajoRealizadoController =
      TrabajoRealizadoController();
  final SalidasController _salidasController = SalidasController();
  final CallesController _callesController = CallesController();
  final ColoniasController _coloniasController = ColoniasController();
  final OrdenTrabajoController _ordenTrabajoController =
      OrdenTrabajoController();

  final TextEditingController _comentarioController = TextEditingController();

  String? _ubicacion;
  String? _fotoAntesPath;
  String? _fotoDespuesPath;
  String? _nombreCalle;
  String? _nombreColonia;
  bool _isLoading = false;
  Salidas? _salida;
  final _formKey = GlobalKey<FormState>();
  bool _hasExistingData = false;

  @override
  void initState() {
    super.initState();
    _loadSalidaData();
    _getCurrentLocation();
    _loadInitialData();
    _loadCalleColoniaNames();
    _comentarioController.addListener(_saveDraftData);

    // Determinar si hay datos existentes completos
    _hasExistingData =
        widget.trabajoRealizado != null &&
        widget.trabajoRealizado!.idTrabajoRealizado != null &&
        widget.trabajoRealizado!.fotoAntes64TR != null &&
        widget.trabajoRealizado!.fotoAntes64TR!.isNotEmpty &&
        widget.trabajoRealizado!.fotoDespues64TR != null &&
        widget.trabajoRealizado!.fotoDespues64TR!.isNotEmpty &&
        widget.trabajoRealizado!.ubicacionTR != null &&
        widget.trabajoRealizado!.comentarioTR != null;
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar datos de salida
      await _loadSalidaData();

      // Verificar si hay un trabajo existente para editar
      if (widget.trabajoRealizado != null &&
          widget.trabajoRealizado!.idTrabajoRealizado != null) {
        _comentarioController.text =
            widget.trabajoRealizado!.comentarioTR ?? '';
        _ubicacion = widget.trabajoRealizado!.ubicacionTR;

        // Cargar fotos desde base64 si existen
        if (widget.trabajoRealizado!.fotoAntes64TR != null &&
            widget.trabajoRealizado!.fotoAntes64TR!.isNotEmpty) {
          final directory = await getApplicationCacheDirectory();
          final filePath =
              '${directory.path}/antes_${widget.trabajoRealizado!.idTrabajoRealizado}.jpg';
          await File(
            filePath,
          ).writeAsBytes(base64Decode(widget.trabajoRealizado!.fotoAntes64TR!));
          _fotoAntesPath = filePath;
        }

        if (widget.trabajoRealizado!.fotoDespues64TR != null &&
            widget.trabajoRealizado!.fotoDespues64TR!.isNotEmpty) {
          final directory = await getApplicationDocumentsDirectory();
          final filePath =
              '${directory.path}/despues_${widget.trabajoRealizado!.idTrabajoRealizado}.jpg';
          await File(filePath).writeAsBytes(
            base64Decode(widget.trabajoRealizado!.fotoDespues64TR!),
          );
          _fotoDespuesPath = filePath;
        }
      } else {
        // Solo cargar ubicación si es un nuevo registro
        await _getCurrentLocation();
      }
    } catch (e) {
      print('Error al cargar datos iniciales: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSalidaData() async {
    if (widget.ordenTrabajo.idOrdenTrabajo == null) return;

    try {
      final salidas = await _salidasController.getSalidaXOT(
        widget.ordenTrabajo.idOrdenTrabajo!,
      );
      if (salidas.isNotEmpty) {
        _salida = salidas.first;
        await _loadCalleColoniaNames();
      }
    } catch (e) {
      print('Error al cargar salida: $e');
    }
  }

  Future<void> _loadCalleColoniaNames() async {
    if (_salida?.idCalle != null) {
      final calle = await _callesController.getCalleXId(_salida!.idCalle!);
      if (calle != null) {
        setState(() {
          _nombreCalle = calle.calleNombre;
        });
      }
    }

    if (_salida?.idColonia != null) {
      final colonia = await _coloniasController.getColoniaXId(
        _salida!.idColonia!,
      );
      if (colonia != null) {
        setState(() {
          _nombreColonia = colonia.nombreColonia;
        });
      }
    }
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
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${isBefore ? 'antes' : 'despues'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(
        pickedFile.path,
      ).copy('${directory.path}/$fileName');

      setState(() {
        if (isBefore) {
          _fotoAntesPath = savedImage.path;
        } else {
          _fotoDespuesPath = savedImage.path;
        }
      });

      await _saveDraftData();
    }
  }

  Future<String?> _getImageBase64(String? imagePath) async {
    if (imagePath == null) return null;

    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      print('Error converting image to base64: $e');
    }
    return null;
  }

  Future<void> _updateOrdenTrabajoStatus() async {
    if (widget.ordenTrabajo.idOrdenTrabajo == null) return;

    try {
      final ordenActualizada = widget.ordenTrabajo.copyWith(
        estadoOT: 'Revisión',
      );

      final success = await _ordenTrabajoController.editOrdenTrabajo(
        ordenActualizada,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estado actualizado correctamente')),
        );
      }
    } catch (e) {
      print('Error al actualizar estado de orden de trabajo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar estado: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || widget.isReadOnly) return;

    setState(() => _isLoading = true);

    try {
      // Obtener ubicación actual justo antes de guardar
      await _getCurrentLocation();

      if (_ubicacion == null) {
        throw 'No se pudo obtener la ubicación actual';
      }

      final fotoAntes64 = await _getImageBase64(_fotoAntesPath);
      final fotoDespues64 = await _getImageBase64(_fotoDespuesPath);

      if (fotoAntes64 == null || fotoDespues64 == null) {
        if (!mounted) return;
        showAdvertence(context, 'Debes tomar ambas fotos (antes y después)');
        return;
      }

      final trabajo = TrabajoRealizado(
        idTrabajoRealizado: widget.trabajoRealizado?.idTrabajoRealizado ?? 0,
        folioTR: widget.trabajoRealizado?.folioTR,
        fechaTR: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
        ubicacionTR: _ubicacion!,
        comentarioTR: _comentarioController.text,
        fotoAntes64TR: fotoAntes64,
        fotoDespues64TR: fotoDespues64,
        idUserTR:
            widget.trabajoRealizado?.idUserTR ?? _salida?.id_User_Asignado,
        idOrdenTrabajo: widget.ordenTrabajo.idOrdenTrabajo,
        idSalida: _salida?.id_Salida,
      );

      bool success;
      if (widget.trabajoRealizado?.idTrabajoRealizado != null) {
        // Modo edición
        success = await _trabajoRealizadoController.editTrabajoRealizado(
          trabajo,
        );
      } else {
        // Modo creación
        success = await _trabajoRealizadoController.addTrabajoRealizado(
          trabajo,
        );
      }

      if (success) {
        // Actualizar estado de la orden de trabajo
        await _updateOrdenTrabajoStatus();

        // Eliminar borrador
        final directory = await getApplicationDocumentsDirectory();
        final file = File(
          '${directory.path}/trabajo_draft_${widget.ordenTrabajo.idOrdenTrabajo}.json',
        );
        if (await file.exists()) await file.delete();

        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        throw 'Error al ${widget.trabajoRealizado?.idTrabajoRealizado != null ? 'editar' : 'crear'} el trabajo realizado';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDraftData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/trabajo_draft_${widget.ordenTrabajo.idOrdenTrabajo}.json',
      );

      final draftData = {
        'idSalida': widget.ordenTrabajo.idOrdenTrabajo,
        'comentario': _comentarioController.text,
        'ubicacion': _ubicacion,
        'fotoAntesPath': _fotoAntesPath,
        'fotoDespuesPath': _fotoDespuesPath,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(json.encode(draftData));
    } catch (e) {
      print('Error saving draft data: $e');
    }
  }

  bool get _isTrabajoCompleto {
    return widget.trabajoRealizado != null &&
        widget.trabajoRealizado!.fotoAntes64TR != null &&
        widget.trabajoRealizado!.fotoAntes64TR!.isNotEmpty &&
        widget.trabajoRealizado!.fotoDespues64TR != null &&
        widget.trabajoRealizado!.fotoDespues64TR!.isNotEmpty &&
        widget.trabajoRealizado!.ubicacionTR != null &&
        widget.trabajoRealizado!.comentarioTR != null &&
        widget.trabajoRealizado!.comentarioTR!.isNotEmpty;
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

                      //Info Orden de trabajo
                      buildSectionCard(
                        'Orden de Trabajo: ${widget.ordenTrabajo.folioOT ?? 'N/A'}',
                        [
                          buildInfoItem(
                            'Dirección',
                            widget.ordenTrabajo.direccionOT ?? 'N/A',
                          ),
                          const SizedBox(height: 8),
                          buildInfoItem(
                            'Descripción',
                            widget.ordenTrabajo.descripcionOT ?? 'N/A',
                          ),
                          const SizedBox(height: 8),
                          buildInfoItem(
                            'Problema',
                            widget.ordenTrabajo.tipoProblemaOT ?? 'N/A',
                          ),
                        ],
                      ),

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

                      // Botón de enviar
                      if (isEditable)
                        Center(
                          child: SizedBox(
                            width: 150,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade900,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 4,
                                shadowColor: Colors.blue.shade900,
                              ),
                              child: Text(
                                widget.trabajoRealizado?.idTrabajoRealizado !=
                                        null
                                    ? 'Registrar Trabajo'
                                    : 'Registrar Trabajo',
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
