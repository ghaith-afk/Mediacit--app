
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mediatech/views/user_loans_page.dart';
import 'package:mediatech/widgets/app_drawer.dart';
import 'user_catalogue_page.dart';
import 'events_page.dart';
import 'messages_page.dart';
import 'profile_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _idx = 0;

  final _searchController = TextEditingController();
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
  
    pages = [
      const CataloguePage(),
      UserLoansPage(),
      EventsPage(),
      MessagesPage(),
      ProfilePage(),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mediacité')),
      drawer: AppDrawer(onLogout: () {/* hook auth logout */}),
      body: pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Catalogue',),
          BottomNavigationBarItem(icon: Icon(Icons.book_online_rounded), label: 'Réservations',),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Événements'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
