import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_profile_service.dart';

String userInitials(User? user) {
  if (user == null) return '?';

  final name = user.displayName?.trim();
  if (name != null && name.isNotEmpty) {
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  final email = user.email;
  if (email != null && email.isNotEmpty) {
    return email[0].toUpperCase();
  }

  return '?';
}

ImageProvider? avatarImageProvider(String? url) {
  if (url == null || url.isEmpty) return null;

  if (url.startsWith('data:')) {
    final commaIndex = url.indexOf(',');
    if (commaIndex == -1) return null;
    try {
      final bytes = base64Decode(url.substring(commaIndex + 1));
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  return NetworkImage(url);
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.photoUrl,
    this.radius = 30,
    this.showEditBadge = false,
    this.onTap,
  });

  final User? user;
  final String? photoUrl;
  final double radius;
  final bool showEditBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedPhotoUrl = photoUrl ?? user?.photoURL;
    final imageProvider = avatarImageProvider(resolvedPhotoUrl);

    Widget avatar = CircleAvatar(
      key: ValueKey(resolvedPhotoUrl ?? userInitials(user)),
      radius: radius,
      backgroundColor: cs.primaryContainer,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              userInitials(user),
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.62,
              ),
            )
          : null,
    );

    if (showEditBadge) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                border: Border.all(color: cs.surface, width: 2),
              ),
              child: Icon(Icons.camera_alt_rounded, size: radius * 0.34, color: cs.onPrimary),
            ),
          ),
        ],
      );
    }

    if (onTap == null) return avatar;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      ),
    );
  }
}

class AuthUserAvatar extends StatelessWidget {
  const AuthUserAvatar({
    super.key,
    this.radius = 30,
    this.showEditBadge = false,
    this.onTap,
  });

  final double radius;
  final bool showEditBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data ?? FirebaseAuth.instance.currentUser;
        if (user == null) {
          return UserAvatar(
            user: null,
            radius: radius,
            showEditBadge: showEditBadge,
            onTap: onTap,
          );
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(UserProfileService.usersCollection)
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            final profileUrl = profileSnapshot.data?.data()?['photoUrl'] as String?;

            return UserAvatar(
              user: user,
              photoUrl: profileUrl ?? user.photoURL,
              radius: radius,
              showEditBadge: showEditBadge,
              onTap: onTap,
            );
          },
        );
      },
    );
  }
}
