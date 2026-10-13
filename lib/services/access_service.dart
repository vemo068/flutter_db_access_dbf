import 'dart:convert';
import 'dart:io';
import '../models/access_models.dart';

class AccessService {
  static String? _resolvedBridgeExe;

  /// Locates the access_bridge.exe binary on the system
  static Future<String> _getBridgeExePath() async {
    if (_resolvedBridgeExe != null && File(_resolvedBridgeExe!).existsSync()) {
      return _resolvedBridgeExe!;
    }

    final candidatePaths = [
      r'd:\DEV\maj_ged\tools\access_bridge.exe',
      r'd:\DEV\maj_ged\assets\bin\access_bridge.exe',
      '${Directory.current.path}\\tools\\access_bridge.exe',
      '${Directory.current.path}\\assets\\bin\\access_bridge.exe',
      '${File(Platform.resolvedExecutable).parent.path}\\tools\\access_bridge.exe',
      '${File(Platform.resolvedExecutable).parent.path}\\data\\flutter_assets\\assets\\bin\\access_bridge.exe',
    ];

    for (final p in candidatePaths) {
      if (File(p).existsSync()) {
        _resolvedBridgeExe = p;
        return p;
      }
    }

    // Try to auto-compile from C# source if available
    const csSource = r'd:\DEV\maj_ged\tools\access_bridge.cs';
    const targetExe = r'd:\DEV\maj_ged\tools\access_bridge.exe';
    const cscPath = r'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe';

    if (File(csSource).existsSync() && File(cscPath).existsSync()) {
      final res = await Process.run(cscPath, [
        '/optimize',
        '/target:exe',
        '/out:$targetExe',
        csSource,
      ]);
      if (res.exitCode == 0 && File(targetExe).existsSync()) {
        _resolvedBridgeExe = targetExe;
        return targetExe;
      }
    }

    throw Exception('access_bridge.exe could not be found. Please ensure tools/access_bridge.exe is compiled.');
  }

