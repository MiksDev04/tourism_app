// GENERATED CODE EDIT WITH CAUTION
// THIS FILE **WILL NOT** BE REGENERATED
// This file should be version controlled and can be manually edited.
part of 'schema.g.dart';

// While migrations are intelligently created, the difference between some commands, such as
// DropTable vs. RenameTable, cannot be determined. For this reason, please review migrations after
// they are created to ensure the correct inference was made.

// The migration version must **always** mirror the file name

const List<MigrationCommand> _migration_20260511135429_up = [
  InsertTable('Business'),
  InsertColumn('id', Column.varchar, onTable: 'Business', unique: true),
  InsertForeignKey('Business', 'Profile', foreignKeyColumn: 'profile_Profile_brick_id', onDeleteCascade: false, onDeleteSetDefault: false),
  InsertColumn('business_name', Column.varchar, onTable: 'Business'),
  InsertColumn('business_type', Column.integer, onTable: 'Business'),
  InsertColumn('owner_name', Column.varchar, onTable: 'Business'),
  InsertColumn('permit_number', Column.varchar, onTable: 'Business'),
  InsertColumn('registration_number', Column.varchar, onTable: 'Business'),
  InsertColumn('address', Column.varchar, onTable: 'Business'),
  InsertColumn('contact_number', Column.varchar, onTable: 'Business'),
  InsertColumn('email', Column.varchar, onTable: 'Business'),
  InsertColumn('total_rooms', Column.integer, onTable: 'Business'),
  InsertColumn('permit_file_url', Column.varchar, onTable: 'Business'),
  InsertColumn('valid_id_url', Column.varchar, onTable: 'Business'),
  InsertColumn('status', Column.integer, onTable: 'Business'),
  InsertColumn('remarks', Column.varchar, onTable: 'Business'),
  InsertColumn('created_at', Column.varchar, onTable: 'Business'),
  InsertColumn('updated_at', Column.varchar, onTable: 'Business'),
  InsertColumn('deleted_at', Column.varchar, onTable: 'Business'),
  CreateIndex(columns: ['id'], onTable: 'Business', unique: true)
];

const List<MigrationCommand> _migration_20260511135429_down = [
  DropTable('Business'),
  DropColumn('id', onTable: 'Business'),
  DropColumn('profile_Profile_brick_id', onTable: 'Business'),
  DropColumn('business_name', onTable: 'Business'),
  DropColumn('business_type', onTable: 'Business'),
  DropColumn('owner_name', onTable: 'Business'),
  DropColumn('permit_number', onTable: 'Business'),
  DropColumn('registration_number', onTable: 'Business'),
  DropColumn('address', onTable: 'Business'),
  DropColumn('contact_number', onTable: 'Business'),
  DropColumn('email', onTable: 'Business'),
  DropColumn('total_rooms', onTable: 'Business'),
  DropColumn('permit_file_url', onTable: 'Business'),
  DropColumn('valid_id_url', onTable: 'Business'),
  DropColumn('status', onTable: 'Business'),
  DropColumn('remarks', onTable: 'Business'),
  DropColumn('created_at', onTable: 'Business'),
  DropColumn('updated_at', onTable: 'Business'),
  DropColumn('deleted_at', onTable: 'Business'),
  DropIndex('index_Business_on_id')
];

//
// DO NOT EDIT BELOW THIS LINE
//

@Migratable(
  version: '20260511135429',
  up: _migration_20260511135429_up,
  down: _migration_20260511135429_down,
)
class Migration20260511135429 extends Migration {
  const Migration20260511135429()
    : super(
        version: 20260511135429,
        up: _migration_20260511135429_up,
        down: _migration_20260511135429_down,
      );
}
