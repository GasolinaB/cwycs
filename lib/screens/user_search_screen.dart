import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _controller = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  Future<void> _search() async {
    setState(() {
      _isLoading = true;
      _results = [];
    });

    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) return;

    try {
      final snapshot = await _firestore
          .collection('usernames')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: '$query\uf8ff')
          .get();

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          final uid = doc['uid'];
          final userDoc = await _firestore.collection('users').doc(uid).get();
          if (userDoc.exists) {
            _results.add(userDoc.data()!);
          }
        }
      }
    } catch (e) {
      print('Ошибка поиска: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addFriend(String friendUid) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('friends')
        .doc(friendUid)
        .set({
      'uid': friendUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1F23),
      appBar: AppBar(
        title: const Text('Поиск пользователей'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Введите никнейм',
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
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return _UserTile(
                    username: user['username'],
                    avatarUrl: user['avatarUrl'] ?? '',
                    onAddFriend: () => _addFriend(user['uid']),
                    onMessage: () {
                      // Навигация к чату
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String username;
  final String avatarUrl;
  final VoidCallback onAddFriend;
  final VoidCallback onMessage;

  const _UserTile({
    required this.username,
    required this.avatarUrl,
    required this.onAddFriend,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A34),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : const AssetImage('assets/default_avatar.png') as ImageProvider,
        ),
        title: Text(
          username,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
              onPressed: onAddFriend,
            ),
            IconButton(
              icon: const Icon(Icons.message, color: Colors.white),
              onPressed: onMessage,
            ),
          ],
        ),
      ),
    );
  }
}