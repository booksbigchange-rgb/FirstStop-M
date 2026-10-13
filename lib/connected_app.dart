import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'first_stop_dashboard.dart';

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

  Widget section(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFECE5DF)),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 25, color: firstStopInk,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );

  Widget _staffEditor() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFECE5DF)),
    ),
    child: ExpansionTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFFFEEEE),
        child: Icon(Icons.manage_accounts_outlined, color: firstStopRed),
      ),
      title: Text(
        t('Manage staff access', 'የሠራተኞች ፈቃድ አስተዳድር'),
        style: const TextStyle(
            fontWeight: FontWeight.w800, color: firstStopInk),
      ),
      subtitle: Text(
        t('Assign a role to an existing confirmed account',
            'ለተረጋገጠ መለያ የሥራ ድርሻ ይመድቡ'),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      children: [
        field(staffEmail, t('Staff email', 'የሠራተኛ ኢሜይል'), mail: true),
        field(staffName, t('Staff name', 'የሠራተኛ ስም')),
        DropdownButtonFormField<String>(
          initialValue: staffRole,
          decoration: InputDecoration(labelText: t('Role', 'የሥራ ድርሻ')),
          items: [
            for (final r in ['manager', 'cashier', 'washer', 'barista'])
              DropdownMenuItem(value: r, child: Text(roleName(r))),
          ],
          onChanged: busy ? null : (v) {
            if (v != null) setState(() => staffRole = v);
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t('Account enabled', 'መለያ ንቁ ነው')),
          value: enabled,
          onChanged: busy ? null : (v) => setState(() => enabled = v),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : saveStaff,
            icon: const Icon(Icons.save_outlined),
            label: Text(t('Save staff access', 'የሠራተኛ ፈቃድ አስቀምጥ')),
          ),
        ),
      ],
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
        scaffoldBackgroundColor: firstStopCream,
        colorScheme: ColorScheme.fromSeed(seedColor: firstStopRed),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: firstStopInk,
          surfaceTintColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFCFAF8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE7DCD6)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: firstStopRed,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_cafe_rounded, color: firstStopRed),
              SizedBox(width: 9),
              Flexible(
                child: Text(
                  'FIRST STOP',
                  style: TextStyle(
                    color: firstStopInk,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
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
              constraints: const BoxConstraints(maxWidth: 1160),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 40),
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
                  if (profile != null)
                    FirstStopDashboard(
                      profile: profile!,
                      role: role,
                      washes: washes,
                      cafes: cafes,
                      staff: staff,
                      t: t,
                      roleName: roleName,
                      statusName: statusName,
                      onRefresh: busy ? null : load,
                      staffEditor: role == 'owner' ? _staffEditor() : null,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
