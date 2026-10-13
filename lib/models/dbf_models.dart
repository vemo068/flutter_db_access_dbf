class DbfField {
  final String name;
  final String type; // 'C' (Char), 'N' (Numeric), 'D' (Date), 'L' (Logical), 'F' (Float), 'M' (Memo)
  final int length;
  final int decimals;

  const DbfField({
    required this.name,
    required this.type,
    required this.length,
    this.decimals = 0,
  });

  String get typeDescription {
    switch (type.toUpperCase()) {
      case 'C':
        return 'Text ($length)';
      case 'N':
        return decimals > 0 ? 'Decimal ($length,$decimals)' : 'Integer ($length)';
      case 'F':
        return 'Float ($length,$decimals)';
      case 'D':
        return 'Date';
      case 'L':
        return 'Logical/Bool';
      case 'M':
        return 'Memo';
      default:
        return 'Type $type ($length)';
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'length': length,
    'decimals': decimals,
  };
}

class DbfTable {
  final List<DbfField> fields;
  final List<Map<String, dynamic>> records;
  final int recordCount;
  final DateTime lastUpdate;
  final String filePath;
  final int fileSizeBytes;

  DbfTable({
    required this.fields,
    required this.records,
    required this.recordCount,
    required this.lastUpdate,
    required this.filePath,
    required this.fileSizeBytes,
  });
}
