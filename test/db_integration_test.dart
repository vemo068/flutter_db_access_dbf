import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:maj_ged/services/access_service.dart';
import 'package:maj_ged/services/dbf_service.dart';

void main() {
  group('DBF Service Tests', () {
    test('Parse 30-column sample DBF file successfully', () async {
      final dbfFile = File(r'd:\DEV\maj_ged\sample_ged.dbf');
      if (!await dbfFile.exists()) {
        await DbfService.generateSampleDbf(dbfFile, rowCount: 20);
      }

      final table = await DbfService.parseDbfFile(dbfFile);
      expect(table.fields.length, equals(30));
      expect(table.recordCount, greaterThan(0));
      expect(table.records.length, equals(table.recordCount));

      // Verify field names
      final fieldNames = table.fields.map((f) => f.name).toSet();
      expect(fieldNames.contains('ID'), isTrue);
      expect(fieldNames.contains('DOC_NUM'), isTrue);
      expect(fieldNames.contains('CLIENT_NOM'), isTrue);
      expect(fieldNames.contains('MONTANT_TTC'), isTrue);
      expect(fieldNames.contains('EST_VALIDE'), isTrue);

      // Verify first record values
      final first = table.records.first;
      expect(first['ID'], equals(1));
      expect(first['DEVISE'], equals('MAD'));
    });
  });

  group('Access Database CRUD Tests', () {
    const dbPath = r'd:\DEV\maj_ged\test_access.accdb';

    setUpAll(() async {
      final file = File(dbPath);
      if (!file.existsSync()) {
        await AccessService.createSampleDatabase(dbPath);
      }
    });

    test('Ping Access DB', () async {
      final isOk = await AccessService.ping(dbPath);
      expect(isOk, isTrue);
    });

    test('Get Tables', () async {
      final tables = await AccessService.getTables(dbPath);
      expect(tables, contains('Employees'));
    });

    test('Get Schema for Employees', () async {
      final schema = await AccessService.getSchema(dbPath, 'Employees');
      expect(schema.columns.any((c) => c.name == 'FullName'), isTrue);
      expect(schema.columns.any((c) => c.name == 'Salary'), isTrue);
      expect(schema.primaryKeyColumn, isNotNull);
      expect(schema.primaryKeyColumn!.name, equals('ID'));
    });

    test('CRUD Cycle: Insert, Read, Update, Delete', () async {
      final schema = await AccessService.getSchema(dbPath, 'Employees');

      // 1. Create (Insert)
      final insertRes = await AccessService.insertRecord(
        dbPath,
        'Employees',
        {
          'FullName': 'Test Unit User',
          'Department': 'QA Testing',
          'Salary': 3800.0,
          'Active': true,
        },
        schema,
      );
      expect(insertRes.success, isTrue);

      // 2. Read (Query)
      final rows = await AccessService.query(dbPath, "SELECT * FROM Employees WHERE FullName = 'Test Unit User'");
      expect(rows, isNotEmpty);
      final createdRow = rows.first;
      final newId = createdRow['ID'];
      expect(createdRow['Department'], equals('QA Testing'));

      // 3. Update
      final updateRes = await AccessService.updateRecord(
        dbPath,
        'Employees',
        {
          'FullName': 'Test Unit User Updated',
          'Salary': 4200.0,
        },
        'ID',
        newId,
        schema,
      );
      expect(updateRes.success, isTrue);

      final updatedRows = await AccessService.query(dbPath, "SELECT * FROM Employees WHERE ID = $newId");
      expect(updatedRows.first['FullName'], equals('Test Unit User Updated'));
      expect(updatedRows.first['Salary'], equals(4200.0));

      // 4. Delete
      final deleteRes = await AccessService.deleteRecord(dbPath, 'Employees', 'ID', newId, schema);
      expect(deleteRes.success, isTrue);

      final afterDelete = await AccessService.query(dbPath, "SELECT * FROM Employees WHERE ID = $newId");
      expect(afterDelete, isEmpty);
    });
  });
}
