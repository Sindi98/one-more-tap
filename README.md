# One More Tap

Gioco arcade verticale a un dito, Godot 4.7 / GDScript. Tre modalità infinite (ZIGZAG, TORRE, DINO), un solo controllo, percorsi generati, game over, record locale per modalità, restart immediato, grafica neon. Gratuito con annunci AdMob e acquisti in-app facoltativi (stili, gettoni, niente annunci), pronto per Google Play e App Store: i passi per pubblicarlo sono in **[PUBBLICAZIONE.md](PUBBLICAZIONE.md)**.

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
- **CONTINUA**: una volta per partita, se hai almeno 5 punti, un breve video (o un gettone, vedi [Acquisti in-app](#acquisti-in-app)) ti rimette sulla piattaforma dove sei caduto, con la pallina rallentata per un attimo.

### TORRE

- La pallina sale da sola lungo una rampa a spirale intorno a una torre che gira. Ogni tap la fa saltare.
- La rampa ha dei buchi: salta prima del bordo e atterra oltre. Troppo presto atterri nel buco ("Troppo presto"), troppo tardi ci cadi dentro ("Troppo tardi"). Un salto lontano dal buco è solo un saltello innocuo.
- Ogni buco superato vale 1 punto. Saltare nell'ultimo 30% della rincorsa utile, vicino al bordo, è un **PERFETTO**: +1 e combo, come in ZIGZAG.
- Buchi sempre più lunghi e pallina più veloce; il salto copre sempre la stessa distanza.
- Quando cadi: bordi del buco in rosso, cerchio nel punto giusto di stacco e la traiettoria del salto che avrebbe funzionato.
- **CONTINUA**: riparti dall'inizio del tratto prima del buco mancato.

### DINO

- **Si apre giocando 3 giorni di fila** (basta aprire il gioco una volta al giorno). Il pulsante mostra a che punto sei, per esempio "DINO 1/3"; saltare un giorno fa ripartire il conto. Una volta aperta resta aperta. Chi aveva già un record in DINO la trova aperta.
- Omaggio al gioco del browser senza internet: il dino corre da solo, ogni tap lo fa saltare. Un tap poco prima di atterrare salta appena tocca terra.
- Salta i cactus (piccoli, grandi, in gruppi) e gli uccelli bassi. Gli uccelli alti passano sopra il dino a terra: se salti li prendi ("Non saltare").
- Il punteggio è la distanza, a 5 cifre, con un "ding" ogni 100 punti. La velocità cresce con la distanza, gli uccelli arrivano dopo 250 punti, il colore cambia ogni 100.
- Quando sbatti: cornice rossa su quello che ti ha preso. "Troppo presto" se ci sei ricaduto sopra, "troppo tardi" se non hai saltato in tempo.
- **CONTINUA** (da 150 punti): riparti piano da dove eri, con la strada libera finché non torni alla velocità piena.

## Acquisti in-app

Si aprono da **STILI** nella schermata iniziale. La rarità indica il prezzo e quanto fa un oggetto, mai la fortuna: si compra sempre esattamente quello che si vede, niente casse a sorpresa. Tutto è estetico o comodità: i record restano confrontabili.

| Cosa | Prezzo | Note |
|---|---|---|
| **Colori** (il neon di tutte le modalità) | Comune gratis · Raro 0,99 € · Epico 1,99 € · Leggendario 3,99 € | NEON di base; GHIACCIO con 25 punti in ZIGZAG, DESERTO con 500 in DINO; TRAMONTO e ACIDO rari, ORO epico (luccica), ARCOBALENO leggendario (i colori scorrono) |
| **Pallina** (ZIGZAG e TORRE) | come sopra | CLASSICA di base; ANELLO con 25 punti in TORRE; DIAMANTE e PIXEL rari, COMETA epica (coda di luce), SUPERNOVA leggendaria (stella, scia di stelle, PERFETTO che esplodono con un suono in più) |
| **Rimuovi annunci** | 2,99 € | Niente più annunci né banner, e l'SDK di AdMob non parte più dall'avvio dopo. Niente vite: si gioca senza limiti. CONTINUA usa i gettoni: 10 in regalo con l'acquisto |
| **Gettoni** | 10 a 0,99 € · 30 a 1,99 € · 100 a 4,99 € | Un gettone = un CONTINUA senza video, per chiunque. Chi ha tolto gli annunci e li finisce, da CONTINUA arriva al negozio |
| **Collezione completa** | 9,99 € | Tutti gli stili a pagamento, anche quelli futuri, più Rimuovi annunci |

- Nel negozio toccare una scheda la prova subito sul gioco dietro, anche se non è tua; il pulsante grande dice cosa fare: USA, ACQUISTA con il prezzo dello store, BLOCCATO con il record che manca.
- I prezzi mostrati sono quelli dello store, nella valuta del giocatore. Quelli in `scripts/catalog.gd` servono solo come fasce da impostare negli store e per gli acquisti finti in editor.
- **RIPRISTINA** recupera gli acquisti fatti su un altro telefono o prima di reinstallare (Apple lo richiede). Gli oggetti comprati una volta tornano anche da soli all'avvio; i gettoni, come in tutti i giochi senza account, restano sul telefono.
- **Plugin**: [godot-iap](https://github.com/hyodotdev/openiap/tree/main/libraries/godot-iap) 4.2.0 (OpenIAP, licenza MIT) in `addons/godot-iap`, già attivo: Google Play Billing su Android, StoreKit 2 su iOS. Richiede iOS 17. Nell'editor l'Output mostra all'avvio tre righe rosse "No GDExtension library found…": sono normali, il plugin ha codice nativo solo per i telefoni. I prodotti da creare negli store sono in [PUBBLICAZIONE.md](PUBBLICAZIONE.md#7-acquisti-in-app).
- **Dall'editor (F5)** gli acquisti sono finti e vanno sempre a buon fine: si prova tutto il giro senza telefono. Nei test headless e su desktop esportato non c'è niente in vendita.
- Nessun server: un acquisto che lo store dà per pagato viene dato sul telefono. Per oggetti estetici e un salvataggio locale una verifica su server proteggerebbe poco.

## Annunci

Plugin [AdMob di Poing Studios](https://github.com/poingstudios/godot-admob-plugin) v5.1.0 in `addons/admob` (licenza MIT), già attivo.

- **Solo a gioco fermo**: mai durante una partita.
- **Interstitial**: appena finisce una partita, prima del pannello col punteggio. Al massimo uno ogni 3 partite e ogni 90 secondi (`scripts/ad_pacing.gd`). RIPROVA fa sempre ripartire subito.
- **Banner**: solo nella schermata iniziale (la scelta della modalità), in basso, con i pulsanti sollevati sopra di lui; sparisce appena parte la partita.
- **Video con premio**: CONTINUA nel game over (quando non hai gettoni) e RICARICA quando le vite sono finite.
- **Vite** (`scripts/lives.gd`): 5. Ogni partita ne usa una, CONTINUA no. Ne torna una ogni 15 minuti, oppure tutte con un video. Esistono solo dove ci sono gli annunci: su desktop, nei test e per chi ha tolto gli annunci si gioca senza limiti.
- **Niente annunci** (né banner, né vite) per chi ha comprato Rimuovi annunci o la Collezione completa.
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
| `scripts/game.gd` | Flusso: modalità, stati, input, camera, shake, vibrazione, salvataggio, continua, negozio, annunci tra le partite, DINO dopo 3 giorni |
| `scripts/hud.gd` | UI costruita in codice: punteggio, combo, start con scelta della modalità, game over, pausa, continua, privacy |
| `scripts/shop_panel.gd` | UI del negozio: schede con rarità e prezzo, prova, acquisto, ripristino |
| `scripts/ui_kit.gd` | Mattoncini comuni della UI: colori, font, scritte, pulsanti, pannelli |
| `scripts/ball_look.gd` | Disegno degli stili della pallina (scia e pallina), in ZIGZAG, TORRE e nel negozio |
| `scripts/sfx.gd` | Suoni sintetizzati all'avvio, nessun file audio |
| `scripts/ads.gd` | Quello che il gioco sa degli annunci: ID, "c'è un video pronto?", interstitial quando è il momento, banner del menu |
| `scripts/admob_backend.gd` | Unico file che usa il plugin AdMob: consenso, avvio SDK, caricamento e visualizzazione |
| `scripts/ad_pacing.gd` | Regole pure su quando mostrare un interstitial |
| `scripts/lives.gd` | Regole pure delle vite: una a partita, ritorno col tempo, ricarica |
| `scripts/lives_view.gd` | Cuori disegnati in codice, col tempo che manca alla prossima vita |
| `scripts/catalog.gd` | Cosa c'è nel negozio: stili con rarità, colori di ogni palette, extra, ID dei prodotti, fasce di prezzo |
| `scripts/inventory.gd` | Regole pure di cosa possiedi e indossi: stili, gettoni, niente annunci, salvataggio |
| `scripts/streak.gd` | Regole pure dei giorni di fila che aprono DINO |
| `scripts/shop.gd` | Quello che il gioco sa degli acquisti: prezzi, compra, ripristina; acquisti finti in editor |
| `scripts/iap_backend.gd` | Unico file che usa il plugin godot-iap: connessione, prezzi, acquisti, ripristino |
| `tests/test_track.gd` | Test headless delle regole di ZIGZAG, compreso il "continua" |
| `tests/test_tower.gd` | Test headless delle regole di TORRE |
| `tests/test_runner.gd` | Test headless delle regole di DINO |
| `tests/test_ad_pacing.gd` | Test headless della frequenza degli annunci |
| `tests/test_lives.gd` | Test headless delle vite |
| `tests/test_shop.gd` | Test headless del negozio: catalogo, possesso, gettoni, salvataggio, giorni di fila |
| `tests/test_iap_backend.gd` | Test headless del collegamento agli store, con un finto plugin (`tests/fake_iap.gd`, `tests/fake_iap_types.gd`) |
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
godot --headless --path . --script res://tests/test_lives.gd
godot --headless --path . --script res://tests/test_shop.gd
godot --headless --path . --script res://tests/test_iap_backend.gd
```

Controllano che un giocatore perfetto sopravviva su 60 percorsi diversi per modalità (in DINO fino alla velocità massima), che gli angoli restino sempre nello schermo, che dopo ogni buco ci sia rampa per reagire, che ogni gruppo di cactus sia superabile con un margine, che "presto/tardi/non saltare" sia corretto, il conteggio dei perfetti e la rampa di difficoltà. Controllano anche che "continua" valga una volta sola, mantenga il punteggio e riparta piano, che gli interstitial rispettino le pause e che le vite si spendano, tornino col tempo senza superare il massimo e non si possano ottenere spostando l'orologio. Per il negozio: che ogni prodotto abbia un ID valido e un prezzo, che gli stili si sblocchino coi record giusti, che i gettoni non si contino due volte e non vadano sotto zero, che i 10 gettoni in regalo arrivino una volta sola, che il salvataggio ignori dati strani, e che DINO si apra al terzo giorno di fila e non prima. Il collegamento agli store è provato contro un finto plugin: prezzi, acquisto, annullato, errore, pagamento approvato dopo, prodotto già posseduto, ripristino. Durano qualche secondo.

## Export su telefono

I preset Android (AAB firmato, build Gradle, permessi INTERNET e VIBRATE) e iOS (progetto Xcode, solo iPhone, iOS 17+) sono già in `export_presets.cfg`. Strumenti da installare, chiavi di firma e invio agli store: **[PUBBLICAZIONE.md](PUBBLICAZIONE.md)**.

Prova veloce su Android: template di export, JDK 17 e Android SDK installati, *Project → Install Android Build Template*, telefono in debug USB, poi il pulsante Android in alto a destra nell'editor.

## Prossimi passi

1. Playtest su telefono vero: tarare `W_START`, `W_STEP`, `V_START`, `V_STEP`, `PERFECT_FRAC` in `track.gd`, le costanti in cima a `tower.gd` e `runner.gd`, più `REVIVE_SLOW`, la frequenza degli annunci in `ad_pacing.gd` e le vite in `lives.gd` (`MAX`, `REFILL_SECONDS`).
2. Sfida giornaliera: `Track.new(width, height, seed)` accetta già un seed, basta derivarlo dalla data.
3. Creare i prodotti negli store e provarli con un account di test ([PUBBLICAZIONE.md](PUBBLICAZIONE.md#7-acquisti-in-app)).
4. Traduzione inglese; skin del Dino nel negozio.

Font: Bungee e Chakra Petch, licenza SIL Open Font License (file in `assets/fonts`).
