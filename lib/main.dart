import 'package:flutter/material.dart';

void main() => runApp(const FirstStopApp());

class FirstStopApp extends StatefulWidget {
  const FirstStopApp({super.key});

  @override
  State<FirstStopApp> createState() => _FirstStopAppState();
}

class _FirstStopAppState extends State<FirstStopApp> {
  bool amharic = false;
  int page = 0;
  final washJobs = <String>[];
  final coffeeOrders = <String>[];

  String t(String english, String amharicText) => amharic ? amharicText : english;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboard(),
      _wash(),
      _coffee(),
      _settings(),
    ];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FirstStop-M',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF125BA5)),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FirstStop-M'),
          actions: [
            TextButton(
              onPressed: () => setState(() => amharic = !amharic),
              child: Text(amharic ? 'English' : 'አማርኛ'),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: pages[page],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: page,
          onDestinationSelected: (value) => setState(() => page = value),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              label: t('Dashboard', 'ዳሽቦርድ'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.local_car_wash_outlined),
              label: t('Car Wash', 'መኪና ማጠቢያ'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.coffee_outlined),
              label: t('Coffee', 'ቡና'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              label: t('Settings', 'ቅንብሮች'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _screen(List<Widget> children) => ListView(
        padding: const EdgeInsets.all(20),
        children: children,
      );

  Widget _heading(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      );

  Widget _tile(IconData icon, String title, String subtitle) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
        ),
      );

  Widget _dashboard() => _screen([
        _heading(t('Business overview', 'የንግድ አጠቃላይ እይታ')),
        _tile(Icons.car_repair, t('Demo wash tickets', 'የሙከራ የመኪና ትዕዛዞች'), '${washJobs.length}'),
        _tile(Icons.coffee, t('Demo coffee orders', 'የሙከራ የቡና ትዕዛዞች'), '${coffeeOrders.length}'),
        const SizedBox(height: 12),
        Text(t('Starter preview only. No database, authentication, or payments are connected.',
            'ይህ የሙከራ ማሳያ ብቻ ነው። የመረጃ ቋት፣ መግቢያ ወይም ክፍያ አልተገናኘም።')),
      ]);

  Widget _wash() => _screen([
        _heading(t('Car wash queue', 'የመኪና ማጠቢያ ተራ')),
        FilledButton.icon(
          onPressed: () => setState(() => washJobs.add('Wash #${washJobs.length + 1}')),
          icon: const Icon(Icons.add),
          label: Text(t('Add demo wash ticket', 'የሙከራ የማጠብ ትዕዛዝ ጨምር')),
        ),
        for (final job in washJobs) _tile(Icons.local_car_wash, job, t('Waiting', 'በመጠባበቅ ላይ')),
      ]);

  Widget _coffee() => _screen([
        _heading(t('Coffee orders', 'የቡና ትዕዛዞች')),
        for (final item in <String>['Espresso', 'Macchiato', 'Tea'])
          Card(
            child: ListTile(
              title: Text(item),
              trailing: IconButton(
                tooltip: t('Add demo order', 'የሙከራ ትዕዛዝ ጨምር'),
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => coffeeOrders.add(item)),
              ),
            ),
          ),
        const SizedBox(height: 10),
        _heading(t('Demo order list', 'የሙከራ ትዕዛዝ ዝርዝር')),
        for (final item in coffeeOrders) _tile(Icons.coffee, item, t('New', 'አዲስ')),
      ]);

  Widget _settings() => _screen([
        _heading(t('Settings', 'ቅንብሮች')),
        SwitchListTile(
          title: Text(t('Amharic language', 'አማርኛ ቋንቋ')),
          value: amharic,
          onChanged: (v) => setState(() => amharic = v),
        ),
        Text(t('Language selection is local to this app session.',
            'የቋንቋ ምርጫው ለዚህ የመተግበሪያ ክፍለ ጊዜ ብቻ ነው።')),
      ]);
}
