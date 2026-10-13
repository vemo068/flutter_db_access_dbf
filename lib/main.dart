import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'views/access_view.dart';
import 'views/dbf_view.dart';
import 'views/settings_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsService = SettingsService();
  await settingsService.loadSettings();

  runApp(MajGedApp(settingsService: settingsService));
}

class MajGedApp extends StatelessWidget {
  final SettingsService settingsService;

  const MajGedApp({super.key, required this.settingsService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DualBase Manager — DBF & MS Access Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        fontFamily: 'Segoe UI',
        cardTheme: const CardTheme(
          elevation: 1,
          margin: EdgeInsets.zero,
        ),
      ),
      home: MainShell(settingsService: settingsService),
    );
  }
}

class MainShell extends StatefulWidget {
  final SettingsService settingsService;

  const MainShell({super.key, required this.settingsService});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final GlobalKey<DbfViewState> _dbfKey = GlobalKey<DbfViewState>();
  final GlobalKey<AccessViewState> _accessKey = GlobalKey<AccessViewState>();

  void _onDbfUpdated() {
    _dbfKey.currentState?.loadDbf();
  }

  void _onAccessUpdated() {
    _accessKey.currentState?.loadAccessDb();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail for Desktop Form Factor
          NavigationRail(
            selectedIndex: _selectedIndex,
            extended: true,
            minExtendedWidth: 230,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.dataset, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DualBase Manager',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'DBF & Access Suite',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.table_chart_outlined),
                selectedIcon: Icon(Icons.table_chart, color: Colors.amber),
                label: Text('DBF (Read-Only)'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.storage_outlined),
                selectedIcon: Icon(Icons.storage, color: Colors.redAccent),
                label: Text('MS Access (CRUD)'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings, color: Colors.teal),
                label: Text('Settings / Locations'),
              ),
            ],
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),

          // Main Views
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                DbfView(
                  key: _dbfKey,
                  settingsService: widget.settingsService,
                  onNavigateToSettings: () => setState(() => _selectedIndex = 2),
                ),
                AccessView(
                  key: _accessKey,
                  settingsService: widget.settingsService,
                  onNavigateToSettings: () => setState(() => _selectedIndex = 2),
                ),
                SettingsView(
                  settingsService: widget.settingsService,
                  onDbfUpdated: _onDbfUpdated,
                  onAccessUpdated: _onAccessUpdated,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
