import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/dbf_models.dart';

class DbfService {
  /// Reads and parses a .dbf file into a [DbfTable]
  static Future<DbfTable> parseDbfFile(File file, {String encodingName = 'CP1252'}) async {
    if (!await file.exists()) {
      throw Exception('DBF file not found: ${file.path}');
    }

    final bytes = await file.readAsBytes();
    if (bytes.length < 32) {
      throw Exception('File is too small to be a valid DBF file.');
    }

    final byteData = ByteData.sublistView(bytes);

    // Header byte 0: version (0x03 dBase III, 0x83 with memo, 0x30 VFP, etc.)
    final year = 1900 + bytes[1];
    final month = bytes[2];
    final day = bytes[3];
    DateTime lastUpdate;
    try {
      lastUpdate = DateTime(year, month, day);
    } catch (_) {
      lastUpdate = DateTime.now();
    }

    final recordCount = byteData.getUint32(4, Endian.little);
    final headerLength = byteData.getUint16(8, Endian.little);
    final recordLength = byteData.getUint16(10, Endian.little);

    if (headerLength > bytes.length) {
      throw Exception('Invalid DBF header: header length ($headerLength) exceeds file size (${bytes.length}).');
    }

    final fields = <DbfField>[];
    int offset = 32;

    // Read field descriptors (32 bytes each)
    while (offset < headerLength) {
      if (bytes[offset] == 0x0D) {
        // 0x0D marks the end of field descriptors
        break;
      }
      if (offset + 32 > bytes.length) break;

      // Field name (up to 11 bytes, null terminated or zero padded)
      int nameEnd = offset;
      while (nameEnd < offset + 11 && bytes[nameEnd] != 0) {
        nameEnd++;
      }
      final name = ascii.decode(bytes.sublist(offset, nameEnd)).trim();
      final type = String.fromCharCode(bytes[offset + 11]);
      final fieldLen = bytes[offset + 16];
      final fieldDec = bytes[offset + 17];

      if (name.isNotEmpty) {
        fields.add(DbfField(
          name: name,
          type: type,
          length: fieldLen,
          decimals: fieldDec,
        ));
      }

      offset += 32;
    }

    final records = <Map<String, dynamic>>[];
    int recOffset = headerLength;

    for (int i = 0; i < recordCount; i++) {
      if (recOffset + recordLength > bytes.length) break;

      final isDeleted = bytes[recOffset] == 0x2A; // '*' = deleted
      if (isDeleted) {
        recOffset += recordLength;
        continue;
      }

      int fieldOffset = recOffset + 1;
      final row = <String, dynamic>{};

      for (final field in fields) {
        if (fieldOffset + field.length > bytes.length) break;

        final fieldBytes = bytes.sublist(fieldOffset, fieldOffset + field.length);
        final strVal = _decodeBytes(fieldBytes, encodingName).trim();

        dynamic parsedVal;
        switch (field.type.toUpperCase()) {
          case 'N':
            if (strVal.isEmpty) {
              parsedVal = null;
            } else if (field.decimals > 0 || strVal.contains('.')) {
              parsedVal = double.tryParse(strVal);
            } else {
              parsedVal = int.tryParse(strVal);
            }
            break;

          case 'F':
            parsedVal = strVal.isEmpty ? null : double.tryParse(strVal);
            break;

          case 'L':
            final upper = strVal.toUpperCase();
            if (upper == 'T' || upper == 'Y') {
              parsedVal = true;
            } else if (upper == 'F' || upper == 'N') {
              parsedVal = false;
            } else {
              parsedVal = null;
            }
            break;

          case 'D':
            if (strVal.length == 8) {
              final y = int.tryParse(strVal.substring(0, 4));
              final m = int.tryParse(strVal.substring(4, 6));
              final d = int.tryParse(strVal.substring(6, 8));
              if (y != null && m != null && d != null) {
                parsedVal = "$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";
              } else {
                parsedVal = strVal;
              }
            } else {
              parsedVal = strVal.isEmpty ? null : strVal;
            }
            break;

          default:
            parsedVal = strVal;
        }

        row[field.name] = parsedVal;
        fieldOffset += field.length;
      }

      records.add(row);
      recOffset += recordLength;
    }

    return DbfTable(
      fields: fields,
      records: records,
      recordCount: records.length,
      lastUpdate: lastUpdate,
      filePath: file.path,
      fileSizeBytes: bytes.length,
    );
  }

