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
            inputFormatters: widget.inputFormatters,
            onChanged: widget.onChanged,
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
