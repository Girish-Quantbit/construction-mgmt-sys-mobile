import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;

  const User({required this.id, required this.username});

  @override
  List<Object?> get props => [id, username];
}