  static const List<int> _cp1256Table = [
    0x20AC, 0x067E, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021,
    0x02C6, 0x2030, 0x0679, 0x2039, 0x0152, 0x0686, 0x0698, 0x0688,
    0x06AF, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
    0x06A9, 0x2122, 0x0691, 0x203A, 0x0153, 0x200C, 0x200D, 0x06BA,
    0x00A0, 0x060C, 0x00A2, 0x00A3, 0x00A4, 0x00A5, 0x00A6, 0x00A7,
    0x00A8, 0x00A9, 0x06BE, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x00AF,
    0x00B0, 0x00B1, 0x00B2, 0x00B3, 0x00B4, 0x00B5, 0x00B6, 0x00B7,
    0x00B8, 0x00B9, 0x061B, 0x00BB, 0x00BC, 0x00BD, 0x00BE, 0x061F,
    0x06C1, 0x0621, 0x0622, 0x0623, 0x0624, 0x0625, 0x0626, 0x0627,
    0x0628, 0x0629, 0x062A, 0x062B, 0x062C, 0x062D, 0x062E, 0x062F,
    0x0630, 0x0631, 0x0632, 0x0633, 0x0634, 0x0635, 0x0636, 0x00D7,
    0x0637, 0x0638, 0x0639, 0x063A, 0x0640, 0x0641, 0x0642, 0x0643,
    0x00E0, 0x0644, 0x00E2, 0x0645, 0x0646, 0x0647, 0x0648, 0x00E7,
    0x00E8, 0x00E9, 0x00EA, 0x00EB, 0x0649, 0x064A, 0x00EE, 0x00EF,
    0x064B, 0x064C, 0x064D, 0x064E, 0x00F4, 0x064F, 0x0650, 0x00F7,
    0x0651, 0x00F9, 0x0652, 0x00FB, 0x00FC, 0x200E, 0x200F, 0x06D2,
  ];

  static String _decodeBytes(Uint8List bytes, String encoding) {
    if (encoding == 'UTF-8') {
      try {
        return utf8.decode(bytes);
      } catch (_) {}
    } else if (encoding == 'CP1256') {
      final chars = <int>[];
      for (final b in bytes) {
        if (b < 128) {
          chars.add(b);
        } else {
          chars.add(_cp1256Table[b - 128]);
        }
      }
      return String.fromCharCodes(chars);
    }
    // CP1252 / Latin1 fallback
    return latin1.decode(bytes);
  }

  /// Exports current table to CSV string
  static String exportToCsv(DbfTable table, {List<String>? visibleColumns, List<Map<String, dynamic>>? rows}) {
    final columnsToExport = visibleColumns ?? table.fields.map((f) => f.name).toList();
    final rowsToExport = rows ?? table.records;

    final sb = StringBuffer();
    // Header
    sb.writeln(columnsToExport.map(_escapeCsvCell).join(','));

    // Rows
    for (final row in rowsToExport) {
      final line = columnsToExport.map((col) {
        final val = row[col];
        return _escapeCsvCell(val == null ? '' : val.toString());
      }).join(',');
      sb.writeln(line);
    }

    return sb.toString();
  }

  static String _escapeCsvCell(String cell) {
    if (cell.contains(',') || cell.contains('"') || cell.contains('\n') || cell.contains('\r')) {
      return '"${cell.replaceAll('"', '""')}"';
    }
    return cell;
  }

