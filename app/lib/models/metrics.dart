/// System information from the agent
class SystemInfo {
  final String hostname;
  final String platform;
  final String platformVersion;
  final String architecture;
  final int uptime; // seconds
  final int bootTime;

  SystemInfo({
    required this.hostname,
    required this.platform,
    required this.platformVersion,
    required this.architecture,
    required this.uptime,
    required this.bootTime,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) => SystemInfo(
    hostname: json['hostname'] as String? ?? '',
    platform: json['platform'] as String? ?? '',
    platformVersion: json['platform_version'] as String? ?? '',
    architecture: json['architecture'] as String? ?? '',
    uptime: json['uptime'] as int? ?? 0,
    bootTime: json['boot_time'] as int? ?? 0,
  );

  /// Uptime formatted as "Xd Yh Zm"
  String get uptimeFormatted {
    final d = uptime ~/ 86400;
    final h = (uptime % 86400) ~/ 3600;
    final m = (uptime % 3600) ~/ 60;
    if (d > 0) return '${d}d ${h}h ${m}m';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

/// CPU metrics
class CpuMetrics {
  final double usagePercent;
  final int coreCount;
  final double load1;
  final double load5;
  final double load15;

  CpuMetrics({
    required this.usagePercent,
    required this.coreCount,
    required this.load1,
    required this.load5,
    required this.load15,
  });

  factory CpuMetrics.fromJson(Map<String, dynamic> json) => CpuMetrics(
    usagePercent: (json['usage_percent'] as num?)?.toDouble() ?? 0,
    coreCount: json['core_count'] as int? ?? 1,
    load1: (json['load_1'] as num?)?.toDouble() ?? 0,
    load5: (json['load_5'] as num?)?.toDouble() ?? 0,
    load15: (json['load_15'] as num?)?.toDouble() ?? 0,
  );
}

/// Memory metrics
class MemoryMetrics {
  final int total;
  final int used;
  final int available;
  final double usedPercent;
  final int swapTotal;
  final int swapUsed;

  MemoryMetrics({
    required this.total,
    required this.used,
    required this.available,
    required this.usedPercent,
    required this.swapTotal,
    required this.swapUsed,
  });

  factory MemoryMetrics.fromJson(Map<String, dynamic> json) => MemoryMetrics(
    total: json['total'] as int? ?? 0,
    used: json['used'] as int? ?? 0,
    available: json['available'] as int? ?? 0,
    usedPercent: (json['used_percent'] as num?)?.toDouble() ?? 0,
    swapTotal: json['swap_total'] as int? ?? 0,
    swapUsed: json['swap_used'] as int? ?? 0,
  );

  /// Format bytes to human-readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }

  String get totalFormatted => formatBytes(total);
  String get usedFormatted => formatBytes(used);
  String get availableFormatted => formatBytes(available);
}

/// Disk partition info
class DiskPartition {
  final String device;
  final String mountpoint;
  final String fstype;
  final int total;
  final int used;
  final int free;
  final double usedPercent;

  DiskPartition({
    required this.device,
    required this.mountpoint,
    required this.fstype,
    required this.total,
    required this.used,
    required this.free,
    required this.usedPercent,
  });

  factory DiskPartition.fromJson(Map<String, dynamic> json) => DiskPartition(
    device: json['device'] as String? ?? '',
    mountpoint: json['mountpoint'] as String? ?? '',
    fstype: json['fstype'] as String? ?? '',
    total: json['total'] as int? ?? 0,
    used: json['used'] as int? ?? 0,
    free: json['free'] as int? ?? 0,
    usedPercent: (json['used_percent'] as num?)?.toDouble() ?? 0,
  );

  String get totalFormatted => MemoryMetrics.formatBytes(total);
  String get usedFormatted => MemoryMetrics.formatBytes(used);
  String get freeFormatted => MemoryMetrics.formatBytes(free);
}

/// Disk metrics (all partitions)
class DiskMetrics {
  final List<DiskPartition> partitions;

  DiskMetrics({required this.partitions});

  factory DiskMetrics.fromJson(Map<String, dynamic> json) {
    final parts = (json['partitions'] as List<dynamic>?)
        ?.map((e) => DiskPartition.fromJson(e as Map<String, dynamic>))
        .where((p) => p.total > 0 && p.mountpoint != '/dev') // Filter out virtual/empty
        .toList() ?? [];
    return DiskMetrics(partitions: parts);
  }
}

/// Network interface stats
class NetworkInterface {
  final String name;
  final int bytesSent;
  final int bytesRecv;

  NetworkInterface({
    required this.name,
    required this.bytesSent,
    required this.bytesRecv,
  });

  factory NetworkInterface.fromJson(Map<String, dynamic> json) => NetworkInterface(
    name: json['name'] as String? ?? '',
    bytesSent: json['bytes_sent'] as int? ?? 0,
    bytesRecv: json['bytes_recv'] as int? ?? 0,
  );

  String get sentFormatted => MemoryMetrics.formatBytes(bytesSent);
  String get recvFormatted => MemoryMetrics.formatBytes(bytesRecv);
}

/// Network metrics (all interfaces)
class NetworkMetrics {
  final List<NetworkInterface> interfaces;

  NetworkMetrics({required this.interfaces});

  factory NetworkMetrics.fromJson(Map<String, dynamic> json) {
    final ifaces = (json['interfaces'] as List<dynamic>?)
        ?.map((e) => NetworkInterface.fromJson(e as Map<String, dynamic>))
        .where((i) => i.name != 'lo0' && (i.bytesSent > 0 || i.bytesRecv > 0))
        .toList() ?? [];
    return NetworkMetrics(interfaces: ifaces);
  }
}

/// Complete metrics snapshot
class MetricsSnapshot {
  final int timestamp;
  final SystemInfo system;
  final CpuMetrics cpu;
  final MemoryMetrics memory;
  final DiskMetrics disk;
  final NetworkMetrics network;

  MetricsSnapshot({
    required this.timestamp,
    required this.system,
    required this.cpu,
    required this.memory,
    required this.disk,
    required this.network,
  });

  factory MetricsSnapshot.fromJson(Map<String, dynamic> json) => MetricsSnapshot(
    timestamp: json['timestamp'] as int? ?? 0,
    system: SystemInfo.fromJson(json['system'] as Map<String, dynamic>? ?? {}),
    cpu: CpuMetrics.fromJson(json['cpu'] as Map<String, dynamic>? ?? {}),
    memory: MemoryMetrics.fromJson(json['memory'] as Map<String, dynamic>? ?? {}),
    disk: DiskMetrics.fromJson(json['disk'] as Map<String, dynamic>? ?? {}),
    network: NetworkMetrics.fromJson(json['network'] as Map<String, dynamic>? ?? {}),
  );
}
