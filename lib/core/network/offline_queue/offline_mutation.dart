/// Represents an immutable HTTP mutation made offline to be dispatched later.
class OfflineMutation {
  final String id;
  final String endpoint;
  final String method; // POST, PATCH, PUT, DELETE
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final int retryCount;
  final String description;

  const OfflineMutation({
    required this.id,
    required this.endpoint,
    required this.method,
    required this.payload,
    required this.timestamp,
    this.retryCount = 0,
    required this.description,
  });

  OfflineMutation copyWith({
    String? id,
    String? endpoint,
    String? method,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    int? retryCount,
    String? description,
  }) {
    return OfflineMutation(
      id: id ?? this.id,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endpoint': endpoint,
      'method': method,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
      'description': description,
    };
  }

  factory OfflineMutation.fromJson(Map<String, dynamic> json) {
    return OfflineMutation(
      id: json['id'] as String,
      endpoint: json['endpoint'] as String,
      method: (json['method'] as String?)?.toUpperCase() ?? 'POST',
      payload: (json['payload'] as Map<String, dynamic>?) ?? {},
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? 'მოქმედება ოფლაინში',
    );
  }
}
