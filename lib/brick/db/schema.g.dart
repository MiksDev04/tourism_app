// GENERATED CODE DO NOT EDIT
// This file should be version controlled
import 'package:brick_sqlite/db.dart';
part '20260511141400.migration.dart';
part '20260511130600.migration.dart';

/// All intelligently-generated migrations from all `@Migratable` classes on disk
final migrations = <Migration>{
  const Migration20260511141400(),const Migration20260511130600()};

/// A consumable database structure including the latest generated migration.
final schema = Schema(
  20260511130600,
  generatorVersion: 1,
  tables: <SchemaTable>{
    SchemaTable(
      'Business',
      columns: <SchemaColumn>{
        SchemaColumn(
          '_brick_id',
          Column.integer,
          autoincrement: true,
          nullable: false,
          isPrimaryKey: true,
        ),
        SchemaColumn('id', Column.varchar, unique: true),
        SchemaColumn(
          'profile_Profile_brick_id',
          Column.integer,
          isForeignKey: true,
          foreignTableName: 'Profile',
          onDeleteCascade: false,
          onDeleteSetDefault: false,
        ),
        SchemaColumn('business_name', Column.varchar),
        SchemaColumn('business_type', Column.integer),
        SchemaColumn('owner_name', Column.varchar),
        SchemaColumn('permit_number', Column.varchar),
        SchemaColumn('registration_number', Column.varchar),
        SchemaColumn('address', Column.varchar),
        SchemaColumn('total_rooms', Column.integer),
        SchemaColumn('permit_file_url', Column.varchar),
        SchemaColumn('valid_id_url', Column.varchar),
        SchemaColumn('status', Column.integer),
        SchemaColumn('remarks', Column.varchar),
        SchemaColumn('created_at', Column.varchar),
        SchemaColumn('updated_at', Column.varchar),
        SchemaColumn('deleted_at', Column.varchar),
      },
      indices: <SchemaIndex>{
        SchemaIndex(columns: ['id'], unique: true),
      },
    ),
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
        SchemaColumn('created_at', Column.varchar),
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
