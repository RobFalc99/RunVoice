# RunVoice v0.3.1 - Dynamic Gemini AI Model Selector & Gemini 3.x Flash 🚀

Questa release introduce la selezione interattiva del modello di intelligenza artificiale Google Gemini direttamente nelle Impostazioni, garantendo piena compatibilità con le nuove specifiche Google AI Studio 2026 (`gemini-3.5-flash-lite`, `gemini-3.8-flash`, ecc.).

---

## 🌟 Novità di questa Release

### 1. 🎛️ Selettore Modelli AI nelle Impostazioni
- **Posizionato sopra la chiave API**: Un menu a tendina neumorphic permette di scegliere il modello desiderato tra quelli ufficiali attivi e funzionanti:
  - ⚡ **Gemini 3.5 Flash-Lite** (Consigliato): Risposta istantanea, latenza minima, ottimizzato per uso frequente a consumo token ridotto (Free Tier garantito).
  - 🚀 **Gemini 3.8 Flash** (Novità 2026): L'ultimo modello raccomandato da Google AI Studio per generazioni articolate.
  - 🎯 **Gemini 3.5 Flash** (Bilanciato): Massimo equilibrio tra velocità e reasoning.
  - 🔄 **Gemini Flash Latest & Flash-Lite Latest**: Modelli dinamici che puntano sempre alla versione stabile più recente.
  - 📦 **Gemini 2.5 Flash**: Mantenuto per retrocompatibilità.
- **Pulsante "🔄 Rileva"**: Interroga in tempo reale l'endpoint `/v1beta/models` della propria API Key e aggiunge alla lista i modelli effettivamente abilitati per il proprio account.
- **Pulsante "Testa Connessione (Nome Modello)"**: Testa in tempo reale il funzionamento esatto del modello selezionato con diagnostica trasparente.

### 2. ⚡ Propagazione del Modello Selezionato a Tutta l'App
- Il modello scelto dall'utente viene memorizzato nel profilo (`user_profile.dart`) e persistito localmente in `SharedPreferences`.
- Tutta la generazione (sia il foglio rapido "Al Volo 🚀" nella schermata iniziale che la creazione e modifica nei Presets) invoca direttamente il modello preferito.
- Indicatore visivo dinamico: `"Powered by Gemini 3.5 Flash-Lite"` (o modello attivo).

### 3. 🧪 Qualità del Codice e Test
- **59/59 test unitari e di widget passati** con successo.
- **0 errori e 0 warning** su `flutter analyze`.

---

## 📦 Asset Inclusi
- `RunVoice-v0.3.1.apk`: Binario release Android pronto all'installazione diretta.
