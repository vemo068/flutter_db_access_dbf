using System;
using System.Collections.Generic;
using System.Data;
using System.Data.OleDb;
using System.IO;
using System.Text;

namespace AccessBridgeApp {
    class Program {
        static int Main(string[] args) {
            Console.OutputEncoding = Encoding.UTF8;
            Console.InputEncoding = Encoding.UTF8;

            if (args.Length < 2) {
                OutputError("Usage: access_bridge <command> <dbPath> [sql/args...]");
                return 1;
            }

            string command = args[0].ToLowerInvariant();
            string dbPath = args[1];

            if (command == "create_db") {
                return HandleCreateDb(dbPath);
            }

            if (!File.Exists(dbPath)) {
                OutputError("Database file not found: " + dbPath);
                return 2;
            }

            string usedProvider;
            string connectErr;
            OleDbConnection conn = Connect(dbPath, out usedProvider, out connectErr);
            if (conn == null) {
                OutputError("Could not connect to Access DB: " + connectErr);
                return 3;
            }

            try {
                switch (command) {
                    case "ping":
                        Console.WriteLine("{\"status\":\"ok\",\"provider\":\"" + EscapeJson(usedProvider) + "\",\"file\":\"" + EscapeJson(dbPath) + "\"}");
                        return 0;

                    case "tables":
                        return HandleTables(conn);

                    case "schema":
                        if (args.Length < 3) {
                            OutputError("Table name parameter required for schema command");
                            return 4;
                        }
                        return HandleSchema(conn, args[2]);

                    case "query": {
                        string sql = ReadSqlArg(args, 2);
                        if (string.IsNullOrEmpty(sql)) {
                            OutputError("SQL query string is required");
                            return 5;
                        }
                        return HandleQuery(conn, sql);
                    }

                    case "execute": {
                        string sql = ReadSqlArg(args, 2);
                        if (string.IsNullOrEmpty(sql)) {
                            OutputError("SQL execution string is required");
                            return 6;
                        }
                        return HandleExecute(conn, sql);
                    }

                    default:
                        OutputError("Unknown command: " + command);
                        return 7;
                }
            } catch (Exception ex) {
                OutputError("SQL Execution Error: " + ex.Message);
                return 10;
            } finally {
                try {
                    if (conn != null) {
                        if (conn.State == ConnectionState.Open) conn.Close();
                        conn.Dispose();
                    }
                } catch {}
            }
        }

        static string ReadSqlArg(string[] args, int index) {
            if (args.Length > index) {
                if (args[index] == "--stdin") {
                    return Console.In.ReadToEnd().Trim();
                }
                // If there are multiple arguments after index, join them
                var sb = new StringBuilder();
                for (int i = index; i < args.Length; i++) {
                    if (i > index) sb.Append(" ");
                    sb.Append(args[i]);
                }
                return sb.ToString().Trim();
            }
            // If no arg, check if stdin has data
            try {
                return Console.In.ReadToEnd().Trim();
            } catch {
                return "";
            }
        }

        static OleDbConnection Connect(string dbPath, out string usedProvider, out string error) {
            usedProvider = null;
            error = null;

            string[] providers = new string[] {
                "Microsoft.ACE.OLEDB.12.0",
                "Microsoft.ACE.OLEDB.16.0",
                "Microsoft.Jet.OLEDB.4.0"
            };

            foreach (string prov in providers) {
                try {
                    string connStr = string.Format("Provider={0};Data Source={1};Persist Security Info=False;", prov, dbPath);
                    var conn = new OleDbConnection(connStr);
                    conn.Open();
                    usedProvider = prov;
                    return conn;
                } catch (Exception ex) {
                    error = ex.Message;
                }
            }

            return null;
        }

