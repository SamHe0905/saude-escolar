import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config.dart';
import 'theme.dart';
import 'common.dart';

final supabase = Supabase.instance.client;

const _selectAtestado =
    '*, professor:professores!atestados_professor_id_fkey(id,nome,area), '
    'substituto:substitutos!atestados_substituto_id_fkey(id,nome,area)';

const double kContentMax = 1080;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const AtestadosApp());
}

class AtestadosApp extends StatelessWidget {
  const AtestadosApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saúde Escolar',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, _) {
        final session = supabase.auth.currentSession;
        return session == null ? const LoginPage() : const AppShell();
      },
    );
  }
}

// ===========================================================================
// LOGIN
// ===========================================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _loading = false;
  bool _verSenha = false;
  String? _erro;
  final _senhaFocus = FocusNode();

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      await supabase.auth.signInWithPassword(
          email: _email.text.trim(), password: _senha.text);
    } on AuthException catch (e) {
      setState(() => _erro = _traduz(e.message));
    } catch (e) {
      setState(() => _erro = 'Não foi possível entrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Faixa institucional no topo
          Container(height: 4, color: AppColors.navy),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: Image.asset('assets/logo.png', height: 92)),
                      const SizedBox(height: 18),
                      Center(
                        child: Text('Sistema de Controle de Atestados',
                            textAlign: TextAlign.center,
                            style: GoogleFontsInter.w700(18)),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text('E.E. Teotonio Vilela',
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.soft,
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Acesso ao sistema', style: sectionTitle()),
                            const SizedBox(height: 4),
                            Text('Identifique-se para continuar.', style: bodyMuted()),
                            const SizedBox(height: 22),
                            _Campo(
                              label: 'E-mail',
                              child: TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => _senhaFocus.requestFocus(),
                                decoration: const InputDecoration(
                                  hintText: 'seu@email.com',
                                  prefixIcon: Icon(Icons.mail_outline, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _Campo(
                              label: 'Senha',
                              child: _PasswordField(
                                controller: _senha,
                                focusNode: _senhaFocus,
                                visible: _verSenha,
                                onToggle: () => setState(() => _verSenha = !_verSenha),
                                onSubmit: _entrar,
                              ),
                            ),
                            if (_erro != null) ...[
                              const SizedBox(height: 16),
                              _ErroBox(_erro!),
                            ],
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: _loading ? null : _entrar,
                              child: _loading ? const _BtnSpinner() : const Text('Entrar'),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.textMuted),
                                icon: const Icon(Icons.badge_outlined, size: 16),
                                label: const Text('Tenho um convite — criar conta'),
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const SignupPage())),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Center(
                        child: Text('Acesso restrito à equipe gestora autorizada.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SIGNUP
// ===========================================================================
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _senha2 = TextEditingController();
  final _codigo = TextEditingController();
  bool _loading = false;
  bool _verSenha = false;
  String? _erro;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _senha2.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    final email = _email.text.trim();
    final senha = _senha.text;
    final codigo = _codigo.text.trim();
    if (email.isEmpty || senha.isEmpty || codigo.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos.'); return;
    }
    if (codigo != inviteCode) {
      setState(() => _erro = 'Código de convite inválido.'); return;
    }
    if (senha.length < 6) {
      setState(() => _erro = 'A senha precisa ter ao menos 6 caracteres.'); return;
    }
    if (senha != _senha2.text) {
      setState(() => _erro = 'As senhas não coincidem.'); return;
    }
    setState(() { _loading = true; _erro = null; _info = null; });
    try {
      final res = await supabase.auth.signUp(email: email, password: senha);
      if (!mounted) return;
      if (res.session != null) {
        Navigator.of(context).pop();
      } else {
        setState(() => _info =
            'Conta criada. Verifique seu e-mail para confirmar antes de entrar.');
      }
    } on AuthException catch (e) {
      setState(() => _erro = _traduz(e.message));
    } catch (e) {
      setState(() => _erro = 'Não foi possível criar a conta.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Subpage(
      title: 'Criar conta',
      maxWidth: 440,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          Center(child: Image.asset('assets/logo.png', height: 92)),
          const SizedBox(height: 22),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Acesso da equipe', style: title()),
                const SizedBox(height: 6),
                Text('Use o código de convite fornecido pela escola.',
                    style: bodyMuted()),
                const SizedBox(height: 22),
                _Campo(
                  label: 'Código de convite',
                  child: TextField(
                    controller: _codigo,
                    decoration: const InputDecoration(
                      hintText: 'Informe o código',
                      prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _Campo(
                  label: 'E-mail',
                  child: TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'seu@email.com',
                      prefixIcon: Icon(Icons.mail_outline, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _Campo(
                  label: 'Senha',
                  child: _PasswordField(
                    controller: _senha,
                    visible: _verSenha,
                    hint: 'Mínimo 6 caracteres',
                    onToggle: () => setState(() => _verSenha = !_verSenha),
                  ),
                ),
                const SizedBox(height: 16),
                _Campo(
                  label: 'Confirmar senha',
                  child: _PasswordField(
                    controller: _senha2,
                    visible: _verSenha,
                    hint: 'Repita a senha',
                    onToggle: () => setState(() => _verSenha = !_verSenha),
                    onSubmit: _cadastrar,
                  ),
                ),
                if (_erro != null) ...[const SizedBox(height: 16), _ErroBox(_erro!)],
                if (_info != null) ...[const SizedBox(height: 16), _InfoBox(_info!)],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _cadastrar,
                  child: _loading ? const _BtnSpinner() : const Text('Criar conta'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// APP SHELL (sidebar + conteúdo)
// ===========================================================================
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _itens = [
    (_NavData(Icons.dashboard_outlined, Icons.dashboard, 'Painel')),
    (_NavData(Icons.event_note_outlined, Icons.event_note, 'Atestados')),
    (_NavData(Icons.groups_outlined, Icons.groups, 'Professores')),
    (_NavData(Icons.swap_horiz_outlined, Icons.swap_horiz, 'Substitutos')),
  ];

  Widget _view() {
    switch (_index) {
      case 1:
        return const AtestadosView();
      case 2:
        return const BancoView(
            key: ValueKey('prof'),
            tabela: 'professores',
            titulo: 'Professores',
            subtitulo: 'Quadro de docentes da escola.',
            singular: 'professor');
      case 3:
        return const BancoView(
            key: ValueKey('subs'),
            tabela: 'substitutos',
            titulo: 'Substitutos',
            subtitulo: 'Profissionais disponíveis para cobertura.',
            singular: 'substituto');
      default:
        return DashboardView(onIrPara: (i) => setState(() => _index = i));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= kBreakpoint;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              itens: _itens,
              index: _index,
              onSelect: (i) => setState(() => _index = i),
            ),
            Expanded(child: _view()),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        title: Row(children: [
          Image.asset('assets/logo.png', height: 30),
          const SizedBox(width: 10),
          Text('Saúde Escolar',
              style: GoogleFontsInter.w700(15)),
        ]),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        child: _Sidebar(
          itens: _itens,
          index: _index,
          onSelect: (i) {
            setState(() => _index = i);
            Navigator.of(context).pop();
          },
          inDrawer: true,
        ),
      ),
      body: _view(),
    );
  }
}

class _NavData {
  final IconData icon;
  final IconData active;
  final String label;
  const _NavData(this.icon, this.active, this.label);
}

class _Sidebar extends StatelessWidget {
  final List<_NavData> itens;
  final int index;
  final ValueChanged<int> onSelect;
  final bool inDrawer;
  const _Sidebar({
    required this.itens,
    required this.index,
    required this.onSelect,
    this.inDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? '';
    return Container(
      width: kSidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              child: Row(
                children: [
                  Image.asset('assets/logo.png', height: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Saúde Escolar', style: GoogleFontsInter.w700(15)),
                        Text('E.E. Teotonio Vilela',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Text('MENU', style: overline()),
            ),
            for (var i = 0; i < itens.length; i++)
              _NavTile(
                data: itens[i],
                selected: index == i,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  PersonAvatar(email.isEmpty ? '?' : email, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(email.split('@').first,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const Text('Conectado',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sair',
                    icon: const Icon(Icons.logout, size: 19),
                    onPressed: () => supabase.auth.signOut(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavData data;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile({required this.data, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? AppColors.navySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.navySoft.withValues(alpha: 0.5),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(selected ? data.active : data.icon,
                    size: 20,
                    color: selected ? AppColors.navy : AppColors.textMuted),
                const SizedBox(width: 12),
                Text(data.label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? AppColors.navy : AppColors.text)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Área de conteúdo rolável centralizada.
class ContentArea extends StatelessWidget {
  final Widget child;
  const ContentArea({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kContentMax),
        child: child,
      ),
    );
  }
}

// ===========================================================================
// PAINEL (DASHBOARD)
// ===========================================================================
class DashboardView extends StatefulWidget {
  final ValueChanged<int> onIrPara;
  const DashboardView({super.key, required this.onIrPara});
  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late Future<List<Map<String, dynamic>>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Map<String, dynamic>>> _carregar() async {
    final ats = await supabase
        .from('atestados')
        .select(_selectAtestado)
        .order('data_inicio', ascending: false);
    return List<Map<String, dynamic>>.from(ats);
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  Future<void> _novo() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const FormularioPage()));
    _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return ContentArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futuro,
        builder: (context, snap) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
            children: [
              PageHeader(
                'Painel',
                subtitle: 'Visão geral dos afastamentos e coberturas.',
                actions: [
                  FilledButton.icon(
                    onPressed: _novo,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Registrar atestado'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (snap.connectionState == ConnectionState.waiting)
                const SkeletonList(count: 3, height: 96)
              else if (snap.hasError)
                _ErroBox('Erro ao carregar: ${snap.error}')
              else
                _conteudo(snap.data ?? []),
            ],
          );
        },
      ),
    );
  }

  Widget _conteudo(List<Map<String, dynamic>> atestados) {
    final ativos = atestados.where((a) => statusOf(a) == 'ativo').toList();
    final futuros = atestados.where((a) => statusOf(a) == 'futuro').toList();
    final h = hojeData();
    final encerram7 = ativos.where((a) {
      final fim = DateTime.parse(a['data_fim']);
      final dias = fim.difference(h).inDays;
      return dias >= 0 && dias <= 7;
    }).length;
    final coberturas = ativos.where((a) => a['substituto'] != null).toList();
    final substitutosDistintos = coberturas
        .map((a) => a['substituto']?['id'])
        .whereType<String>()
        .toSet()
        .length;

    final cards = [
      _Stat('Atestados ativos', '${ativos.length}', Icons.event_available_outlined,
          AppColors.green, AppColors.greenSoft),
      _Stat('Programados', '${futuros.length}', Icons.schedule_outlined,
          AppColors.navy, AppColors.navySoft),
      _Stat('Encerram em 7 dias', '$encerram7', Icons.timelapse_outlined,
          AppColors.amber, AppColors.amberSoft),
      _Stat('Substitutos atuando', '$substitutosDistintos', Icons.diversity_3_outlined,
          AppColors.navy, AppColors.navySoft),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, c) {
          final cols = (c.maxWidth / 230).floor().clamp(1, 4);
          const gap = 16.0;
          final w = (c.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [for (final s in cards) SizedBox(width: w, child: s)],
          );
        }),
        const SizedBox(height: 28),
        _Painel(
          titulo: 'Coberturas ativas hoje',
          icon: Icons.diversity_3_outlined,
          trailing: TextButton(
            onPressed: () => widget.onIrPara(1),
            child: const Text('Ver atestados'),
          ),
          child: coberturas.isEmpty
              ? _miniVazio('Nenhuma cobertura em andamento hoje.')
              : Column(
                  children: [
                    for (final a in coberturas) _CoberturaRow(a),
                  ],
                ),
        ),
        const SizedBox(height: 20),
        _Painel(
          titulo: 'Próximos retornos',
          icon: Icons.event_repeat_outlined,
          child: ativos.isEmpty
              ? _miniVazio('Nenhum professor afastado no momento.')
              : Column(
                  children: [
                    for (final a in (ativos
                          ..sort((x, y) => DateTime.parse(x['data_fim'])
                              .compareTo(DateTime.parse(y['data_fim'])))))
                      _RetornoRow(a),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _miniVazio(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Center(
            child: Text(t, style: bodyMuted())),
      );
}

class _Stat extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icon;
  final Color fg;
  final Color bg;
  const _Stat(this.label, this.valor, this.icon, this.fg, this.bg);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: fg, size: 21),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(valor,
              style: GoogleFontsInter.w800(28).copyWith(letterSpacing: -1)),
          const SizedBox(height: 2),
          Text(label, style: bodyMuted()),
        ],
      ),
    );
  }
}

class _Painel extends StatelessWidget {
  final String titulo;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  const _Painel({
    required this.titulo,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.navy),
              const SizedBox(width: 8),
              Text(titulo, style: sectionTitle()),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _CoberturaRow extends StatelessWidget {
  final Map<String, dynamic> a;
  const _CoberturaRow(this.a);
  @override
  Widget build(BuildContext context) {
    final prof = a['professor'] as Map<String, dynamic>?;
    final sub = a['substituto'] as Map<String, dynamic>?;
    final fim = DateTime.parse(a['data_fim']);
    final nomeSub = sub?['nome'] ?? '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          PersonAvatar(nomeSub, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nomeSub,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text(
                    'cobrindo ${prof?['nome'] ?? '—'}'
                    '${(prof?['area'] ?? '').toString().isNotEmpty ? ' · ${prof!['area']}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyMuted()),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MetaPill(turnosIcon(a['turno']), turnosLabel(a['turno'])),
              const SizedBox(height: 4),
              Text('até ${dataCurta(fim)}',
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 11.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RetornoRow extends StatelessWidget {
  final Map<String, dynamic> a;
  const _RetornoRow(this.a);
  @override
  Widget build(BuildContext context) {
    final prof = a['professor'] as Map<String, dynamic>?;
    final fim = DateTime.parse(a['data_fim']);
    final faltam = fim.difference(hojeData()).inDays;
    final frase = faltam <= 0
        ? 'Último dia hoje'
        : faltam == 1
            ? 'Retorna amanhã'
            : 'Retorna em $faltam dias';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          PersonAvatar(prof?['nome'] ?? '?', size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prof?['nome'] ?? '—',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text((prof?['area'] ?? '').toString(),
                    style: bodyMuted()),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(frase,
                  style: TextStyle(
                      color: faltam <= 1 ? AppColors.amber : AppColors.textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
              Text(dataCurta(fim),
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 11.5)),
            ],
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ATESTADOS
// ===========================================================================
class AtestadosView extends StatefulWidget {
  const AtestadosView({super.key});
  @override
  State<AtestadosView> createState() => _AtestadosViewState();
}

class _AtestadosViewState extends State<AtestadosView> {
  late Future<List<Map<String, dynamic>>> _futuro;
  String _busca = '';
  String _status = 'todos';

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Map<String, dynamic>>> _carregar() async {
    final res = await supabase
        .from('atestados')
        .select(_selectAtestado)
        .order('data_inicio', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  Future<void> _novo() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const FormularioPage()));
    _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 560;
    return ContentArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              'Atestados',
              subtitle: 'Todos os afastamentos registrados.',
              actions: [
                FilledButton.icon(
                  onPressed: _novo,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Novo atestado'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            wide
                ? Row(children: [
                    Expanded(child: _campoBusca()),
                    const SizedBox(width: 12),
                    SegmentedFilter(
                      value: _status,
                      onChanged: (v) => setState(() => _status = v),
                    ),
                  ])
                : Column(children: [
                    _campoBusca(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedFilter(
                          value: _status,
                          onChanged: (v) => setState(() => _status = v),
                        ),
                      ),
                    ),
                  ]),
            const SizedBox(height: 18),
            Expanded(child: _lista()),
          ],
        ),
      ),
    );
  }

  Widget _campoBusca() => TextField(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search, size: 20),
          hintText: 'Buscar por professor ou substituto…',
        ),
        onChanged: (v) => setState(() => _busca = v.toLowerCase()),
      );

  Widget _lista() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SkeletonList();
        }
        if (snap.hasError) {
          return _ErroBox('Erro ao carregar: ${snap.error}');
        }
        final todos = snap.data ?? [];
        final lista = todos.where((a) {
          if (_status != 'todos' && statusOf(a) != _status) return false;
          if (_busca.isEmpty) return true;
          final p = ((a['professor']?['nome']) ?? '').toString().toLowerCase();
          final s = ((a['substituto']?['nome']) ?? '').toString().toLowerCase();
          return p.contains(_busca) || s.contains(_busca);
        }).toList();

        if (lista.isEmpty) {
          return EmptyState(
            icon: todos.isEmpty ? Icons.event_note_outlined : Icons.search_off,
            title: todos.isEmpty ? 'Nenhum atestado ainda' : 'Nada encontrado',
            subtitle: todos.isEmpty
                ? 'Registre o primeiro afastamento para começar.'
                : 'Ajuste a busca ou o filtro de status.',
            action: todos.isEmpty
                ? FilledButton.icon(
                    onPressed: _novo,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Novo atestado'),
                  )
                : null,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _recarregar(),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 28),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _AtestadoTile(
              atestado: lista[i],
              onChanged: _recarregar,
            ),
          ),
        );
      },
    );
  }
}

class _AtestadoTile extends StatelessWidget {
  final Map<String, dynamic> atestado;
  final VoidCallback onChanged;
  const _AtestadoTile({required this.atestado, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final a = atestado;
    final ini = DateTime.parse(a['data_inicio']);
    final fim = DateTime.parse(a['data_fim']);
    final dias = diasInclusivos(ini, fim);
    final status = statusOf(a);
    final prof = a['professor'] as Map<String, dynamic>?;
    final sub = a['substituto'] as Map<String, dynamic>?;
    final nome = prof?['nome'] ?? '—';

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () async {
        await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DetalhePage(atestado: a)));
        onChanged();
      },
      child: Row(
        children: [
          PersonAvatar(nome, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(nome,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFontsInter.w600(15)),
                    ),
                    if ((prof?['area'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('· ${prof!['area']}',
                            overflow: TextOverflow.ellipsis,
                            style: bodyMuted()),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    MetaPill(Icons.event_outlined,
                        '${dateFmt.format(ini)} – ${dateFmt.format(fim)}'),
                    MetaPill(Icons.timelapse_outlined,
                        '$dias dia${dias > 1 ? 's' : ''}'),
                    MetaPill(turnosIcon(a['turno']), turnosLabel(a['turno'])),
                    if (sub != null)
                      MetaPill(Icons.person_outline, 'Cobre: ${sub['nome']}',
                          color: AppColors.navy, bg: AppColors.navySoft),
                    if (a['arquivo_path'] != null)
                      const MetaPill(Icons.attach_file, 'Anexo'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(status),
              const SizedBox(height: 12),
              const Icon(Icons.chevron_right,
                  color: AppColors.textFaint, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class SegmentedFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const SegmentedFilter({super.key, required this.value, required this.onChanged});

  static const _opts = [
    ('todos', 'Todos'),
    ('ativo', 'Ativos'),
    ('futuro', 'Programados'),
    ('encerrado', 'Encerrados'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF4),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in _opts)
            GestureDetector(
              onTap: () => onChanged(o.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: value == o.$1 ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: value == o.$1 ? AppShadows.soft : null,
                ),
                child: Text(o.$2,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: value == o.$1 ? AppColors.navy : AppColors.textMuted)),
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// FORMULÁRIO
// ===========================================================================
class FormularioPage extends StatefulWidget {
  final Map<String, dynamic>? atestado;
  const FormularioPage({super.key, this.atestado});
  @override
  State<FormularioPage> createState() => _FormularioPageState();
}

class _FormularioPageState extends State<FormularioPage> {
  final _formKey = GlobalKey<FormState>();
  final _observacoes = TextEditingController();
  DateTime? _inicio;
  DateTime? _fim;
  final Set<String> _turnos = {};
  PlatformFile? _novoArquivo;
  String? _arquivoExistente;
  bool _removerArquivo = false;
  bool _salvando = false;
  bool _carregando = true;

  List<Map<String, dynamic>> _professores = [];
  List<Map<String, dynamic>> _substitutos = [];
  Map<String, Cobertura> _coberturas = {};
  Map<String, dynamic>? _profSel;
  Map<String, dynamic>? _subSel;

  bool get _editando => widget.atestado != null;

  @override
  void dispose() {
    _observacoes.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (_editando) {
      final a = widget.atestado!;
      _inicio = DateTime.parse(a['data_inicio']);
      _fim = DateTime.parse(a['data_fim']);
      _turnos.addAll(turnosOf(a['turno']));
      _observacoes.text = (a['observacoes'] ?? '').toString();
      _arquivoExistente = a['arquivo_path'];
      _profSel = a['professor'] is Map ? Map<String, dynamic>.from(a['professor']) : null;
      _subSel = a['substituto'] is Map ? Map<String, dynamic>.from(a['substituto']) : null;
    }
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final p = await supabase.from('professores').select().order('nome');
      _professores = List<Map<String, dynamic>>.from(p);
      final s = await supabase.from('substitutos').select().order('nome');
      _substitutos = List<Map<String, dynamic>>.from(s);

      final hoje = DateTime.now().toIso8601String().substring(0, 10);
      final ativos = await supabase
          .from('atestados')
          .select('id, substituto_id, data_fim, turno, '
              'professor:professores!atestados_professor_id_fkey(nome)')
          .gte('data_fim', hoje)
          .not('substituto_id', 'is', null);
      final mapa = <String, Cobertura>{};
      for (final a in ativos) {
        final sid = a['substituto_id'] as String?;
        if (sid == null) continue;
        if (_editando && a['id'] == widget.atestado!['id']) continue;
        mapa[sid] = Cobertura(
          (a['professor']?['nome'] ?? '').toString(),
          DateTime.parse(a['data_fim']),
          turnosOf(a['turno']),
        );
      }
      _coberturas = mapa;
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _pickArquivo() async {
    final res = await FilePicker.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() {
        _novoArquivo = res.files.first;
        _removerArquivo = false;
      });
    }
  }

  Future<void> _pickData(bool inicio) async {
    final base = inicio ? (_inicio ?? DateTime.now()) : (_fim ?? _inicio ?? DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.navy)),
        child: child!,
      ),
    );
    if (d != null) {
      setState(() {
        if (inicio) {
          _inicio = d;
          if (_fim != null && _fim!.isBefore(d)) _fim = d;
        } else {
          _fim = d;
        }
      });
    }
  }

  Future<void> _pickPessoa(bool substituto) async {
    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _PessoaPicker(
        titulo: substituto ? 'Selecionar substituto' : 'Selecionar professor',
        pessoas: substituto ? _substitutos : _professores,
        coberturas: substituto ? _coberturas : null,
        tabela: substituto ? 'substitutos' : 'professores',
      ),
    );
    if (res != null) {
      final lista = substituto ? _substitutos : _professores;
      if (!lista.any((p) => p['id'] == res['id'])) {
        final nova = [...lista, res]
          ..sort((a, b) => (a['nome'] as String).compareTo(b['nome'] as String));
        if (substituto) {
          _substitutos = nova;
        } else {
          _professores = nova;
        }
      }
      setState(() => substituto ? _subSel = res : _profSel = res);
    }
  }

  Future<void> _salvar() async {
    if (_profSel == null) return _toast('Selecione o professor afastado.');
    if (_inicio == null || _fim == null) return _toast('Informe início e fim.');
    if (_fim!.isBefore(_inicio!)) return _toast('A data fim não pode ser antes do início.');
    if (_turnos.isEmpty) return _toast('Selecione ao menos um turno.');

    if (_subSel != null) {
      final conflitos = await _conflitosDeCobertura();
      if (!mounted) return;
      if (conflitos.isNotEmpty && await _confirmarConflito(conflitos) != true) {
        return;
      }
    }

    setState(() => _salvando = true);
    try {
      String? path = _arquivoExistente;
      if (_novoArquivo != null && _novoArquivo!.bytes != null) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final safe = _novoArquivo!.name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
        final novo = '$ts-$safe';
        await supabase.storage.from(atestadosBucket).uploadBinary(
            novo, _novoArquivo!.bytes!,
            fileOptions: const FileOptions(upsert: false));
        if (_arquivoExistente != null) {
          try { await supabase.storage.from(atestadosBucket).remove([_arquivoExistente!]); } catch (_) {}
        }
        path = novo;
      } else if (_removerArquivo && _arquivoExistente != null) {
        try { await supabase.storage.from(atestadosBucket).remove([_arquivoExistente!]); } catch (_) {}
        path = null;
      }

      final payload = {
        'professor_id': _profSel!['id'],
        'substituto_id': _subSel?['id'],
        'data_inicio': _inicio!.toIso8601String().substring(0, 10),
        'data_fim': _fim!.toIso8601String().substring(0, 10),
        'turno': _turnos.toList(),
        'observacoes': _observacoes.text.trim(),
        'arquivo_path': path,
      };
      if (_editando) {
        await supabase.from('atestados').update(payload).eq('id', widget.atestado!['id']);
      } else {
        await supabase.from('atestados').insert(
            {...payload, 'criado_por': supabase.auth.currentUser?.email});
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _toast('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  /// Procura coberturas do substituto selecionado que se sobreponham em
  /// período E turno ao atestado atual.
  Future<List<String>> _conflitosDeCobertura() async {
    try {
      final ini = _inicio!.toIso8601String().substring(0, 10);
      final fim = _fim!.toIso8601String().substring(0, 10);
      final rows = await supabase
          .from('atestados')
          .select('id, data_inicio, data_fim, turno, '
              'professor:professores!atestados_professor_id_fkey(nome)')
          .eq('substituto_id', _subSel!['id'])
          .lte('data_inicio', fim)
          .gte('data_fim', ini);
      final out = <String>[];
      for (final r in rows) {
        if (_editando && r['id'] == widget.atestado!['id']) continue;
        final inter = turnosOf(r['turno']).toSet().intersection(_turnos);
        if (inter.isEmpty) continue;
        final prof = (r['professor']?['nome'] ?? '—').toString();
        final di = DateTime.parse(r['data_inicio']);
        final df = DateTime.parse(r['data_fim']);
        out.add('$prof — ${inter.map(turnoLabel).join(', ')} '
            '(${dateFmt.format(di)} a ${dateFmt.format(df)})');
      }
      return out;
    } catch (_) {
      return []; // se a checagem falhar, não bloqueia o salvamento
    }
  }

  Future<bool?> _confirmarConflito(List<String> conflitos) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Conflito de cobertura',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_subSel!['nome']} já está cobrindo no mesmo turno e período:',
                style: bodyMuted()),
            const SizedBox(height: 12),
            for (final c in conflitos)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: AppColors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(c,
                          style: const TextStyle(
                              fontSize: 13.5, color: AppColors.text)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.amber),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar mesmo assim'),
          ),
        ],
      ),
    );
  }

  void _toast(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    return Subpage(
      title: _editando ? 'Editar atestado' : 'Novo atestado',
      maxWidth: 620,
      child: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionLabel('Professor afastado'),
                        const SizedBox(height: 10),
                        _SeletorPessoa(
                          pessoa: _profSel,
                          placeholder: 'Selecionar professor',
                          onTap: () => _pickPessoa(false),
                          onClear: () => setState(() => _profSel = null),
                        ),
                        const SizedBox(height: 22),
                        const SectionLabel('Período do afastamento'),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _dataBtn('Início', _inicio, true)),
                          const SizedBox(width: 12),
                          Expanded(child: _dataBtn('Fim', _fim, false)),
                        ]),
                        const SizedBox(height: 14),
                        Text('Turnos', style: _lbl()),
                        const SizedBox(height: 4),
                        Text('Selecione um ou mais', style: bodyMuted()),
                        const SizedBox(height: 8),
                        _seletorTurnos(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionLabel('Cobertura'),
                        const SizedBox(height: 10),
                        _SeletorPessoa(
                          pessoa: _subSel,
                          placeholder: 'Selecionar substituto (opcional)',
                          onTap: () => _pickPessoa(true),
                          onClear: () => setState(() => _subSel = null),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionLabel('Detalhes'),
                        const SizedBox(height: 12),
                        Text('Observações', style: _lbl()),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _observacoes,
                          maxLines: 3,
                          decoration: const InputDecoration(
                              hintText: 'Notas adicionais (opcional)'),
                        ),
                        const SizedBox(height: 16),
                        Text('Anexo do atestado', style: _lbl()),
                        const SizedBox(height: 8),
                        _anexo(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _salvando ? null : _salvar,
                    child: _salvando
                        ? const _BtnSpinner()
                        : Text(_editando ? 'Salvar alterações' : 'Salvar atestado'),
                  ),
                ],
              ),
            ),
    );
  }

  TextStyle _lbl() =>
      const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text);

  Widget _dataBtn(String label, DateTime? d, bool inicio) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _pickData(inicio),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(d == null ? 'Selecionar' : dateFmt.format(d),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: d == null ? AppColors.textFaint : AppColors.text)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _seletorTurnos() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kTurnos.entries.map((e) {
        final sel = _turnos.contains(e.key);
        return GestureDetector(
          onTap: () => setState(() {
            if (sel) {
              _turnos.remove(e.key);
            } else {
              _turnos.add(e.key);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? AppColors.navy : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? AppColors.navy : AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(turnoIcon(e.key),
                    size: 16, color: sel ? Colors.white : AppColors.textMuted),
                const SizedBox(width: 7),
                Text(e.value,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : AppColors.text)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _anexo() {
    if (_novoArquivo != null) {
      return _anexoLinha(_novoArquivo!.name, 'Novo arquivo selecionado', [
        _miniBtn(Icons.close, 'Desfazer', () => setState(() => _novoArquivo = null)),
      ]);
    }
    if (_arquivoExistente != null && !_removerArquivo) {
      return _anexoLinha(_nomeAmigavel(_arquivoExistente!), 'Anexo atual', [
        _miniBtn(Icons.sync, 'Trocar', _pickArquivo),
        _miniBtn(Icons.delete_outline, 'Remover', () {
          setState(() {
            _novoArquivo = null;
            _removerArquivo = true;
          });
        }, danger: true),
      ]);
    }
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _pickArquivo,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.navySoft.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.borderStrong,
              style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_outlined, color: AppColors.navy, size: 26),
            const SizedBox(height: 8),
            const Text('Anexar atestado',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            const SizedBox(height: 2),
            Text('PDF, JPG ou PNG', style: bodyMuted()),
          ],
        ),
      ),
    );
  }

  Widget _anexoLinha(String nome, String sub, List<Widget> acoes) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: AppColors.navy, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(nome,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text(sub, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
          ...acoes,
        ],
      ),
    );
  }

  Widget _miniBtn(IconData i, String t, VoidCallback onTap, {bool danger = false}) {
    final c = danger ? AppColors.danger : AppColors.navy;
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: c, padding: const EdgeInsets.symmetric(horizontal: 8)),
      icon: Icon(i, size: 16),
      label: Text(t, style: const TextStyle(fontSize: 12.5)),
      onPressed: onTap,
    );
  }

  String _nomeAmigavel(String path) {
    final idx = path.indexOf('-');
    return idx > 0 && idx < path.length - 1 ? path.substring(idx + 1) : path;
  }
}

class _SeletorPessoa extends StatelessWidget {
  final Map<String, dynamic>? pessoa;
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _SeletorPessoa({
    required this.pessoa,
    required this.placeholder,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (pessoa == null)
              const Icon(Icons.person_search_outlined, color: AppColors.textMuted, size: 22)
            else
              PersonAvatar(pessoa!['nome'], size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: pessoa == null
                  ? Text(placeholder,
                      style: const TextStyle(color: AppColors.textFaint, fontSize: 14))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(pessoa!['nome'],
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text((pessoa!['area'] ?? '').toString(),
                            style: bodyMuted()),
                      ],
                    ),
            ),
            if (pessoa != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.textFaint),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// PICKERS / DIÁLOGOS DE PESSOA
// ===========================================================================
class Cobertura {
  final String professor;
  final DateTime fim;
  final List<String> turnos;
  Cobertura(this.professor, this.fim, this.turnos);
}

class _PessoaPicker extends StatefulWidget {
  final String titulo;
  final List<Map<String, dynamic>> pessoas;
  final Map<String, Cobertura>? coberturas;
  final String tabela;
  const _PessoaPicker({
    required this.titulo,
    required this.pessoas,
    required this.tabela,
    this.coberturas,
  });
  @override
  State<_PessoaPicker> createState() => _PessoaPickerState();
}

class _PessoaPickerState extends State<_PessoaPicker> {
  String _busca = '';
  String get _singular => widget.tabela == 'substitutos' ? 'substituto' : 'professor';

  Future<void> _novo() async {
    final novo = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _NovaPessoa(nomeInicial: _busca.trim(), tabela: widget.tabela),
    );
    if (novo != null && mounted) Navigator.of(context).pop(novo);
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = widget.pessoas.where((p) {
      if (_busca.isEmpty) return true;
      final q = _busca.toLowerCase();
      return (p['nome'] ?? '').toString().toLowerCase().contains(q) ||
          (p['area'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.titulo, style: title()),
              const SizedBox(height: 14),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 20),
                  hintText: 'Buscar por nome ou área…',
                ),
                onChanged: (v) => setState(() => _busca = v),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtrados.isEmpty
                    ? EmptyState(
                        icon: Icons.person_off_outlined,
                        title: _busca.isEmpty
                            ? 'Nenhum $_singular cadastrado'
                            : 'Nada encontrado',
                        subtitle: 'Use o botão abaixo para adicionar.',
                      )
                    : ListView.separated(
                        itemCount: filtrados.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final p = filtrados[i];
                          final cob = widget.coberturas?[p['id']];
                          return _PickerItem(pessoa: p, cobertura: cob,
                              onTap: () => Navigator.of(context).pop(p));
                        },
                      ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: Text(_busca.trim().isEmpty
                      ? 'Cadastrar novo'
                      : 'Cadastrar "${_busca.trim()}"'),
                  onPressed: _novo,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerItem extends StatelessWidget {
  final Map<String, dynamic> pessoa;
  final Cobertura? cobertura;
  final VoidCallback onTap;
  const _PickerItem({required this.pessoa, required this.onTap, this.cobertura});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppColors.navySoft.withValues(alpha: 0.5),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              PersonAvatar(pessoa['nome'], size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pessoa['nome'],
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text((pessoa['area'] ?? '').toString(), style: bodyMuted()),
                    if (cobertura != null) ...[
                      const SizedBox(height: 6),
                      MetaPill(
                        Icons.info_outline,
                        'Cobrindo ${cobertura!.professor}${cobertura!.turnos.isEmpty ? '' : ' (${cobertura!.turnos.map(turnoLabel).join(', ')})'} até ${dateFmt.format(cobertura!.fim)}',
                        color: AppColors.amber,
                        bg: AppColors.amberSoft,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NovaPessoa extends StatefulWidget {
  final String nomeInicial;
  final String tabela;
  const _NovaPessoa({required this.nomeInicial, required this.tabela});
  @override
  State<_NovaPessoa> createState() => _NovaPessoaState();
}

class _NovaPessoaState extends State<_NovaPessoa> {
  late final _nome = TextEditingController(text: widget.nomeInicial);
  final _area = TextEditingController();
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _area.dispose();
    super.dispose();
  }
  String get _singular => widget.tabela == 'substitutos' ? 'substituto' : 'professor';

  Future<void> _salvar() async {
    final nome = _nome.text.trim();
    final area = _area.text.trim();
    if (nome.isEmpty || area.isEmpty) {
      setState(() => _erro = 'Preencha nome e área.'); return;
    }
    setState(() { _salvando = true; _erro = null; });
    try {
      final inserido = await supabase
          .from(widget.tabela)
          .insert({'nome': nome, 'area': area})
          .select()
          .single();
      if (mounted) Navigator.of(context).pop(inserido);
    } catch (e) {
      setState(() => _erro = e.toString().contains('duplicate')
          ? 'Já existe um $_singular com esse nome.'
          : 'Erro ao salvar.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PessoaForm(
      titulo: 'Cadastrar $_singular',
      subtitulo: 'Será adicionado ao banco e poderá ser reutilizado.',
      nome: _nome,
      area: _area,
      erro: _erro,
      salvando: _salvando,
      onSalvar: _salvar,
      autofocusArea: widget.nomeInicial.isNotEmpty,
    );
  }
}

class _EditarPessoa extends StatefulWidget {
  final Map<String, dynamic> pessoa;
  final String tabela;
  final String singular;
  const _EditarPessoa({required this.pessoa, required this.tabela, required this.singular});
  @override
  State<_EditarPessoa> createState() => _EditarPessoaState();
}

class _EditarPessoaState extends State<_EditarPessoa> {
  late final _nome = TextEditingController(text: widget.pessoa['nome']);
  late final _area = TextEditingController(text: widget.pessoa['area']);
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nome.text.trim();
    final area = _area.text.trim();
    if (nome.isEmpty || area.isEmpty) {
      setState(() => _erro = 'Preencha nome e área.'); return;
    }
    setState(() { _salvando = true; _erro = null; });
    try {
      await supabase.from(widget.tabela)
          .update({'nome': nome, 'area': area}).eq('id', widget.pessoa['id']);
      if (mounted) Navigator.of(context).pop('salvo');
    } catch (e) {
      setState(() => _erro = 'Erro ao salvar.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        titulo: 'Excluir do banco?',
        mensagem:
            'Só é possível se não houver atestados ligados a esse ${widget.singular}.',
        confirmar: 'Excluir',
      ),
    );
    if (ok != true) return;
    try {
      await supabase.from(widget.tabela).delete().eq('id', widget.pessoa['id']);
      if (mounted) Navigator.of(context).pop('excluido');
    } catch (e) {
      setState(() => _erro = e.toString().contains('foreign')
          ? 'Não dá pra excluir: há atestados ligados a esse ${widget.singular}.'
          : 'Erro ao excluir.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PessoaForm(
      titulo: 'Editar ${widget.singular}',
      nome: _nome,
      area: _area,
      erro: _erro,
      salvando: _salvando,
      onSalvar: _salvar,
      onExcluir: _excluir,
    );
  }
}

/// Form compartilhado entre cadastrar e editar pessoa.
class _PessoaForm extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final TextEditingController nome;
  final TextEditingController area;
  final String? erro;
  final bool salvando;
  final VoidCallback onSalvar;
  final VoidCallback? onExcluir;
  final bool autofocusArea;
  const _PessoaForm({
    required this.titulo,
    this.subtitulo,
    required this.nome,
    required this.area,
    required this.erro,
    required this.salvando,
    required this.onSalvar,
    this.onExcluir,
    this.autofocusArea = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(titulo, style: title()),
              if (subtitulo != null) ...[
                const SizedBox(height: 6),
                Text(subtitulo!, style: bodyMuted()),
              ],
              const SizedBox(height: 20),
              _Campo(
                label: 'Nome completo',
                child: TextField(
                  controller: nome,
                  autofocus: !autofocusArea,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Ex.: Flávio Souza'),
                ),
              ),
              const SizedBox(height: 14),
              _Campo(
                label: 'Disciplina / área',
                child: TextField(
                  controller: area,
                  autofocus: autofocusArea,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      hintText: 'Ex.: Física, Pedagogia, Matemática'),
                  onSubmitted: (_) => onSalvar(),
                ),
              ),
              if (erro != null) ...[const SizedBox(height: 14), _ErroBox(erro!)],
              const SizedBox(height: 22),
              Row(children: [
                if (onExcluir != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Excluir'),
                    onPressed: onExcluir,
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: salvando ? null : onSalvar,
                  child: salvando ? const _BtnSpinner() : const Text('Salvar'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// BANCO DE PESSOAS
// ===========================================================================
class BancoView extends StatefulWidget {
  final String tabela;
  final String titulo;
  final String subtitulo;
  final String singular;
  const BancoView({
    super.key,
    required this.tabela,
    required this.titulo,
    required this.subtitulo,
    required this.singular,
  });
  @override
  State<BancoView> createState() => _BancoViewState();
}

class _BancoViewState extends State<BancoView> {
  late Future<List<Map<String, dynamic>>> _futuro;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _futuro = _carregar();
  }

  Future<List<Map<String, dynamic>>> _carregar() async {
    final res = await supabase.from(widget.tabela).select().order('nome');
    return List<Map<String, dynamic>>.from(res);
  }

  void _recarregar() => setState(() => _futuro = _carregar());

  Future<void> _adicionar() async {
    final novo = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _NovaPessoa(nomeInicial: '', tabela: widget.tabela),
    );
    if (novo != null) _recarregar();
  }

  Future<void> _editar(Map<String, dynamic> p) async {
    final r = await showDialog<String>(
      context: context,
      builder: (_) => _EditarPessoa(
          pessoa: p, tabela: widget.tabela, singular: widget.singular),
    );
    if (r == 'salvo' || r == 'excluido') _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return ContentArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              widget.titulo,
              subtitle: widget.subtitulo,
              actions: [
                FilledButton.icon(
                  onPressed: _adicionar,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 20),
                hintText: 'Buscar por nome ou área…',
              ),
              onChanged: (v) => setState(() => _busca = v.toLowerCase()),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _futuro,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SkeletonList();
                  }
                  final lista = (snap.data ?? []).where((p) {
                    if (_busca.isEmpty) return true;
                    return (p['nome'] ?? '').toString().toLowerCase().contains(_busca) ||
                        (p['area'] ?? '').toString().toLowerCase().contains(_busca);
                  }).toList();

                  if (lista.isEmpty) {
                    return EmptyState(
                      icon: Icons.groups_outlined,
                      title: 'Nenhum ${widget.singular}',
                      subtitle: 'Adicione o primeiro para começar.',
                      action: FilledButton.icon(
                        onPressed: _adicionar,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Adicionar'),
                      ),
                    );
                  }

                  return LayoutBuilder(builder: (context, c) {
                    final cols = (c.maxWidth / 320).floor().clamp(1, 3);
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 28),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 76,
                      ),
                      itemCount: lista.length,
                      itemBuilder: (_, i) => _PessoaTile(
                          pessoa: lista[i], onTap: () => _editar(lista[i])),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PessoaTile extends StatelessWidget {
  final Map<String, dynamic> pessoa;
  final VoidCallback onTap;
  const _PessoaTile({required this.pessoa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          PersonAvatar(pessoa['nome'], size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(pessoa['nome'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text((pessoa['area'] ?? '').toString(),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: bodyMuted()),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, size: 17, color: AppColors.textFaint),
        ],
      ),
    );
  }
}

// ===========================================================================
// DETALHE
// ===========================================================================
class DetalhePage extends StatefulWidget {
  final Map<String, dynamic> atestado;
  const DetalhePage({super.key, required this.atestado});
  @override
  State<DetalhePage> createState() => _DetalhePageState();
}

class _DetalhePageState extends State<DetalhePage> {
  late Map<String, dynamic> _a = widget.atestado;
  bool _baixando = false;
  bool _mudou = false;

  Future<void> _reload() async {
    try {
      final r = await supabase
          .from('atestados')
          .select(_selectAtestado)
          .eq('id', _a['id'])
          .single();
      if (mounted) setState(() => _a = Map<String, dynamic>.from(r));
    } catch (_) {}
  }

  Future<void> _editar() async {
    final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => FormularioPage(atestado: _a)));
    if (ok == true) {
      _mudou = true;
      await _reload();
    }
  }

  Future<void> _abrirAnexo() async {
    final path = _a['arquivo_path'];
    if (path == null) return;
    setState(() => _baixando = true);
    try {
      final url = await supabase.storage.from(atestadosBucket).createSignedUrl(path, 600);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _baixando = false);
    }
  }

  Future<void> _excluir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _ConfirmDialog(
        titulo: 'Excluir atestado?',
        mensagem: 'Esta ação não pode ser desfeita. O anexo também será removido.',
        confirmar: 'Excluir',
      ),
    );
    if (ok != true) return;
    try {
      final path = _a['arquivo_path'];
      if (path != null) {
        await supabase.storage.from(atestadosBucket).remove([path]);
      }
      await supabase.from('atestados').delete().eq('id', _a['id']);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ini = DateTime.parse(_a['data_inicio']);
    final fim = DateTime.parse(_a['data_fim']);
    final dias = diasInclusivos(ini, fim);
    final status = statusOf(_a);
    final prof = _a['professor'] as Map<String, dynamic>?;
    final sub = _a['substituto'] as Map<String, dynamic>?;

    return Subpage(
      title: 'Atestado',
      maxWidth: 620,
      onPop: () => Navigator.of(context).pop(_mudou),
      actions: [
        IconButton(
          tooltip: 'Editar',
          icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.text),
          onPressed: _editar,
        ),
        IconButton(
          tooltip: 'Excluir',
          icon: const Icon(Icons.delete_outline, size: 21, color: AppColors.danger),
          onPressed: _excluir,
        ),
        const SizedBox(width: 6),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
        children: [
          AppCard(
            child: Row(
              children: [
                PersonAvatar(prof?['nome'] ?? '?', size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prof?['nome'] ?? '—', style: title()),
                      if ((prof?['area'] ?? '').toString().isNotEmpty)
                        Text(prof!['area'], style: bodyMuted()),
                    ],
                  ),
                ),
                StatusPill(status),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(
              children: [
                _linha(Icons.event_outlined, 'Início', dateFmt.format(ini)),
                const Divider(),
                _linha(Icons.event_available_outlined, 'Fim', dateFmt.format(fim)),
                const Divider(),
                _linha(Icons.timelapse_outlined, 'Duração',
                    '$dias dia${dias > 1 ? 's' : ''}'),
                const Divider(),
                _linha(turnosIcon(_a['turno']), 'Turno', turnosLabel(_a['turno'])),
                const Divider(),
                _linha(
                  Icons.diversity_3_outlined,
                  'Cobertura',
                  sub == null
                      ? 'Sem substituto'
                      : '${sub['nome']}${(sub['area'] ?? '').toString().isNotEmpty ? ' · ${sub['area']}' : ''}',
                ),
                if ((_a['observacoes'] ?? '').toString().isNotEmpty) ...[
                  const Divider(),
                  _linha(Icons.notes_outlined, 'Observações', _a['observacoes']),
                ],
                const Divider(),
                _linha(Icons.person_pin_outlined, 'Registrado por',
                    (_a['criado_por'] ?? '—').toString()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_a['arquivo_path'] != null)
            FilledButton.icon(
              onPressed: _baixando ? null : _abrirAnexo,
              icon: _baixando
                  ? const _BtnSpinner()
                  : const Icon(Icons.file_open_outlined, size: 18),
              label: const Text('Abrir anexo'),
            )
          else
            OutlinedButton.icon(
              onPressed: _editar,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('Adicionar anexo'),
            ),
        ],
      ),
    );
  }

  Widget _linha(IconData icon, String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textFaint),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(rotulo,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.text, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// COMPONENTES COMPARTILHADOS
// ===========================================================================

/// Casca de página secundária (tela cheia empilhada) com top bar limpa.
class Subpage extends StatelessWidget {
  final String title;
  final Widget child;
  final double maxWidth;
  final List<Widget> actions;
  final VoidCallback? onPop;
  const Subpage({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 640,
    this.actions = const [],
    this.onPop,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text, size: 20),
          onPressed: onPop ?? () => Navigator.of(context).pop(),
        ),
        title: Text(title, style: GoogleFontsInter.w600(16)),
        actions: actions,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final Widget child;
  const _Campo({required this.label, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool visible;
  final VoidCallback onToggle;
  final VoidCallback? onSubmit;
  final FocusNode? focusNode;
  final String hint;
  const _PasswordField({
    required this.controller,
    required this.visible,
    required this.onToggle,
    this.onSubmit,
    this.focusNode,
    this.hint = '••••••••',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !visible,
      onSubmitted: onSubmit == null ? null : (_) => onSubmit!(),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 19),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

class _ErroBox extends StatelessWidget {
  final String texto;
  const _ErroBox(this.texto);
  @override
  Widget build(BuildContext context) => _AvisoBox(
        texto: texto,
        cor: AppColors.danger,
        bg: AppColors.dangerSoft,
        icon: Icons.error_outline,
      );
}

class _InfoBox extends StatelessWidget {
  final String texto;
  const _InfoBox(this.texto);
  @override
  Widget build(BuildContext context) => _AvisoBox(
        texto: texto,
        cor: AppColors.greenDark,
        bg: AppColors.greenSoft,
        icon: Icons.check_circle_outline,
      );
}

class _AvisoBox extends StatelessWidget {
  final String texto;
  final Color cor;
  final Color bg;
  final IconData icon;
  const _AvisoBox({required this.texto, required this.cor, required this.bg, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto, style: TextStyle(color: cor, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String titulo;
  final String mensagem;
  final String confirmar;
  const _ConfirmDialog({
    required this.titulo,
    required this.mensagem,
    required this.confirmar,
  });
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titulo, style: GoogleFontsInter.w700(17)),
      content: Text(mensagem, style: bodyMuted()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmar),
        ),
      ],
    );
  }
}

class _BtnSpinner extends StatelessWidget {
  const _BtnSpinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
      height: 18, width: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
}

/// Atalhos tipográficos com Inter (evita repetição).
class GoogleFontsInter {
  static TextStyle w600(double size) =>
      TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: AppColors.text);
  static TextStyle w700(double size) => TextStyle(
      fontSize: size, fontWeight: FontWeight.w700, color: AppColors.text, letterSpacing: -0.2);
  static TextStyle w800(double size) => TextStyle(
      fontSize: size, fontWeight: FontWeight.w800, color: AppColors.text, letterSpacing: -0.4);
}

String _traduz(String msg) {
  final m = msg.toLowerCase();
  if (m.contains('invalid login') || m.contains('invalid credentials')) {
    return 'E-mail ou senha incorretos.';
  }
  if (m.contains('already registered') || m.contains('already been registered')) {
    return 'Este e-mail já está cadastrado.';
  }
  if (m.contains('email not confirmed')) {
    return 'Confirme seu e-mail antes de entrar.';
  }
  if (m.contains('email logins are disabled') || m.contains('email provider')) {
    return 'Login por e-mail está desativado no Supabase (ative o provider de Email).';
  }
  if (m.contains('signups not allowed') || m.contains('signup is disabled')) {
    return 'Cadastro desativado no Supabase.';
  }
  return msg;
}
