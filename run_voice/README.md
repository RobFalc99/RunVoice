# RunVoice 🏃‍♂️🎧

RunVoice è un assistente alla corsa smart, minimale e progettato attorno al concetto di "voce" e "invisibilità". L'obiettivo dell'applicazione è fornire agli atleti tutte le metriche cruciali dell'allenamento (passo, distanza, frequenza cardiaca) tramite feedback audio fluido e non intrusivo. In questo modo il runner può mantenere alta la concentrazione sul tracciato e la tecnica di corsa, senza necessità di guardare lo schermo.

---

## 🎯 Funzionalità Principali (User Perspective)

Dal punto di vista dell'utente finale, RunVoice offre:

1. **Zero Distrazioni Visuali**: Un'interfaccia utente pulita, esteticamente moderna e dark, caratterizzata da colori vibranti per le varie dashboard di lettura, la cui funzione base è principalmente impostare la dinamica della corsa prima di cominciare, ignorando controlli macchinosi post-avvio.
2. **Rilevamento GPS e Metriche Avanzate**: Calcolo istantaneo di metriche fisiche come *Distanza (km)*, *Passo (min/km)* e *Velocità (km/h)*, con logiche anti-interferenza per escludere eventuali balzi o buchi di copertura (filtri sul track point).
3. **Bluetooth BLE Cardio (Frequenza Cardiaca)**: Abbinamento diretto a un dispositivo Bluetooth (Fasce Garmin, Polar, e persino array proprietari in broadcast HR mode come i wearable Whoop). Aggancio intelligente e metriche calcolate in BPM reali.
4. **Calcolo Zone Cardiache Reale (Tanaka)**: Implementazione strutturata e metodologica delle zone cardiache (dalla vitale *Zona 0* al bottom up della *Zona 5*) inquadrati al millimetro usando il calcolo dell'HR Massimo formula Tanaka.
5. **Vocalità TTS Dinamica (Audio Focus)**: I comandi vocali vengono letti senza interrompere il podcast o la musica dell'utente, bensì posizionandoli "sotto" momentaneamente (Audio Ducking/Attenuazione Categoria OS iOS/Android). Il sistema processa testi logici italiani con corretta interpolazione singolare/plurale o decifrazione delle unità misurative (*Es: pronuncia B P M e non battiti anonimi*).
6. **Profili Allenamento ed Editor (Preset)**:
    - **Avvisi Periodici**: Possibilità di domandarsi il "come sto andando?" scansionando ciclicamente. Es: *“Ogni 1000m, fammi il punto della situazione su distanza e battiti”*.
    - **Modalità Coaching Mentore**: Controllo stretto continuo. Puoi dare limitazioni (Es. *"Non andare oltre i 160 BPM e non andare più lento di 5 min/km"*). Se la tendenza fuoriesce, la coach voice ti informerà avvisandoti specificatamente che un parametro risulta troppo basso o troppo alto finché non recuperi, rincuorandoti quando torni nel range stabilito.
    - **Super Profilo (Modalità Ripetute)**: Allenamento configurabile step by step (Flessibile Corsa/Riposo o Fartlek). Si avvalora di una schermata a schede copiabili. La logica prenderà interamente il controllo, indicando il cambio fase, gestendo per te il timer intervallo o i metri da fare tra il passo precedente e il passo successivo.

---

## 🖥️ Implementazione & Struttura (Tech Perspective)

Architettura del progetto basata sull'SDK di **Flutter**, orientata alla modularizzazione ed al multi-threading. La logica asincrona sfrutta le potenze del Provider e Service Pattern per isolare ed estendere individualmente le singole sfaccettature dell'app.

### Core Architecture & State Management:
- **Provider Pattern (`ChangeNotifier`)**: Cuore pulsante che smista il flusso di ascolto fra la dashboard UI e i servizi isolati di stato (`PresetProvider` per i settaggi salvati serialmente via SharedPreferences, `WorkoutProvider` per i flussi e delta attivi nel training corrente).
- **Service Layers autonomi**:
  - `TtsService`: Controlla ed incapsula completamente le dipendenze `flutter_tts`. Alloca la coda FIFO per gli stream vocali e setta l'`AudioCategory` del sistema operativo host per dominare i privilegi di Ducking (silenziare le terze parti).
  - `LocationService`: Disaccoppiato dai layer grafici, lavora col pacchetto `geolocator`. Valuta le coordinate GPS, confronta i delta vector position per mitigare il rumore e i dropout del ricevitore satellite, gestisce la richiesta di permesso.
  - `HRBluetoothService`: Scanner puro dei dispositivi Bluetooth, interpreta lo Standard Heart Rate profile e le relative `Characteristics` dei sensori BLE emersi per spingere un stream perpetuo in direzione del core tracker.
  - `WorkoutService`: L'Intelligenza Virtuale. Integra il tick 1-second interval che muove i check d'analisi incrociando i provider fisici. Mantiene l'allineamento dei "checkpoint" metrologici, giudicando quando invocare l'aiuto dell'engine di TTS a seconda della modalità attivabile (TimeInterval, DistanceTrigger o Coaching threshold).

### Models ed Entità Chiave:
Tutti i settings e avvisi sono descritti tramite entità solidissime:
- `Preset`: Categoria ombrello di uno scenario (`"Maratona di Roma"`, `"Recupero in soglia"` etc)
- `AlertConfig` & `CoachingAlert`: Sotto-modelli che processano formule in base ad aggregazioni di TargetMetrics. Generano autonomamente lo scaffold logico della stringa in italiano basandosi sul loro context ed eventuale limite (Enum).
- `IntervalStep`: Un singolo "passo" di vita misurabile di un set di ripetute, reppresentante i requisiti trigger prima del drop temporale verso quello cronologicamente successivo. 

---

## 🚀 Setup & Note di Lancio

- Essendo un'applicazione di navigatore atletico, i permessi di rilevazione Bluetooth Scanning / Connect e GPS sono bloccanti per l'avvio sensoriale.
- Particolare attenzione necessita sui settaggi del dispositivo target che deve prevedere l'esecuzione in *Background Illimitato* (Nessun risparmio energetico attivato sulle query di Localizzazione o Bluetooth OS). La privazione di tali diritti farebbe saltare il sync GPS a schermo spento, perdendo l'effettivo delta chilometrico della traccia.
- Testare accuratamente con `flutter run --release` o installare la release di build `.apk` / `.ipa`, specialmente qualora volessi misurare reattività di rendering dei frame colorimetrici e fluidità dei layer vocali che in Debug potrebbero soffrire di de-sync jitter.

### 📦 Compilazione Rapida dell'APK (Scorciatoia Windows)
Per facilitare lo sviluppo e la generazione rapida dell'APK senza dover navigare o digitare comandi lunghi ogni volta, è presente uno script di utilità nativo nella radice del progetto:
* **`build_apk.bat`**: Esegue automaticamente il cambio directory alla cartella del progetto corretta (`[04] RunVoice`), lancia `flutter build apk --release` usando l'ambiente Windows locale e mantiene aperta la finestra al termine, indicando l'esatto percorso del file APK compilato. Puoi eseguirlo con un semplice doppio clic da Windows Explorer o digitando `.\build_apk.bat` in PowerShell.
