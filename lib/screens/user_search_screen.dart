import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _searchController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _performSearch() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults.clear();
    });

    try {
      final usernameSnapshot = await _firestore
          .collection('usernames')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: '$query\uf8ff')
          .get();

      final results = await Future.wait(usernameSnapshot.docs.map((doc) async {
        final userDoc = await _firestore.collection('users').doc(doc['uid']).get();
        final data = userDoc.data();
        if (data != null && userDoc.id != _auth.currentUser?.uid) {
          return {...data, 'uid': userDoc.id};
        }
        return null;
      }));

      if (mounted) {
        setState(() {
          _searchResults = results.whereType<Map<String, dynamic>>().toList();
        });
      }
    } catch (e) {
      debugPrint('Ошибка поиска: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск пользователей'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Введите никнейм',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Expanded(child: Center(child: CircularProgressIndicator()))
                : Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return _UserCard(
                    userData: user,
                    currentUserId: currentUserId,
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

class _UserCard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String currentUserId;

  const _UserCard({
    required this.userData,
    required this.currentUserId,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  String? _friendRequestId;
  String? _incomingRequestId;
  String? _friendshipStatus;

  @override
  void initState() {
    super.initState();
    if (widget.currentUserId.isNotEmpty) {
      _checkFriendStatus();
    }
  }

  Future<void> _checkFriendStatus() async {
    final firestore = FirebaseFirestore.instance;

    final sent = await firestore
        .collection('friendRequests')
        .where('from', isEqualTo: widget.currentUserId)
        .where('to', isEqualTo: widget.userData['uid'])
        .get();

    if (sent.docs.isNotEmpty) {
      if (mounted) {
        setState(() {
          _friendRequestId = sent.docs.first.id;
          _friendshipStatus = sent.docs.first['status'];
        });
      }
      return;
    }

    final incoming = await firestore
        .collection('friendRequests')
        .where('from', isEqualTo: widget.userData['uid'])
        .where('to', isEqualTo: widget.currentUserId)
        .get();

    if (incoming.docs.isNotEmpty) {
      if (mounted) {
        setState(() {
          _incomingRequestId = incoming.docs.first.id;
          _friendshipStatus = incoming.docs.first['status'];
        });
      }
    }
  }

  Future<void> _sendOrCancelRequest() async {
    final firestore = FirebaseFirestore.instance;

    if (_friendRequestId != null) {
      await firestore.collection('friendRequests').doc(_friendRequestId).delete();
      if (mounted) {
        setState(() {
          _friendRequestId = null;
          _friendshipStatus = null;
        });
      }
    } else {
      final docRef = await firestore.collection('friendRequests').add({
        'from': widget.currentUserId,
        'to': widget.userData['uid'],
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() {
          _friendRequestId = docRef.id;
          _friendshipStatus = 'pending';
        });
      }
    }
  }

  Future<void> _acceptRequest() async {
    if (_incomingRequestId == null) return;

    await FirebaseFirestore.instance
        .collection('friendRequests')
        .doc(_incomingRequestId)
        .update({'status': 'accepted'});

    if (mounted) {
      setState(() {
        _friendshipStatus = 'accepted';
      });
    }
  }

  Future<void> _rejectRequest() async {
    if (_incomingRequestId == null) return;

    await FirebaseFirestore.instance
        .collection('friendRequests')
        .doc(_incomingRequestId)
        .delete();

    if (mounted) {
      setState(() {
        _incomingRequestId = null;
        _friendshipStatus = null;
      });
    }
  }

  void _goToChat() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showAuthWarning();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          receiverUserId: widget.userData['uid'],
          receiverUserName: widget.userData['username'] ?? 'Без имени',
          receiverAvatarUrl: widget.userData['avatarUrl'] ?? '',
        ),
      ),
    );
  }

  void _showAuthWarning() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Требуется авторизация'),
        content: const Text('Для общения необходимо войти в аккаунт'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingIcon() {
    if (_friendshipStatus == 'pending' && _friendRequestId != null) {
      return IconButton(
        icon: const Icon(Icons.check, color: Colors.green),
        onPressed: _sendOrCancelRequest,
      );
    }

    if (_friendshipStatus == 'pending' && _incomingRequestId != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: _acceptRequest,
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: _rejectRequest,
          ),
        ],
      );
    }

    if (_friendshipStatus == 'accepted') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people, color: Colors.green),
          IconButton(
            icon: const Icon(Icons.message, color: Colors.lightBlueAccent),
            onPressed: () {
              if (widget.currentUserId.isEmpty) {
                _showAuthWarning();
                return;
              }
              _goToChat();
            },
          ),
        ],
      );
    }

    return IconButton(
      icon: const Icon(Icons.person_add, color: Colors.white),
      onPressed: _sendOrCancelRequest,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: widget.userData['avatarUrl'] != null &&
              widget.userData['avatarUrl'].isNotEmpty
              ? NetworkImage(widget.userData['avatarUrl'])
              : const AssetImage('assets/default_avatar.png') as ImageProvider,
        ),
        title: Text(
          widget.userData['username'] ?? '',
          style: const TextStyle(color: Colors.white),
        ),
        trailing: _buildTrailingIcon(),
      ),
    );
  }
}