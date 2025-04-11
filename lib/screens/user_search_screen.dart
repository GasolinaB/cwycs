import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    final doc = await FirebaseFirestore.instance.collection('usernames').doc(query).get();
    if (doc.exists) {
      final uid = doc['uid'];
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() => _results = [userDoc.data()!]);
    } else {
      setState(() => _results = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F23),
      appBar: AppBar(
        title: const Text('Поиск пользователей'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Введите логин',
                hintStyle: const TextStyle(color: Colors.white54),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _search,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _results.isEmpty
                  ? const Text('Пользователь не найден', style: TextStyle(color: Colors.white60))
                  : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return ListTile(
                    title: Text(user['username'], style: const TextStyle(color: Colors.white)),
                    subtitle: Text(user['email'], style: const TextStyle(color: Colors.white60)),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
