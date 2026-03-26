import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/server.dart';

/// Persists the list of monitored servers locally using SharedPreferences.
class ServerStorage {
  static const _key = 'servers';

  /// Load all saved servers
  Future<List<Server>> loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null || data.isEmpty) return [];

    final list = jsonDecode(data) as List<dynamic>;
    return list
        .map((e) => Server.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Save the full server list
  Future<void> saveServers(List<Server> servers) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(servers.map((s) => s.toJson()).toList());
    await prefs.setString(_key, data);
  }

  /// Add a new server
  Future<void> addServer(Server server) async {
    final servers = await loadServers();
    servers.add(server);
    await saveServers(servers);
  }

  /// Remove a server by ID
  Future<void> removeServer(String id) async {
    final servers = await loadServers();
    servers.removeWhere((s) => s.id == id);
    await saveServers(servers);
  }

  /// Update an existing server
  Future<void> updateServer(Server updated) async {
    final servers = await loadServers();
    final index = servers.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      servers[index] = updated;
      await saveServers(servers);
    }
  }
}
