class AccessColumn {
  final String name;
  final String rawType;
  final String friendlyType; // "String", "Integer", "Number", "Boolean", "DateTime"
  final bool isAutoIncrement;
  final bool isKey;
  final bool isReadOnly;
  final bool allowDbNull;
  final int size;

  AccessColumn({
    required this.name,
    required this.rawType,
    required this.friendlyType,
    this.isAutoIncrement = false,
    this.isKey = false,
    this.isReadOnly = false,
    this.allowDbNull = true,
    this.size = 0,
  });

  factory AccessColumn.fromJson(Map<String, dynamic> json) {
    return AccessColumn(
      name: json['name'] as String? ?? '',
      rawType: json['rawType'] as String? ?? '',
      friendlyType: json['friendlyType'] as String? ?? 'String',
      isAutoIncrement: json['isAutoIncrement'] as bool? ?? false,
      isKey: json['isKey'] as bool? ?? false,
      isReadOnly: json['isReadOnly'] as bool? ?? false,
      allowDbNull: json['allowDbNull'] as bool? ?? true,
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

class AccessTableSchema {
  final String tableName;
  final List<AccessColumn> columns;

  AccessTableSchema({
    required this.tableName,
    required this.columns,
  });

  AccessColumn? get primaryKeyColumn {
    try {
      return columns.firstWhere((c) => c.isKey);
    } catch (_) {
      try {
        return columns.firstWhere((c) => c.isAutoIncrement);
      } catch (_) {
        return columns.isNotEmpty ? columns.first : null;
      }
    }
  }
}

class AccessExecuteResult {
  final bool success;
  final int affectedRows;
  final String? error;

  AccessExecuteResult({
    required this.success,
    this.affectedRows = 0,
    this.error,
  });
}
