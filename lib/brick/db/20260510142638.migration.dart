// GENERATED CODE EDIT WITH CAUTION
// THIS FILE **WILL NOT** BE REGENERATED
// This file should be version controlled and can be manually edited.
part of 'schema.g.dart';

// While migrations are intelligently created, the difference between some commands, such as
// DropTable vs. RenameTable, cannot be determined. For this reason, please review migrations after
// they are created to ensure the correct inference was made.

// The migration version must **always** mirror the file name

const List<MigrationCommand> _migration_20260510142638_up = [
  InsertColumn('deleted_at', Column.varchar, onTable: 'Profile')
];

const List<MigrationCommand> _migration_20260510142638_down = [
  DropColumn('deleted_at', onTable: 'Profile')
];

//
// DO NOT EDIT BELOW THIS LINE
//

@Migratable(
  version: '20260510142638',
  up: _migration_20260510142638_up,
  down: _migration_20260510142638_down,
)
class Migration20260510142638 extends Migration {
  const Migration20260510142638()
    : super(
        version: 20260510142638,
        up: _migration_20260510142638_up,
        down: _migration_20260510142638_down,
      );
}
