// GENERATED CODE EDIT WITH CAUTION
// THIS FILE **WILL NOT** BE REGENERATED
// This file should be version controlled and can be manually edited.
part of 'schema.g.dart';

// While migrations are intelligently created, the difference between some commands, such as
// DropTable vs. RenameTable, cannot be determined. For this reason, please review migrations after
// they are created to ensure the correct inference was made.

// The migration version must **always** mirror the file name

const List<MigrationCommand> _migration_20260507142519_up = [
  InsertTable('Profile'),
  InsertColumn('full_name', Column.varchar, onTable: 'Profile'),
  InsertColumn('role', Column.varchar, onTable: 'Profile'),
  InsertColumn('create_at', Column.varchar, onTable: 'Profile'),
  InsertColumn('updated_at', Column.varchar, onTable: 'Profile'),
  InsertColumn('id', Column.varchar, onTable: 'Profile', unique: true),
  CreateIndex(columns: ['id'], onTable: 'Profile', unique: true)
];

const List<MigrationCommand> _migration_20260507142519_down = [
  DropTable('Profile'),
  DropColumn('full_name', onTable: 'Profile'),
  DropColumn('role', onTable: 'Profile'),
  DropColumn('create_at', onTable: 'Profile'),
  DropColumn('updated_at', onTable: 'Profile'),
  DropColumn('id', onTable: 'Profile'),
  DropIndex('index_Profile_on_id')
];

//
// DO NOT EDIT BELOW THIS LINE
//

@Migratable(
  version: '20260507142519',
  up: _migration_20260507142519_up,
  down: _migration_20260507142519_down,
)
class Migration20260507142519 extends Migration {
  const Migration20260507142519()
    : super(
        version: 20260507142519,
        up: _migration_20260507142519_up,
        down: _migration_20260507142519_down,
      );
}
