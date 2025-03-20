import '../../models/user.dart';
import '../../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<User> execute(String email, String password) {
    return repository.register(email, password);
  }
} 