import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Role checks here control navigation only. PostgreSQL enforces every request.
bool canReadWash(String role) =>
    ['owner', 'manager', 'cashier', 'washer'].contains(role);
bool canReadCafe(String role) =>
    ['owner', 'manager', 'cashier', 'barista'].contains(role);

class ConnectedApp extends StatefulWidget {
  const ConnectedApp({super.key, required this.client});
  final SupabaseClient client;
  @override
  State<ConnectedApp> createState() => _ConnectedAppState();
}

class _ConnectedAppState extends State<ConnectedApp> {
  final email = TextEditingController();
  final password = TextEditingController();
  final staffEmail = TextEditingController();
  final staffName = TextEditingController();
  StreamSubscription<AuthState>? subscription;
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> washes = [], cafes = [], staff = [];
  bool am = false, busy = false, enabled = true;
  String? error;
  String staffRole = 'cashier';
  int request = 0;
  String t(String en, String ah) => am ? ah : en;
  String roleName(String role) => switch (role) {
    'owner' => t('Owner', 'ባለቤት'),
    'manager' => t('Manager', 'ሥራ አስኪያጅ'),
    'cashier' => t('Cashier', 'ገንዘብ ተቀባይ'),
    'washer' => t('Washer', 'አጣቢ'),
    'barista' => t('Barista', 'ቡና አዘጋጅ'),
    _ => '',
  };

