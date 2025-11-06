import 'package:flutter/material.dart';

class LogsCard extends StatelessWidget {
  final GestureTapCallback? onShareCurrentSession;
  final GestureTapCallback? onShareAllLogs;

  const LogsCard({super.key, this.onShareCurrentSession, this.onShareAllLogs});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Logs', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Share logs for debugging',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.share),
              title: const Text('Share Current Session'),
              subtitle: const Text('Share logs from this session only'),
              onTap: onShareCurrentSession,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_zip),
              title: const Text('Share All Logs'),
              subtitle: const Text('Share all session logs (last 10)'),
              onTap: onShareAllLogs,
            ),
          ],
        ),
      ),
    );
  }
}
