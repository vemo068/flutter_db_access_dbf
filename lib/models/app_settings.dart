class AppSettings {
  final String dbfPath;
  final String accessDbPath;
  final String dbfEncoding; // "CP1252", "UTF-8", "Latin1"
  final int itemsPerPage;

  const AppSettings({
    required this.dbfPath,
    required this.accessDbPath,
    this.dbfEncoding = 'CP1252',
    this.itemsPerPage = 25,
  });

  AppSettings copyWith({
    String? dbfPath,
    String? accessDbPath,
    String? dbfEncoding,
    int? itemsPerPage,
  }) {
    return AppSettings(
      dbfPath: dbfPath ?? this.dbfPath,
      accessDbPath: accessDbPath ?? this.accessDbPath,
      dbfEncoding: dbfEncoding ?? this.dbfEncoding,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    );
  }
}
