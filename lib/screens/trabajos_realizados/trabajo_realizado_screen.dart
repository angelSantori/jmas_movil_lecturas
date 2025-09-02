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
import 'package:signature/signature.dart';

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
  String? _fotoMaterialPath;
  String? _nombreCalle;
  String? _nombreColonia;
  bool _isLoading = false;
  Salidas? _salida;
  String? _estadoTrabajo;
  final _formKey = GlobalKey<FormState>();
  final bool _hasExistingData = false;
  bool _requiereMaterial = false;

  //  Firma
  SignatureController? _signatureController;
  String? _firmaPath;
  bool _showSignaturePad = false;

  @override
  void initState() {
    super.initState();
    _comentarioController = TextEditingController();
    _getCurrentLocation();
    _loadInitialData();
    _comentarioController.addListener(_saveDraftData);
    _loadDraftData();

    _signatureController = SignatureController(
      penStrokeWidth: 2,
      penColor: Colors.blue.shade900,
    );

    if (widget.trabajoRealizado?.estadoTR == null) {
      _estadoTrabajo = 'Completado';
    }
  }

  @override
  void dispose() {
    _signatureController?.dispose();
    _comentarioController.removeListener(_saveDraftData);
    _comentarioController.dispose();
    _saveDraftData();
    super.dispose();
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
            _fotoMaterialPath = draftData['fotoMaterialPath'];
            _firmaPath = draftData['firmaPath'];
            _requiereMaterial = draftData['requiereMaterial'] ?? false;
            _estadoTrabajo = draftData['estadoTrabajo'] ?? 'Completado';
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
        _estadoTrabajo = widget.trabajoRealizado!.estadoTR ?? 'Completado';
        _fotoAntesPath = widget.trabajoRealizado!.fotoAntes64TR;
        _fotoDespuesPath = widget.trabajoRealizado!.fotoDespues64TR;
        _fotoMaterialPath = widget.trabajoRealizado!.fotoRequiereMaterial64TR;
        _firmaPath = widget.trabajoRealizado!.firma64TR;
        _requiereMaterial =
            widget.trabajoRealizado!.fotoRequiereMaterial64TR != null;
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

  Future<void> _takeMaterialPhoto() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (pickedFile != null) {
        setState(() => _isLoading = true);
        final bytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          _fotoMaterialPath = base64Image;
          _requiereMaterial = true;
          _isLoading = false;
        });
        await _saveDraftData();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showError(context, 'Error al tomar foto');
      print('Error al tomar foto : $e');
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
      if (_comentarioController.text.isEmpty) {
        showAdvertence(context, 'Debes agregar un comentario');
        return;
      }
      if (_requiereMaterial && _fotoMaterialPath == null) {
        showAdvertence(context, 'Debes tomar una foto de evidencia');
        return;
      }

      if (!_requiereMaterial && _fotoAntesPath == null) {
        showAdvertence(context, 'Debes tomar una foto del antes del trabajo');
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
        fotoAntes64TR: _fotoAntesPath,
        fotoDespues64TR: _fotoDespuesPath,
        fotoRequiereMaterial64TR: _fotoMaterialPath,
        firma64TR: _firmaPath,
        estadoTR: _estadoTrabajo,
        idUserTR:
            widget.trabajoRealizado?.idUserTR ?? _salida?.id_User_Asignado,
        idOrdenServicio: widget.ordenServicio.idOrdenServicio,
        folioSalida: widget.trabajoRealizado?.folioOS,
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
        _fotoMaterialPath = trabajo.fotoRequiereMaterial64TR;
        _comentarioController.text = trabajo.comentarioTR ?? '';
        _estadoTrabajo = _estadoTrabajo ?? 'Completado';
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
        'fotoMaterialPath': _fotoMaterialPath,
        'firmaPath': _firmaPath,
        'requiereMaterial': _requiereMaterial,
        'estadoTrabajo': _estadoTrabajo,
      };

      await file.writeAsString(json.encode(draftData));
    } catch (e) {
      print('Error saving draft data: $e');
    }
  }

  bool get _isTrabajoCompleto {
    return widget.isReadOnly ||
        (widget.trabajoRealizado?.fotoAntes64TR != null &&
            widget.trabajoRealizado?.fotoDespues64TR != null) ||
        (widget.trabajoRealizado?.fotoRequiereMaterial64TR != null &&
            widget.trabajoRealizado?.comentarioTR != null &&
            widget.trabajoRealizado!.comentarioTR!.isNotEmpty);
  }

  Future<void> _captureSignature() async {
    try {
      if (_signatureController!.isNotEmpty) {
        setState(() => _isLoading = true);

        // Configuración de alta calidad
        final signature = await _signatureController!.toPngBytes(
          height: 500, // Alta resolución
          width: 1000, // Alta resolución
        );

        if (signature != null) {
          setState(() {
            _firmaPath = base64Encode(signature);
            _showSignaturePad = false;
            _isLoading = false;
          });
          await _saveDraftData();

          if (mounted) {
            showOk(context, 'Firma capturada con éxito');
          }
        }
      } else {
        showAdvertence(context, 'Por favor, proporciona la firma');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error al capturar firma: $e');
      showError(context, 'Error al capturar firma');
    }
  }

  void _clearSignature() {
    _signatureController!.clear();
  }

  bool get _shouldShowSignatureOptions {
    return !_requiereMaterial &&
        _fotoAntesPath != null &&
        _fotoDespuesPath != null &&
        _comentarioController.text.isNotEmpty &&
        _estadoTrabajo != null;
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
                        buildSectionCard('Orden de Servicio', [
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
                      ],
                      const SizedBox(height: 10),

                      if (isEditable) ...[
                        buildSectionCard('¿Requiere Material?', [
                          ToggleButtons(
                            isSelected: [!_requiereMaterial, _requiereMaterial],
                            onPressed: (index) {
                              setState(() {
                                _requiereMaterial = index == 1;
                                if (!_requiereMaterial) {
                                  _fotoMaterialPath = null;
                                }
                              });
                            },
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width * 0.2,
                              minHeight: 36,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            selectedColor: Colors.white,
                            color:
                                Colors.grey, // Color del texto no seleccionado
                            fillColor:
                                _requiereMaterial
                                    ? Colors.green
                                    : Colors.grey.shade400,
                            renderBorder: true,
                            borderColor: Colors.grey,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'No',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'Sí',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ]),
                      ],
                      const SizedBox(height: 16),

                      if (_requiereMaterial) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: buildPhotoSection(
                                'Foto de Evidencia',
                                _fotoMaterialPath,
                                () => _takeMaterialPhoto(),
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
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            //  Foto antes
                            Flexible(
                              child: buildPhotoSection(
                                'Foto Antes',
                                _fotoAntesPath,
                                isEditable ? () => _takePhoto(true) : null,
                                isEditable: isEditable,
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

                        // Sección de firma - CORREGIDO
                        if (_shouldShowSignatureOptions &&
                            !_showSignaturePad &&
                            _firmaPath == null)
                          Column(
                            children: [
                              const SizedBox(height: 24),
                              const Text(
                                'Firma del cliente',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _showSignaturePad = true;
                                  });
                                },
                                child: const Text('Capturar firma'),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),

                        if (_showSignaturePad)
                          Column(
                            children: [
                              const SizedBox(height: 24),
                              const Text(
                                'Firma del cliente',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                ),
                                height: 200,
                                child: Signature(
                                  controller: _signatureController!,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: _clearSignature,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text(
                                      'Limpiar',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _captureSignature,
                                    child: const Text('Guardar Firma'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),

                        if (_firmaPath != null && !_showSignaturePad)
                          Column(
                            children: [
                              const SizedBox(height: 24),
                              const Text(
                                'Firma Capturada',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Image.memory(
                                base64Decode(_firmaPath!),
                                height: 100,
                              ),
                              const SizedBox(height: 8),
                              if (isEditable)
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _firmaPath = null;
                                      _showSignaturePad = true;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                  child: const Text(
                                    'Capturar Nueva Firma',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              const SizedBox(height: 16),
                            ],
                          ),

                        const SizedBox(height: 24),

                        //  Rating
                        if (showRating || widget.isReadOnly) ...[
                          Column(
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                'Estado del trabajo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Opción Completado (Verde)
                                  GestureDetector(
                                    onTap:
                                        isEditable
                                            ? () {
                                              setState(() {
                                                _estadoTrabajo = 'Completado';
                                              });
                                            }
                                            : null,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            _estadoTrabajo == 'Completado'
                                                ? Colors.green
                                                : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              _estadoTrabajo == 'Completado'
                                                  ? Colors.green
                                                  : Colors.grey,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text('Completado'),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Opción Pendiente (Amarillo)
                                  GestureDetector(
                                    onTap:
                                        isEditable
                                            ? () {
                                              setState(() {
                                                _estadoTrabajo = 'Pendiente';
                                              });
                                            }
                                            : null,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            _estadoTrabajo == 'Pendiente'
                                                ? Colors.orange
                                                : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              _estadoTrabajo == 'Pendiente'
                                                  ? Colors.orange
                                                  : Colors.grey,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              color: Colors.orange,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text('Pendiente'),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Opción Cancelado (Rojo)
                                  GestureDetector(
                                    onTap:
                                        isEditable
                                            ? () {
                                              setState(() {
                                                _estadoTrabajo = 'Falla';
                                              });
                                            }
                                            : null,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            _estadoTrabajo == 'Falla'
                                                ? Colors.red
                                                : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              _estadoTrabajo == 'Falla'
                                                  ? Colors.red
                                                  : Colors.grey,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text('Falla'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ],
                      ],

                      // Botón para guardar
                      if (widget.isReadOnly == false)
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
