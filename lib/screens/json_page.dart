import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/manual_user.dart';
import '../models/photo.dart';
import '../models/serializable_user.dart';
import '../models/address.dart';
import '../services/photo_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';

class JsonPage extends StatelessWidget {
  const JsonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'JSON playground',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Manual'),
              Tab(text: 'Generated'),
              Tab(text: 'Photos'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ManualJsonTab(),
                _GeneratedJsonTab(),
                _PhotosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonCard extends StatelessWidget {
  const _JsonCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassCard(cs),
      child: child,
    );
  }
}

class _ManualJsonTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userMap = jsonDecode(sampleUserJson) as Map<String, dynamic>;
    final user = ManualUser.fromJson(userMap);
    final encoded = jsonEncode(user);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _JsonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Howdy, ${user.name}!', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 6),
              Text('Email: ${user.email}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _JsonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Encoded JSON:', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    tooltip: 'Copy JSON',
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: encoded));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('JSON copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(encoded, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.45)),
            ],
          ),
        ),
      ],
    );
  }
}

class _GeneratedJsonTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = SerializableUser(
      name: 'John',
      address: const Address(street: 'My st.', city: 'New York'),
    );
    final jsonMap = user.toJson();
    final encoded = jsonEncode(jsonMap);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _JsonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('json_serializable', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text('Name: ${user.name}'),
              Text('Street: ${user.address.street}'),
              Text('City: ${user.address.city}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _JsonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('toJson() with nested address:', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SelectableText(encoded, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.45)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotosTab extends StatefulWidget {
  @override
  State<_PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends State<_PhotosTab> {
  late Future<List<Photo>> _futurePhotos;

  @override
  void initState() {
    super.initState();
    _futurePhotos = fetchPhotos(http.Client());
  }

  void _reload() {
    setState(() {
      _futurePhotos = fetchPhotos(http.Client());
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Photo>>(
      future: _futurePhotos,
      builder: (context, snapshot) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reload'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      snapshot.hasData
                          ? '${snapshot.data!.length} photos loaded'
                          : snapshot.hasError
                              ? 'Load failed'
                              : 'Loading…',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildPhotoBody(snapshot),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoBody(AsyncSnapshot<List<Photo>> snapshot) {
    if (snapshot.hasError) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load photos',
        subtitle: '${snapshot.error}',
        action: FilledButton.tonal(onPressed: _reload, child: const Text('Try again')),
      );
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    final photos = snapshot.data!;
    if (photos.isEmpty) {
      return const EmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No photos loaded.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Image.network(
                  photo.displayThumbnailUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image_rounded)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  photo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.3),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
