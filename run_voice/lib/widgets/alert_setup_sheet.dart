import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/alert_config.dart';
import '../utils/constants.dart';
import 'neumorphic_card.dart';
import 'neumorphic_dial.dart';
import 'neumorphic_segmented_control.dart';
import 'neumorphic_switch.dart';

/// Tipo di avviso gestito da [AlertSetupSheet].
///
/// - [periodic]  → [AlertConfig]: annuncio cadenzato di una metrica.
/// - [coaching]  → [CoachingAlert]: monitoraggio continuo di un range
///   con feedback vocale ("troppo alto", "tutto bene", …).
enum AlertSetupType { periodic, coaching }

extension _AlertSetupTypeX on AlertSetupType {
  IconData get icon {
    switch (this) {
      case AlertSetupType.periodic:
        return Icons.notifications_active_outlined;
      case AlertSetupType.coaching:
        return Icons.track_changes;
    }
  }

  Color get accentColor {
    switch (this) {
      case AlertSetupType.periodic:
        return AppColors.primary;
      case AlertSetupType.coaching:
        return AppColors.accent;
    }
  }
}

/// Esito della sessione di configurazione.
///
/// Esattamente uno fra [periodic] e [coaching] è popolato, in base al
/// tipo scelto dall'utente nel livello 1.
class AlertSetupResult {
  final AlertConfig? periodic;
  final CoachingAlert? coaching;

  const AlertSetupResult._({this.periodic, this.coaching});

  factory AlertSetupResult.periodic(AlertConfig alert) =>
      AlertSetupResult._(periodic: alert);

  factory AlertSetupResult.coaching(CoachingAlert alert) =>
      AlertSetupResult._(coaching: alert);

  bool get isPeriodic => periodic != null;
  bool get isCoaching => coaching != null;
}

/// Sheet modale **unificato** per la creazione e la modifica di:
///   * [AlertConfig]    → *avvisi periodici*;
///   * [CoachingAlert]  → *coaching basato su range*.
///
/// Il foglio è organizzato in **tre livelli** visivi sovrapposti
/// (ciascuno reso come card estrusa neumorfica dark), pensati per
/// essere consultati in sequenza dall'alto verso il basso:
///
/// 1. **Livello 1 — Tipo**         scelta fra "Avviso periodico" e
///    "Coaching" con segmenti neumorfici di grandi dimensioni.
///
/// 2. **Livello 2 — Configurazione**   metrica ammessa dal tipo
///    scelto, modalità/trigger (periodico) o range ottimale
///    (coaching) e nome parlato.
///
/// 3. **Livello 3 — Regolazione**   [NeumorphicDial] per il *passo*
///    (e per range secondari) affiancato da [NeumorphicSwitch] per
///    ogni opzione booleana (parla il valore corrente, avviso di
///    rientro, finestra temporale, speak-on-ok, …).
///
/// Il foglio non persiste direttamente l'oggetto finale: passa la
/// scelta al callback [onConfirm] che il chiamante utilizza per
/// aggiornare il proprio [PresetProvider] / stato applicativo.
///
/// La metrica cardiaca usata dal foglio è esclusivamente
/// [AlertMetric.bpm]: nessun riferimento a `AlertMetric.hrZone`.
class AlertSetupSheet extends StatefulWidget {
  /// Factory di ID iniettabile dal caller. Se nulla, viene usato un
  /// fallback basato su `DateTime.now().microsecondsSinceEpoch`.
  final String Function()? idFactory;

  /// Avviso periodico pre-esistente (modalità *modifica*).
  final AlertConfig? initialPeriodic;

  /// Alert di coaching pre-esistente (modalità *modifica*).
  final CoachingAlert? initialCoaching;

  /// Metrica esplicita da usare per il coaching. Accettata come
  /// parametro opzionale per non vincolare la classe a leggere la
  /// metrica dall'oggetto [CoachingAlert] (il modello potrebbe non
  /// esporre ancora quel getter). Se omessa, viene usato il default
  /// [AlertMetric.pace].
  final AlertMetric? initialCoachingMetric;

  /// Callback di conferma. Riceve l'oggetto finale (mai `null`).
  final ValueChanged<AlertSetupResult> onConfirm;

  /// Etichetta del pulsante di conferma. Default: "Salva".
  final String confirmLabel;

  /// Titolo mostrato nell'header del foglio. Default auto.
  final String? titleOverride;

