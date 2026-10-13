import 'dart:io';
import 'package:flutter/material.dart';
import '../models/access_models.dart';
import '../services/access_service.dart';
import '../services/settings_service.dart';

class AccessView extends StatefulWidget {
  final SettingsService settingsService;
  final VoidCallback onNavigateToSettings;

  const AccessView({
    super.key,
    required this.settingsService,
    required this.onNavigateToSettings,
  });

  @override
  State<AccessView> createState() => AccessViewState();
}

class AccessViewState extends State<AccessView> {
  List<String> _tables = [];
  String? _selectedTable;
  AccessTableSchema? _schema;
  List<Map<String, dynamic>> _rows = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  int _currentPage = 1;
  int _rowsPerPage = 25;

  // Custom SQL Console state
  bool _showSqlConsole = false;
  final TextEditingController _sqlController = TextEditingController();
  String? _sqlResultStatus;
  List<Map<String, dynamic>>? _sqlCustomRows;
  bool _isExecutingSql = false;
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadAccessDb();
  }

  @override
  void dispose() {
    _sqlController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> loadAccessDb() async {
    final path = widget.settingsService.settings.accessDbPath;
    if (path.isEmpty) {
      setState(() {
        _tables = [];
        _selectedTable = null;
        _schema = null;
        _rows = [];
        _errorMessage = 'No Access database configured. Please specify the path in Settings.';
      });
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      setState(() {
        _tables = [];
        _selectedTable = null;
        _schema = null;
        _rows = [];
        _errorMessage = 'Access database file not found on disk:\n$path';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tables = await AccessService.getTables(path);
      setState(() {
        _tables = tables;
        _selectedTable = tables.isNotEmpty ? tables.first : null;
      });

      if (_selectedTable != null) {
        await _loadTableData(_selectedTable!);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to connect to Access Database: $e';
      });
    }
  }

  Future<void> _loadTableData(String tableName) async {
    final path = widget.settingsService.settings.accessDbPath;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedTable = tableName;
    });

    try {
      final schema = await AccessService.getSchema(path, tableName);
      final rows = await AccessService.query(path, 'SELECT * FROM [$tableName]');

      setState(() {
        _schema = schema;
        _rows = rows;
        _isLoading = false;
        _currentPage = 1;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load table $tableName: $e';
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredRows() {
    if (_searchQuery.trim().isEmpty) return _rows;
    final q = _searchQuery.toLowerCase();
    return _rows.where((row) {
      for (final val in row.values) {
        if (val != null && val.toString().toLowerCase().contains(q)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  // --- CRUD: CREATE (Add Record) ---
  void _showAddRecordDialog() {
    if (_schema == null || _selectedTable == null) return;

    final formKey = GlobalKey<FormState>();
    final controllers = <String, TextEditingController>{};
    final boolValues = <String, bool>{};

    for (final col in _schema!.columns) {
      if (col.isAutoIncrement || col.isReadOnly) continue;
      if (col.friendlyType == 'Boolean') {
        boolValues[col.name] = false;
      } else {
        controllers[col.name] = TextEditingController();
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.add_circle, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text('Add Record to [$_selectedTable]'),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _schema!.columns.map((col) {
                        if (col.isAutoIncrement || col.isReadOnly) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              dense: true,
                              tileColor: Colors.grey.shade100,
                              title: Text('${col.name} (${col.friendlyType})'),
                              subtitle: const Text('Auto-generated / Read-only'),
                              leading: const Icon(Icons.lock, size: 18, color: Colors.grey),
                            ),
                          );
                        }

                        if (col.friendlyType == 'Boolean') {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SwitchListTile(
                              title: Text(col.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(col.friendlyType),
                              value: boolValues[col.name] ?? false,
                              onChanged: (val) {
                                setDialogState(() {
                                  boolValues[col.name] = val;
                                });
                              },
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextFormField(
                            controller: controllers[col.name],
                            keyboardType: (col.friendlyType == 'Integer' || col.friendlyType == 'Number')
                                ? const TextInputType.numberWithOptions(decimal: true)
                                : TextInputType.text,
                            decoration: InputDecoration(
                              labelText: col.name,
                              hintText: col.friendlyType == 'DateTime' ? 'YYYY-MM-DD' : null,
                              helperText: 'Type: ${col.friendlyType}${col.isKey ? ' (Primary Key)' : ''}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (val) {
                              if (!col.allowDbNull && (val == null || val.trim().isEmpty)) {
                                return '${col.name} is required.';
                              }
                              return null;
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final rowData = <String, dynamic>{};
                      for (final col in _schema!.columns) {
                        if (col.isAutoIncrement || col.isReadOnly) continue;
                        if (col.friendlyType == 'Boolean') {
                          rowData[col.name] = boolValues[col.name] ?? false;
                        } else {
                          final text = controllers[col.name]?.text.trim() ?? '';
                          if (text.isEmpty && col.allowDbNull) {
                            rowData[col.name] = null;
                          } else {
                            rowData[col.name] = text;
                          }
                        }
                      }

                      Navigator.pop(ctx);
                      await _executeInsert(rowData);
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Insert Record'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeInsert(Map<String, dynamic> rowData) async {
    final path = widget.settingsService.settings.accessDbPath;
    setState(() => _isLoading = true);
    try {
      final res = await AccessService.insertRecord(path, _selectedTable!, rowData, _schema!);
      if (res.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record added successfully!'), backgroundColor: Colors.teal),
          );
        }
        await _loadTableData(_selectedTable!);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add record: ${res.error}'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding record: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // --- CRUD: UPDATE (Edit Record) ---
  void _showEditRecordDialog(Map<String, dynamic> record) {
    if (_schema == null || _selectedTable == null) return;

    final primaryKeyCol = _schema!.primaryKeyColumn;
    if (primaryKeyCol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot edit: No identifiable primary key column in this table.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final primaryKeyValue = record[primaryKeyCol.name];
    final formKey = GlobalKey<FormState>();
    final controllers = <String, TextEditingController>{};
    final boolValues = <String, bool>{};

    for (final col in _schema!.columns) {
      if (col.isAutoIncrement || col.isReadOnly) continue;
      if (col.friendlyType == 'Boolean') {
        boolValues[col.name] = record[col.name] == true;
      } else {
        final initial = record[col.name] == null ? '' : record[col.name].toString();
        controllers[col.name] = TextEditingController(text: initial);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('Edit Record (${primaryKeyCol.name} = $primaryKeyValue)'),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _schema!.columns.map((col) {
                        if (col.isAutoIncrement || col.isReadOnly) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              dense: true,
                              tileColor: Colors.grey.shade100,
                              title: Text('${col.name}: ${record[col.name]}'),
                              subtitle: const Text('Auto-generated / Read-only'),
                              leading: const Icon(Icons.lock, size: 18, color: Colors.grey),
                            ),
                          );
                        }

                        if (col.friendlyType == 'Boolean') {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SwitchListTile(
                              title: Text(col.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(col.friendlyType),
                              value: boolValues[col.name] ?? false,
                              onChanged: (val) {
                                setDialogState(() {
                                  boolValues[col.name] = val;
                                });
                              },
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextFormField(
                            controller: controllers[col.name],
                            keyboardType: (col.friendlyType == 'Integer' || col.friendlyType == 'Number')
                                ? const TextInputType.numberWithOptions(decimal: true)
                                : TextInputType.text,
                            decoration: InputDecoration(
                              labelText: col.name,
                              helperText: 'Type: ${col.friendlyType}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (val) {
                              if (!col.allowDbNull && (val == null || val.trim().isEmpty)) {
                                return '${col.name} cannot be empty.';
                              }
                              return null;
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final updatedData = <String, dynamic>{};
                      for (final col in _schema!.columns) {
                        if (col.isAutoIncrement || col.isReadOnly) continue;
                        if (col.friendlyType == 'Boolean') {
                          updatedData[col.name] = boolValues[col.name] ?? false;
                        } else {
                          final text = controllers[col.name]?.text.trim() ?? '';
                          if (text.isEmpty && col.allowDbNull) {
                            updatedData[col.name] = null;
                          } else {
                            updatedData[col.name] = text;
                          }
                        }
                      }

                      Navigator.pop(ctx);
                      await _executeUpdate(updatedData, primaryKeyCol.name, primaryKeyValue);
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeUpdate(Map<String, dynamic> updatedData, String keyCol, dynamic keyVal) async {
    final path = widget.settingsService.settings.accessDbPath;
    setState(() => _isLoading = true);
    try {
      final res = await AccessService.updateRecord(path, _selectedTable!, updatedData, keyCol, keyVal, _schema!);
      if (res.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record updated successfully!'), backgroundColor: Colors.teal),
          );
        }
        await _loadTableData(_selectedTable!);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Update failed: ${res.error}'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating record: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // --- CRUD: DELETE ---
  void _confirmDeleteRecord(Map<String, dynamic> record) {
    if (_schema == null || _selectedTable == null) return;
    final primaryKeyCol = _schema!.primaryKeyColumn;
    if (primaryKeyCol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: No primary key found.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final keyVal = record[primaryKeyCol.name];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirm Deletion'),
          ],
        ),
        content: Text('Are you sure you want to permanently delete this record where ${primaryKeyCol.name} = $keyVal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _executeDelete(primaryKeyCol.name, keyVal);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDelete(String keyCol, dynamic keyVal) async {
    final path = widget.settingsService.settings.accessDbPath;
    setState(() => _isLoading = true);
    try {
      final res = await AccessService.deleteRecord(path, _selectedTable!, keyCol, keyVal, _schema!);
      if (res.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted.'), backgroundColor: Colors.redAccent),
          );
        }
        await _loadTableData(_selectedTable!);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: ${res.error}'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting record: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // --- CUSTOM SQL RUNNER ---
  Future<void> _runCustomSql() async {
    final sql = _sqlController.text.trim();
    if (sql.isEmpty) return;

    final path = widget.settingsService.settings.accessDbPath;
    setState(() {
      _isExecutingSql = true;
      _sqlResultStatus = null;
      _sqlCustomRows = null;
    });

    try {
      if (sql.toLowerCase().startsWith('select')) {
        final rows = await AccessService.query(path, sql);
        setState(() {
          _isExecutingSql = false;
          _sqlCustomRows = rows;
          _sqlResultStatus = 'Returned ${rows.length} rows.';
        });
      } else {
        final res = await AccessService.execute(path, sql);
        setState(() {
          _isExecutingSql = false;
          _sqlResultStatus = res.success ? 'Success! Affected ${res.affectedRows} row(s).' : 'Error: ${res.error}';
        });
        if (res.success && _selectedTable != null) {
          _loadTableData(_selectedTable!);
        }
      }
    } catch (e) {
      setState(() {
        _isExecutingSql = false;
        _sqlResultStatus = 'Exception: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _tables.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to Microsoft Access Database via OLEDB...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _tables.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storage, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.red),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: widget.onNavigateToSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings to Configure Access Path'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredRows = _getFilteredRows();
    final totalRows = filteredRows.length;
    final totalPages = (totalRows / _rowsPerPage).ceil().clamp(1, 999999);
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalRows);
    final pagedRows = (startIndex < totalRows) ? filteredRows.sublist(startIndex, endIndex) : <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.storage, color: Colors.redAccent, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MS Access Manager (CRUD) - ${_selectedTable ?? "No Table"}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_tables.length} tables | ${_rows.length} total records | Primary Key: ${_schema?.primaryKeyColumn?.name ?? "None"}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showSqlConsole ? Icons.terminal : Icons.terminal_outlined),
            tooltip: 'Toggle SQL Console',
            onPressed: () => setState(() => _showSqlConsole = !_showSqlConsole),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Table',
            onPressed: () {
              if (_selectedTable != null) _loadTableData(_selectedTable!);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: widget.onNavigateToSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Table Selector Bar & Add Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                const Text('Select Table:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedTable,
                  items: _tables.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                  onChanged: (newTable) {
                    if (newTable != null && newTable != _selectedTable) {
                      _loadTableData(newTable);
                    }
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search in $_selectedTable rows...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _schema != null ? _showAddRecordDialog : null,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Record'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
                ),
              ],
            ),
          ),

          // SQL Console (Collapsible)
          if (_showSqlConsole) _buildSqlConsole(),

          // Main Table Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _schema == null
                    ? const Center(child: Text('No schema available'))
                    : Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Scrollbar(
                          controller: _verticalScrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _verticalScrollController,
                            scrollDirection: Axis.vertical,
                            child: Scrollbar(
                              controller: _horizontalScrollController,
                              thumbVisibility: true,
                              notificationPredicate: (notif) => notif.depth == 1,
                              child: SingleChildScrollView(
                                controller: _horizontalScrollController,
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                headingRowHeight: 44,
                                dataRowMinHeight: 40,
                                dataRowMaxHeight: 46,
                                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                                columns: [
                                  // Actions Column (CRUD operations)
                                  const DataColumn(
                                    label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                  // Schema Columns
                                  ..._schema!.columns.map((col) {
                                    return DataColumn(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            col.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: col.isKey ? Colors.blue.shade800 : Colors.black87,
                                            ),
                                          ),
                                          if (col.isKey) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.key, size: 14, color: Colors.blue),
                                          ],
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              col.friendlyType,
                                              style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                rows: List.generate(pagedRows.length, (idx) {
                                  final row = pagedRows[idx];

                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                                      if (states.contains(WidgetState.hovered)) {
                                        return Colors.teal.withAlpha(20);
                                      }
                                      return idx % 2 == 0 ? Colors.transparent : Colors.grey.shade50;
                                    }),
                                    cells: [
                                      // Action cell: Edit & Delete
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                              tooltip: 'Edit Record',
                                              onPressed: () => _showEditRecordDialog(row),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                              tooltip: 'Delete Record',
                                              onPressed: () => _confirmDeleteRecord(row),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Data values
                                      ..._schema!.columns.map((col) {
                                        final val = row[col.name];
                                        return DataCell(
                                          Text(
                                            val == null ? 'NULL' : val.toString(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: val == null ? Colors.grey : Colors.black87,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
          ),

          // Pagination Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Text(
                  'Showing ${totalRows == 0 ? 0 : startIndex + 1} to $endIndex of $totalRows rows',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const Spacer(),
                const Text('Rows per page:', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _rowsPerPage,
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 25, child: Text('25')),
                    DropdownMenuItem(value: 50, child: Text('50')),
                    DropdownMenuItem(value: 100, child: Text('100')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _rowsPerPage = val;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.first_page, size: 20),
                  onPressed: _currentPage > 1 ? () => setState(() => _currentPage = 1) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                ),
                Text('Page $_currentPage of $totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.last_page, size: 20),
                  onPressed: _currentPage < totalPages ? () => setState(() => _currentPage = totalPages) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSqlConsole() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 8),
              const Text('Custom SQL Query Runner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                onPressed: () => setState(() => _showSqlConsole = false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sqlController,
                  style: const TextStyle(color: Colors.greenAccent, fontFamily: 'Consolas', fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. SELECT * FROM Employees WHERE Salary > 4000',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.black45,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isExecutingSql ? null : _runCustomSql,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Execute'),
                style: FilledButton.styleFrom(backgroundColor: Colors.teal),
              ),
            ],
          ),
          if (_sqlResultStatus != null) ...[
            const SizedBox(height: 8),
            Text(
              _sqlResultStatus!,
              style: TextStyle(
                color: _sqlResultStatus!.contains('Error') || _sqlResultStatus!.contains('Exception')
                    ? Colors.redAccent
                    : Colors.lightGreenAccent,
                fontSize: 12,
              ),
            ),
          ],
          if (_sqlCustomRows != null && _sqlCustomRows!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowHeight: 32,
                    dataRowMinHeight: 28,
                    dataRowMaxHeight: 32,
                    columns: _sqlCustomRows!.first.keys.map((k) {
                      return DataColumn(
                        label: Text(k, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                    rows: _sqlCustomRows!.map((r) {
                      return DataRow(
                        cells: r.values.map((v) {
                          return DataCell(
                            Text(
                              v == null ? 'NULL' : v.toString(),
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
