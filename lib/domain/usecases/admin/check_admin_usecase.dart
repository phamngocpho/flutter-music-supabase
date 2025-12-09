import 'package:spotify/domain/repositories/admin_repository.dart';
import 'package:spotify/service_locator.dart';

class CheckAdminUseCase {
  bool call({String? email}) {
    if (email == null) return false;
    return sl<AdminRepository>().isAdmin(email);
  }
}

