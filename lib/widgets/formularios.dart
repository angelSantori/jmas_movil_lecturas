import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFielTexto extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final IconData prefixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool? obscureText;
  final bool preventSpaces;

  const CustomTextFielTexto({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.prefixIcon = Icons.text_fields,
    this.inputFormatters,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
    this.preventSpaces = false,
  });

  @override
  State<CustomTextFielTexto> createState() => _CustomTextFielTextoState();
}

class _CustomTextFielTextoState extends State<CustomTextFielTexto>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  late FocusNode _focusNode;
  bool _isFocused = false;

  final _noSpacesFormatter = FilteringTextInputFormatter.deny(RegExp(r'\s'));

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500), // Animación más rápida para móvil
    );

    _animation = Tween<Offset>(
      begin: Offset(0, -0.5), // Desplazamiento inicial más pequeño
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );
    _animationController.forward();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    List<TextInputFormatter> finalInputFormatters = [];

    if (widget.inputFormatters != null) {
      finalInputFormatters.addAll(widget.inputFormatters!);
    }

    if (widget.preventSpaces) {
      finalInputFormatters.add(_noSpacesFormatter);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SlideTransition(
        position: _animation,
        child: Container(
          width: screenWidth * 0.9, // 90% del ancho de pantalla
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                _isFocused
                    ? [
                      BoxShadow(
                        color: Colors.blue.shade900.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: Offset(0, 4),
                      ),
                    ]
                    : null, // Sombra solo cuando está enfocado
          ),
          child: TextFormField(
            controller: widget.controller,
            inputFormatters: finalInputFormatters,
            onChanged: (value) {
              if (widget.onChanged != null) {
                widget.onChanged!(value);
              }
            },
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText ?? false,
            decoration: InputDecoration(
              labelText: widget.labelText,
              labelStyle: TextStyle(
                color: _isFocused ? Colors.blue.shade900 : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: _isFocused ? Colors.blue.shade900 : Colors.grey.shade700,
                size: 20, // Tamaño de icono más pequeño
              ),
              filled: true,
              fillColor:
                  _isFocused ? Colors.blue.shade50 : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14, // Más padding vertical para mejor tacto
                horizontal: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.blue.shade900,
                  width: 1.5,
                ), // Borde más delgado
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red, width: 1.0),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
            style: TextStyle(
              fontSize: 16, // Tamaño de fuente más pequeño
              color: Colors.black,
            ),
            validator: widget.validator,
          ),
        ),
      ),
    );
  }
}

//Comentario
class CustomCommentField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final IconData prefixIcon;
  final bool showBorder;
  final bool readOnly;

  const CustomCommentField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.onChanged,
    this.maxLines = 3,
    this.prefixIcon = Icons.comment,
    this.showBorder = true,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: readOnly ? Colors.grey.shade600 : Colors.grey.shade700,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: readOnly ? Colors.grey.shade500 : Colors.grey.shade700,
          size: 20,
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade200 : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        enabledBorder:
            showBorder
                ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color:
                        readOnly ? Colors.grey.shade300 : Colors.grey.shade300,
                    width: 1.0,
                  ),
                )
                : InputBorder.none,
        focusedBorder:
            showBorder && !readOnly
                ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.blue.shade900,
                    width: 1.5,
                  ),
                )
                : InputBorder.none,
        errorBorder:
            showBorder && !readOnly
                ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1.0),
                )
                : InputBorder.none,
        focusedErrorBorder:
            showBorder && !readOnly
                ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                )
                : InputBorder.none,
        alignLabelWithHint: true,
      ),
      style: TextStyle(
        fontSize: 16,
        color: readOnly ? Colors.grey.shade700 : Colors.black,
      ),
      validator: readOnly ? null : validator,
    );
  }
}
