### Novità e Correzioni v0.3.5

- **Risoluzione Bug Livellatore Battito Fuori Range (Coaching Alert HR)**:
  - **Reattività Immediata**: Risolto il ritardo per cui l'avviso vocale di fuori range (es. impostato tra 120 e 130 BPM) arrivava solo a 145 BPM. Il delay di conferma fuori soglia (`outOfRangeDelaySeconds`) per i BPM è stato ottimizzato a 3 secondi (anziché 10-15s), permettendo di allertare subito l'atleta a 131-133 BPM.
  - **Filtro Isteresi / Anti-Jitter sul Confine**: Evitato l'azzeramento improprio del contatore fuori soglia dovuto a micro-oscillazioni fisiologiche (es. 131, 130, 132, 130 BPM). Una singola lettura di confine non cancella più l'accumulo di fuori range; il ritorno stabile richiede conferma genuina.
  - **Sincronizzazione Stream BLE e Timer Workout**: Eliminati conflitti e race condition tra il callback asincrono dei pacchetti Bluetooth e il timer a 1 Hz: ogni secondo di workout viene valutato esattamente una volta sia all'arrivo dell'evento BLE sia dal tick periodico.
  - **Regolazione nel Setup Avvisi**: Aggiunti in `AlertSetupSheet` lo slider dedicato per range BPM target (min-max) e il selettore del ritardo di avviso fuori soglia.

- **Memorizzazione Automatica Dispositivi BLE (Sensori Recenti / Abituali)**:
  - **Persistenza Locale**: Creato il modello `SavedBleDevice` persistito in `SharedPreferences`. I dispositivi cardio (identificati da MAC address su Android o UUID) utilizzati in precedenza vengono memorizzati automaticamente.
  - **Accesso Diretto in Homepage**: Nella schermata principale (`TrainingScreen`), sotto lo stato sensori, compare la lista dei dispositivi memorizzati. Se il sensore è attivo / nelle vicinanze, viene evidenziato con badge verde *"Attivo"*.
  - **Connessione Rapida a 1-Tap**: Toccando *"Connetti"* sul dispositivo memorizzato, l'app avvia la connessione diretta senza dover effettuare scansioni manuali o aprire modali.
  - **Integrazione Dialogo Sensori**: I dispositivi salvati sono disponibili anche nel `BluetoothDeviceDialog` con opzione per dimenticare/rimuovere i sensori obsoleti.

- **Suite di Test di Simulazione**:
  - Implementata una suite di simulazione live con stream di battiti cardiaci (`test/heart_rate_coaching_simulation_test.dart`): testati scenari di salita repentina, jitter di confine, rientro in range ("tutto bene"), discesa sotto soglia ("troppo bassi") e attivazione interfaccia/callback.
  - Aggiunti test dedicati per il modello e provider BLE memorizzato (`test/saved_ble_device_test.dart`).
  - Suite completa: 81/81 test unitari superati con successo (zero regressioni).
