import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cms/core/di/injection_container.dart' as di;
import 'package:cms/core/theme/app_theme.dart';
import 'package:cms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cms/features/auth/presentation/bloc/auth_event.dart';
import 'package:cms/features/auth/presentation/bloc/auth_state.dart';
import 'package:cms/features/auth/presentation/pages/login_page.dart';
import 'package:cms/features/projects/presentation/pages/projects_home_page.dart';
import 'package:cms/features/projects/presentation/bloc/project_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
      child: MaterialApp(
        title: 'ConstructionMS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppContent(),
      ),
    );
  }
}

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) =>
                    di.sl<ProjectBloc>()..add(GetProjectsRequested()),
              ),
            ],
            child: const ProjectsHomePage(),
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
