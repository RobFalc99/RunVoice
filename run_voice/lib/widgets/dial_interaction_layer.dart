import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Utility per la matematica del dial circolare (corona / knob rotante).
///
/// Tutti gli angoli sono espressi in **gradi** e vivono nel range
/// `(-180°, +180°)` prodotto da `atan2`.
class DialAngles {
  // Costruttore privato: questa classe è solo un namespace statico.
  DialAngles._();

  /// Calcola l'angolo (in gradi) che il vettore `center → localPosition`
  /// forma rispetto all'asse orizzontale positivo.
  ///
  /// Usa [`math.atan2`] per gestire correttamente tutti e quattro i
  /// quadranti (anche i casi degeneri in cui `dx == 0`).
  ///
  /// Risultato:
  /// - `0°`   → il punto è esattamente a destra del centro;
  /// - `90°`  → il punto è sotto il centro (asse y rivolto verso il basso);
  /// - `-90°` → il punto è sopra il centro;
  /// - `±180°`→ il punto è esattamente a sinistra del centro.
  static double calculateDialAngle(Offset localPosition, Offset center) {
    final double dx = localPosition.dx - center.dx;
    final double dy = localPosition.dy - center.dy;
    return math.atan2(dy, dx) * 180.0 / math.pi;
  }

  /// Calcola il **delta angolare** tra [currentAngle] e [lastAngle]
  /// correggendo il "salto" che si verifica quando si attraversa il
  /// confine `±180°`.
  ///
  /// Esempio senza normalizzazione:
  /// ```
  /// lastAngle = +175°, currentAngle = -175°
  /// delta naive = -350°   ← drammatico, manda il knob a -480°
  /// ```
  /// Con normalizzazione:
  /// ```
  /// delta = -350° + 360° = +10°   ← movimento corretto (10° in avanti)
  /// ```
  ///
  /// Restituisce un delta nel range `(-180°, +180°)`.
  static double normalizeAngleDelta(double currentAngle, double lastAngle) {
    double delta = currentAngle - lastAngle;
    if (delta > 180.0) {
      delta -= 360.0;
    } else if (delta < -180.0) {
      delta += 360.0;
    }
    return delta;
  }
}

/// Widget che isola l'interazione circolare (corona / knob del dial) dai
/// widget di scorrimento sottostanti (tipicamente `SingleChildScrollView`,
/// `ListView`, `PageView`, `NestedScrollView`, ecc.).
///
/// Strategia di blocco a triplo livello, dall'esterno verso l'interno:
///
/// 1. un [Listener] con `behavior: HitTestBehavior.opaque` rivendica
///    *esclusivamente* l'area del proprio `child`: nessun widget dietro
///    o davanti può ricevere hit test in quella zona.
///
/// 2. In `onPointerDown` viene registrata una [PointerRoute] sul
///    [GestureBinding.instance.pointerRouter] che assorbe **silenziosamente**
///    gli eventi successivi dello stesso puntatore (`move` / `up` /
///    `cancel`), impedendo che raggiungano i recognizer ereditati
///    (in particolare il `VerticalDragGestureRecognizer` della
///    ScrollView sottostante).
///
/// 3. Un [GestureDetector] interno con `HitTestBehavior.opaque` espone un
///    `PanGestureRecognizer` che compete in arena con il recognizer di
///    drag dello scrollable antenato: appena l'utente inizia a muovere
///    il dito sull'area del dial, il pan vince e lo scroll viene
///    cancellato.
///
/// Risultato per l'utente: trascinando il dito sulla corona, **la
/// schermata sottostante non si muove mai**.
class DialScrollBlocker extends StatefulWidget {
  /// Widget da avvolgere (di norma il paint del dial o un `GestureDetector`
  /// che gestisce la rotazione vera e propria).
  final Widget child;

  /// Callback opzionale invocata al primo tocco sull'area del dial.
  final ValueChanged<PointerDownEvent>? onPointerDown;

  /// Callback opzionale invocata ad ogni movimento del puntatore
  /// catturato dal blocker.
  final ValueChanged<PointerMoveEvent>? onPointerMove;

  /// Callback opzionale invocata al rilascio del puntatore.
  final ValueChanged<PointerUpEvent>? onPointerUp;

  /// Callback opzionale invocata se il puntatore viene annullato
  /// (es. interruzione di sistema, finestra persa di focus, ecc.).
  final ValueChanged<PointerCancelEvent>? onPointerCancel;

  const DialScrollBlocker({
    super.key,
    required this.child,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
  });

  @override
  State<DialScrollBlocker> createState() => _DialScrollBlockerState();
}

class _DialScrollBlockerState extends State<DialScrollBlocker> {
  /// Mappa `pointerId → PointerRoute` per tenere traccia di quali route di
  /// assorbimento sono correntemente installate su
  /// [GestureBinding.instance.pointerRouter].
  ///
  /// Viene usata per poter rimuovere **esattamente la stessa funzione**
  /// che era stata aggiunta (Flutter richiede identità referenziale).
  final Map<int, PointerRoute> _routes = <int, PointerRoute>{};