  /// Generates a realistic sample DBF file with 30 columns for testing
  static Future<File> generateSampleDbf(File targetFile, {int rowCount = 30}) async {
    final fields = <DbfField>[
      const DbfField(name: "ID", type: "N", length: 6, decimals: 0),
      const DbfField(name: "DOC_NUM", type: "C", length: 15),
      const DbfField(name: "DOC_DATE", type: "D", length: 8),
      const DbfField(name: "CLIENT_ID", type: "N", length: 8, decimals: 0),
      const DbfField(name: "CLIENT_NOM", type: "C", length: 30),
      const DbfField(name: "ADRESSE", type: "C", length: 40),
      const DbfField(name: "VILLE", type: "C", length: 20),
      const DbfField(name: "CODE_POST", type: "C", length: 10),
      const DbfField(name: "PAYS", type: "C", length: 15),
      const DbfField(name: "TEL", type: "C", length: 18),
      const DbfField(name: "EMAIL", type: "C", length: 35),
      const DbfField(name: "TYPE_GED", type: "C", length: 12),
      const DbfField(name: "STATUT", type: "C", length: 12),
      const DbfField(name: "MONTANT_HT", type: "N", length: 12, decimals: 2),
      const DbfField(name: "TAUX_TVA", type: "N", length: 6, decimals: 2),
      const DbfField(name: "MONTANT_TTC", type: "N", length: 12, decimals: 2),
      const DbfField(name: "DEVISE", type: "C", length: 5),
      const DbfField(name: "MODE_PAIE", type: "C", length: 15),
      const DbfField(name: "DATE_ECHEA", type: "D", length: 8),
      const DbfField(name: "EST_VALIDE", type: "L", length: 1),
      const DbfField(name: "CATEGORIE", type: "C", length: 20),
      const DbfField(name: "SOUS_CAT", type: "C", length: 20),
      const DbfField(name: "REF_EXTER", type: "C", length: 25),
      const DbfField(name: "NB_PAGES", type: "N", length: 5, decimals: 0),
      const DbfField(name: "FORMAT_FIC", type: "C", length: 8),
      const DbfField(name: "EMPLACEMEN", type: "C", length: 50),
      const DbfField(name: "INDEX_GED", type: "C", length: 20),
      const DbfField(name: "LOT_NUM", type: "N", length: 6, decimals: 0),
      const DbfField(name: "UTILISATEU", type: "C", length: 15),
      const DbfField(name: "OBSERVATIO", type: "C", length: 40),
    ];

    int headerLength = 32 + (fields.length * 32) + 1;
    int recordLength = 1;
    for (var f in fields) {
      recordLength += f.length;
    }

    final bb = BytesBuilder();
    final header = Uint8List(32);
    header[0] = 0x03; // dBase III
    header[1] = 26;   // Year 2026
    header[2] = 10;   // Month
    header[3] = 13;   // Day
    final bd = ByteData.sublistView(header);
    bd.setUint32(4, rowCount, Endian.little);
    bd.setUint16(8, headerLength, Endian.little);
    bd.setUint16(10, recordLength, Endian.little);
    bb.add(header);

    for (final f in fields) {
      final fBytes = Uint8List(32);
      final nameBytes = ascii.encode(f.name);
      for (int i = 0; i < nameBytes.length && i < 11; i++) {
        fBytes[i] = nameBytes[i];
      }
      fBytes[11] = ascii.encode(f.type)[0];
      fBytes[16] = f.length;
      fBytes[17] = f.decimals;
      bb.add(fBytes);
    }

    bb.addByte(0x0D);

    final statuses = ["EN_COURS", "VALIDE", "ARCHIVE", "EN_ATTENTE"];
    final types = ["FACTURE", "DEVIS", "CONTRAT", "BON_LIVR"];
    final users = ["ADMIN", "AHASSOUNA", "OPERATEUR1", "SUPERVISEUR"];

    for (int i = 1; i <= rowCount; i++) {
      final rowBytes = BytesBuilder();
      rowBytes.addByte(0x20); // space (not deleted)

      for (final f in fields) {
        String valStr = "";
        switch (f.name) {
          case "ID": valStr = i.toString().padLeft(f.length, ' '); break;
          case "DOC_NUM": valStr = "DOC-2026-${(1000 + i).toString()}".padRight(f.length, ' '); break;
          case "DOC_DATE": valStr = "202610${(i % 28 + 1).toString().padLeft(2, '0')}"; break;
          case "CLIENT_ID": valStr = (5000 + (i % 10)).toString().padLeft(f.length, ' '); break;
          case "CLIENT_NOM": valStr = "Client Entreprise ${(i % 15) + 1}".padRight(f.length, ' '); break;
          case "ADRESSE": valStr = "${10 + i} Boulevard Hassan II".padRight(f.length, ' '); break;
          case "VILLE": valStr = (i % 2 == 0 ? "Casablanca" : "Rabat").padRight(f.length, ' '); break;
          case "CODE_POST": valStr = (20000 + i * 10).toString().padRight(f.length, ' '); break;
          case "PAYS": valStr = "Maroc".padRight(f.length, ' '); break;
          case "TEL": valStr = "+212 600-${(100000 + i)}".padRight(f.length, ' '); break;
          case "EMAIL": valStr = "contact$i@entreprise.ma".padRight(f.length, ' '); break;
          case "TYPE_GED": valStr = types[i % types.length].padRight(f.length, ' '); break;
          case "STATUT": valStr = statuses[i % statuses.length].padRight(f.length, ' '); break;
          case "MONTANT_HT": valStr = ((1250.0 * i) % 99999.0).toStringAsFixed(2).padLeft(f.length, ' '); break;
          case "TAUX_TVA": valStr = "20.00".padLeft(f.length, ' '); break;
          case "MONTANT_TTC": valStr = (((1250.0 * i) % 99999.0) * 1.2).toStringAsFixed(2).padLeft(f.length, ' '); break;
          case "DEVISE": valStr = "MAD".padRight(f.length, ' '); break;
          case "MODE_PAIE": valStr = (i % 2 == 0 ? "VIREMENT" : "CHEQUE").padRight(f.length, ' '); break;
          case "DATE_ECHEA": valStr = "202611${(i % 28 + 1).toString().padLeft(2, '0')}"; break;
          case "EST_VALIDE": valStr = i % 2 == 0 ? "T" : "F"; break;
          case "CATEGORIE": valStr = "FINANCE".padRight(f.length, ' '); break;
          case "SOUS_CAT": valStr = "COMPTABILITE".padRight(f.length, ' '); break;
          case "REF_EXTER": valStr = "EXT-REF-$i-2026".padRight(f.length, ' '); break;
          case "NB_PAGES": valStr = ((i % 5) + 1).toString().padLeft(f.length, ' '); break;
          case "FORMAT_FIC": valStr = "PDF".padRight(f.length, ' '); break;
          case "EMPLACEMEN": valStr = "d:/ged/archives/2026/doc_$i.pdf".padRight(f.length, ' '); break;
          case "INDEX_GED": valStr = "IDX-${i.toString().padLeft(6, '0')}".padRight(f.length, ' '); break;
          case "LOT_NUM": valStr = (100 + (i % 5)).toString().padLeft(f.length, ' '); break;
          case "UTILISATEU": valStr = users[i % users.length].padRight(f.length, ' '); break;
          case "OBSERVATIO": valStr = "Document classe sans anomalie".padRight(f.length, ' '); break;
          default: valStr = "".padRight(f.length, ' ');
        }
        final bytesVal = latin1.encode(valStr);
        if (bytesVal.length > f.length) {
          rowBytes.add(bytesVal.sublist(0, f.length));
        } else {
          rowBytes.add(bytesVal);
          for (int k = bytesVal.length; k < f.length; k++) {
            rowBytes.addByte(0x20);
          }
        }
      }
      bb.add(rowBytes.takeBytes());
    }

    bb.addByte(0x1A); // EOF marker
    await targetFile.writeAsBytes(bb.takeBytes());
    return targetFile;
  }
}
