# RunVoice v0.3.0 - AI Workout Generation & Auto-Scan UX 🚀🤖

Questa release introduce la generazione intelligente di allenamenti tramite intelligenza artificiale Google Gemini, la scansione automatica istantanea dei sensori cardio e la completa ristrutturazione dell'editor per allenamenti a intervalli/ripetute.

---

## 🌟 Principali Novità

### 1. 🤖 Generazione Workout con Google Gemini AI
- **Generazione Rapida "Al Volo" (Training Home)**: Nuova card interattiva nella schermata iniziale per creare all'istante una sessione personalizzata in linguaggio naturale (es. *"5 ripetute da 1000m a 4:30 con recupero 2 min"* o *"Allenamento progressivo di 8 km"*) e avviarla immediatamente con feedback vocale.
- **Creazione & Modifica Presets con AI**: Pulsante **"Crea con AI"** aggiunto sia nella schermata della lista dei Presets che direttamente nell'AppBar dell'Editor, per popolare o rigenerare rapidamente qualsiasi workout strutturato.
- **Modello Efficiente & Gratuito**: Configurato con Google **`gemini-2.5-flash`** (Free Tier Google AI Studio: fino a 15 RPM e 1.500 RPD a costo zero).
- **Integrazione Sicura delle API Key**: Gestione della chiave API nelle Impostazioni con pulsante Incolla, test di connessione in tempo reale e salvataggio locale sicuro senza leak.

### 2. 💓 Scansione Cardio Automatica e Istantanea
- Rimosso il passaggio ridondante del pulsante *"Cerca sensori"*: al tocco della card della frequenza cardiaca, il radar Bluetooth BLE avvia immediatamente la scansione e l'aggiornamento dei dispositivi disponibili con indicatore visivo animato.

### 3. ⏱️ Editor Ripetute & Intervalli Completamente Restaurato
- Risolto il problema di visualizzazione (precedentemente mostrava codice JSON grezzo e campi vuoti).
- Nuove card modulari per ogni fase con:
  - Badge numerato e durata calcolata.
  - Azioni rapide: Modifica, Duplica ed Elimina step.
  - Foglio di configurazione avvisi vocali contestuali per singolo step (Target Passo, Cadenza, BPM).

### 4. 🧪 Affidabilità & Qualità del Codice
- **50/50 test unitari e di widget passati** con successo.
- **0 errori e 0 warning** su `flutter analyze`.

---

## 📦 Asset Inclusi
- `RunVoice-v0.3.0.apk`: Binario release per Android pronto all'installazione diretta.
