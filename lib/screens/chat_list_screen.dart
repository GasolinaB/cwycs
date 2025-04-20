import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Подключаем intl для форматирования дат
import 'chat_screen.dart';
import 'user_search_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final DateFormat _dateFormat = DateFormat('dd MMM');

  Future<void> _togglePin(String chatId, bool isPinned) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('userChats').doc(user.uid).update({
      'pinnedChats': isPinned
          ? FieldValue.arrayRemove([chatId])
          : FieldValue.arrayUnion([chatId])
    });
  }

  Future<void> _deleteChat(String chatId, bool deleteForEveryone) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (deleteForEveryone) {
      await _firestore.collection('chats').doc(chatId).delete();
    } else {
      await _firestore.collection('userChats').doc(user.uid).update({
        'activeChats': FieldValue.arrayRemove([chatId])
      });
    }
  }

  Widget _buildTimeWidget(Timestamp? timestamp) {
    if (timestamp == null) return const SizedBox.shrink();

    final date = timestamp.toDate();
    final now = DateTime.now();
    final String timeText = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day
        ? _timeFormat.format(date)
        : _dateFormat.format(date);

    return Text(
      timeText,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
      ),
    );
  }

  Widget _buildPinnedIndicator(bool isPinned) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isPinned
          ? Icon(
        Icons.push_pin,
        color: Colors.amber[700],
        size: 18.0,
      )
          : SizedBox(width: 18.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Пользователь не авторизован'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserSearchScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('userChats').doc(currentUser.uid).snapshots(),
        builder: (context, userChatsSnapshot) {
          if (userChatsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userChatsSnapshot.hasError) {
            return Center(child: Text('Ошибка: ${userChatsSnapshot.error}'));
          }

          if (!userChatsSnapshot.hasData || !userChatsSnapshot.data!.exists) {
            // Создаем документ при первом открытии
            _firestore.collection('userChats').doc(currentUser.uid).set({
              'activeChats': [],
              'pinnedChats': [],
            }, SetOptions(merge: true));

            return const Center(child: CircularProgressIndicator());
          }

          final userChatsData = userChatsSnapshot.data!.data() as Map<String, dynamic>;
          final pinnedChats = List<String>.from(userChatsData['pinnedChats'] ?? []);

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('chats')
                .where('users', arrayContains: currentUser.uid)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, chatsSnapshot) {
              if (chatsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (chatsSnapshot.hasError) {
                return Center(child: Text('Ошибка чатов: ${chatsSnapshot.error}'));
              }

              final chats = chatsSnapshot.data!.docs;
              final pinned = chats.where((c) => pinnedChats.contains(c.id)).toList();
              final unpinned = chats.where((c) => !pinnedChats.contains(c.id)).toList();

              return CustomScrollView(
                slivers: [
                  _buildChatListSection('Закрепленные', pinned, currentUser.uid),
                  _buildChatListSection('Все чаты', unpinned, currentUser.uid),
                ],
              );
            },
          );
        },
      ),
    );
  }

  SliverList _buildChatListSection(String title, List<QueryDocumentSnapshot> chats, String userId) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }
          final chat = chats[index - 1];
          return _buildChatItem(chat, userId);
        },
        childCount: chats.isEmpty ? 0 : chats.length + 1,
      ),
    );
  }

  Widget _buildChatItem(QueryDocumentSnapshot chat, String userId) {
    final data = chat.data() as Map<String, dynamic>;
    final participants = List<String>.from(data['users']);
    final receiverId = participants.firstWhere((id) => id != userId);
    final isPinned = (data['pinnedBy'] as List?)?.contains(userId) ?? false;

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(receiverId).get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(title: Text('Загрузка...'));
        }

        if (userSnapshot.hasError) {
          return ListTile(title: Text('Ошибка: ${userSnapshot.error}'));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final lastMessage = data['lastMessage'] ?? '';
        final timestamp = data['timestamp'] as Timestamp?;

        return Dismissible(
          key: Key(chat.id),
          direction: DismissDirection.horizontal,
          background: _buildSwipeBackground(Colors.amber, Icons.push_pin, Alignment.centerLeft),
          secondaryBackground: _buildSwipeBackground(Colors.red, Icons.delete, Alignment.centerRight),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              return await _showDeleteDialog(chat.id);
            } else if (direction == DismissDirection.startToEnd) {
              _togglePin(chat.id, isPinned);
              return false;
            }
            return null;
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: userData['avatarUrl'] != null &&
                        userData['avatarUrl'].isNotEmpty
                        ? NetworkImage(userData['avatarUrl'])
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildPinnedIndicator(isPinned),
                  ),
                ],
              ),
              title: Text(
                userData['username'] ?? 'Без имени',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[400]),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeWidget(timestamp),
                  if ((data['unreadCount'] is int) && (data['unreadCount'] as int) > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        (data['unreadCount'] as int).toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 500),
                  pageBuilder: (_, __, ___) => ChatScreen(
                    receiverUserId: receiverId,
                    receiverUserName: userData['username'] ?? 'Без имени',
                    receiverAvatarUrl: userData['avatarUrl'] ?? '',
                  ),
                  transitionsBuilder: (_, animation, __, child) {
                    return SlideTransition(
                      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
                      child: child,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwipeBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteDialog(String chatId) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить чат'),
        content: const Text('Вы хотите удалить чат только для себя или для всех участников?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, false);
              _deleteChat(chatId, false);
            },
            child: const Text('Только для меня'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              _deleteChat(chatId, true);
            },
            child: const Text('Для всех', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
