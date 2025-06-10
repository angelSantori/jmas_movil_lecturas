import 'package:flutter/material.dart';
import 'package:jmas_movil_lecturas/configs/controllers/users_controller.dart';
import 'package:jmas_movil_lecturas/screens/general/home_screen.dart';
import 'package:jmas_movil_lecturas/widgets/formularios.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

      if (success && mounted) {
        // Pequeño delay para permitir que las animaciones terminen
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error en login: $e');
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color.fromARGB(255, 96, 156, 217),
              const Color.fromARGB(255, 4, 134, 240),
            ],
          ),
        ),
        child: Center(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Título simplificado
                  const Text(
                    'TRABAJOS',
                    style: TextStyle(
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black,
                          offset: Offset(2, 2),
                        ),
                      ],
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Formulario
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Usuario
                        CustomTextFielTexto(
                          controller: _userNameController,
                          labelText: 'Usuario',
                          prefixIcon: Icons.person_outline,
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true
                                      ? 'Ingresa tu usuario'
                                      : null,
                        ),
                        const SizedBox(height: 20),

                        // Contraseña
                        CustomTextFielTexto(
                          controller: _passwordController,
                          labelText: 'Contraseña',
                          prefixIcon: Icons.lock_outline,
                          obscureText: !_isPasswordVisible,
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true
                                      ? 'Ingresa tu contraseña'
                                      : null,
                        ),
                        const SizedBox(height: 10),

                        // Checkbox para mostrar contraseña
                        Row(
                          children: [
                            Checkbox(
                              value: _isPasswordVisible,
                              onChanged:
                                  (value) => setState(
                                    () => _isPasswordVisible = value ?? false,
                                  ),
                              fillColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                    (states) =>
                                        states.contains(MaterialState.selected)
                                            ? Colors.white
                                            : Colors.transparent,
                                  ),
                              checkColor: Colors.blue.shade900,
                              side: BorderSide(color: Colors.white),
                            ),
                            Text(
                              'Mostrar contraseña',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Botón de login
                        SizedBox(
                          width: 150,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue.shade900,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.blue,
                                      ),
                                    )
                                    : const Text(
                                      'INICIAR SESIÓN',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
