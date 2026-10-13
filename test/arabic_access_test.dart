import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:maj_ged/services/access_service.dart';

void main() {
  test('Verify Arabic reading and writing in Access DB', () async {
    const dbPath = r'd:\DEV\maj_ged\test_access.accdb';
    final file = File(dbPath);
    if (!file.existsSync()) {
      await AccessService.createSampleDatabase(dbPath);
    }

    final schema = await AccessService.getSchema(dbPath, 'Employees');

    // 1. Insert Arabic record
    const arabicName = 'أيمن حسونة - فحص يونيكود';
    const arabicDept = 'إدارة نظم المعلومات والتحول الرقمي';
    final insertRes = await AccessService.insertRecord(
      dbPath,
      'Employees',
      {
        'FullName': arabicName,
        'Department': arabicDept,
        'Salary': 12000.0,
        'Active': true,
      },
      schema,
    );
    expect(insertRes.success, isTrue);

    // 2. Query Arabic record back
    final rows = await AccessService.query(
      dbPath,
      "SELECT * FROM Employees WHERE FullName = '$arabicName'",
    );
    expect(rows, isNotEmpty);
    final row = rows.first;

    // Verify exact Arabic characters match without corruption or mojibake
    expect(row['FullName'], equals(arabicName));
    expect(row['Department'], equals(arabicDept));

    // 3. Clean up test record
    final id = row['ID'];
    final delRes = await AccessService.deleteRecord(dbPath, 'Employees', 'ID', id, schema);
    expect(delRes.success, isTrue);
  });
}
