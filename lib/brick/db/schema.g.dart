// GENERATED CODE DO NOT EDIT
// This file should be version controlled
import 'package:brick_sqlite/db.dart';
part '20260510142638.migration.dart';
part '20260507142519.migration.dart';

/// All intelligently-generated migrations from all `@Migratable` classes on disk
final migrations = <Migration>{
  const Migration20260510142638(),const Migration20260507142519()};

/// A consumable database structure including the latest generated migration.
final schema = Schema(
  20260507142519,
  generatorVersion: 1,
  tables: <SchemaTable>{
    SchemaTable(
      'Profile',
      columns: <SchemaColumn>{
        SchemaColumn(
          '_brick_id',
          Column.integer,
          autoincrement: true,
          nullable: false,
          isPrimaryKey: true,
        ),
        SchemaColumn('full_name', Column.varchar),
        SchemaColumn('role', Column.varchar),
        SchemaColumn('create_at', Column.varchar),
        SchemaColumn('updated_at', Column.varchar),
        SchemaColumn('id', Column.varchar, unique: true),
        SchemaColumn('deleted_at', Column.varchar),
      },
      indices: <SchemaIndex>{
        SchemaIndex(columns: ['id'], unique: true),
      },
    ),
  },
);
