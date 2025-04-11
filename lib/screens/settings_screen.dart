import 'package:flutter/material.dart';
import 'account_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Настройки'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Аккаунт',
            subtitle: 'Управление профилем',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(color: Colors.white12),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Уведомления',
            subtitle: 'Настроить push-уведомления',
            onTap: () {
              // TODO: уведомления
            },
          ),
          const Divider(color: Colors.white12),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Конфиденциальность',
            subtitle: 'Управление безопасностью',
            onTap: () {
              // TODO: конфиденциальность
            },
          ),
          const Divider(color: Colors.white12),
          _SettingsTile(
            icon: Icons.color_lens_outlined,
            title: 'Тема',
            subtitle: 'Изменить оформление',
            onTap: () {
              // TODO: смена темы
            },
          ),
          const Divider(color: Colors.white12),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'О приложении',
            subtitle: 'Версия, поддержка, лицензия',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'CWYCS Messenger',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 CWYCS',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white24),
      onTap: onTap,
    );
  }
}