        static int HandleCreateDb(string dbPath) {
            try {
                if (File.Exists(dbPath)) {
                    OutputError("File already exists: " + dbPath);
                    return 20;
                }
                var cat = Activator.CreateInstance(Type.GetTypeFromProgID("ADOX.Catalog"));
                string connStr = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" + dbPath;
                cat.GetType().InvokeMember("Create", System.Reflection.BindingFlags.InvokeMethod, null, cat, new object[] { connStr });
                Console.WriteLine("{\"status\":\"ok\",\"created\":\"" + EscapeJson(dbPath) + "\"}");
                return 0;
            } catch (Exception ex) {
                OutputError("Failed to create database: " + ex.Message);
                return 21;
            }
        }

        static int HandleTables(OleDbConnection conn) {
            DataTable dt = conn.GetOleDbSchemaTable(OleDbSchemaGuid.Tables, new object[] { null, null, null, "TABLE" });
            var tables = new List<string>();
            if (dt != null) {
                foreach (DataRow row in dt.Rows) {
                    string tName = row["TABLE_NAME"].ToString();
                    if (!tName.StartsWith("MSys") && !tName.StartsWith("~") && !tName.StartsWith("usys")) {
                        tables.Add(tName);
                    }
                }
            }
            tables.Sort();

            var sb = new StringBuilder();
            sb.Append("[");
            for (int i = 0; i < tables.Count; i++) {
                if (i > 0) sb.Append(",");
                sb.Append("\"").Append(EscapeJson(tables[i])).Append("\"");
            }
            sb.Append("]");
            Console.WriteLine(sb.ToString());
            return 0;
        }

        static int HandleSchema(OleDbConnection conn, string tableName) {
            var primaryKeys = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            try {
                DataTable pkTable = conn.GetOleDbSchemaTable(OleDbSchemaGuid.Primary_Keys, new object[] { null, null, tableName });
                if (pkTable != null) {
                    foreach (DataRow r in pkTable.Rows) {
                        primaryKeys.Add(r["COLUMN_NAME"].ToString());
                    }
                }
            } catch {}

            using (var cmd = conn.CreateCommand()) {
                cmd.CommandText = string.Format("SELECT TOP 1 * FROM [{0}]", tableName.Replace("]", "]]"));
                using (var reader = cmd.ExecuteReader(CommandBehavior.SchemaOnly)) {
                    var schemaTable = reader.GetSchemaTable();
                    var sb = new StringBuilder();
                    sb.Append("[");
                    bool first = true;
                    if (schemaTable != null) {
                        foreach (DataRow row in schemaTable.Rows) {
                            if (!first) sb.Append(",");
                            first = false;

                            string colName = row["ColumnName"].ToString();
                            string dataTypeName = row["DataType"].ToString();
                            bool isAutoIncrement = row.Table.Columns.Contains("IsAutoIncrement") && row["IsAutoIncrement"] != DBNull.Value && Convert.ToBoolean(row["IsAutoIncrement"]);
                            bool isKey = primaryKeys.Contains(colName) || (row.Table.Columns.Contains("IsKey") && row["IsKey"] != DBNull.Value && Convert.ToBoolean(row["IsKey"]));
                            bool isReadOnly = row.Table.Columns.Contains("IsReadOnly") && row["IsReadOnly"] != DBNull.Value && Convert.ToBoolean(row["IsReadOnly"]);
                            bool allowDbNull = row.Table.Columns.Contains("AllowDBNull") && row["AllowDBNull"] != DBNull.Value && Convert.ToBoolean(row["AllowDBNull"]);
                            int columnSize = row.Table.Columns.Contains("ColumnSize") && row["ColumnSize"] != DBNull.Value ? Convert.ToInt32(row["ColumnSize"]) : 0;

                            // Translate .NET data types to friendly names
                            string friendlyType = "String";
                            if (dataTypeName.Contains("Int32") || dataTypeName.Contains("Int64") || dataTypeName.Contains("Int16") || dataTypeName.Contains("Byte")) {
                                friendlyType = "Integer";
                            } else if (dataTypeName.Contains("Double") || dataTypeName.Contains("Single") || dataTypeName.Contains("Decimal")) {
                                friendlyType = "Number";
                            } else if (dataTypeName.Contains("Boolean")) {
                                friendlyType = "Boolean";
                            } else if (dataTypeName.Contains("DateTime")) {
                                friendlyType = "DateTime";
                            }

                            sb.Append("{");
                            sb.Append("\"name\":\"").Append(EscapeJson(colName)).Append("\",");
                            sb.Append("\"rawType\":\"").Append(EscapeJson(dataTypeName)).Append("\",");
                            sb.Append("\"friendlyType\":\"").Append(EscapeJson(friendlyType)).Append("\",");
                            sb.Append("\"isAutoIncrement\":").Append(isAutoIncrement ? "true" : "false").Append(",");
                            sb.Append("\"isKey\":").Append(isKey ? "true" : "false").Append(",");
                            sb.Append("\"isReadOnly\":").Append(isReadOnly ? "true" : "false").Append(",");
                            sb.Append("\"allowDbNull\":").Append(allowDbNull ? "true" : "false").Append(",");
                            sb.Append("\"size\":").Append(columnSize);
                            sb.Append("}");
                        }
                    }
                    sb.Append("]");
                    Console.WriteLine(sb.ToString());
                }
            }
            return 0;
        }

