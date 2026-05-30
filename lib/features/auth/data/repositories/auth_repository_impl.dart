import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FrappeSDK sdk;
  final SharedPreferences sharedPreferences;
  User? _currentUser;

  static const String _userKey = 'cached_user_id';
  static const String _usernameKey = 'cached_username';

  AuthRepositoryImpl(this.sdk, this.sharedPreferences);

  @override
  Future<Either<Failure, User>> login(String username, String password) async {
    try {
      final response = await sdk.auth.login(username, password);

      if (response.isNotEmpty) {
        final userId = response['full_name'] ?? response['message'] ?? username;
        _currentUser = User(id: userId, username: username);

        // Persist user info
        await sharedPreferences.setString(_userKey, userId);
        await sharedPreferences.setString(_usernameKey, username);

        return Right(_currentUser!);
      } else {
        return const Left(
          AuthFailure('Login failed. Please check your credentials.'),
        );
      }
    } catch (e) {
      return Left(AuthFailure('Error: ${e.toString()}'));
    }
  }

  @override
  Future<void> logout() async {
    await sdk.auth.logout();
    await sharedPreferences.remove(_userKey);
    await sharedPreferences.remove(_usernameKey);
    _currentUser = null;
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    if (_currentUser != null) {
      return Right(_currentUser!);
    }

    final userId = sharedPreferences.getString(_userKey);
    final username = sharedPreferences.getString(_usernameKey);

    if (userId != null && username != null && sdk.isAuthenticated) {
      _currentUser = User(id: userId, username: username);
      return Right(_currentUser!);
    }

    return const Left(AuthFailure('No user logged in.'));
  }
}
