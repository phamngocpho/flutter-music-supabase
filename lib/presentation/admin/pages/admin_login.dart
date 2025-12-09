import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spotify/core/extensions/is_dark_mode.dart';
import 'package:spotify/core/theme/app_colors.dart';
import 'package:spotify/data/models/signin_user_req.dart';
import 'package:spotify/domain/usecases/admin/check_admin_usecase.dart';
import 'package:spotify/domain/usecases/signin_usecase.dart';
import 'package:spotify/presentation/admin/pages/admin_dashboard.dart';
import 'package:spotify/service_locator.dart';
import 'package:spotify/shared/widgets/basic_app_bar.dart';
import 'package:spotify/shared/widgets/basic_app_button.dart';
import 'package:spotify/core/constants/app_vectors.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    // Check if email is admin
    bool isAdmin = sl<CheckAdminUseCase>().call(email: _emailController.text);
    if (!isAdmin) {
      _showSnackBar('Access denied. Admin only.');
      return;
    }

    setState(() => _isLoading = true);

    var result = await sl<SigninUseCase>().call(
      params: SigninUserReq(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );

    setState(() => _isLoading = false);

    result.fold(
      (error) => _showSnackBar(error),
      (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppbar(
        title: SvgPicture.asset(
          AppVectors.logo,
          height: 40,
          width: 40,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeader(),
            const SizedBox(height: 50),
            _buildEmailField(),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 30),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.admin_panel_settings,
          size: 80,
          color: AppColors.primary,
        ),
        const SizedBox(height: 20),
        const Text(
          'Admin Login',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Sign in to manage songs',
          style: TextStyle(
            fontSize: 14,
            color: context.isDarkMode ? AppColors.grey : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        hintText: 'Admin Email',
        prefixIcon: Icon(Icons.email_outlined),
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }

  Widget _buildLoginButton() {
    return _isLoading
        ? const CircularProgressIndicator(color: AppColors.primary)
        : BasicAppButton(
            onPressed: _login,
            title: 'Login as Admin',
          );
  }
}

