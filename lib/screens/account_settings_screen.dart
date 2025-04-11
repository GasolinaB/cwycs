import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  late TextEditingController _newPasswordController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _emailChangePasswordController;

  bool _isLoading = false;
  User? _currentUser;
  File? _avatarImage;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _nicknameController = TextEditingController();
    _emailController = TextEditingController(text: _currentUser?.email);
    _newPasswordController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _emailChangePasswordController = TextEditingController();

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc = await _firestore.collection('users').doc(_currentUser?.uid).get();
    setState(() {
      _nicknameController.text = doc['nickname'] ?? '';
      _avatarUrl = doc['avatarUrl'];
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarImage = File(pickedFile.path);
      });
      await _uploadAvatar();
    }
  }

  Future<void> _uploadAvatar() async {
    if (_avatarImage == null) return;

    setState(() => _isLoading = true);
    try {
      final ref = _storage.ref().child('avatars/${_currentUser!.uid}');
      await ref.putFile(_avatarImage!);
      final url = await ref.getDownloadURL();

      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'avatarUrl': url,
      });

      setState(() => _avatarUrl = url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки аватара: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reauthenticate(String password) async {
    final credential = EmailAuthProvider.credential(
      email: _currentUser!.email!,
      password: password,
    );
    await _currentUser!.reauthenticateWithCredential(credential);
  }

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Обновление никнейма
      await _firestore.collection('users').doc(_currentUser?.uid).update({
        'nickname': _nicknameController.text.trim(),
      });

      // Обновление email
      if (_emailController.text.trim() != _currentUser?.email) {
        if (_emailChangePasswordController.text.isEmpty) {
          throw FirebaseAuthException(
            code: 'missing-password',
            message: 'Введите пароль для изменения email',
          );
        }
        await _reauthenticate(_emailChangePasswordController.text.trim());
        await _currentUser!.verifyBeforeUpdateEmail(_emailController.text.trim());
      }

      // Обновление пароля
      if (_newPasswordController.text.isNotEmpty) {
        if (_currentPasswordController.text.isEmpty) {
          throw FirebaseAuthException(
            code: 'missing-password',
            message: 'Введите текущий пароль',
          );
        }
        await _reauthenticate(_currentPasswordController.text.trim());
        await _currentUser!.updatePassword(_newPasswordController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные успешно обновлены!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.message ?? 'Неизвестная ошибка'}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _currentPasswordController.dispose();
    _emailChangePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Настройки аккаунта'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white24,
                    backgroundImage: _avatarUrl != null
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: _avatarUrl == null
                        ? const Icon(Icons.camera_alt,
                        size: 40,
                        color: Colors.white70)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _nicknameController,
                label: 'Никнейм',
                hint: 'Введите новый никнейм',
                icon: Icons.person,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Введите новый email',
                icon: Icons.email,
                isEmail: true,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _emailChangePasswordController,
                label: 'Пароль для изменения email',
                hint: 'Введите текущий пароль',
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _newPasswordController,
                label: 'Новый пароль',
                hint: 'Введите новый пароль',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _currentPasswordController,
                label: 'Текущий пароль',
                hint: 'Введите текущий пароль',
                icon: Icons.lock_clock,
                isPassword: true,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _updateAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Сохранить изменения'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      validator: (value) {
        if (isEmail && value!.isNotEmpty && !value.contains('@')) {
          return 'Некорректный email';
        }
        if (isPassword && value!.isNotEmpty && value.length < 6) {
          return 'Пароль должен быть не менее 6 символов';
        }
        return null;
      },
    );
  }
}