import 'package:flutter/material.dart';
import 'signup_screen.dart'; // Import SignupScreen
import '../services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _email, _password;
  final AuthService _authService = AuthService(); // Create an instance of AuthService

  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email address',style: TextStyle(color: Colors.black)),
            TextField(
              controller: emailController,
              decoration: InputDecoration(hintText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String email = emailController.text.trim();
              if (email.isNotEmpty) {
                try {
                  await _authService.sendPasswordResetEmail(email);
                  Navigator.pop(context); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Password reset link sent! Check your email.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error sending reset link. Please try again.')),
                  );
                }
              }
            },
            child: Text('Send Reset Link'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue,
                      width: 4.0,
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/tasty_logo.png', // Path to your asset
                      width: 120, // Adjust as needed
                      height: 120, // Adjust as needed
                    ),
                  ),
                ),
                SizedBox(height: 50),

                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    fillColor: Colors.grey[800],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.email, color: Colors.white),
                  ),
                  style: TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  onSaved: (value) => _email = value,
                ),
                SizedBox(height: 20),

                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    fillColor: Colors.grey[800],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.white),
                  ),
                  style: TextStyle(color: Colors.white),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onSaved: (value) => _password = value,
                ),
                SizedBox(height: 30),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding:
                    EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    textStyle:
                    TextStyle(fontSize: 18),
                    shape:
                    RoundedRectangleBorder(borderRadius:
                    BorderRadius.circular(30)),
                  ),
                  onPressed:
                      () async { // Call signIn method from AuthService
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      try {
                        User? user = await _authService.signInWithEmailAndPassword(_email!, _password!);
                        if (user != null) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage()));
                        }
                      } catch (e) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Error'),
                            content: Text('User doesn\'t exist. Please signup.'),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                          ),
                        );
                      }
                    }
                  },
                  child:
                  Text('Login'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero, // Reset padding
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final user = await _authService.signInWithGoogle(username: ''); // Pass an empty string for username
                    if (user != null) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHomePage()));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10), // Padding around the content
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/google.png',
                          width: 24,
                          height: 24,
                        ),
                        SizedBox(width: 8),
                        Text('Sign in with Google'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height:
                20),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children:
                  [
                    TextButton(
                      onPressed: () {
                        _showForgotPasswordDialog(context);
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Text(' | ',
                        style:
                        TextStyle(color:
                        Colors.grey)),
                    TextButton(
                      onPressed:
                          () { Navigator.push(context, MaterialPageRoute(builder:(context)=> SignupScreen())); },
                      child:
                      Text('Register here',
                        style:
                        TextStyle(color:
                        Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
