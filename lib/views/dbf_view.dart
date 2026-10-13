import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/dbf_models.dart';
import '../services/dbf_service.dart';
import '../services/settings_service.dart';

class DbfView extends StatefulWidget {
  final SettingsService settingsService;
  final VoidCallback onNavigateToSettings;

  const DbfView({
    super.key,
    required this.settingsService,
    required this.onNavigateToSettings,
  });

  @override
  State<DbfView> createState() => DbfViewState();
}

class DbfViewState extends State<DbfView> {
  DbfTable? _table;
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  int _currentPage = 1;
  int _rowsPerPage = 25;

  // Column visibility management for tables with many columns
  final Set<String> _visibleColumnNames = {};

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadDbf();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> loadDbf() async {
    final path = widget.settingsService.settings.dbfPath;
    if (path.isEmpty) {
      setState(() {
        _table = null;
        _errorMessage = 'No DBF file configured. Please set the DBF path in Settings.';
      });
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      setState(() {
        _table = null;
        _errorMessage = 'The specified DBF file does not exist on disk:\n$path';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final table = await DbfService.parseDbfFile(
        file,
        encodingName: widget.settingsService.settings.dbfEncoding,
      );

      setState(() {
        _table = table;
        _isLoading = false;
        _currentPage = 1;
        // Default: Show all columns
        _visibleColumnNames.clear();
        for (var f in table.fields) {
          _visibleColumnNames.add(f.name);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to parse DBF file: $e';
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredRecords() {
    if (_table == null) return [];
    if (_searchQuery.trim().isEmpty) return _table!.records;

    final q = _searchQuery.toLowerCase();
    return _table!.records.where((record) {
      for (final col in _visibleColumnNames) {
        final val = record[col];
        if (val != null && val.toString().toLowerCase().contains(q)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  void _showColumnSelectorDialog() {
    if (_table == null) return;

    final allFields = _table!.fields;
    String colSearch = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final filteredFields = colSearch.isEmpty
                ? allFields
                : allFields.where((f) => f.name.toLowerCase().contains(colSearch.toLowerCase())).toList();

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.view_column, color: Colors.amber),
                  const SizedBox(width: 10),
                  Text('Select Columns (${_visibleColumnNames.length}/${allFields.length})'),
                ],
              ),
              content: SizedBox(
                width: 480,
                height: 480,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search columns...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          colSearch = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _visibleColumnNames.addAll(allFields.map((f) => f.name));
                            });
                            setState(() {});
                          },
                          child: const Text('Select All'),
                        ),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              _visibleColumnNames.clear();
                              // Keep at least the first column
                              if (allFields.isNotEmpty) {
                                _visibleColumnNames.add(allFields.first.name);
                              }
                            });
                            setState(() {});
                          },
                          child: const Text('Deselect All'),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredFields.length,
                        itemBuilder: (ctx, idx) {
                          final f = filteredFields[idx];
                          final isChecked = _visibleColumnNames.contains(f.name);
                          return CheckboxListTile(
                            dense: true,
                            title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${f.typeDescription} (Type ${f.type})'),
                            value: isChecked,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  _visibleColumnNames.add(f.name);
                                } else {
                                  if (_visibleColumnNames.length > 1) {
                                    _visibleColumnNames.remove(f.name);
                                  }
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRecordDetailDialog(Map<String, dynamic> record, int recordIndex) {
    if (_table == null) return;
    String fieldSearch = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDetailState) {
            final allFields = _table!.fields;
            final displayedFields = fieldSearch.isEmpty
                ? allFields
                : allFields.where((f) => f.name.toLowerCase().contains(fieldSearch.toLowerCase())).toList();

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.assignment, color: Colors.teal),
                  const SizedBox(width: 10),
                  Text('Record #$recordIndex Details (${allFields.length} Columns)'),
                ],
              ),
              content: SizedBox(
                width: 600,
                height: 520,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search field names or values...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setDetailState(() => fieldSearch = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: displayedFields.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final f = displayedFields[idx];
                          final val = record[f.name];
                          final valStr = val == null ? 'NULL' : val.toString();

                          return ListTile(
                            dense: true,
                            title: Row(
                              children: [
                                Text(f.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withAlpha(40),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    f.typeDescription,
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: SelectableText(
                              valStr,
                              style: TextStyle(
                                fontSize: 13,
                                color: val == null ? Colors.grey : Colors.blueGrey.shade900,
                                fontFamily: 'Consolas',
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              tooltip: 'Copy value',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: valStr));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Copied ${f.name} to clipboard'), duration: const Duration(seconds: 1)),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportCsv() async {
    if (_table == null) return;
    try {
      final filteredRecords = _getFilteredRecords();
      final csvString = DbfService.exportToCsv(
        _table!,
        visibleColumns: _table!.fields
            .where((f) => _visibleColumnNames.contains(f.name))
            .map((f) => f.name)
            .toList(),
        rows: filteredRecords,
      );

      final result = await FilePicker.saveFile(
        dialogTitle: 'Export DBF Data to CSV',
        fileName: 'export_dbf_data.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(csvString);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exported ${filteredRecords.length} records to ${file.path}'), backgroundColor: Colors.teal),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Parsing DBF file and schema...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.table_chart_outlined, size: 64, color: Colors.amber),
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
                label: const Text('Open Settings to Configure DBF Path'),
              ),
            ],
          ),
        ),
      );
    }

    if (_table == null) {
      return const Center(child: Text('No DBF table loaded.'));
    }

    final filteredRecords = _getFilteredRecords();
    final totalRecords = filteredRecords.length;
    final totalPages = (totalRecords / _rowsPerPage).ceil().clamp(1, 999999);
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalRecords);
    final pagedRecords = (startIndex < totalRecords) ? filteredRecords.sublist(startIndex, endIndex) : <Map<String, dynamic>>[];

    final visibleFields = _table!.fields.where((f) => _visibleColumnNames.contains(f.name)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.table_view, color: Colors.amber, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DBF Viewer (Read-Only) - ${File(_table!.filePath).uri.pathSegments.last}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_table!.recordCount} records | ${_table!.fields.length} columns | Updated: ${_table!.lastUpdate.year}-${_table!.lastUpdate.month.toString().padLeft(2, '0')}-${_table!.lastUpdate.day.toString().padLeft(2, '0')} | ${( _table!.fileSizeBytes / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload DBF',
            onPressed: loadDbf,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export visible to CSV',
            onPressed: _exportCsv,
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
          // Toolbar: Search, Column Selector, Column count badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search in ${_visibleColumnNames.length} visible columns...',
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
                OutlinedButton.icon(
                  onPressed: _showColumnSelectorDialog,
                  icon: const Icon(Icons.view_column, size: 18),
                  label: Text('Columns (${_visibleColumnNames.length}/${_table!.fields.length})'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Informational Tip for many columns
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: Colors.amber.withAlpha(20),
            child: Row(
              children: [
                const Icon(Icons.touch_app, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Showing ${_visibleColumnNames.length} columns. Scroll horizontally to see all columns, or click any row to inspect all fields in full detail.',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                ),
                const Spacer(),
                Text(
                  '${filteredRecords.length} records matching filter',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // Main Table (Dual Axis Scrollable)
          Expanded(
            child: Container(
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
                      dataRowMinHeight: 38,
                      dataRowMaxHeight: 42,
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                      columns: [
                        // Row Number Column
                        const DataColumn(
                          label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        // Quick Action Inspect
                        const DataColumn(
                          label: Text('Inspect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        // Dynamic DBF Columns
                        ...visibleFields.map((f) {
                          return DataColumn(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  f.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade100,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    f.type,
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      rows: List.generate(pagedRecords.length, (idx) {
                        final record = pagedRecords[idx];
                        final globalIdx = startIndex + idx + 1;

                        return DataRow(
                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return Colors.teal.withAlpha(20);
                            }
                            return idx % 2 == 0 ? Colors.transparent : Colors.grey.shade50;
                          }),
                          cells: [
                            DataCell(Text(
                              globalIdx.toString(),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            )),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.teal),
                                tooltip: 'View all columns for record #$globalIdx',
                                onPressed: () => _showRecordDetailDialog(record, globalIdx),
                              ),
                            ),
                            ...visibleFields.map((f) {
                              final val = record[f.name];
                              final valStr = val == null ? '' : val.toString();
                              return DataCell(
                                InkWell(
                                  onTap: () => _showRecordDetailDialog(record, globalIdx),
                                  child: Text(
                                    valStr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: val == null ? Colors.grey : Colors.black87,
                                    ),
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

          // Pagination Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Text(
                  'Showing ${totalRecords == 0 ? 0 : startIndex + 1} to $endIndex of $totalRecords records',
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
}
