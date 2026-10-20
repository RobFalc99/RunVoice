# RunVoice v0.3.2 - Automatic AI Coaching & Periodic Alerts 🎯🔊

Questa release risolve la mancata generazione di avvisi vocali quando si inseriscono workout strutturati con target di frequenza cardiaca (BPM) o passo tramite Google Gemini AI.

---

## 🌟 Novità di questa Release

### 1. 🎯 Risoluzione Parsing Target BPM & Passo da Gemini
- Corretto il mismatch di casing (`heart_rate_bpm` da Gemini vs `heartRateBpm` di Dart): ora il parser accetta in modo flessibile formati snake_case, camelCase e varianti sintattiche.
- Supporto nativo ai range di battito cardiaco: memorizzazione di `target_hr_bpm_min` e `target_hr_bpm_max` (es. 120-135 bpm, 145-155 bpm) e derivazione automatica di centro e tolleranza.

### 2. 🔊 Generazione Automatica di Coaching Alert per Ogni Fase
- Tutte le fasi di riscaldamento, ripetute veloci, recupero e defaticamento dotate di target BPM ora generano automaticamente un **`CoachingAlert`** dedicato:
  - Monitoraggio costante del range minimo e massimo.
  - Annuncio vocale in tempo reale in caso di superamento della soglia (battito troppo alto o troppo basso) e al rientro nel target desiderato.
- Supporto analogo per target di Passo (min/max min/km).

### 3. ⏱️ Generazione Automatica di Avvisi Periodici a Tempo
- Per ogni intervallo di durata $\ge 60$ secondi dotato di target, viene aggiunto automaticamente un **avviso periodico** (`AlertConfig`):
  - Fasi di lavoro o recupero corte (60s - 180s): annuncio vocale del battito cardiaco ogni 30 secondi.
  - Fasi lunghe o di riscaldamento/defaticamento ($\ge 180$ secondi): annuncio vocale del battito ogni 60 secondi.

### 4. 👁️ Anteprima Immediata nella Card AI
- La card di anteprima del workout prima della conferma mostra ora:
  - Il badge verde con il conteggio totale degli avvisi configurati (`✓ X avvisi vocali (coaching & periodici) configurati`).
  - Il chip rosso per ciascuna fase con il target esatto (es. `🎯 145-155 bpm`).
- Nell'Editor delle ripetute, ogni fase mostra chiaramente i chip degli avvisi attivi.

### 5. 🧪 Test & Affidabilità
- **62/62 test passati** con successo.
- **0 errori e 0 warning** su `flutter analyze`.
- Test live superato con il prompt dell'utente: generati 24 avvisi di coaching e 18 avvisi periodici.

---

## 📦 Asset Inclusi
- `RunVoice-v0.3.2.apk`: Binario release per Android pronto all'installazione diretta.
