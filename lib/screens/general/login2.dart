import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:jmas_movil_lecturas/configs/controllers/users_controller.dart';
import 'package:jmas_movil_lecturas/screens/general/home_screen.dart';
import 'package:jmas_movil_lecturas/widgets/formularios.dart';
import 'package:jmas_movil_lecturas/widgets/mensajes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final UsersController _usersController = UsersController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final success = await _usersController.loginUser(
        _userNameController.text,
        _passwordController.text,
        context,
      );

      if (!mounted) return;

      if (!success) {
        showAdvertence(context, 'Usuario o contraseña incorrectos');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Error en login: $e');
      showError(context, 'Error _submitForm: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              flex: 6,
              child: Container(
                width: 100,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 40, 3, 250),
                      Color.fromARGB(255, 255, 255, 255),
                    ],
                    stops: [0, 1],
                    begin: AlignmentDirectional(0.87, -1),
                    end: AlignmentDirectional(-0.87, 1),
                  ),
                ),
                alignment: AlignmentDirectional(0, -1),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(0, 80, 0, 10),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          height: MediaQuery.of(context).size.height * 0.2,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            image: DecorationImage(
                              fit: BoxFit.contain,
                              image: AssetImage('assets/png/logo_jmas_sf.png'),
                            ),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 6,
                                color: Color(0xC9000000),
                                offset: Offset(0, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(0),
                              bottomRight: Radius.circular(50),
                              topLeft: Radius.circular(50),
                              topRight: Radius.circular(0),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(maxWidth: 570),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 4,
                                color: Color(0x33000000),
                                offset: Offset(0, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Align(
                            alignment: AlignmentDirectional(0, 0),
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Servicios',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF101213),
                                        fontSize: 36,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                        0,
                                        12,
                                        0,
                                        24,
                                      ),
                                      child: Text(
                                        'Bienvenido de vuelta!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF57636C),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                        0,
                                        0,
                                        0,
                                        16,
                                      ),
                                      child: Column(
                                        children: [
                                          CustomTextFielTexto(
                                            controller: _userNameController,
                                            labelText: 'Usuario',
                                            preventSpaces: true,
                                            prefixIcon: Icons.person_outline,
                                            validator:
                                                (value) =>
                                                    value?.isEmpty ?? true
                                                        ? 'Ingresa tu usuario'
                                                        : null,
                                          ),
                                          CustomTextFielTexto(
                                            controller: _passwordController,
                                            labelText: 'Contraseña',
                                            preventSpaces: true,
                                            prefixIcon: Icons.lock_outline,
                                            obscureText: !_isPasswordVisible,
                                            validator:
                                                (value) =>
                                                    value?.isEmpty ?? true
                                                        ? 'Ingresa tu contraseña'
                                                        : null,
                                          ),
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: _isPasswordVisible,
                                                onChanged:
                                                    (value) => setState(
                                                      () =>
                                                          _isPasswordVisible =
                                                              value ?? false,
                                                    ),
                                                fillColor:
                                                    WidgetStateProperty.resolveWith<
                                                      Color
                                                    >(
                                                      (states) =>
                                                          states.contains(
                                                                MaterialState
                                                                    .selected,
                                                              )
                                                              ? Colors.white
                                                              : Colors
                                                                  .transparent,
                                                    ),
                                                checkColor:
                                                    Colors.blue.shade900,
                                                side: BorderSide(
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Text(
                                                'Mostrar contraseña',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                        0,
                                        0,
                                        0,
                                        16,
                                      ),
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _submitForm,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade900,
                                          minimumSize: Size(
                                            double.infinity,
                                            44,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 3,
                                        ),
                                        child: Text(
                                          'Iniciar Sesión',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'v.02092025',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
