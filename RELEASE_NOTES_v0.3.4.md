### Novità e Correzioni v0.3.4

- **Anteprima Workout Interamente Scrollabile**: Cliccando su *"Mostra altro (+X fasi) ▼"* o *"Mostra tutto"* nella preview del piano generato con AI, è ora possibile scorrere l'intero elenco delle ripetute/fasi con scrollbar visibile dedicata (`Scrollbar` + `SingleChildScrollView`), e richiuderlo con *"Mostra meno ▲"*.
- **Risoluzione Bug Selezione Preset e Crash del Selettore**: Risolto il problema per cui due allenamenti creati con l'AI ricevevano lo stesso ID (`workout_custom`), provocando la selezione contemporanea di più card e l'errore di chiavi duplicate nel menu a tendina (*DropdownButtonFormField*). Ora ogni piano riceve un ID univoco e i preset salvati vengono deduplicati automaticamente.
- **Correzione Switcher Avvisi Inizio/Fine**:
  - Separati gli switch in 3 opzioni indipendenti nell'Editor Preset: *Avviso inizio allenamento*, *Avviso fine allenamento* e *Sommario finale*.
  - L'intera riga delle impostazioni è ora cliccabile con feedback aptico immediato.
  - Il servizio di tracciamento rispetta rigorosamente i flag scelti, evitando annunci non voluti alla fine della sessione o delle ripetute.
- **Suite di Test**: 71/71 test unitari superati con successo.
