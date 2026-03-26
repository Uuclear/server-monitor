import 'dart:async';
import 'package:flutter/material.dart';
import '../models/server.dart';
import '../models/metrics.dart';
import '../services/api_client.dart';
import '../widgets/metric_gauge.dart';
import '../widgets/disk_list.dart';

/// Detailed view for a single server showing all metrics.
class ServerDetailPage extends StatefulWidget {
  final Server server;

  const ServerDetailPage({super.key, required this.server});

  @override
  State<ServerDetailPage> createState() => _ServerDetailPageState();
}

class _ServerDetailPageState extends State<ServerDetailPage> {
  MetricsSnapshot? _metrics;
  bool _loading = true;
  String? _error;
  Timer? _timer;
  final List<double> _cpuHistory = [];
  final List<double> _memHistory = [];
  static const _maxHistory = 60; // Keep last 60 data points

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    final client = ApiClient(
      baseUrl: widget.server.baseUrl,
      token: widget.server.token,
    );
    try {
      final metrics = await client.fetchMetrics();
      setState(() {
        _metrics = metrics;
        _loading = false;
        _error = null;
        _cpuHistory.add(metrics.cpu.usagePercent);
        if (_cpuHistory.length > _maxHistory) _cpuHistory.removeAt(0);
        _memHistory.add(metrics.memory.usedPercent);
        if (_memHistory.length > _maxHistory) _memHistory.removeAt(0);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _metrics;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.server.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetch,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _fetch, child: const Text('Retry')),
                    ],
                  ),
                )
              : m == null
                  ? const Center(child: Text('No data'))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildSystemInfo(m.system),
                          const SizedBox(height: 16),
                          _buildCPUCard(m.cpu),
                          const SizedBox(height: 16),
                          _buildMemoryCard(m.memory),
                          const SizedBox(height: 16),
                          DiskList(disk: m.disk),
                          const SizedBox(height: 16),
                          _buildNetworkCard(m.network),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSystemInfo(SystemInfo info) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.computer, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('System Info', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            _infoRow('Hostname', info.hostname),
            _infoRow('Platform', '${info.platform} ${info.platformVersion}'),
            _infoRow('Architecture', info.architecture),
            _infoRow('Uptime', info.uptimeFormatted),
            if (widget.server.expireDate != null)
              _infoRow('Expire Date',
                  '${widget.server.expireDate!.year}-${widget.server.expireDate!.month.toString().padLeft(2, '0')}-${widget.server.expireDate!.day.toString().padLeft(2, '0')}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCPUCard(CpuMetrics cpu) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('CPU', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MetricGauge(
                    value: cpu.usagePercent,
                    label: 'Usage',
                    color: _gaugeColor(cpu.usagePercent),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('${cpu.coreCount} cores', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _loadRow('1m', cpu.load1),
                      _loadRow('5m', cpu.load5),
                      _loadRow('15m', cpu.load15),
                    ],
                  ),
                ),
              ],
            ),
            if (_cpuHistory.length > 1) ...[
              const SizedBox(height: 12),
              _buildMiniChart(_cpuHistory, Colors.blue),
            ],
          ],
        ),
      ),
    );
  }

  Widget _loadRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value.toStringAsFixed(2), style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(MemoryMetrics mem) {
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
                Text('Memory', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MetricGauge(
                    value: mem.usedPercent,
                    label: 'RAM',
                    color: _gaugeColor(mem.usedPercent),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _memRow('Total', mem.totalFormatted),
                      _memRow('Used', mem.usedFormatted),
                      _memRow('Free', mem.availableFormatted),
                    ],
                  ),
                ),
              ],
            ),
            if (mem.swapTotal > 0) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: mem.swapTotal > 0 ? mem.swapUsed / mem.swapTotal : 0,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 4),
              Text(
                'Swap: ${MemoryMetrics.formatBytes(mem.swapUsed)} / ${MemoryMetrics.formatBytes(mem.swapTotal)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (_memHistory.length > 1) ...[
              const SizedBox(height: 12),
              _buildMiniChart(_memHistory, Colors.green),
            ],
          ],
        ),
      ),
    );
  }

  Widget _memRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNetworkCard(NetworkMetrics net) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Network', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            ...net.interfaces.map((iface) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 60, child: Text(iface.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                  Expanded(child: Text('↑ ${iface.sentFormatted}', style: const TextStyle(fontSize: 13))),
                  Expanded(child: Text('↓ ${iface.recvFormatted}', style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Simple sparkline chart
  Widget _buildMiniChart(List<double> data, Color color) {
    return SizedBox(
      height: 40,
      child: CustomPaint(
        painter: _SparklinePainter(data: data, color: color),
        size: Size.infinite,
      ),
    );
  }

  Color _gaugeColor(double value) {
    if (value > 90) return Colors.red;
    if (value > 70) return Colors.orange;
    return Colors.green;
  }
}

/// Simple sparkline painter
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final maxVal = 100.0;
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (data[i] / maxVal) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => true;
}
