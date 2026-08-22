import 'package:equatable/equatable.dart';

abstract class ProjectEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetProjectsRequested extends ProjectEvent {}
