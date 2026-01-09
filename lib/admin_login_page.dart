import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_dashboard.dart';

class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 🎨 Palette (same as student login)
  final Color kDarkBlue = const Color(0xFF1B3C53);
  final Color kBlueGray = const Color(0xFF456882);
  final Color kBeige = const Color(0xFFC1B6F9);
  final Color kCream = const Color(0xFFF3EFEC);

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      try {
        print("🔍 Admin Login Attempt"); // Debug for developer only

        // Get all documents from Admin collection
        QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
            .collection('Admin')
            .get();

        print("📊 Found ${adminSnapshot.docs.length} documents in Admin collection"); // Debug

        bool credentialsMatch = false;

        // Check each document for matching credentials
        for (var doc in adminSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Convert to strings to ensure proper comparison
          String dbEmail = data['email']?.toString().trim() ?? '';
          String dbPassword = data['password']?.toString().trim() ?? '';

          if (dbEmail == email && dbPassword == password) {
            credentialsMatch = true;
            print("✅ Admin login successful"); // Debug
            break;
          }
        }

        if (credentialsMatch) {
          // SUCCESS: navigate to admin dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminDashboard()),
          );
        } else {
          setState(() {
            _errorMessage = "Invalid admin credentials!";
          });
          print("❌ Invalid credentials provided"); // Debug
        }
      } catch (e) {
        setState(() {
          _errorMessage = "Connection error. Please try again.";
        });
        print("🚨 Error occurred: $e"); // Debug
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      appBar: AppBar(
        title: const Text(
          "Admin Login",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: kDarkBlue,
        centerTitle: true,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 🎓 Top Badge (Admin Icon)
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              kBlueGray.withOpacity(0.75),
                              kBeige.withOpacity(0.9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: kDarkBlue.withOpacity(0.25),
                              offset: const Offset(0, 6),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 60,
                          color: kDarkBlue.withOpacity(0.85),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Error message
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),

                    // Admin Email
                    _buildTextField(
                      controller: emailController,
                      label: "Admin Email",
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter admin email";
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Password
                    _buildTextField(
                      controller: passwordController,
                      label: "Admin Password",
                      icon: Icons.lock,
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter admin password";
                        }
                        return null;
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: kBlueGray.withOpacity(0.65),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Admin Login Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDarkBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        shadowColor: kDarkBlue.withOpacity(0.4),
                      ),
                      onPressed: _isLoading ? null : _handleAdminLogin,
                      child: _isLoading
                          ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(kCream),
                      )
                          : Text(
                        "Login as Admin",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: kCream,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reusable styled TextField (same style as student login)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      style: TextStyle(
          color: kDarkBlue, fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kBlueGray.withOpacity(0.75)),
        prefixIcon: Icon(
          icon,
          color: kBlueGray.withOpacity(0.65),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
          BorderSide(color: kBlueGray.withOpacity(0.6), width: 1.5),
        ),
      ),
    );
  }
}
