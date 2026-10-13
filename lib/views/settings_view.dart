import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/access_service.dart';
import '../services/dbf_service.dart';
import '../services/settings_service.dart';

class SettingsView extends StatefulWidget {
  final SettingsService settingsService;
  final VoidCallback onDbfUpdated;
  final VoidCallback onAccessUpdated;

  const SettingsView({
    super.key,
    required this.settingsService,
    required this.onDbfUpdated,
    required this.onAccessUpdated,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _dbfPathController;
  late TextEditingController _accessPathController;

  bool _isTestingDbf = false;
  String? _dbfTestStatus;
  bool _dbfTestSuccess = false;

  bool _isTestingAccess = false;
  String? _accessTestStatus;
  bool _accessTestSuccess = false;

  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final s = widget.settingsService.settings;
    _dbfPathController = TextEditingController(text: s.dbfPath);
    _accessPathController = TextEditingController(text: s.accessDbPath);

    if (s.dbfPath.isNotEmpty) _testDbfConnection(s.dbfPath);
    if (s.accessDbPath.isNotEmpty) _testAccessConnection(s.accessDbPath);
  }

  @override
  void dispose() {
    _dbfPathController.dispose();
    _accessPathController.dispose();
    super.dispose();
  }

  Future<void> _pickDbfFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['dbf'],
      dialogTitle: 'Select DBF Database File',
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      setState(() {
        _dbfPathController.text = path;
      });
      await _saveSettings();
      await _testDbfConnection(path);
      widget.onDbfUpdated();
    }
  }

  Future<void> _pickAccessFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['accdb', 'mdb'],
      dialogTitle: 'Select Microsoft Access Database File',
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      setState(() {
        _accessPathController.text = path;
      });
      await _saveSettings();
      await _testAccessConnection(path);
      widget.onAccessUpdated();
    }
  }

  Future<void> _testDbfConnection(String path) async {
    setState(() {
      _isTestingDbf = true;
      _dbfTestStatus = 'Testing DBF file...';
    });

    try {
      final file = File(path);
      if (!await file.exists()) {
        setState(() {
          _isTestingDbf = false;
          _dbfTestSuccess = false;
          _dbfTestStatus = 'File does not exist on disk';
        });
        return;
      }

      final table = await DbfService.parseDbfFile(
        file,
        encodingName: widget.settingsService.settings.dbfEncoding,
      );

      setState(() {
        _isTestingDbf = false;
        _dbfTestSuccess = true;
        _dbfTestStatus = 'Connected: ${table.recordCount} records, ${table.fields.length} columns (${(table.fileSizeBytes / 1024).toStringAsFixed(1)} KB)';
      });
    } catch (e) {
      setState(() {
        _isTestingDbf = false;
        _dbfTestSuccess = false;
        _dbfTestStatus = 'Error: $e';
      });
    }
  }

  Future<void> _testAccessConnection(String path) async {
    setState(() {
      _isTestingAccess = true;
      _accessTestStatus = 'Testing Access connection...';
    });

    try {
      final file = File(path);
      if (!await file.exists()) {
        setState(() {
          _isTestingAccess = false;
          _accessTestSuccess = false;
          _accessTestStatus = 'File does not exist on disk';
        });
        return;
      }

      final isOk = await AccessService.ping(path);
      if (isOk) {
        final tables = await AccessService.getTables(path);
        setState(() {
          _isTestingAccess = false;
          _accessTestSuccess = true;
          _accessTestStatus = 'Connected! Found ${tables.length} table(s): ${tables.join(', ')}';
        });
      } else {
        setState(() {
          _isTestingAccess = false;
          _accessTestSuccess = false;
          _accessTestStatus = 'Could not establish OLEDB connection.';
        });
      }
    } catch (e) {
      setState(() {
        _isTestingAccess = false;
        _accessTestSuccess = false;
        _accessTestStatus = 'Error: $e';
      });
    }
  }

  Future<void> _saveSettings() async {
    final current = widget.settingsService.settings;
    await widget.settingsService.updateSettings(
      current.copyWith(
        dbfPath: _dbfPathController.text.trim(),
        accessDbPath: _accessPathController.text.trim(),
      ),
    );
  }

  Future<void> _loadSampleDatabases() async {
    setState(() => _isBusy = true);
    try {
      final dbfFile = File(r'd:\DEV\maj_ged\sample_ged.dbf');
      if (!await dbfFile.exists()) {
        await DbfService.generateSampleDbf(dbfFile, rowCount: 30);
      }

      final accessFile = File(r'd:\DEV\maj_ged\test_access.accdb');
      if (!await accessFile.exists()) {
        await AccessService.createSampleDatabase(accessFile.path);
      }

      setState(() {
        _dbfPathController.text = dbfFile.path;
        _accessPathController.text = accessFile.path;
      });

      await _saveSettings();
      await _testDbfConnection(dbfFile.path);
      await _testAccessConnection(accessFile.path);

      widget.onDbfUpdated();
      widget.onAccessUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample DBF and Access databases loaded successfully!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize sample databases: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSettings = widget.settingsService.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.settings, size: 26),
            SizedBox(width: 10),
            Text('Database Connections & Settings'),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: _isBusy ? null : _loadSampleDatabases,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Quick Setup (Sample DBs)'),
            style: FilledButton.styleFrom(backgroundColor: Colors.teal.shade700),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isBusy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // Info Card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.primaryContainer.withAlpha(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.primary.withAlpha(60)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blueAccent, size: 28),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Configure the file locations for both the DBF database (Read-Only) and Microsoft Access database (.accdb/.mdb, CRUD). The settings are persisted automatically.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // DBF SECTION
                _buildDbfCard(theme, currentSettings),
                const SizedBox(height: 24),

                // ACCESS SECTION
                _buildAccessCard(theme),
                const SizedBox(height: 24),

                // SAVE & ACTIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        _testDbfConnection(_dbfPathController.text.trim());
                        _testAccessConnection(_accessPathController.text.trim());
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text('Retest Both Connections'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        await _saveSettings();
                        widget.onDbfUpdated();
                        widget.onAccessUpdated();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Database configuration saved.'),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save Configuration'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildDbfCard(ThemeData theme, AppSettings currentSettings) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.table_chart, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. DBF Database (Read-Only)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Supports dBase III/IV and FoxPro .dbf files with any number of columns.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final target = File(r'd:\DEV\maj_ged\sample_ged.dbf');
                    await DbfService.generateSampleDbf(target, rowCount: 40);
                    _dbfPathController.text = target.path;
                    await _saveSettings();
                    await _testDbfConnection(target.path);
                    widget.onDbfUpdated();
                  },
                  icon: const Icon(Icons.create_new_folder, size: 16),
                  label: const Text('Generate Sample DBF (30 Cols)'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dbfPathController,
                    decoration: InputDecoration(
                      labelText: 'DBF File Path (*.dbf)',
                      hintText: r'D:\path\to\database.dbf',
                      prefixIcon: const Icon(Icons.folder_open),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (val) {
                      _saveSettings();
                      _testDbfConnection(val.trim());
                      widget.onDbfUpdated();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _pickDbfFile,
                  icon: const Icon(Icons.file_open),
                  label: const Text('Browse...'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () {
                    _saveSettings();
                    _testDbfConnection(_dbfPathController.text.trim());
                    widget.onDbfUpdated();
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Test DBF',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Character Encoding:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: currentSettings.dbfEncoding,
                  items: const [
                    DropdownMenuItem(value: 'CP1252', child: Text('Windows-1252 (CP1252 / Western)')),
                    DropdownMenuItem(value: 'UTF-8', child: Text('UTF-8')),
                    DropdownMenuItem(value: 'Latin1', child: Text('ISO-8859-1 (Latin1)')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await widget.settingsService.updateSettings(
                        currentSettings.copyWith(dbfEncoding: val),
                      );
                      _testDbfConnection(_dbfPathController.text.trim());
                      widget.onDbfUpdated();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Status feedback
            _buildStatusBox(_isTestingDbf, _dbfTestSuccess, _dbfTestStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storage, color: Colors.redAccent, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. Microsoft Access Database (Full CRUD)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Supports Access .accdb and .mdb databases with Insert, Update, Delete & Queries.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final target = File(r'd:\DEV\maj_ged\test_access.accdb');
                    await AccessService.createSampleDatabase(target.path);
                    _accessPathController.text = target.path;
                    await _saveSettings();
                    await _testAccessConnection(target.path);
                    widget.onAccessUpdated();
                  },
                  icon: const Icon(Icons.add_box_outlined, size: 16),
                  label: const Text('Create Sample Access DB'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _accessPathController,
                    decoration: InputDecoration(
                      labelText: 'Access DB File Path (*.accdb, *.mdb)',
                      hintText: r'D:\path\to\database.accdb',
                      prefixIcon: const Icon(Icons.folder_open),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (val) {
                      _saveSettings();
                      _testAccessConnection(val.trim());
                      widget.onAccessUpdated();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _pickAccessFile,
                  icon: const Icon(Icons.file_open),
                  label: const Text('Browse...'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () {
                    _saveSettings();
                    _testAccessConnection(_accessPathController.text.trim());
                    widget.onAccessUpdated();
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Test Access Connection',
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Status feedback
            _buildStatusBox(_isTestingAccess, _accessTestSuccess, _accessTestStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBox(bool isLoading, bool isSuccess, String? message) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Verifying database connection...', style: TextStyle(fontSize: 13)),
          ],
        ),
      );
    }

    if (message == null) return const SizedBox.shrink();

    final color = isSuccess ? Colors.green : Colors.red;
    final icon = isSuccess ? Icons.check_circle : Icons.error_outline;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: color.shade800, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
