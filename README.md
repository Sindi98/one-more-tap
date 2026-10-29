# One More Tap

Gioco arcade verticale a un dito, Godot 4.7 / GDScript. Tre modalità infinite (ZIGZAG, TORRE, DINO), un solo controllo, percorsi generati, game over, record locale per modalità, restart immediato, grafica neon. Gratuito con annunci AdMob, pronto per Google Play e App Store: i passi per pubblicarlo sono in **[PUBBLICAZIONE.md](PUBBLICAZIONE.md)**.

## Aprire e giocare

1. Installa **Godot 4.7** (versione Standard, non .NET). Il plugin AdMob richiede almeno la 4.5.
2. Project Manager → **Import** → seleziona `project.godot`.
3. Al primo avvio Godot importa i font (qualche secondo). Poi **F5**.

Su desktop: clic sinistro, Spazio, Invio o Freccia su. Su telefono: tap ovunque.

## Regole

La modalità si sceglie con i pulsanti in basso nella schermata iniziale; dal game over il pulsante MODALITÀ riporta lì. Ogni modalità ha il suo record e il gioco ricorda l'ultima scelta.

### ZIGZAG

- La pallina sale da sola in diagonale. Ogni tap la fa girare di 90°.
- Bisogna girare **dentro l'angolo**: prima cade di lato ("Troppo presto"), dopo esce dalla fine della piattaforma ("Troppo tardi").
- Ogni piattaforma raggiunta vale 1 punto. Girare al centro esatto dell'angolo (±16% della larghezza) è un **PERFETTO**: +1 punto, la pallina si riallinea al centro e le combo salgono di nota.
- Piattaforme sempre più strette e pallina sempre più veloce. Il colore cambia ogni 12 punti.
- Quando cadi: anello rosso sull'angolo mancato + freccia nella direzione giusta. Riprova subito col pulsante o con un tap.
- **CONTINUA**: una volta per partita, se hai almeno 5 punti, un breve video ti rimette sulla piattaforma dove sei caduto, con la pallina rallentata per un attimo.

### TORRE

- La pallina sale da sola lungo una rampa a spirale intorno a una torre che gira. Ogni tap la fa saltare.
- La rampa ha dei buchi: salta prima del bordo e atterra oltre. Troppo presto atterri nel buco ("Troppo presto"), troppo tardi ci cadi dentro ("Troppo tardi"). Un salto lontano dal buco è solo un saltello innocuo.
- Ogni buco superato vale 1 punto. Saltare nell'ultimo 30% della rincorsa utile, vicino al bordo, è un **PERFETTO**: +1 e combo, come in ZIGZAG.
- Buchi sempre più lunghi e pallina più veloce; il salto copre sempre la stessa distanza.
- Quando cadi: bordi del buco in rosso, cerchio nel punto giusto di stacco e la traiettoria del salto che avrebbe funzionato.
- **CONTINUA**: riparti dall'inizio del tratto prima del buco mancato.

### DINO

- Omaggio al gioco del browser senza internet: il dino corre da solo, ogni tap lo fa saltare. Un tap poco prima di atterrare salta appena tocca terra.
- Salta i cactus (piccoli, grandi, in gruppi) e gli uccelli bassi. Gli uccelli alti passano sopra il dino a terra: se salti li prendi ("Non saltare").
- Il punteggio è la distanza, a 5 cifre, con un "ding" ogni 100 punti. La velocità cresce con la distanza, gli uccelli arrivano dopo 250 punti, il colore cambia ogni 100.
- Quando sbatti: cornice rossa su quello che ti ha preso. "Troppo presto" se ci sei ricaduto sopra, "troppo tardi" se non hai saltato in tempo.
- **CONTINUA** (da 150 punti): riparti piano da dove eri, con la strada libera finché non torni alla velocità piena.

## Annunci

