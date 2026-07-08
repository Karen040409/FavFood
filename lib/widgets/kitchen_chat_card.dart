import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../theme/app_theme.dart';
import 'section_header.dart';

/// WebSocket echo on Home — same pattern as the Flutter networking tutorial.
class KitchenChatCard extends StatefulWidget {
  const KitchenChatCard({super.key});

  @override
  State<KitchenChatCard> createState() => _KitchenChatCardState();
}

class _KitchenChatCardState extends State<KitchenChatCard> {
  final TextEditingController _controller = TextEditingController();
  late final WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    _channel = WebSocketChannel.connect(Uri.parse('wss://echo.websocket.org'));
  }

  @override
  void dispose() {
    _channel.sink.close();
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    if (_controller.text.isNotEmpty) {
      _channel.sink.add(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard(cs).copyWith(
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: 'Kitchen chat (WebSocket)',
            subtitle: 'Messages echo live from the server — useful for real-time tips or chat.',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: AppColors.accentSage),
                  const SizedBox(width: 6),
                  Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Send a message',
              prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
            ),
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _send,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send'),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: StreamBuilder(
              stream: _channel.stream,
              builder: (context, snapshot) {
                return Text(
                  snapshot.hasData ? 'Echo: ${snapshot.data}' : 'Waiting for a reply…',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