  @override
  void initState() {
    super.initState();
    subscription = widget.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedOut) {
        request++;
        if (mounted) {
          setState(() {
            profile = null;
            washes = [];
            cafes = [];
            staff = [];
            busy = false;
            error = null;
          });
        }
      } else if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.initialSession) {
        if (event.session != null) {
          unawaited(load());
        }
      }
    });
    if (widget.client.auth.currentUser != null) {
      unawaited(load());
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    for (final c in [email, password, staffEmail, staffName]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    final user = widget.client.auth.currentUser;
    if (user == null) {
      return;
    }
    final current = ++request;
    setState(() {
      busy = true;
      error = null;
      profile = null;
      washes = [];
      cafes = [];
      staff = [];
    });
    try {
      final p = await widget.client
          .from('profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (p == null || p['active'] != true) {
        throw StateError('No active profile');
      }
      final role = p['role'] as String;
      final w = canReadWash(role)
          ? await widget.client
                .from('wash_jobs')
                .select('id,plate_number,status')
                .order('created_at', ascending: false)
                .limit(50)
          : <Map<String, dynamic>>[];
      final c = canReadCafe(role)
          ? await widget.client
                .from('cafe_orders')
                .select('id,status')
                .order('created_at', ascending: false)
                .limit(50)
          : <Map<String, dynamic>>[];
      final s = ['owner', 'manager'].contains(role)
          ? await widget.client
                .from('profiles')
                .select('display_name,role,active')
                .order('created_at')
          : <Map<String, dynamic>>[];
      if (!mounted || current != request) {
        return;
      }
      setState(() {
        profile = p;
        washes = w;
        cafes = c;
        staff = s;
        am = p['preferred_language'] == 'am';
      });
    } catch (_) {
      if (mounted && current == request) {
        setState(() => error = 'access');
      }
    } finally {
      if (mounted && current == request) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> signIn() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'login');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.client.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
      password.clear();
      await load();
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'login';
          busy = false;
        });
      }
    }
  }

  Future<void> changeLanguage() async {
    final next = !am;
    if (profile == null) {
      setState(() => am = next);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.client.rpc(
        'set_preferred_language',
        params: {'language_code': next ? 'am' : 'en'},
      );
      if (mounted) {
        setState(() => am = next);
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'save');
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> saveStaff() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.client.rpc(
        'set_staff_access',
        params: {
          'staff_email': staffEmail.text.trim(),
          'staff_role': staffRole,
          'staff_name': staffName.text.trim(),
          'enabled': enabled,
        },
      );
      staffEmail.clear();
      staffName.clear();
      await load();
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'staff';
          busy = false;
        });
      }
    }
  }

  String statusName(String status) => switch (status) {
    'waiting' => t('Waiting', 'በመጠባበቅ ላይ'),
    'washing' => t('Washing', 'በመታጠብ ላይ'),
    'ready' => t('Ready', 'ዝግጁ'),
    'completed' => t('Completed', 'ተጠናቋል'),
    'cancelled' => t('Cancelled', 'ተሰርዟል'),
    'new' => t('New', 'አዲስ'),
    'preparing' => t('Preparing', 'በዝግጅት ላይ'),
    'served' => t('Served', 'ቀርቧል'),
    _ => status,
  };

  Widget field(
    TextEditingController controller,
    String label, {
    bool secret = false,
    bool mail = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextField(
      controller: controller,
      obscureText: secret,
      enabled: !busy,
      autocorrect: !secret && !mail,
      enableSuggestions: !secret,
      keyboardType: mail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final signedIn = widget.client.auth.currentUser != null;
    final role = profile?['role'] as String? ?? '';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FirstStop-M',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF125BA5)),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FirstStop-M'),
          actions: [
            TextButton(
              onPressed: busy ? null : changeLanguage,
              child: Text(am ? 'English' : 'አማርኛ'),
            ),
            if (signedIn)
              IconButton(
                tooltip: t('Sign out', 'ውጣ'),
                onPressed: busy
                    ? null
                    : () async {
                        try {
                          await widget.client.auth.signOut();
                        } catch (_) {
                          if (mounted) {
                            setState(() => error = 'save');
                          }
                        }
                      },
                icon: const Icon(Icons.logout),
              ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (busy) const LinearProgressIndicator(),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(switch (error) {
                        'login' => t(
                          'Could not sign in. Check your email, password and connection.',
                          'መግባት አልተቻለም። ኢሜይል፣ የይለፍ ቃል እና ግንኙነት ያረጋግጡ።',
                        ),
                        'access' => t(
                          'Could not load your account. Check your connection or ask the owner to enable your account.',
                          'መለያዎን መጫን አልተቻለም። ግንኙነትዎን ያረጋግጡ ወይም ባለቤቱን ያነጋግሩ።',
                        ),
                        'staff' => t(
                          'Could not save staff. Use a confirmed account, a name and a staff role. Owner accounts cannot be changed here.',
                          'ሠራተኛውን ማስቀመጥ አልተቻለም። የተረጋገጠ መለያ፣ ስም እና ሚና ያስገቡ። የባለቤት መለያ እዚህ አይቀየርም።',
                        ),
                        _ => t(
                          'Could not save. Check your connection and try again.',
                          'ማስቀመጥ አልተቻለም። ግንኙነትዎን ያረጋግጡ እና እንደገና ይሞክሩ።',
                        ),
                      }),
                    ),
                  if (!signedIn)
                    section(t('Sign in', 'ግባ'), [
                      field(email, t('Email', 'ኢሜይል'), mail: true),
                      field(password, t('Password', 'የይለፍ ቃል'), secret: true),
                      FilledButton(
                        onPressed: busy ? null : signIn,
                        child: Text(t('Sign in', 'ግባ')),
                      ),
                    ]),
                  if (signedIn)
                    OutlinedButton.icon(
                      onPressed: busy ? null : load,
                      icon: const Icon(Icons.refresh),
                      label: Text(t('Refresh account', 'መለያ አድስ')),
                    ),
                  if (profile != null) ...[
                    section(t('Your account', 'የእርስዎ መለያ'), [
                      Text('${profile!['display_name']} • ${roleName(role)}'),
                    ]),
                    Text(
                      t(
                        'Connected to your business. Orders are read-only while checkout is under development.',
                        'ከንግድዎ ጋር ተገናኝቷል። የክፍያ ሥርዓቱ እስኪጠናቀቅ ድረስ ትዕዛዞችን ማየት ብቻ ይቻላል።',
                      ),
                    ),
                    if (canReadWash(role))
                      section(t('Car wash queue', 'የመኪና ማጠቢያ ተራ'), [
                        if (washes.isEmpty)
                          Text(t('No wash tickets yet.', 'ገና የማጠብ ትዕዛዞች የሉም።')),
                        for (final job in washes)
                          ListTile(
                            title: Text(job['plate_number'] as String),
                            subtitle: Text(statusName(job['status'] as String)),
                          ),
                      ]),
                    if (canReadCafe(role))
                      section(t('Coffee orders', 'የቡና ትዕዛዞች'), [
                        if (cafes.isEmpty)
                          Text(t('No coffee orders yet.', 'ገና የቡና ትዕዛዞች የሉም።')),
                        for (final order in cafes)
                          ListTile(
                            title: Text(
                              '${t('Order', 'ትዕዛዝ')} ${order['id'].toString().substring(0, 8)}',
                            ),
                            subtitle: Text(
                              statusName(order['status'] as String),
                            ),
                          ),
                      ]),
                    if (['owner', 'manager'].contains(role))
                      section(t('Staff', 'ሠራተኞች'), [
                        for (final person in staff)
                          ListTile(
                            title: Text(person['display_name'] as String),
                            subtitle: Text(
                              '${roleName(person['role'] as String)} • ${person['active'] == true ? t('Active', 'ንቁ') : t('Disabled', 'ታግዷል')}',
                            ),
                          ),
                      ]),
                    if (role == 'owner')
                      section(t('Set staff access', 'የሠራተኛ ፈቃድ ያዘጋጁ'), [
                        Text(
                          t(
                            'Use the email of an existing confirmed staff account.',
                            'የነባር የተረጋገጠ የሠራተኛ መለያ ኢሜይል ይጠቀሙ።',
                          ),
                        ),
                        field(
                          staffEmail,
                          t('Staff email', 'የሠራተኛ ኢሜይል'),
                          mail: true,
                        ),
                        field(staffName, t('Staff name', 'የሠራተኛ ስም')),
                        DropdownButton<String>(
                          value: staffRole,
                          isExpanded: true,
                          items: [
                            for (final r in [
                              'manager',
                              'cashier',
                              'washer',
                              'barista',
                            ])
                              DropdownMenuItem(
                                value: r,
                                child: Text(roleName(r)),
                              ),
                          ],
                          onChanged: busy
                              ? null
                              : (v) => setState(() => staffRole = v!),
                        ),
                        SwitchListTile(
                          title: Text(t('Account enabled', 'መለያ ንቁ ነው')),
                          value: enabled,
                          onChanged: busy
                              ? null
                              : (v) => setState(() => enabled = v),
                        ),
                        FilledButton(
                          onPressed: busy ? null : saveStaff,
                          child: Text(
                            t('Save staff access', 'የሠራተኛ ፈቃድ አስቀምጥ'),
                          ),
                        ),
                      ]),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
