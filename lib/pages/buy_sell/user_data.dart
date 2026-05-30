import 'package:e_waste/app/data/supabase_repository.dart';

Future<Map<String, dynamic>?> getUserDataSell() async {
  return SupabaseRepository.ensureCurrentProfileExists();
}
