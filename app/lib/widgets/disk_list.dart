import 'package:flutter/material.dart';
import '../models/metrics.dart';

/// Displays disk partitions as a list with progress bars.
class DiskList extends StatelessWidget {
  final DiskMetrics disk;

  const DiskList({super.key, required this.disk});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Disk', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            if (disk.partitions.isEmpty)
              const Text('No disk data available')
            else
              ...disk.partitions.map((p) => _DiskPartitionTile(partition: p)),
          ],
        ),
      ),
    );
  }
}

class _DiskPartitionTile extends StatelessWidget {
  final DiskPartition partition;

  const _DiskPartitionTile({required this.partition});

  @override
  Widget build(BuildContext context) {
    final pct = partition.usedPercent;
    final color = pct > 90
        ? Colors.red
        : pct > 70
            ? Colors.orange
            : Colors.blue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  partition.mountpoint,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${partition.usedFormatted} / ${partition.totalFormatted}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 2),
          Text(
            '${pct.toStringAsFixed(1)}% used (${partition.fstype})',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
