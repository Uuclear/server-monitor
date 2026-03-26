/// Represents a monitored server with its connection details.
class Server {
  final String id;       // Unique identifier
  final String name;     // User-given name
  final String host;     // IP or domain
  final int port;        // Agent API port
  final String token;    // Auth token (empty if none)
  final DateTime? expireDate;  // VPS expiration date (optional)

  Server({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    this.token = '',
    this.expireDate,
  });

  /// API base URL for this server
  String get baseUrl => 'http://$host:$port';

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'port': port,
    'token': token,
    'expireDate': expireDate?.toIso8601String(),
  };

  /// Create from JSON
  factory Server.fromJson(Map<String, dynamic> json) => Server(
    id: json['id'] as String,
    name: json['name'] as String,
    host: json['host'] as String,
    port: json['port'] as int,
    token: json['token'] as String? ?? '',
    expireDate: json['expireDate'] != null
        ? DateTime.parse(json['expireDate'] as String)
        : null,
  );

  /// Create a copy with some fields changed
  Server copyWith({
    String? name,
    String? host,
    int? port,
    String? token,
    DateTime? expireDate,
  }) =>
      Server(
        id: id,
        name: name ?? this.name,
        host: host ?? this.host,
        port: port ?? this.port,
        token: token ?? this.token,
        expireDate: expireDate ?? this.expireDate,
      );
}
