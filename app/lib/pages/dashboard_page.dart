import 'dart:async';
import 'package:flutter/material.dart';
import '../models/server.dart';
import '../models/metrics.dart';
import '../services/api_client.dart';
import '../services/server_storage.dart';
import '../widgets/add_server_dialog.dart';
import '../widgets/server_card.dart';
import 'server_detail_page.dart';

/// Main dashboard showing all monitored servers.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _storage = ServerStorage();
  List<Server> _servers = [];

  // Cache of latest metrics per server
  final Map<String, MetricsSnapshot> _metricsCache = {};
  final Map<String, bool> _onlineCache = {};
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadServers();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshAll());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadServers() async {
    final servers = await _storage.loadServers();
    setState(() {
      _servers = servers;
      _loading = false;
    });
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    for (final server in _servers) {
      _fetchServer(server);
    }
  }

  Future<void> _fetchServer(Server server) async {
    final client = ApiClient(baseUrl: server.baseUrl, token: server.token);
    try {
      final metrics = await client.fetchMetrics();
      setState(() {
        _metricsCache[server.id] = metrics;
        _onlineCache[server.id] = true;
      });
    } catch (_) {
      setState(() {
        _onlineCache[server.id] = false;
      });
    }
  }

  void _addServer() async {
    final result = await showDialog<Server>(
      context: context,
      builder: (_) => const AddServerDialog(),
    );
    if (result != null) {
      await _storage.addServer(result);
      _loadServers();
    }
  }

  void _removeServer(Server server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Server'),
        content: Text('Remove "${server.name}" from monitoring?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _storage.removeServer(server.id);
      setState(() {
        _metricsCache.remove(server.id);
        _onlineCache.remove(server.id);
      });
      _loadServers();
    }
  }

  void _openDetail(Server server) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServerDetailPage(server: server),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = _onlineCache.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Server Monitor${_servers.isNotEmpty ? " ($onlineCount/${_servers.length})" : ""}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: 'Refresh all',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _servers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _servers.length,
                    itemBuilder: (context, index) {
                      final server = _servers[index];
                      final metrics = _metricsCache[server.id];
                      final online = _onlineCache[server.id] ?? false;

                      return ServerCard(
                        server: server,
                        metrics: metrics,
                        online: online,
                        onTap: () => _openDetail(server),
                        onLongPress: () => _removeServer(server),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addServer,
        icon: const Icon(Icons.add),
        label: const Text('Add Server'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dns_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No servers yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Install the agent on your server,\nthen tap "Add Server" to begin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