        static int HandleQuery(OleDbConnection conn, string sql) {
            using (var cmd = conn.CreateCommand()) {
                cmd.CommandText = sql;
                using (var adapter = new OleDbDataAdapter(cmd)) {
                    var dt = new DataTable();
                    adapter.Fill(dt);

                    var sb = new StringBuilder();
                    sb.Append("[");
                    for (int r = 0; r < dt.Rows.Count; r++) {
                        if (r > 0) sb.Append(",");
                        sb.Append("{");
                        for (int c = 0; c < dt.Columns.Count; c++) {
                            if (c > 0) sb.Append(",");
                            string colName = dt.Columns[c].ColumnName;
                            object val = dt.Rows[r][c];
                            sb.Append("\"").Append(EscapeJson(colName)).Append("\":");
                            if (val == DBNull.Value) {
                                sb.Append("null");
                            } else if (val is bool) {
                                sb.Append((bool)val ? "true" : "false");
                            } else if (val is byte || val is sbyte || val is short || val is int || val is long || val is float || val is double || val is decimal) {
                                sb.Append(Convert.ToString(val, System.Globalization.CultureInfo.InvariantCulture));
                            } else if (val is DateTime) {
                                sb.Append("\"").Append(((DateTime)val).ToString("yyyy-MM-dd HH:mm:ss")).Append("\"");
                            } else {
                                sb.Append("\"").Append(EscapeJson(val.ToString())).Append("\"");
                            }
                        }
                        sb.Append("}");
                    }
                    sb.Append("]");
                    Console.WriteLine(sb.ToString());
                }
            }
            return 0;
        }

        static int HandleExecute(OleDbConnection conn, string sql) {
            using (var cmd = conn.CreateCommand()) {
                cmd.CommandText = sql;
                int affected = cmd.ExecuteNonQuery();
                Console.WriteLine("{\"status\":\"ok\",\"affectedRows\":" + affected + "}");
            }
            return 0;
        }

        static void OutputError(string message) {
            Console.WriteLine("{\"status\":\"error\",\"error\":\"" + EscapeJson(message) + "\"}");
        }

        static string EscapeJson(string s) {
            if (string.IsNullOrEmpty(s)) return "";
            var sb = new StringBuilder();
            foreach (char c in s) {
                switch (c) {
                    case '\\': sb.Append("\\\\"); break;
                    case '\"': sb.Append("\\\""); break;
                    case '\b': sb.Append("\\b"); break;
                    case '\f': sb.Append("\\f"); break;
                    case '\n': sb.Append("\\n"); break;
                    case '\r': sb.Append("\\r"); break;
                    case '\t': sb.Append("\\t"); break;
                    default:
                        if (c < 32) {
                            sb.AppendFormat("\\u{0:X4}", (int)c);
                        } else {
                            sb.Append(c);
                        }
                        break;
                }
            }
            return sb.ToString();
        }
    }
}
