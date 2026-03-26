import 'package:flutter/material.dart';
import '../models/server.dart';
import '../models/metrics.dart';

/// Card showing a server's summary on the dashboard.
class ServerCard extends StatelessWidget {
  final Server server;
  final MetricsSnapshot? metrics;
  final bool online;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ServerCard({
    super.key,
    required this.server,
    required this.metrics,
    required this.online,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: online ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      server.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${server.host}:${server.port}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (m != null) ...[
                const SizedBox(height: 12),
                // Quick stats row
                Row(
                  children: [
                    _QuickStat(
                      icon: Icons.memory,
                      label: 'CPU',
                      value: '${m.cpu.usagePercent.toStringAsFixed(1)}%',
                      color: _statColor(m.cpu.usagePercent),
                    ),
                    const SizedBox(width: 16),
                    _QuickStat(
                      icon: Icons.storage,
                      label: 'RAM',
                      value: '${m.memory.usedPercent.toStringAsFixed(1)}%',
                      color: _statColor(m.memory.usedPercent),
                    ),
                    const SizedBox(width: 16),
                    _QuickStat(
                      icon: Icons.schedule,
                      label: 'Uptime',
                      value: m.system.uptimeFormatted,
                      color: Colors.blue,
                    ),
                  ],
                ),
                if (server.expireDate != null) ...[
                  const SizedBox(height: 8),
                  _buildExpireBadge(context),
                ],
              ] else if (!online) ...[
                const SizedBox(height: 8),
                Text(
                  'Server unreachable',
                  style: TextStyle(color: Colors.red[400], fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpireBadge(BuildContext context) {
    final expire = server.expireDate!;
    final daysLeft = expire.difference(DateTime.now()).inDays;
    final color = daysLeft < 7
        ? Colors.red
        : daysLeft < 30
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Expires in $daysLeft days',
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }

  Color _statColor(double value) {
    if (value > 90) return Colors.red;
    if (value > 70) return Colors.orange;
    return Colors.green;
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
