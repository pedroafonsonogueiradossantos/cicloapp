import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'cities/city_list_screen.dart';
import 'items/item_list_screen.dart';
import 'maintenance/maintenance_screen.dart';
import 'orders/order_list_screen.dart';
import 'persons/person_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Clientes'),
    NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'Manutenção'),
    NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Pedidos'),
    NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Itens'),
    NavigationDestination(icon: Icon(Icons.location_city_outlined), selectedIcon: Icon(Icons.location_city), label: 'Cidades'),
  ];

  @override
  Widget build(BuildContext context) {
    final actions = [
      IconButton(
        tooltip: 'Sair',
        icon: const Icon(Icons.logout),
        onPressed: () => context.read<AuthProvider>().logout(),
      ),
    ];
    final screens = [
      PersonListScreen(actions: actions),
      MaintenanceScreen(actions: actions),
      OrderListScreen(actions: actions),
      ItemListScreen(actions: actions),
      CityListScreen(actions: actions),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
