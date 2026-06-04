import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'theme.dart';

final dateFmt = DateFormat('dd/MM/yyyy');
const _meses = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez'
];

String dataCurta(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${_meses[d.month - 1]}';

DateTime hojeData() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

int diasInclusivos(DateTime ini, DateTime fim) => fim.difference(ini).inDays + 1;

const Map<String, String> kTurnos = {
  'manha': 'Manhã',
  'tarde': 'Tarde',
  'noite': 'Noite',
  'integral': 'Integral',
};
String turnoLabel(String? t) => kTurnos[t] ?? 'Integral';

IconData turnoIcon(String? t) {
  switch (t) {
    case 'manha':
      return Icons.wb_twilight;
    case 'tarde':
      return Icons.wb_sunny_outlined;
    case 'noite':
      return Icons.nightlight_outlined;
    default:
      return Icons.schedule_outlined;
  }
}

String statusOf(Map<String, dynamic> a) {
  final ini = DateTime.parse(a['data_inicio']);
  final fim = DateTime.parse(a['data_fim']);
  final h = hojeData();
  if (h.isBefore(ini)) return 'futuro';
  if (h.isAfter(fim)) return 'encerrado';
  return 'ativo';
}

class StatusInfo {
  final String label;
  final Color fg;
  final Color bg;
  final Color dot;
  const StatusInfo(this.label, this.fg, this.bg, this.dot);
}

StatusInfo statusInfo(String s) {
  switch (s) {
    case 'ativo':
      return const StatusInfo('Ativo', AppColors.greenDark, AppColors.greenSoft, AppColors.green);
    case 'futuro':
      return const StatusInfo('Programado', AppColors.navy, AppColors.navySoft, AppColors.navy);
    default:
      return const StatusInfo('Encerrado', AppColors.textMuted, Color(0xFFEEF1F6), AppColors.textFaint);
  }
}

String iniciais(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
  return (partes.first.substring(0, 1) + partes.last.substring(0, 1)).toUpperCase();
}

const _avatarPalette = [
  Color(0xFF15396B),
  Color(0xFF1E7A4D),
  Color(0xFF8A5A1E),
  Color(0xFF4A4F7A),
  Color(0xFF843E5C),
  Color(0xFF2B6E8A),
];
Color avatarColor(String nome) =>
    _avatarPalette[nome.hashCode.abs() % _avatarPalette.length];

// ===========================================================================
// WIDGETS REUTILIZÁVEIS
// ===========================================================================

class PersonAvatar extends StatelessWidget {
  final String nome;
  final double size;
  const PersonAvatar(this.nome, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final c = avatarColor(nome);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        iniciais(nome),
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String status;
  final bool small;
  const StatusPill(this.status, {super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    final info = statusInfo(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 9 : 11, vertical: small ? 4 : 5),
      decoration: BoxDecoration(
        color: info.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: info.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(info.label,
              style: TextStyle(
                  color: info.fg,
                  fontSize: small ? 11 : 11.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final Color? bg;
  const MetaPill(this.icon, this.text, {super.key, this.color, this.bg});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg ?? const Color(0xFFF1F3F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Cartão branco com borda + sombra suave.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
      boxShadow: AppShadows.soft,
    );
    if (onTap == null) {
      return Container(
        decoration: decoration,
        padding: padding,
        child: child,
      );
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        hoverColor: AppColors.navySoft.withValues(alpha: 0.4),
        onTap: onTap,
        child: Ink(
          decoration: decoration,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: overline());
}

/// Estado vazio elegante.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.navySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 30, color: AppColors.navy),
            ),
            const SizedBox(height: 18),
            Text(title, style: sectionTitle()),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: bodyMuted()),
            ],
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Esqueleto de carregamento (pulsa suavemente).
class SkeletonList extends StatefulWidget {
  final int count;
  final double height;
  const SkeletonList({super.key, this.count = 5, this.height = 76});
  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.55, end: 1.0).animate(
          CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Column(
        children: List.generate(
          widget.count,
          (_) => Container(
            height: widget.height,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                      color: Color(0xFFEDF0F5), shape: BoxShape.circle),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 160, height: 12, color: const Color(0xFFEDF0F5)),
                    const SizedBox(height: 8),
                    Container(width: 100, height: 10, color: const Color(0xFFF1F3F8)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cabeçalho de página (título + subtítulo + ações).
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  const PageHeader(this.title, {super.key, this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: display()),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: bodyMuted()),
              ],
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}
