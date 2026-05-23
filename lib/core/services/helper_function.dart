import 'package:supabase_flutter/supabase_flutter.dart';

Future<List<Map<String, dynamic>>> getAdminAccounts() async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('profiles')
      .select('full_name, email, phone')
      .eq('role', 'admin')
      .isFilter('deleted_at', null);

  return List<Map<String, dynamic>>.from(response);
}