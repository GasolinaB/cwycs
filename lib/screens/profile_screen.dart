import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_list_screen.dart';
import 'friends_screen.dart';
import 'user_search_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart'; // Добавили экран настроек

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Профиль"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              user?.email ?? "Без email",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'UID: ${user?.uid ?? ""}',
              style: const TextStyle(color: Colors.white24, fontSize: 12),
            ),
            const SizedBox(height: 30),

            // Навигационные кнопки
            _ProfileButton(
              icon: Icons.chat,
              label: 'Чаты',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ChatListScreen(),
                ));
              },
            ),
            _ProfileButton(
              icon: Icons.people,
              label: 'Друзья',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const FriendsScreen(),
                ));
              },
            ),
            _ProfileButton(
              icon: Icons.search,
              label: 'Поиск пользователей',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const UserSearchScreen(),
                ));
              },
            ),
            _ProfileButton(
              icon: Icons.settings,
              label: 'Настройки',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ));
              },
            ),

            const Spacer(),

            // Кнопка выхода
            TextButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                "Выйти",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}