  /// Registra una [PointerRoute] di assorbimento per il puntatore [pointer]
  /// sul [GestureBinding.instance.pointerRouter].
  ///
  /// La route non fa nulla di visibile: serve solo a marcare l'evento come
  /// già gestito, sottraendolo dai recognizer antenati che altrimenti
  /// lo userebbero per far scorrere la pagina sottostante.
  ///
  /// In caso la route fosse già presente, viene reinstallata in modo
  /// idempotente (prima remove e poi add).
  void _capturePointer(int pointer) {
    _releasePointer(pointer);

    final PointerRoute route = _absorbingPointerRoute;
    _routes[pointer] = route;
    GestureBinding.instance.pointerRouter.addRoute(pointer, route);
  }

  /// Rimuove la [PointerRoute] precedentemente installata per [pointer],
  /// se presente.
  void _releasePointer(int pointer) {
    final PointerRoute? existing = _routes.remove(pointer);
    if (existing != null) {
      GestureBinding.instance.pointerRouter.removeRoute(pointer, existing);
    }
  }

  /// [PointerRoute] usata per marcare come "consumato" un [PointerEvent]
  /// senza compiere alcuna azione visibile.
  ///
  /// È una funzione statica (nessuno stato d'istanza): la stessa identità
  /// referenziale può essere usata per più puntatori.
  static void _absorbingPointerRoute(PointerEvent _) {
    // Assorbimento silenzioso: nessuna azione.
    // L'evento è stato consumato dal nostro widget prima di arrivare
    // a qualunque recognizer di scroll / drag antenato.
  }

  @override
  void dispose() {
    // Importante: pulire TUTTE le route ancora installate per evitare
    // memory leak / pointer "orfani" nel router.
    for (final int pointer in _routes.keys.toList(growable: false)) {
      _releasePointer(pointer);
    }
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _capturePointer(event.pointer);
    widget.onPointerDown?.call(event);
  }

  void _onPointerMove(PointerMoveEvent event) {
    // Aggiornamento della route già installata: non serve reinstallarla,
    // resta valida fino a `onPointerUp` o `onPointerCancel`.
    widget.onPointerMove?.call(event);
  }

  void _onPointerUp(PointerUpEvent event) {
    widget.onPointerUp?.call(event);
    _releasePointer(event.pointer);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    widget.onPointerCancel?.call(event);
    _releasePointer(event.pointer);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // [HitTestBehavior.opaque] garantisce che la nostra area sia
      // opaca al hit test: tutto ciò che sta "dietro" non riceve eventi,
      // ogni puntatore che cade qui è nostro.
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: GestureDetector(
        // Idem per il GestureDetector, ma riferito ai gesture recognizer.
        behavior: HitTestBehavior.opaque,
        // Dichiarando un `PanGestureRecognizer`, questo entra nell'arena
        // insieme al `DragGestureRecognizer` dello scrollable antenato.
        // Non appena il dito si muove, il nostro recognizer vince e
        // cancella lo scroll sottostante.
        onPanStart: (_) {/* la vittoria in arena basta a sé stessa */},
        onPanUpdate: (_) {/* assorbe il movimento */},
        onPanEnd: (_) {/* fine del pan */},
        onPanCancel: () {/* pan cancellato da altro recognizer */},
        // Tap brevi: utile a intercettare tap rapidi sopra la corona
        // circolare (ad es. pressione centrale = reset / conferma).
        onTapDown: (_) {},
        child: widget.child,
      ),
    );
  }
}

/// Mixin opzionale per [State] che vogliono reagire al ciclo di vita
/// di un puntatore catturato da [DialScrollBlocker].
///
/// Espone le informazioni minime necessarie senza vincolare
/// all'utilizzo del blocco stesso.
mixin DialPointerLifecycleMixin<T extends StatefulWidget> on State<T> {
  bool _hasPointer = false;

  /// `true` se almeno un puntatore è attualmente catturato.
  bool get hasCapturedPointer => _hasPointer;

  /// Chiamato dal figlio quando un puntatore entra nella sua area.
  void notifyPointerCaptured(PointerDownEvent event) {
    if (!_hasPointer) {
      _hasPointer = true;
      onPointerCaptureStart(event);
    }
  }

  /// Chiamato dal figlio quando un puntatore lascia la sua area.
  void notifyPointerReleased(PointerEvent event) {
    if (_hasPointer) {
      _hasPointer = false;
      onPointerCaptureEnd(event);
    }
  }

  /// Hook ridefinibile: primo puntatore catturato.
  void onPointerCaptureStart(PointerDownEvent event) {}

  /// Hook ridefinibile: ultimo puntatore rilasciato.
  void onPointerCaptureEnd(PointerEvent event) {}
}