  /// Pings the database to verify connectivity
  static Future<bool> ping(String dbPath) async {
    if (!File(dbPath).existsSync()) return false;
    try {
      final exe = await _getBridgeExePath();
      final result = await Process.run(
        exe,
        ['ping', dbPath],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (result.exitCode == 0) {
        final json = jsonDecode(result.stdout.toString().trim());
        return json['status'] == 'ok';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Gets the list of user tables in the Access database
  static Future<List<String>> getTables(String dbPath) async {
    final exe = await _getBridgeExePath();
    final result = await Process.run(
      exe,
      ['tables', dbPath],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw Exception('Failed to get tables: ${result.stderr.toString().isNotEmpty ? result.stderr : result.stdout}');
    }
    final List<dynamic> list = jsonDecode(result.stdout.toString().trim());
    return list.cast<String>();
  }

  /// Gets the schema/columns for a specific table
  static Future<AccessTableSchema> getSchema(String dbPath, String tableName) async {
    final exe = await _getBridgeExePath();
    final result = await Process.run(
      exe,
      ['schema', dbPath, tableName],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw Exception('Failed to get schema for table $tableName: ${result.stderr.toString().isNotEmpty ? result.stderr : result.stdout}');
    }
    final List<dynamic> list = jsonDecode(result.stdout.toString().trim());
    final columns = list.map((item) => AccessColumn.fromJson(item as Map<String, dynamic>)).toList();
    return AccessTableSchema(tableName: tableName, columns: columns);
  }

  /// Runs a SELECT SQL query and returns rows
  static Future<List<Map<String, dynamic>>> query(String dbPath, String sql) async {
    final exe = await _getBridgeExePath();
    final result = await Process.run(
      exe,
      ['query', dbPath, sql],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    final outText = result.stdout.toString().trim();

    if (result.exitCode != 0) {
      throw Exception('SQL query error: ${result.stderr.toString().isNotEmpty ? result.stderr : outText}');
    }

    if (outText.startsWith('{') && outText.contains('"status":"error"')) {
      final errObj = jsonDecode(outText);
      throw Exception(errObj['error'] ?? 'SQL execution error');
    }

    final dynamic parsed = jsonDecode(outText);
    if (parsed is List) {
      return parsed.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Executes an INSERT, UPDATE, or DELETE SQL statement
  static Future<AccessExecuteResult> execute(String dbPath, String sql) async {
    final exe = await _getBridgeExePath();
    final result = await Process.run(
      exe,
      ['execute', dbPath, sql],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    final outText = result.stdout.toString().trim();

    if (result.exitCode != 0) {
      return AccessExecuteResult(
        success: false,
        error: result.stderr.toString().isNotEmpty ? result.stderr : outText,
      );
    }

    try {
      final json = jsonDecode(outText);
      if (json['status'] == 'ok') {
        return AccessExecuteResult(
          success: true,
          affectedRows: (json['affectedRows'] as num?)?.toInt() ?? 0,
        );
      } else {
        return AccessExecuteResult(
          success: false,
          error: json['error'] ?? 'Execution error',
        );
      }
    } catch (e) {
      return AccessExecuteResult(
        success: false,
        error: 'Invalid response from bridge: $outText',
      );
    }
  }

  /// Inserts a new record into [tableName]
  static Future<AccessExecuteResult> insertRecord(
    String dbPath,
    String tableName,
    Map<String, dynamic> rowData,
    AccessTableSchema schema,
  ) async {
    final cols = <String>[];
    final values = <String>[];

    for (final col in schema.columns) {
      if (col.isAutoIncrement || col.isReadOnly) continue;
      if (!rowData.containsKey(col.name)) continue;

      final val = rowData[col.name];
      if (val == null && !col.allowDbNull) continue;

      cols.add('[${col.name}]');
      values.add(_formatSqlValue(val, col));
    }

    if (cols.isEmpty) {
      return AccessExecuteResult(success: false, error: 'No writable fields provided to insert.');
    }

    final sql = 'INSERT INTO [$tableName] (${cols.join(', ')}) VALUES (${values.join(', ')})';
    return await execute(dbPath, sql);
  }

  /// Updates an existing record in [tableName]
  static Future<AccessExecuteResult> updateRecord(
    String dbPath,
    String tableName,
    Map<String, dynamic> rowData,
    String keyColumn,
    dynamic keyValue,
    AccessTableSchema schema,
  ) async {
    final setClauses = <String>[];

    for (final col in schema.columns) {
      if (col.name.toLowerCase() == keyColumn.toLowerCase()) continue;
      if (col.isAutoIncrement || col.isReadOnly) continue;
      if (!rowData.containsKey(col.name)) continue;

      final val = rowData[col.name];
      setClauses.add('[${col.name}] = ${_formatSqlValue(val, col)}');
    }

    if (setClauses.isEmpty) {
      return AccessExecuteResult(success: false, error: 'No fields to update.');
    }

    final keyColObj = schema.columns.firstWhere(
      (c) => c.name.toLowerCase() == keyColumn.toLowerCase(),
      orElse: () => AccessColumn(name: keyColumn, rawType: '', friendlyType: 'Integer'),
    );

    final whereClause = '[$keyColumn] = ${_formatSqlValue(keyValue, keyColObj)}';
    final sql = 'UPDATE [$tableName] SET ${setClauses.join(', ')} WHERE $whereClause';
    return await execute(dbPath, sql);
  }

  /// Deletes a record from [tableName]
  static Future<AccessExecuteResult> deleteRecord(
    String dbPath,
    String tableName,
    String keyColumn,
    dynamic keyValue,
    AccessTableSchema schema,
  ) async {
    final keyColObj = schema.columns.firstWhere(
      (c) => c.name.toLowerCase() == keyColumn.toLowerCase(),
      orElse: () => AccessColumn(name: keyColumn, rawType: '', friendlyType: 'Integer'),
    );

    final whereClause = '[$keyColumn] = ${_formatSqlValue(keyValue, keyColObj)}';
    final sql = 'DELETE FROM [$tableName] WHERE $whereClause';
    return await execute(dbPath, sql);
  }

  /// Formats value for Microsoft Access SQL syntax
  static String _formatSqlValue(dynamic val, AccessColumn col) {
    if (val == null) return 'NULL';

    if (col.friendlyType == 'Boolean') {
      if (val is bool) return val ? 'True' : 'False';
      final s = val.toString().toLowerCase();
      return (s == 'true' || s == '1' || s == 'yes') ? 'True' : 'False';
    }

    if (col.friendlyType == 'Integer' || col.friendlyType == 'Number') {
      if (val is num) return val.toString();
      final parsed = double.tryParse(val.toString());
      if (parsed != null) {
        return col.friendlyType == 'Integer' ? parsed.toInt().toString() : parsed.toString();
      }
      return '0';
    }

    if (col.friendlyType == 'DateTime') {
      final s = val.toString().trim();
      if (s.isEmpty) return 'NULL';
      return '#$s#';
    }

    // Default: String
    final str = val.toString().replaceAll("'", "''");
    return "'$str'";
  }

  /// Creates a sample Access database with default tables and records
  static Future<void> createSampleDatabase(String targetPath) async {
    final exe = await _getBridgeExePath();
    final file = File(targetPath);
    if (file.existsSync()) {
      file.deleteSync();
    }

    // Create file
    final res = await Process.run(exe, ['create_db', targetPath]);
    if (res.exitCode != 0) {
      throw Exception('Failed to create DB: ${res.stderr.toString().isNotEmpty ? res.stderr : res.stdout}');
    }

    // Create Employees table
    await execute(targetPath, '''
      CREATE TABLE Employees (
        ID AUTOINCREMENT PRIMARY KEY,
        FullName VARCHAR(100),
        Department VARCHAR(50),
        Salary DOUBLE,
        HireDate DATETIME,
        Active YESNO
      )
    ''');

    // Insert sample records (including Arabic Unicode)
    await execute(targetPath, "INSERT INTO Employees (FullName, Department, Salary, HireDate, Active) VALUES ('Aymane Hassouna', 'Engineering', 5500.0, #2024-01-15#, True)");
    await execute(targetPath, "INSERT INTO Employees (FullName, Department, Salary, HireDate, Active) VALUES ('أيمن حسونة', 'إدارة تقنية المعلومات والتحول الرقمي', 9500.0, #2023-05-01#, True)");
    await execute(targetPath, "INSERT INTO Employees (FullName, Department, Salary, HireDate, Active) VALUES ('Sarah Connor', 'Security', 4800.0, #2023-06-20#, True)");
    await execute(targetPath, "INSERT INTO Employees (FullName, Department, Salary, HireDate, Active) VALUES ('فاطمة الزهراء الإدريسي', 'الموارد البشرية والشؤون الإدارية', 6800.0, #2024-02-10#, True)");
    await execute(targetPath, "INSERT INTO Employees (FullName, Department, Salary, HireDate, Active) VALUES ('John Smith', 'Marketing', 3900.0, #2025-03-10#, False)");
    await execute(targetPath, "INSERT INTO Employees (FullName, Department, Salary, HireDate, Active) VALUES ('Elena Rostova', 'Finance', 6200.0, #2022-11-01#, True)");

    // Create Documents_GED table
    await execute(targetPath, '''
      CREATE TABLE Documents_GED (
        DocID AUTOINCREMENT PRIMARY KEY,
        Title VARCHAR(120),
        DocCategory VARCHAR(50),
        FileFormat VARCHAR(10),
        FileSizeKB DOUBLE,
        IsVerified YESNO,
        ArchivedDate DATETIME
      )
    ''');

    await execute(targetPath, "INSERT INTO Documents_GED (Title, DocCategory, FileFormat, FileSizeKB, IsVerified, ArchivedDate) VALUES ('Bilan Financier 2025', 'Comptabilite', 'PDF', 1450.5, True, #2026-01-10#)");
    await execute(targetPath, "INSERT INTO Documents_GED (Title, DocCategory, FileFormat, FileSizeKB, IsVerified, ArchivedDate) VALUES ('عقد خدمات استشارية وتقنية #88', 'الشؤون القانونية', 'PDF', 1200.0, True, #2026-02-01#)");
    await execute(targetPath, "INSERT INTO Documents_GED (Title, DocCategory, FileFormat, FileSizeKB, IsVerified, ArchivedDate) VALUES ('Contrat Cadre Client #44', 'Juridique', 'PDF', 890.0, True, #2026-02-14#)");
    await execute(targetPath, "INSERT INTO Documents_GED (Title, DocCategory, FileFormat, FileSizeKB, IsVerified, ArchivedDate) VALUES ('تقرير تدقيق الحسابات السنوي', 'المالية والمحاسبة', 'PDF', 2340.0, True, #2026-03-15#)");
    await execute(targetPath, "INSERT INTO Documents_GED (Title, DocCategory, FileFormat, FileSizeKB, IsVerified, ArchivedDate) VALUES ('Facture Fournisseur Tech', 'Facturation', 'PDF', 320.0, False, #2026-03-05#)");
  }
}
