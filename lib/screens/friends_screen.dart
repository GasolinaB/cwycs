import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _outgoingRequests = [];
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;
  bool _isOutgoingTab = true; // Переключение между вкладками

  @override
  void initState() {
    super.initState();
    _loadFriendsData();
  }

  // Загружаем заявки и друзей
  Future<void> _loadFriendsData() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Загружаем входящие заявки
      final incomingRequestSnapshot = await _firestore
          .collection('friendRequests')
          .where('to', isEqualTo: _currentUser!.uid)
          .where('status', isEqualTo: 'pending') // Входящие заявки
          .get();

      // Загружаем исходящие заявки
      final outgoingRequestSnapshot = await _firestore
          .collection('friendRequests')
          .where('from', isEqualTo: _currentUser!.uid)
          .where('status', isEqualTo: 'pending') // Исходящие заявки
          .get();

      // Загружаем список друзей
      final friendsSnapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('friends')
          .where('status', isEqualTo: 'accepted')
          .get();

      setState(() {
        _incomingRequests = incomingRequestSnapshot.docs
            .map((doc) => doc.data())
            .toList();
        _outgoingRequests = outgoingRequestSnapshot.docs
            .map((doc) => doc.data())
            .toList();
        _friends = friendsSnapshot.docs
            .map((doc) => doc.data())
            .toList();
        _friends.sort((a, b) => (a['username'] as String).compareTo(b['username']));
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки данных: $e');
      setState(() => _isLoading = false);
    }
  }

  // Функция для принятия заявки
  Future<void> _acceptFriendRequest(String friendUid) async {
    if (_currentUser == null) return;

    try {
      // Ожидаем получения данных запроса
      final friendRequestSnapshot = await _firestore
          .collection('friendRequests')
          .where('from', isEqualTo: friendUid)
          .where('to', isEqualTo: _currentUser!.uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      // Проверяем, есть ли заявки
      if (friendRequestSnapshot.docs.isEmpty) return;

      // Используем транзакцию для обновления статуса заявки и добавления друга
      await _firestore.runTransaction((transaction) async {
        final docSnapshot = friendRequestSnapshot.docs.first;

        // Обновляем статус заявки на 'accepted'
        transaction.update(docSnapshot.reference, {
          'status': 'accepted',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Добавляем друга в список обоих пользователей
        final friendUserRef = _firestore
            .collection('users')
            .doc(friendUid)
            .collection('friends')
            .doc(_currentUser!.uid);
        transaction.set(friendUserRef, {
          'status': 'accepted',
          'timestamp': FieldValue.serverTimestamp(),
        });

        final userFriendRef = _firestore
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('friends')
            .doc(friendUid);
        transaction.set(userFriendRef, {
          'status': 'accepted',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      // Перезагружаем данные после принятия заявки
      _loadFriendsData();
    } catch (e) {
      print('Ошибка при принятии заявки: $e');
    }
  }

  // Переключение между вкладками
  void _toggleTab(bool isOutgoing) {
    setState(() {
      _isOutgoingTab = isOutgoing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Друзья'),
        backgroundColor: const Color(0xFF5F4B8B), // Глубокий сиреневый цвет
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Кнопки для переключения вкладок
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_outgoingRequests.isNotEmpty || _incomingRequests.isNotEmpty)
                  GestureDetector(
                    onTap: () => _toggleTab(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isOutgoingTab ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Text(
                        'Исходящие заявки',
                        style: TextStyle(
                          color: _isOutgoingTab ? Colors.white : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                if (_outgoingRequests.isNotEmpty || _incomingRequests.isNotEmpty)
                  GestureDetector(
                    onTap: () => _toggleTab(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isOutgoingTab ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Text(
                        'Входящие заявки',
                        style: TextStyle(
                          color: !_isOutgoingTab ? Colors.white : Colors.blue,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Отображаем заявки в зависимости от вкладки
            _isOutgoingTab
                ? _outgoingRequests.isEmpty
                ? const Text('Нет исходящих заявок', style: TextStyle(color: Colors.white))
                : ListView.builder(
              shrinkWrap: true,
              itemCount: _outgoingRequests.length,
              itemBuilder: (context, index) {
                final request = _outgoingRequests[index];
                return _FriendCard(
                  username: request['username'],
                  avatarUrl: request['avatarUrl'],
                  onAccept: () => {}, // Пустая функция для исходящих заявок
                  isIncomingRequest: false,
                );
              },
            )
                : _incomingRequests.isEmpty
                ? const Text('Нет входящих заявок', style: TextStyle(color: Colors.white))
                : ListView.builder(
              shrinkWrap: true,
              itemCount: _incomingRequests.length,
              itemBuilder: (context, index) {
                final request = _incomingRequests[index];
                return _FriendCard(
                  username: request['username'],
                  avatarUrl: request['avatarUrl'],
                  onAccept: () => _acceptFriendRequest(request['uid']),
                  isIncomingRequest: true,
                );
              },
            ),
            const SizedBox(height: 32),
            // Список друзей
            const Text(
              'Друзья',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _friends.isEmpty
                ? const Text(
              'У вас нет друзей',
              style: TextStyle(color: Colors.white),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  return _FriendCard(
                    username: friend['username'],
                    avatarUrl: friend['avatarUrl'],
                    onAccept: () {},
                    isIncomingRequest: false,
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

class _FriendCard extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final VoidCallback onAccept;
  final bool isIncomingRequest;

  const _FriendCard({
    required this.username,
    required this.avatarUrl,
    required this.onAccept,
    required this.isIncomingRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.transparent,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(avatarUrl ?? ''),
          radius: 25,
        ),
        title: Text(
          username,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: isIncomingRequest
            ? IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          onPressed: onAccept,
        )
            : null,
      ),
    );
  }
}
