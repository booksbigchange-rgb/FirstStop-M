import 'package:flutter/material.dart';

const firstStopRed = Color(0xFFBD1725);
const firstStopInk = Color(0xFF241A1A);
const firstStopCream = Color(0xFFF8F5F2);

/// A read-only, role-aware dashboard. Business permissions remain in Supabase RLS.
class FirstStopDashboard extends StatelessWidget {
  const FirstStopDashboard({
    super.key,
    required this.profile,
    required this.role,
    required this.washes,
    required this.cafes,
    required this.staff,
    required this.t,
    required this.roleName,
    required this.statusName,
    required this.onRefresh,
    this.staffEditor,
  });

  final Map<String, dynamic> profile;
  final String role;
  final List<Map<String, dynamic>> washes;
  final List<Map<String, dynamic>> cafes;
  final List<Map<String, dynamic>> staff;
  final String Function(String, String) t;
  final String Function(String) roleName;
  final String Function(String) statusName;
  final VoidCallback? onRefresh;
  final Widget? staffEditor;

  Widget _panel({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECE5DF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A302020),
            blurRadius: 24,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: firstStopRed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800,
                            color: firstStopInk)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF817474))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _empty(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: firstStopCream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFB6A6A0), size: 32),
          const SizedBox(height: 10),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: firstStopInk, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF827774), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _metric(
      {required IconData icon,
      required String title,
      required String value,
      required String footnote}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFECE5DF)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: firstStopRed, size: 25),
        const SizedBox(height: 16),
        Text(value,
            style: const TextStyle(
                color: firstStopInk,
                fontSize: 34,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(title,
            style: const TextStyle(
                color: firstStopInk,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(footnote,
            style: const TextStyle(
                color: Color(0xFF887B76), fontSize: 11)),
      ]),
    );
  }

  Widget _hero(bool wide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(wide ? 32 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF98121F), Color(0xFFCD2832)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: wide
          ? Row(children: [
              Expanded(child: _heroContent()),
              const SizedBox(width: 20),
              const Icon(Icons.local_cafe_rounded,
                  color: Color(0x55FFFFFF), size: 108),
            ])
          : _heroContent(),
    );
  }

  Widget _heroContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t('WELCOME TO FIRST STOP', 'እንኳን ወደ ፈርስት ስቶፕ በደህና መጡ'),
          style: const TextStyle(
              color: Color(0xFFFFD9D8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2)),
      const SizedBox(height: 12),
      Text(t('Your business, at a glance', 'ንግድዎን በአንድ እይታ'),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.15)),
      const SizedBox(height: 14),
      Text(
        t('Car wash and coffee, together in one place.',
            'የመኪና ማጠቢያና ቡና በአንድ ቦታ።'),
        style: const TextStyle(color: Color(0xFFF9DFDD), fontSize: 14),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Text(
          t('Signed in as ', 'የገቡት፦ ') + roleName(role),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    ]);
  }

  Widget _washPanel() => _panel(
        title: t('Car wash queue', 'የመኪና ማጠቢያ ተራ'),
        subtitle: t('Latest service activity', 'የቅርብ ጊዜ የአገልግሎት እንቅስቃሴ'),
        icon: Icons.local_car_wash_rounded,
        child: washes.isEmpty
            ? _empty(
                Icons.directions_car_outlined,
                t('No wash tickets yet', 'የማጠቢያ ትዕዛዝ የለም'),
                t('New wash tickets will appear here.',
                    'አዲስ የማጠቢያ ትዕዛዞች እዚህ ይታያሉ።'),
              )
            : Column(children: [
                for (final job in washes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFEEEE),
                      child: Icon(Icons.directions_car_outlined,
                          color: firstStopRed),
                    ),
                    title: Text(job['plate_number']?.toString() ?? ''),
                    subtitle: Text(statusName(
                        job['status']?.toString() ?? '')),
                  ),
              ]),
      );

  Widget _cafePanel() => _panel(
        title: t('Coffee orders', 'የቡና ትዕዛዞች'),
        subtitle: t('Drive-thru and takeaway', 'ድራይቭ ትሩና የሚወሰድ ቡና'),
        icon: Icons.local_cafe_rounded,
        child: cafes.isEmpty
            ? _empty(
                Icons.coffee_outlined,
                t('No coffee orders yet', 'የቡና ትዕዛዝ የለም'),
                t('Your latest orders will appear here.',
                    'የቅርብ ጊዜ የቡና ትዕዛዞች እዚህ ይታያሉ።'),
              )
            : Column(children: [
                for (final order in cafes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFEEEE),
                      child: Icon(Icons.local_cafe_outlined,
                          color: firstStopRed),
                    ),
                    title: Text(
                      t('Order ', 'ትዕዛዝ ') +
                          order['id'].toString().substring(0, 8),
                    ),
                    subtitle: Text(statusName(
                        order['status']?.toString() ?? '')),
                  ),
              ]),
      );

  Widget _staffPanel() => _panel(
        title: t('Your team', 'የሠራተኞች ቡድን'),
        subtitle: t('Roles and account status', 'የሥራ ድርሻና የመለያ ሁኔታ'),
        icon: Icons.groups_rounded,
        child: staff.isEmpty
            ? _empty(
                Icons.people_outline,
                t('No staff to display', 'የሚታዩ ሠራተኞች የሉም'),
                t('Staff will appear when assigned.',
                    'ሠራተኞች ከተመደቡ በኋላ ይታያሉ።'),
              )
            : Column(children: [
                for (final person in staff)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFEEEE),
                      child: Icon(Icons.person_outline, color: firstStopRed),
                    ),
                    title: Text(person['display_name']?.toString() ?? ''),
                    subtitle: Text(roleName(person['role']?.toString() ?? '')),
                    trailing: Text(
                      person['active'] == true
                          ? t('Active', 'ንቁ')
                          : t('Disabled', 'የታገደ'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: person['active'] == true
                            ? const Color(0xFF287850)
                            : firstStopRed,
                      ),
                    ),
                  ),
              ]),
      );

  @override
  Widget build(BuildContext context) {
    final canWash = const ['owner', 'manager', 'cashier', 'washer'].contains(role);
    final canCafe = const ['owner', 'manager', 'cashier', 'barista'].contains(role);
    final canStaff = const ['owner', 'manager'].contains(role);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 740;
      final showCount = (canWash ? 1 : 0) +
          (canCafe ? 1 : 0) +
          (canStaff ? 1 : 0);
      final metricColumns = wide ? showCount : (constraints.maxWidth >= 520 ? 2 : 1);
      final metricWidth =
          (constraints.maxWidth - (metricColumns - 1) * 14) / metricColumns;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _hero(wide),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: Text(t('Overview', 'አጠቃላይ እይታ'),
                style: const TextStyle(
                    color: firstStopInk,
                    fontSize: 23,
                    fontWeight: FontWeight.w900)),
          ),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(t('Refresh', 'አድስ')),
          ),
        ]),
        const SizedBox(height: 15),
        Wrap(spacing: 14, runSpacing: 14, children: [
          if (canWash)
            SizedBox(
                width: metricWidth,
                child: _metric(
                    icon: Icons.local_car_wash_rounded,
                    title: t('Wash tickets', 'የማጠቢያ ትዕዛዞች'),
                    value: washes.length.toString(),
                    footnote: t('Latest 50 records', 'የመጨረሻ 50 መዝገቦች'))),
          if (canCafe)
            SizedBox(
                width: metricWidth,
                child: _metric(
                    icon: Icons.local_cafe_rounded,
                    title: t('Coffee orders', 'የቡና ትዕዛዞች'),
                    value: cafes.length.toString(),
                    footnote: t('Latest 50 records', 'የመጨረሻ 50 መዝገቦች'))),
          if (canStaff)
            SizedBox(
                width: metricWidth,
                child: _metric(
                    icon: Icons.groups_rounded,
                    title: t('Active team members', 'ንቁ ሠራተኞች'),
                    value: staff.where((p) => p['active'] == true).length.toString(),
                    footnote: t('Including owner', 'ባለቤቱን ጨምሮ'))),
        ]),
        const SizedBox(height: 24),
        if (canWash && canCafe && wide)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _washPanel()),
            const SizedBox(width: 16),
            Expanded(child: _cafePanel()),
          ])
        else ...[
          if (canWash) _washPanel(),
          if (canWash && canCafe) const SizedBox(height: 16),
          if (canCafe) _cafePanel(),
        ],
        if (canStaff) ...[
          const SizedBox(height: 16),
          _staffPanel(),
        ],
        if (staffEditor != null) ...[
          const SizedBox(height: 16),
          staffEditor!,
        ],
        const SizedBox(height: 20),
        Center(
          child: Text(
            t('READ-ONLY PILOT  •  CHECKOUT COMING SOON',
                'የሙከራ እይታ  •  የክፍያ አገልግሎት በቅርቡ'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF95857E),
                fontWeight: FontWeight.w700,
                letterSpacing: 1),
          ),
        ),
      ]);
    });
  }
}
