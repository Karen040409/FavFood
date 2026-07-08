import 'package:flutter/material.dart';

import 'package:provider/provider.dart';



import '../models/album.dart';


import '../viewmodels/album_list_view_model.dart';

import '../widgets/empty_state.dart';

import '../widgets/section_header.dart';



class AlbumPage extends StatelessWidget {

  const AlbumPage({super.key});



  @override

  Widget build(BuildContext context) {

    final viewModel = context.watch<AlbumListViewModel>();

    final cs = Theme.of(context).colorScheme;



    return Column(

      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [

        Padding(

          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),

          child: SectionHeader(

            title: 'Photo albums',

            subtitle: 'Browse and manage albums from the JSONPlaceholder API',

            trailing: FilledButton.tonalIcon(

              onPressed: viewModel.isLoading ? null : viewModel.loadAlbums,

              icon: const Icon(Icons.refresh_rounded, size: 18),

              label: const Text('Reload'),

            ),

          ),

        ),

        if (viewModel.errorMessage != null)

          Padding(

            padding: const EdgeInsets.symmetric(horizontal: 20),

            child: Container(

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(

                color: cs.errorContainer.withValues(alpha: 0.45),

                borderRadius: BorderRadius.circular(14),

              ),

              child: Text(

                viewModel.errorMessage!,

                style: TextStyle(color: cs.onErrorContainer),

              ),

            ),

          ),

        Expanded(

          child: viewModel.isLoading && viewModel.albums.isEmpty

              ? const Center(child: CircularProgressIndicator())

              : viewModel.albums.isEmpty

                  ? const EmptyState(

                      icon: Icons.album_rounded,

                      title: 'No albums loaded yet',

                      subtitle: 'Tap Reload to fetch albums from the API.',

                    )

                  : ListView.builder(

                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),

                      itemCount: viewModel.albums.length,

                      itemBuilder: (context, index) {

                        final album = viewModel.albums[index];

                        return _AlbumCard(

                          album: album,

                          onTap: () => _showAlbumEditor(context, album),

                        );

                      },

                    ),

        ),

      ],

    );

  }



  void _showAlbumEditor(BuildContext context, Album album) {

    showModalBottomSheet<void>(

      context: context,

      isScrollControlled: true,

      showDragHandle: true,

      backgroundColor: Theme.of(context).colorScheme.surface,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

      ),

      builder: (sheetContext) => _AlbumEditorSheet(album: album),

    );

  }

}



class _AlbumCard extends StatelessWidget {

  const _AlbumCard({required this.album, required this.onTap});



  final Album album;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    final cs = Theme.of(context).colorScheme;



    return Card(

      margin: const EdgeInsets.only(bottom: 12),

      clipBehavior: Clip.antiAlias,

      child: InkWell(

        onTap: onTap,

        child: Padding(

          padding: const EdgeInsets.all(16),

          child: Row(

            children: [

              Container(

                width: 52,

                height: 52,

                decoration: BoxDecoration(

                  gradient: LinearGradient(

                    colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],

                  ),

                  borderRadius: BorderRadius.circular(14),

                ),

                alignment: Alignment.center,

                child: Text(

                  '${album.id}',

                  style: TextStyle(

                    color: cs.onPrimary,

                    fontWeight: FontWeight.w800,

                    fontSize: 16,

                  ),

                ),

              ),

              const SizedBox(width: 14),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      album.title,

                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),

                      maxLines: 2,

                      overflow: TextOverflow.ellipsis,

                    ),

                    const SizedBox(height: 4),

                    Text(

                      'User ID: ${album.userId}',

                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),

                    ),

                  ],

                ),

              ),

              Icon(Icons.chevron_right_rounded, color: cs.outline),

            ],

          ),

        ),

      ),

    );

  }

}



class _AlbumEditorSheet extends StatefulWidget {

  const _AlbumEditorSheet({required this.album});



  final Album album;



  @override

  State<_AlbumEditorSheet> createState() => _AlbumEditorSheetState();

}



class _AlbumEditorSheetState extends State<_AlbumEditorSheet> {

  late final TextEditingController _titleController;



  @override

  void initState() {

    super.initState();

    _titleController = TextEditingController(text: widget.album.title);

  }



  @override

  void dispose() {

    _titleController.dispose();

    super.dispose();

  }



  Future<void> _save() async {

    final title = _titleController.text.trim();

    if (title.isEmpty) return;



    final viewModel = context.read<AlbumListViewModel>();

    try {

      await viewModel.updateAlbum(widget.album.id, title);

      if (mounted) Navigator.pop(context);

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));

      }

    }

  }



  Future<void> _delete() async {

    final viewModel = context.read<AlbumListViewModel>();

    try {

      await viewModel.deleteAlbum(widget.album.id);

      if (mounted) Navigator.pop(context);

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;



    return Padding(

      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),

      child: Column(

        mainAxisSize: MainAxisSize.min,

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Text('Album #${widget.album.id}', style: Theme.of(context).textTheme.titleLarge),

          const SizedBox(height: 16),

          TextField(

            controller: _titleController,

            autofocus: true,

            decoration: const InputDecoration(labelText: 'Title'),

          ),

          const SizedBox(height: 20),

          FilledButton(onPressed: _save, child: const Text('Save')),

          const SizedBox(height: 8),

          TextButton(

            onPressed: _delete,

            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),

            child: const Text('Delete'),

          ),

        ],

      ),

    );

  }

}



class AlbumPageFab extends StatelessWidget {

  const AlbumPageFab({super.key});



  @override

  Widget build(BuildContext context) {

    return FloatingActionButton.extended(

      onPressed: () => _createAlbum(context),

      icon: const Icon(Icons.add_rounded),

      label: const Text('Create'),

    );

  }



  Future<void> _createAlbum(BuildContext context) async {

    final controller = TextEditingController();

    final title = await showDialog<String>(

      context: context,

      builder: (dialogContext) => AlertDialog(

        title: const Text('New album'),

        content: TextField(

          controller: controller,

          autofocus: true,

          decoration: const InputDecoration(hintText: 'Title'),

        ),

        actions: [

          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),

          FilledButton(

            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),

            child: const Text('Create'),

          ),

        ],

      ),

    );

    controller.dispose();



    if (title == null || title.isEmpty || !context.mounted) return;



    try {

      await context.read<AlbumListViewModel>().createAlbum(title);

    } catch (e) {

      if (context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));

      }

    }

  }

}