Plugin [AdMob di Poing Studios](https://github.com/poingstudios/godot-admob-plugin) v5.1.0 in `addons/admob` (licenza MIT), già attivo.

- **Video con premio**: il pulsante CONTINUA nel game over.
- **Interstitial**: solo toccando RIPROVA, al massimo uno ogni 3 partite e ogni 90 secondi (`scripts/ad_pacing.gd`). Mai durante una partita, nessun banner.
- **Consenso GDPR** con il modulo di Google (UMP) al primo avvio in UE. I pulsanti PRIVACY e CONSENSO stanno nei menu.
- **ID**: finché `LIVE_IDS` in `scripts/ads.gd` è vuoto, e sempre nelle build di debug, il gioco usa gli annunci di prova di Google.
- **Dove compaiono**: su telefono con il plugin nativo; dall'editor (F5) il plugin mostra annunci finti. Su desktop esportato e nei test headless gli annunci sono spenti e il gioco funziona come prima.

## Struttura

| File | Ruolo |
|---|---|
| `scripts/run_rules.gd` | Base comune delle regole: tap, punteggio, caduta con motivo, un "continua" a partita |
| `scripts/track.gd` | Regole pure di ZIGZAG (nessun nodo): generazione, tap, caduta con motivo, punteggio. **Tutte le costanti di difficoltà sono in cima**, come negli altri due file di regole. |
| `scripts/tower.gd` | Regole pure di TORRE: rampa come linea dritta, buchi, salto, perfetti |
| `scripts/runner.gd` | Regole pure di DINO: fisica del salto, ostacoli sempre superabili, distanza |
| `scripts/mode_view.gd` | Base comune dei disegni: colore, area visibile, dove guarda la camera |
| `scripts/world_view.gd` | Disegno di ZIGZAG: griglia, percorso neon, pallina, scia, marker dell'errore |
| `scripts/tower_view.gd` | Disegno di TORRE: avvolge la rampa intorno a una torre pseudo-3D che gira |
| `scripts/runner_view.gd` | Disegno di DINO: sprite in pixel art (disegnati per questo gioco), terreno, nuvole |
| `scripts/fx.gd` | Particelle e scritte che volano, per tutte le modalità |
| `scripts/game.gd` | Flusso: modalità, stati, input, camera, shake, vibrazione, salvataggio, continua e annunci tra le partite |
| `scripts/hud.gd` | UI costruita in codice: punteggio, combo, start con scelta della modalità, game over, pausa, continua, privacy |
| `scripts/sfx.gd` | Suoni sintetizzati all'avvio, nessun file audio |
| `scripts/ads.gd` | Quello che il gioco sa degli annunci: ID, "c'è un video pronto?", interstitial quando è il momento |
| `scripts/admob_backend.gd` | Unico file che usa il plugin AdMob: consenso, avvio SDK, caricamento e visualizzazione |
| `scripts/ad_pacing.gd` | Regole pure su quando mostrare un interstitial |
| `tests/test_track.gd` | Test headless delle regole di ZIGZAG, compreso il "continua" |
| `tests/test_tower.gd` | Test headless delle regole di TORRE |
| `tests/test_runner.gd` | Test headless delle regole di DINO |
| `tests/test_ad_pacing.gd` | Test headless della frequenza degli annunci |
| `tools/make_icons.gd` | Rigenera le icone PNG da `assets/icons/*.svg` |
| `export_presets.cfg` | Preset Android (AAB) e iOS |
| `docs/` | Informativa privacy da pubblicare con GitHub Pages |
| `store/` | Testi, screenshot e grafiche per le schede degli store |

Renderer **Compatibility** (OpenGL): massima compatibilità con Android economici. Viewport 720×1280 verticale, si estende sui telefoni più lunghi.

## Test

```
godot --headless --path . --script res://tests/test_track.gd
godot --headless --path . --script res://tests/test_tower.gd
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . --script res://tests/test_ad_pacing.gd
```

Controllano che un giocatore perfetto sopravviva su 60 percorsi diversi per modalità (in DINO fino alla velocità massima), che gli angoli restino sempre nello schermo, che dopo ogni buco ci sia rampa per reagire, che ogni gruppo di cactus sia superabile con un margine, che "presto/tardi/non saltare" sia corretto, il conteggio dei perfetti e la rampa di difficoltà. Controllano anche che "continua" valga una volta sola, mantenga il punteggio e riparta piano, e che gli interstitial rispettino le pause. Durano qualche secondo.

## Export su telefono

I preset Android (AAB firmato, build Gradle, permessi INTERNET e VIBRATE) e iOS (progetto Xcode, solo iPhone, iOS 15+) sono già in `export_presets.cfg`. Strumenti da installare, chiavi di firma e invio agli store: **[PUBBLICAZIONE.md](PUBBLICAZIONE.md)**.

Prova veloce su Android: template di export, JDK 17 e Android SDK installati, *Project → Install Android Build Template*, telefono in debug USB, poi il pulsante Android in alto a destra nell'editor.

## Prossimi passi

1. Playtest su telefono vero: tarare `W_START`, `W_STEP`, `V_START`, `V_STEP`, `PERFECT_FRAC` in `track.gd`, le costanti in cima a `tower.gd` e `runner.gd`, più `REVIVE_SLOW` e la frequenza degli annunci in `ad_pacing.gd`.
2. Sfida giornaliera: `Track.new(width, height, seed)` accetta già un seed, basta derivarlo dalla data.
3. "Rimuovi annunci" come acquisto in-app, traduzione inglese.

Font: Bungee e Chakra Petch, licenza SIL Open Font License (file in `assets/fonts`).
