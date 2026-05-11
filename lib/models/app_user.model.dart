import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:tourism_app/models/profile.model.dart';

class AppUser {
  final supabase.User? authUser; // Supabase auth user
  final Profile? profile;           // Your brick Profile model (the "profile")

  AppUser({this.authUser, this.profile});

  String? get id => authUser?.id;

  String? get email => authUser?.email;

  String? get fullName => profile?.fullName;

  String? get role => profile?.role;

  bool get isAuthenticated => authUser != null;
}