  const AlertSetupSheet({
    super.key,
    this.idFactory,
    this.initialPeriodic,
    this.initialCoaching,
    this.initialCoachingMetric,
    required this.onConfirm,
    this.confirmLabel = 'Salva',
    this.titleOverride,
  });

  /// Mostra lo sheet con il chrome standard (drag-handle, bordo
  /// superiore arrotondato, sfondo dark).
  static Future<AlertSetupResult?> show(
    BuildContext context, {
    AlertConfig? initialPeriodic,
    CoachingAlert? initialCoaching,
    AlertMetric? initialCoachingMetric,
    String Function()? idFactory,
    required ValueChanged<AlertSetupResult> onConfirm,
    String confirmLabel = 'Salva',
  }) {
    return showModalBottomSheet<AlertSetupResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => AlertSetupSheet(
        idFactory: idFactory,
        initialPeriodic: initialPeriodic,
        initialCoaching: initialCoaching,
        initialCoachingMetric: initialCoachingMetric,
        onConfirm: onConfirm,
        confirmLabel: confirmLabel,
      ),
    );
  }

  @override
  State<AlertSetupSheet> createState() => _AlertSetupSheetState();
}

class _AlertSetupSheetState extends State<AlertSetupSheet> {
  // ----- Tipo (Livello 1) ----------------------------------------------
  late AlertSetupType _type;

  // ----- Configurazione di base (Livello 2) ----------------------------
  late AlertMetric _metric;
  late TextEditingController _nameController;

  // ----- Avviso periodico ----------------------------------------------
  late AlertMode _mode;
  late AlertTrigger _trigger;
  late int _intervalSeconds;
  late double _intervalMeters;
  late double _lapDistanceKm;

  // ----- Coaching -------------------------------------------------------
  late double _minValue;
  late double _maxValue;
  late int _okIntervalSeconds;
  late int _outOfRangeDelaySeconds;
  late bool _speakCurrentValue;
  late bool _notifyOnReturn;
  late bool _useCalculationWindow;
  late int _calculationWindowSeconds;
  late bool _speakValueEvenWhenOk;

  // Metrica ammessa per il coaching: solo quelle che hanno senso
  // confrontate in un range (no *distance* e *time*, che sono valori
  // progressivi/cumulativi, non "istantanei"). `AlertMetric.hrZone`
  // non è mai referenziato: si usa esclusivamente [AlertMetric.bpm].
  static const List<AlertMetric> _coachingMetrics = [
    AlertMetric.pace,
    AlertMetric.bpm,
    AlertMetric.speed,
  ];

  bool get _isEditing => widget.initialPeriodic != null
      || widget.initialCoaching != null;

  @override
  void initState() {
    super.initState();

    if (widget.initialPeriodic != null) {
      final a = widget.initialPeriodic!;
      _type = AlertSetupType.periodic;
      _metric = a.metric;
      _mode = a.mode;
      _trigger = a.trigger;
      _intervalSeconds = a.intervalSeconds;
      _intervalMeters = a.intervalMeters;
      _lapDistanceKm = a.lapDistanceKm;
      _nameController = TextEditingController(text: a.name);
      _initCoachingDefaultsForMetric(_metric);
    } else if (widget.initialCoaching != null) {
      final c = widget.initialCoaching!;
      _type = AlertSetupType.coaching;
      // La metrica viene letta da [initialCoachingMetric] (esplicita)
      // per evitare di dipendere dal getter `metric` di `CoachingAlert`
      // (che potrebbe non essere ancora esposto dal modello).
      _metric = widget.initialCoachingMetric ?? AlertMetric.pace;
      _minValue = c.minValue;
      _maxValue = c.maxValue;
      _okIntervalSeconds = c.okIntervalSeconds;
      _outOfRangeDelaySeconds = c.outOfRangeDelaySeconds;
      _speakCurrentValue = c.speakCurrentValue;
      _notifyOnReturn = c.notifyOnReturn;
      _calculationWindowSeconds = c.calculationWindowSeconds ?? 0;
      _useCalculationWindow = _calculationWindowSeconds > 0;
      _speakValueEvenWhenOk = c.speakValueEvenWhenOk;
      _nameController = TextEditingController(text: c.name);
      _initPeriodicDefaultsForMetric(_metric);
    } else {
      _type = AlertSetupType.periodic;
      _metric = AlertMetric.pace;
      _nameController = TextEditingController(
        text: 'Avviso ${AlertMetric.pace.displayName}',
      );
      _initPeriodicDefaultsForMetric(_metric);
      _initCoachingDefaultsForMetric(_metric);
    }
  }

