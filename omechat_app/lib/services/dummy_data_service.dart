import 'dart:math';
import 'package:flutter/material.dart';

import '../../domain/models/chat_models.dart';

class DummyUser {
  final String name;
  final String avatarUrl;
  final String phone;
  final String bio;

  DummyUser({
    required this.name, 
    required this.avatarUrl,
    required this.phone,
    required this.bio
  });

  DummyUser copyWith({String? name, String? avatarUrl, String? phone, String? bio}) {
    return DummyUser(
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
    );
  }
}

class DummyDataService {
  static final DummyDataService _instance = DummyDataService._internal();
  factory DummyDataService() => _instance;
  DummyDataService._internal();

  final Random _random = Random();

  // --- MUTABLE USER STATE ---
  final ValueNotifier<DummyUser> currentUserNotifier = ValueNotifier(
    DummyUser(
      name: 'Gökhan (You)', 
      avatarUrl: 'https://i.pravatar.cc/150?u=0',
      phone: '+90 555 123 45 67',
      bio: 'Hey there! I am using OmeChat.',
    )
  );

  void updateProfile({String? name, String? avatarUrl, String? phone, String? bio}) {
    currentUserNotifier.value = currentUserNotifier.value.copyWith(
      name: name,
      avatarUrl: avatarUrl,
      phone: phone,
      bio: bio,
    );
  }

  // --- FAKE DATA ---
  final List<Map<String, String>> _users = [
    {'name': 'Elif Yılmaz', 'avatar': 'https://i.pravatar.cc/150?u=1'},
    {'name': 'Burak Demir', 'avatar': 'https://i.pravatar.cc/150?u=2'},
    {'name': 'Ayşe Kaya', 'avatar': 'https://i.pravatar.cc/150?u=3'},
    {'name': 'Mehmet Öz', 'avatar': 'https://i.pravatar.cc/150?u=4'},
    {'name': 'Selin Çelik', 'avatar': 'https://i.pravatar.cc/150?u=5'},
    {'name': 'Can Yıldız', 'avatar': 'https://i.pravatar.cc/150?u=6'},
    {'name': 'Zeynep Ak', 'avatar': 'https://i.pravatar.cc/150?u=7'},
    {'name': 'Emre Koç', 'avatar': 'https://i.pravatar.cc/150?u=8'},
    {'name': 'Deniz Arslan', 'avatar': 'https://i.pravatar.cc/150?u=9'},
    {'name': 'Gamze Polat', 'avatar': 'https://i.pravatar.cc/150?u=10'},
    {'name': 'Murat Tekin', 'avatar': 'https://i.pravatar.cc/150?u=11'},
    {'name': 'Ece Güneş', 'avatar': 'https://i.pravatar.cc/150?u=12'},
    {'name': 'Barış Ünal', 'avatar': 'https://i.pravatar.cc/150?u=13'},
    {'name': 'Seda Şahin', 'avatar': 'https://i.pravatar.cc/150?u=14'},
    {'name': 'Kaan kurt', 'avatar': 'https://i.pravatar.cc/150?u=15'},
  ];

  final List<String> _messages = [
    'Naber?',
    'Yarın görüşürüz.',
    'Tamamdır, hallederim.',
    'Bence de harika fikir! 🔥',
    'Akşam ne yapıyorsun?',
    'Dosyayı gönderdim, baktın mı?',
    'Hahaha çok iyiymiş 😂',
    'Geliyorum 5 dakikaya.',
    'Toplantı başladı mı?',
    'Okey.',
    'Süper!',
    'Bilmiyorum, bakarız.',
    'Fotoğraf çok güzel çıkmış 📸',
    'Günaydınn ☀️',
    'İyi geceler 🌙',
  ];

  List<Conversation> getDummyChats() {
    return List.generate(20, (index) {
      final user = _users[index % _users.length];
      final isOnline = _random.nextBool();
      final hasUnread = _random.nextBool();
      final unreadCount = hasUnread ? _random.nextInt(10) + 1 : 0;
      final lastActivity = DateTime.now().subtract(Duration(minutes: _random.nextInt(1000)));
      final userId = 'user_${index % _users.length}';

      return Conversation(
        id: 'chat_$index',
        otherUserId: userId,
        otherUsername: user['name']!,
        otherAvatarUrl: user['avatar'],
        lastMessage: _messages[_random.nextInt(_messages.length)],
        lastActivity: lastActivity,
        unreadCount: unreadCount,
        isOnline: isOnline,
      );
    });
  }

  List<Map<String, dynamic>> getDummyStories() {
    return List.generate(10, (index) {
      final user = _users[index % _users.length];
      return {
        'id': 'story_$index',
        'username': user['name'],
        'avatar': user['avatar'],
        'isViewed': false,
        'imageUrl': 'https://picsum.photos/400/800?random=$index',
      };
    });
  }
}
