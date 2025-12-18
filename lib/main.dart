import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediatech/Controllers/ThemeController.dart';
import 'package:mediatech/models/theme_enum.dart';
import 'package:mediatech/views/admin/admin_page.dart';
import 'package:mediatech/views/admin/admins_loans_page.dart';
import 'package:mediatech/views/admin/dashboard_view.dart';
import 'package:mediatech/views/admin/media_view.dart';
import 'package:mediatech/views/admin/user_management_view.dart';




import 'package:mediatech/views/user_catalogue_page.dart';
import 'package:mediatech/views/home_page.dart';
import 'package:mediatech/views/login_page.dart';
import 'package:mediatech/views/register_page.dart';
import 'package:mediatech/views/user_loans_page.dart';


import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.init();
  runApp(const ProviderScope(child: MyApp()));
}
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: 'Mediacité',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: theme == UserTheme.light ? ThemeMode.light : ThemeMode.dark,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/catalogue': (context) => const CataloguePage(),
        '/home': (context) => const HomePage(),
        '/admin': (context) => const AdminPage(),
        '/forget-password': (context) => const AdminPage(),
        '/admin/user-management': (context) => const UserManagementView(),
        '/admin/media-management': (context) => const MediaManagementView(),
        '/admin/emprunt-management':(context)=> const AdminLoansReservationsPage(),
        

         '/user/loans': (context) => const UserLoansPage(),
      },
    );
  }
}