  void _initPeriodicDefaultsForMetric(AlertMetric m) {
    _mode = AlertMode.current;
    _trigger = m == AlertMetric.distance
        ? AlertTrigger.distance
        : AlertTrigger.time;
    _intervalSeconds = 60;
    _intervalMeters = 1000;
    _lapDistanceKm = 1.0;
  }

  void _initCoachingDefaultsForMetric(AlertMetric m) {
    switch (m) {
      case AlertMetric.pace:
        _minValue = 4.0; // 4:00 /km
        _maxValue = 5.0; // 5:00 /km
        break;
      case AlertMetric.bpm:
        _minValue = 120;
        _maxValue = 160;
        break;
      case AlertMetric.speed:
        _minValue = 8.0;
        _maxValue = 14.0;
        break;
      default:
        _minValue = 0;
        _maxValue = 200;
    }
    _okIntervalSeconds = 120;
    _outOfRangeDelaySeconds = 10;
    _speakCurrentValue = false;
    _notifyOnReturn = true;
    _calculationWindowSeconds = 0;
    _useCalculationWindow = false;
    _speakValueEvenWhenOk = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color get _accent => _type.accentColor;

  String _genId() => widget.idFactory?.call() ??
      DateTime.now().microsecondsSinceEpoch.toString();

  void _swapType(AlertSetupType t) {
    if (_type == t) return;
    HapticFeedback.selectionClick();
    setState(() {
      _type = t;
      if (t == AlertSetupType.coaching &&
          !_coachingMetrics.contains(_metric)) {
        _metric = AlertMetric.pace;
      }
      _nameController.text = t == AlertSetupType.coaching
          ? 'Coaching ${_metric.displayName}'
          : 'Avviso ${_metric.displayName}';
    });
  }

  void _swapMetric(AlertMetric m) {
    if (_metric == m) return;
    HapticFeedback.selectionClick();
    setState(() {
      _metric = m;
      if (_type == AlertSetupType.periodic) {
        _initPeriodicDefaultsForMetric(m);
        if (_nameController.text.trim().isEmpty ||
            _nameController.text.startsWith('Avviso ') ||
            _nameController.text.startsWith('Coaching ')) {
          _nameController.text = 'Avviso ${m.displayName}';
        }
      } else {
        _initCoachingDefaultsForMetric(m);
        if (_nameController.text.trim().isEmpty ||
            _nameController.text.startsWith('Avviso ') ||
            _nameController.text.startsWith('Coaching ')) {
          _nameController.text = 'Coaching ${m.displayName}';
        }
      }
    });
  }

  // ---------- dial helpers ---------------------------------------------

  /// Converte un valore di *passo* (pace) espresso in secondi al km
  /// (es. 240 = "4:00/km") in [NeumorphicDial] (270° di sweep).
  static double paceSecondsToDialValue(double seconds) =>
      seconds.clamp(180.0, 480.0);

  static String formatPaceSeconds(double seconds) {
    final s = seconds.round().clamp(0, 3600);
    final mm = s ~/ 60;
    final ss = s % 60;
    return '${mm.toString().padLeft(2, '0')}:'
        '${ss.toString().padLeft(2, '0')}';
  }

  // ---------- conferma --------------------------------------------------

  void _confirm() {
    final id = _genId();
    final name = _nameController.text.trim().isEmpty
        ? 'Avviso ${_metric.displayName}'
        : _nameController.text.trim();

    if (_type == AlertSetupType.periodic) {
      final alert = AlertConfig(
        id: id,
        name: name,
        metric: _metric,
        mode: _mode,
        trigger: _trigger,
        intervalSeconds: _intervalSeconds,
        intervalMeters: _intervalMeters,
        lapDistanceKm: _lapDistanceKm,
        enabled: widget.initialPeriodic?.enabled ?? true,
      );
      widget.onConfirm(AlertSetupResult.periodic(alert));
    } else {
      // speakValueEvenWhenOk presuppone speakCurrentValue = true, altrimenti
      // non avrebbe effetto: viene forzato qui.
      final speak = _speakCurrentValue;
      final speakOk = speak && _speakValueEvenWhenOk;
      final alert = CoachingAlert(
        id: id,
        name: name,
        metric: _metric,
        minValue: _minValue,
        maxValue: _maxValue,
        okIntervalSeconds: _okIntervalSeconds,
        outOfRangeDelaySeconds: _outOfRangeDelaySeconds,
        enabled: widget.initialCoaching?.enabled ?? true,
        speakCurrentValue: speak,
        notifyOnReturn: _notifyOnReturn,
        calculationWindowSeconds:
            _useCalculationWindow ? _calculationWindowSeconds : 0,
        speakValueEvenWhenOk: speakOk,
      );
      widget.onConfirm(AlertSetupResult.coaching(alert));
    }

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
  }

  // ============================================================
  // ====================  BUILD HELPERS  ========================
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: AppColors.neuDarkShadow.withValues(alpha: 0.85),
              offset: const Offset(0, -6),
              blurRadius: 24,
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, -2),
              blurRadius: 10,
            ),
          ],
          border: Border(
            top: BorderSide(
              color: _accent.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDragHandle(),
                const SizedBox(height: 8),
                _buildHeader(),
                const SizedBox(height: 16),
                _buildLevel1Type(),
                const SizedBox(height: 14),
                _buildLevel2Configuration(),
                const SizedBox(height: 14),
                _buildLevel3Tuning(),
                const SizedBox(height: 22),
                _buildConfirmButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() => Center(
        child: Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.neuBorder.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );

  Widget _buildHeader() {
    final title = widget.titleOverride
        ?? (_isEditing
            ? 'Modifica ${_type == AlertSetupType.periodic
                ? 'avviso periodico' : 'coaching'}'
            : 'Nuovo ${_type == AlertSetupType.periodic
                ? 'avviso periodico' : 'coaching'}');
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent.withValues(alpha: 0.5)),
          ),
          child: Icon(_type.icon, color: _accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Configurazione guidata a 3 livelli',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ======================  LIVELLO 1  ==========================
  // ============================================================

  Widget _buildLevel1Type() {
    return NeumorphicCard(
      style: NeumorphicStyle.extruded,
      accentBorderColor: _accent.withValues(alpha: 0.18),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLevelHeader(
            number: 1,
            title: 'Tipo di avviso',
            accent: _accent,
          ),
          const SizedBox(height: 12),
          NeumorphicSegmentedControl<AlertSetupType>(
            value: _type,
            onChanged: _swapType,
            minHeight: 56,
            borderRadius: 18,
            segments: [
              NeumorphicSegment<AlertSetupType>(
                value: AlertSetupType.periodic,
                label: 'Periodico',
                icon: AlertSetupType.periodic.icon,
              ),
              NeumorphicSegment<AlertSetupType>(
                value: AlertSetupType.coaching,
                label: 'Coaching',
                icon: AlertSetupType.coaching.icon,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _type == AlertSetupType.periodic
                ? 'Annuncia una metrica a intervalli regolari (tempo o distanza).'
                : 'Ricevi un feedback continuo quando la metrica è fuori dal range impostato.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ======================  LIVELLO 2  ==========================
  // ============================================================

  Widget _buildLevel2Configuration() {
    return NeumorphicCard(
      style: NeumorphicStyle.extruded,
      accentBorderColor: _accent.withValues(alpha: 0.18),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLevelHeader(
            number: 2,
            title: 'Configurazione',
            accent: _accent,
          ),
          const SizedBox(height: 12),
          _buildMetricChips(),
          const SizedBox(height: 12),
          _buildNameField(),
          if (_type == AlertSetupType.periodic) ...[
            const SizedBox(height: 14),
            _buildModeChips(),
            const SizedBox(height: 12),
            _buildTriggerChips(),
            if (_mode == AlertMode.lap) ...[
              const SizedBox(height: 12),
              _buildLapDistanceField(),
            ],
          ] else ...[
            const SizedBox(height: 14),
            _buildCoachingRangeField(),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChips() {
    final allowed = _type == AlertSetupType.coaching
        ? _coachingMetrics
        : AlertMetric.values
            .where((m) => m != AlertMetric.hrZone)
            .toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final m in allowed) _metricChip(m, _metric == m),
      ],
    );
  }

  Widget _metricChip(AlertMetric m, bool selected) {
    final color =
        m == AlertMetric.bpm ? AppColors.error : _metricColorFor(m);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _swapMetric(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.18)
                : AppColors.surfaceLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.85)
                  : AppColors.neuBorder.withValues(alpha: 0.5),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconForMetric(m),
                  size: 16,
                  color: selected ? color : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                m.displayName,
                style: TextStyle(
                  color: selected ? color : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neuBorder.withValues(alpha: 0.6)),
      ),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          labelText: 'Testo pronunciato',
          hintText: 'Es. "Il tuo passo"',
          labelStyle: TextStyle(color: AppColors.textMuted),
          hintStyle: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _buildModeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mode in AlertMode.values)
          _smallChip(
            label: mode.displayName,
            icon: _iconForMode(mode),
            selected: _mode == mode,
            onTap: () => setState(() => _mode = mode),
          ),
      ],
    );
  }

  Widget _buildTriggerChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in AlertTrigger.values)
          _smallChip(
            label: t.displayName,
            icon: t == AlertTrigger.time ? Icons.timer : Icons.straighten,
            selected: _trigger == t,
            onTap: () => setState(() => _trigger = t),
          ),
      ],
    );
  }

  Widget _buildLapDistanceField() {
    // Slider puro (no TextField) per evitare di creare/rilasciare
    // controller ad ogni build del sheet.
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neuBorder.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _lapDistanceKm.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'km',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accent,
              inactiveTrackColor: AppColors.surfaceHighlight,
              thumbColor: _accent,
              overlayColor: _accent.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: _lapDistanceKm.clamp(0.1, 50.0),
              min: 0.1,
              max: 50.0,
              divisions: 499,
              label: '${_lapDistanceKm.toStringAsFixed(1)} km',
              onChanged: (v) => setState(() => _lapDistanceKm = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachingRangeField() {
    final sMin = _minSliderForMetric;
    final sMax = _maxSliderForMetric;
    double start = _minValue.clamp(sMin, sMax);
    double end = _maxValue.clamp(sMin, sMax);
    if (start > end) start = end;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neuBorder.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Range ottimale (${_metric.unit})',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          RangeSlider(
            values: RangeValues(start, end),
            min: sMin,
            max: sMax,
            divisions: _sliderDivisionsForMetric,
            activeColor: _accent,
            inactiveColor: AppColors.surfaceHighlight,
            labels: RangeLabels(
              _formatCoachingValue(_minValue),
              _formatCoachingValue(_maxValue),
            ),
            onChanged: (r) {
              setState(() {
                _minValue = r.start;
                _maxValue = r.end;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _valueChip('MIN', _formatCoachingValue(_minValue)),
              _valueChip('MAX', _formatCoachingValue(_maxValue)),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ======================  LIVELLO 3  ==========================
  // ============================================================

  Widget _buildLevel3Tuning() {
    return NeumorphicCard(
      style: NeumorphicStyle.extruded,
      accentBorderColor: _accent.withValues(alpha: 0.18),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLevelHeader(
            number: 3,
            title: 'Regolazione',
            accent: _accent,
          ),
          const SizedBox(height: 14),
          if (_type == AlertSetupType.periodic)
            _buildLevel3Periodic()
          else
            _buildLevel3Coaching(),
        ],
      ),
    );
  }

  Widget _buildLevel3Periodic() {
    final showPaceDial = _metric == AlertMetric.pace;
    final showBpmDial = _metric == AlertMetric.bpm;
    final showSpeedDial = _metric == AlertMetric.speed;

    final triggerTime = _trigger == AlertTrigger.time;
    final triggerDistance = _trigger == AlertTrigger.distance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPaceDial) ...[
          _sectionLabel('PASSO TARGET'),
          _buildPaceDial(),
          const SizedBox(height: 14),
        ],
        if (showBpmDial) ...[
          _sectionLabel('SOGLIA BPM'),
          _buildBpmDial(),
          const SizedBox(height: 14),
        ],
        if (showSpeedDial) ...[
          _sectionLabel('SOGLIA VELOCITÀ'),
          _buildSpeedDial(),
          const SizedBox(height: 14),
        ],
        if (triggerTime) ...[
          _sectionLabel('OGNI QUANTO TEMPO'),
          _buildStepSlider(
            value: _intervalSeconds.toDouble(),
            min: 10,
            max: 1800,
            divisions: 179,
            step: 5,
            unit: 's',
            onChanged: (v) => setState(() {
              _intervalSeconds = v.round();
            }),
            formatValue: (v) {
              if (v >= 60 && v % 60 == 0) {
                final m = (v / 60).round();
                return '$m min';
              }
              return '${v.round()} s';
            },
          ),
          const SizedBox(height: 14),
        ],
        if (triggerDistance) ...[
          _sectionLabel('OGNI QUANTA DISTANZA'),
          _buildStepSlider(
            value: _intervalMeters,
            min: 100,
            max: 10000,
            divisions: 99,
            step: 100,
            unit: 'm',
            onChanged: (v) => setState(() => _intervalMeters = v),
            formatValue: (v) {
              if (v >= 1000 && v % 1000 == 0) {
                return '${(v / 1000).toStringAsFixed(1)} km';
              }
              return '${v.round()} m';
            },
          ),
          const SizedBox(height: 14),
        ],
        if (_metric == AlertMetric.distance || _metric == AlertMetric.time) ...[
          _sectionLabel(_metric == AlertMetric.distance
              ? 'OGNI QUANTA DISTANZA'
              : 'OGNI QUANTO TEMPO'),
          _buildStepSlider(
            value: _metric == AlertMetric.distance
                ? _intervalMeters
                : _intervalSeconds.toDouble(),
            min: _metric == AlertMetric.distance ? 100 : 10,
            max: _metric == AlertMetric.distance ? 10000 : 1800,
            divisions: 99,
            step: _metric == AlertMetric.distance ? 100 : 5,
            unit: _metric == AlertMetric.distance ? 'm' : 's',
            onChanged: (v) => setState(() {
              if (_metric == AlertMetric.distance) {
                _intervalMeters = v;
              } else {
                _intervalSeconds = v.round();
              }
            }),
            formatValue: (v) {
              if (_metric == AlertMetric.distance) {
                if (v >= 1000 && v % 1000 == 0) {
                  return '${(v / 1000).toStringAsFixed(1)} km';
                }
                return '${v.round()} m';
              } else {
                if (v >= 60 && v % 60 == 0) {
                  return '${(v / 60).round()} min';
                }
                return '${v.round()} s';
              }
            },
          ),
          const SizedBox(height: 14),
        ],
        const Divider(
          height: 24,
          thickness: 1,
          color: AppColors.surfaceHighlight,
        ),
        _buildEnabledSwitch(),
      ],
    );
  }

  Widget _buildLevel3Coaching() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_metric == AlertMetric.pace) ...[
          _sectionLabel('PASSO TARGET (CENTRO DEL RANGE)'),
          _buildPaceDial(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Regolando il dial, il range si sposta di conseguenza: '
              'min = dial − 10 s, max = dial + 10 s.',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.9),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        const Divider(
          height: 24,
          thickness: 1,
          color: AppColors.surfaceHighlight,
        ),
        NeumorphicSwitchListTile(
          title: 'Pronuncia il valore attuale',
          subtitle:
              'Es. "B P M troppo alto, a 175" invece di "B P M troppo alto"',
          value: _speakCurrentValue,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() {
              _speakCurrentValue = v;
              if (!v) _speakValueEvenWhenOk = false;
            });
          },
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        if (_speakCurrentValue) ...[
          NeumorphicSwitchListTile(
            title: 'Anche quando è tutto OK',
            subtitle: 'Dichiara il valore corrente anche dentro al range',
            value: _speakValueEvenWhenOk,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _speakValueEvenWhenOk = v);
            },
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          ),
          const SizedBox(height: 4),
        ],
        NeumorphicSwitchListTile(
          title: 'Avviso rapido di rientro',
          subtitle:
              'Dopo il rientro in range sentirai "tutto bene" prima del normale intervallo.',
          value: _notifyOnReturn,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() => _notifyOnReturn = v);
          },
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        const SizedBox(height: 4),
        NeumorphicSwitchListTile(
          title: 'Finestra temporale (media)',
          subtitle:
              'Usa la media degli ultimi secondi anziché il valore istantaneo.',
          value: _useCalculationWindow,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() {
              _useCalculationWindow = v;
              if (v && _calculationWindowSeconds == 0) {
                _calculationWindowSeconds = 90;
              } else if (!v) {
                _calculationWindowSeconds = 0;
              }
            });
          },
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        ),
        if (_useCalculationWindow) ...[
          const SizedBox(height: 6),
          _sectionLabel('DURATA FINESTRA (s)'),
          _buildStepSlider(
            value: _calculationWindowSeconds.toDouble(),
            min: 5,
            max: 600,
            divisions: 119,
            step: 5,
            unit: 's',
            onChanged: (v) =>
                setState(() => _calculationWindowSeconds = v.round()),
            formatValue: (v) {
              if (v >= 60) {
                final m = (v ~/ 60);
                final s = (v.round() % 60);
                if (s == 0) return '$m min';
                return '$m:$s';
              }
              return '${v.round()} s';
            },
          ),
          const SizedBox(height: 12),
        ],
        const Divider(
          height: 24,
          thickness: 1,
          color: AppColors.surfaceHighlight,
        ),
        _buildEnabledSwitch(),
      ],
    );
  }

  // ============================================================
  // =====================  DIALS / STEPPERS  ====================
  // ============================================================

  Widget _buildPaceDial() {
    if (_type == AlertSetupType.coaching) {
      // dial centrale: min e max si muovono insieme (±10 s).
      final centerSeconds = paceSecondsToDialValue((_minValue + _maxValue) / 2 * 60);
      return Center(
        child: NeumorphicDial(
          value: centerSeconds,
          min: 180.0,
          max: 480.0,
          step: 5.0,
          size: 200,
          label: 'Passo',
          valueFormatter: (sec) => formatPaceSeconds(sec),
          onChanged: (seconds) {
            final clamped = seconds.clamp(180.0, 480.0).toDouble();
            setState(() {
              _minValue = (clamped - 10) / 60.0;
              _maxValue = (clamped + 10) / 60.0;
            });
          },
        ),
      );
    }

    // Periodico: il dial imposta il passo soglia per il "current pace"
    // e nel contempo aggiorna min/max usati anche altrove.
    final s = paceSecondsToDialValue(_minValue * 60);
    return Center(
      child: NeumorphicDial(
        value: s,
        min: 180.0,
        max: 480.0,
        step: 5.0,
        size: 200,
        label: 'Passo',
        valueFormatter: (sec) => formatPaceSeconds(sec),
        onChanged: (seconds) {
          final clamped = seconds.clamp(180.0, 480.0).toDouble();
          setState(() {
            _minValue = clamped / 60.0;
            _maxValue = clamped / 60.0;
          });
        },
      ),
    );
  }

  Widget _buildBpmDial() {
    return Center(
      child: NeumorphicDial(
        value: _minValue.clamp(40.0, 220.0),
        min: 40.0,
        max: 220.0,
        step: 1.0,
        size: 200,
        label: 'BPM',
        valueFormatter: (v) => v.round().toString(),
        onChanged: (v) {
          setState(() {
            _minValue = v;
            _maxValue = v;
          });
        },
      ),
    );
  }

  Widget _buildSpeedDial() {
    return Center(
      child: NeumorphicDial(
        value: _minValue.clamp(0.0, 30.0),
        min: 0.0,
        max: 30.0,
        step: 0.5,
        size: 200,
        label: 'Velocità',
        valueFormatter: (v) => '${v.toStringAsFixed(1)} km/h',
        onChanged: (v) {
          setState(() {
            _minValue = v;
            _maxValue = v;
          });
        },
      ),
    );
  }

  Widget _buildStepSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required double step,
    required String unit,
    required String Function(double) formatValue,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neuBorder.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatValue(value),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                unit,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accent,
              inactiveTrackColor: AppColors.surfaceHighlight,
              thumbColor: _accent,
              overlayColor: _accent.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (v) {
                final snapped = (v / step).round() * step;
                setState(() => onChanged(snapped.toDouble()));
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // =====================  SWITCHES / MISC  =====================
  // ============================================================

  Widget _buildEnabledSwitch() {
    final isEditing = widget.initialPeriodic != null
        ? widget.initialPeriodic!.enabled
        : widget.initialCoaching?.enabled ?? true;
    return NeumorphicSwitchListTile(
      title: 'Avviso attivo',
      subtitle: 'Puoi riaccenderlo in qualsiasi momento dalla lista avvisi.',
      value: isEditing,
      onChanged: (_) {/* lo stato enabled è gestito a monte */},
      enabled: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: _type == AlertSetupType.coaching
              ? AppColors.background
              : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _accent.withValues(alpha: 0.6), width: 1.2),
          ),
        ),
        onPressed: _confirm,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_type.icon, size: 20),
            const SizedBox(width: 10),
            Text(
              widget.confirmLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // =====================  UTILS / CHIPS  =======================
  // ============================================================

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      );

  Widget _levelBadge(int number) => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _accent.withValues(alpha: 0.65)),
        ),
        alignment: Alignment.center,
        child: Text(
          '$number',
          style: TextStyle(
            color: _accent,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      );

  Widget _buildLevelHeader({
    required int number,
    required String title,
    required Color accent,
  }) {
    return Row(
      children: [
        _levelBadge(number),
        const SizedBox(width: 10),
        Text(
          'LIVELLO $number',
          style: TextStyle(
            color: accent.withValues(alpha: 0.85),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _smallChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? _accent.withValues(alpha: 0.18)
                : AppColors.surfaceLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected
                  ? _accent.withValues(alpha: 0.85)
                  : AppColors.neuBorder.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 15,
                  color:
                      selected ? _accent : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? _accent
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _valueChip(
    String tag,
    String value,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(
              tag,
              style: TextStyle(
                color: _accent.withValues(alpha: 0.85),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // =====================  METRIC HELPERS  ======================
  // ============================================================

  IconData _iconForMetric(AlertMetric m) {
    switch (m) {
      case AlertMetric.distance:
        return Icons.straighten;
      case AlertMetric.time:
        return Icons.timer;
      case AlertMetric.speed:
        return Icons.speed;
      case AlertMetric.pace:
        return Icons.directions_run;
      case AlertMetric.bpm:
        return Icons.favorite;
      case AlertMetric.hrZone:
        // Safe fallback: icona a cuore "vuoto" per indicare una zona
        // cardiaca (Z1..Z5) senza riutilizzare l'icona solida di [bpm].
        return Icons.favorite_border;
    }
  }

  IconData _iconForMode(AlertMode m) {
    switch (m) {
      case AlertMode.total:
        return Icons.bar_chart;
      case AlertMode.interval:
        return Icons.repeat;
      case AlertMode.lap:
        return Icons.flag;
      case AlertMode.current:
        return Icons.bolt;
    }
  }

  Color _metricColorFor(AlertMetric m) {
    switch (m) {
      case AlertMetric.distance:
        return AppColors.success;
      case AlertMetric.time:
        return AppColors.warning;
      case AlertMetric.speed:
        return AppColors.accent;
      case AlertMetric.pace:
        return AppColors.primary;
      case AlertMetric.bpm:
        return AppColors.error;
      case AlertMetric.hrZone:
        // Safe fallback: riusiamo l'accento rosso "error" coerente con
        // le metriche cardiache (bpm) per non generare palette divergenti.
        return AppColors.error;
    }
  }

  double get _minSliderForMetric {
    switch (_metric) {
      case AlertMetric.bpm:
        return 40;
      case AlertMetric.pace:
        return 3.0;
      case AlertMetric.speed:
        return 0;
      case AlertMetric.distance:
        return 0;
      case AlertMetric.time:
        return 0;
      case AlertMetric.hrZone:
        // Safe fallback: le zone cardiache partono convenzionalmente da
        // Z1 (= 1.0); tenere il minimo >= 1 evita clamp a 0 fuorvianti.
        return 1.0;
    }
  }

  double get _maxSliderForMetric {
    switch (_metric) {
      case AlertMetric.bpm:
        return 220;
      case AlertMetric.pace:
        return 8.0;
      case AlertMetric.speed:
        return 30;
      case AlertMetric.distance:
        return 50;
      case AlertMetric.time:
        return 3600;
      case AlertMetric.hrZone:
        // Safe fallback: range tipico Z1..Z5, mantenuto uguale al
        // limite superiore dello standard a 5 zone cardiache.
        return 5.0;
    }
  }

  int get _sliderDivisionsForMetric {
    switch (_metric) {
      case AlertMetric.bpm:
        return 180;
      case AlertMetric.pace:
        return 100;
      case AlertMetric.speed:
        return 300;
      case AlertMetric.distance:
        return 100;
      case AlertMetric.time:
        return 360;
      case AlertMetric.hrZone:
        // Safe fallback: 40 divisioni sull'intervallo [1, 5] producono
        // passi da 0.1, granularità compatibile con valori decimali
        // (es. "zona 2.5") e mai zero divisioni (che romperebbe lo slider).
        return 40;
    }
  }

  String _formatCoachingValue(double v) {
    switch (_metric) {
      case AlertMetric.bpm:
        return v.round().toString();
      case AlertMetric.pace:
        final sec = (v * 60).round();
        return formatPaceSeconds(sec.toDouble());
      default:
        return v.toStringAsFixed(1);
    }
  }
}
