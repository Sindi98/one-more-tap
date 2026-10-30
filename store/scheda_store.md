# Scheda store: testi pronti da incollare

Limiti di lunghezza tra parentesi. Le immagini sono in questa cartella:

| File | Dove va |
|---|---|
| `icon_512.png` | Google Play, icona dell'app (512×512) |
| `feature_graphic_1024x500.png` | Google Play, grafica in evidenza (italiano) |
| `feature_graphic_1024x500_en.png` | Google Play, grafica in evidenza (inglese) |
| `screenshots/android/*.png`, `screenshots/android_en/*.png` | Google Play, screenshot telefono (1080×1920), italiano e inglese |
| `screenshots/iphone/*.png`, `screenshots/iphone_en/*.png` | App Store, iPhone 6,9" (1320×2868), italiano e inglese |

L'icona dell'App Store (1024×1024) la prende Godot da `assets/icons/icon_1024.png` durante l'export.

Gli screenshot sono catturati dal gioco vero, nelle due lingue dell'interfaccia. Se cambi la grafica, rifalli dal telefono o dall'editor. **Gli screenshot attuali mostrano solo ZIGZAG**: vanno rifatti seguendo [Screenshot da rifare](#screenshot-da-rifare).

## Perché i testi sono scritti così

Sono ottimizzati per le ricerche negli store (ASO):

- **Le ricerche che il gioco copre davvero** sono nel nome, nel sottotitolo e all'inizio delle descrizioni: *air hockey*, *giochi con amici / multiplayer*, *offline / senza internet*, *dino*, *sfida giornaliera*. Prima la scheda parlava quasi solo di ZIGZAG.
- **App Store**: nome, sottotitolo e parole chiave si sommano. Una parola già nel nome o nel sottotitolo (per esempio *tap*, *arcade*, *hockey*) non va ripetuta nelle parole chiave: è spazio sprecato. Le parole si combinano da sole (*air* nelle parole chiave + *hockey* nel nome = "air hockey").
- **Google Play** non ha un campo parole chiave: legge titolo, descrizione breve e descrizione completa. Le parole importanti compaiono qualche volta nella descrizione, in frasi naturali (ripeterle a raffica viola le regole di Play).
- **Niente marchi altrui** nelle parole chiave e nel titolo (per esempio "Chrome" per DINO): Apple rifiuta l'app, Google la può sospendere. Niente "gratis", "n. 1" o "migliore" nel titolo.
- **Ogni lingua è una scheda in più**: le traduzioni sono in fondo. Vanno messe in Play Console (*Presenza nello store → Schede dello store → Gestisci traduzioni*) e in App Store Connect (*lingua* in alto a destra nella pagina della versione), anche se il gioco in quella lingua non ci fosse.
- Dopo un mese guarda in Play Console (*Statistiche → Acquisizione*) e in App Store Connect (*App Analytics → Fonti*) con quali ricerche arrivano i giocatori, e sostituisci le parole chiave che non portano nessuno.

---

## Italiano

**Nome** (Play 30, App Store 30)
One More Tap: Arcade & Hockey

**Sottotitolo App Store** (30)
Giochi a un tap, anche offline

**Descrizione breve Google Play** (80)
3 giochi arcade a un dito e AIR HOCKEY con gli amici. Sfida del giorno, offline.

**Parole chiave App Store** (100, separate da virgola, senza spazi)
air,amici,multiplayer,dino,senza,internet,wifi,zigzag,torre,neon,riflessi,record,sfida,giornaliera

**Testo promozionale App Store** (170, si cambia senza nuova versione)
Novità: la SFIDA del giorno! Stesso percorso per tutti, ogni giorno uno nuovo. Fai il tuo punteggio e manda la sfida agli amici.

**Descrizione completa** (Play 4000, App Store 4000)

Giochi arcade a un dito e AIR HOCKEY con gli amici, in un'unica app. Si impara in tre secondi, si gioca anche offline.

ZIGZAG: la pallina sale da sola e tu hai un solo comando. Tocca, e lei gira di 90°. Gira dentro l'angolo: troppo presto cadi di lato, troppo tardi voli fuori dalla piattaforma. Al centro esatto dell'angolo fai un PERFETTO: punto bonus e la combo sale di nota. Le piattaforme si stringono, la pallina accelera, i colori cambiano.

TORRE: sali una spirale intorno a una torre che gira e salta i buchi della rampa, sempre più veloce, a ritmo.

DINO: corri e salta cactus e uccelli, come nel gioco del browser senza internet. Si apre giocando tre giorni di fila.

AIR HOCKEY con gli amici: crea una lobby sulla stessa Wi-Fi (non serve internet) o online, manda il codice in chat, dividetevi in squadre, 1 contro 1 o 2 contro 2, e trascinate la racchetta. Se manca qualcuno gioca la CPU, così puoi allenarti anche da solo. Senza account.

SFIDA DEL GIORNO: ogni giorno un percorso nuovo, lo stesso per tutti. Niente CONTINUA: conta solo la tua abilità. Fai il tuo punteggio e sfida gli amici a batterlo.

• Tre modalità arcade a un dito, ognuna col suo record
• AIR HOCKEY multiplayer con gli amici, in Wi-Fi o via internet, senza account
• Sfida del giorno: lo stesso percorso per tutti, ogni giorno nuovo
• Gioco offline: ZIGZAG, TORRE e DINO funzionano senza internet
• Partite da pochi secondi, perfette per una pausa
• PERFETTO e combo musicali per chi cerca la precisione
• Grafica neon, musica e suoni arcade
• Stili da collezionare per i colori e la pallina, dal comune al leggendario: alcuni si sbloccano coi record
• Condividi l'immagine del tuo record e sfida gli amici

Gioco gratuito con pubblicità. Dopo una caduta puoi guardare un breve video per ripartire da dove eri, una volta per partita.

Acquisti facoltativi: stili per colori e pallina, gettoni per continuare senza video, Rimuovi annunci (niente pubblicità e partite senza limiti) e la Collezione completa con tutti gli stili. Compri sempre esattamente quello che vedi, niente casse a sorpresa, e nessun acquisto aiuta a vincere.

---

## English

**Name** (30)
One More Tap: Arcade & Hockey

**App Store subtitle** (30)
One-tap games, even offline

**Google Play short description** (80)
3 one-finger arcade games + AIR HOCKEY with friends. Daily challenge. Offline.

**App Store keywords** (100)
air,friends,multiplayer,dino,no,wifi,internet,zigzag,tower,neon,reflex,highscore,daily,challenge

**App Store promotional text** (170)
New: the DAILY challenge! The same track for everyone, a new one every day. Set your score and send the challenge to your friends.

**Full description**

One-finger arcade games and AIR HOCKEY with friends, in one app. Learn it in three seconds, play it offline.

ZIGZAG: the ball climbs on its own and you have one control. Tap, and it turns 90°. Turn inside the corner: too early and you fall off the side, too late and you fly off the end. Turn right in the middle of the corner for a PERFECT: a bonus point, and your combo climbs the scale. Platforms get narrower, the ball gets faster, colours shift.

TOWER: climb a spiral round a spinning tower and jump the holes in the ramp, faster and faster, in rhythm.

DINO: run and jump cacti and birds, like in the browser's no-internet game. It opens when you play three days in a row.

AIR HOCKEY with friends: create a lobby on the same Wi-Fi (no internet needed) or online, send the code in a chat, split into teams, 1 vs 1 or 2 vs 2, and drag your mallet. If someone's missing, the CPU plays, so you can practise on your own too. No account needed.

DAILY CHALLENGE: a new track every day, the same for everyone. No CONTINUE: only your skill counts. Set your score and challenge your friends to beat it.

• Three one-finger arcade modes, each with its own best score
• Multiplayer AIR HOCKEY with friends, on Wi-Fi or over the internet, no account
• Daily challenge: the same track for everyone, a new one every day
• Offline games: ZIGZAG, TOWER and DINO work with no internet
• Runs last seconds, perfect for a short break
• PERFECT turns and musical combos for precision players
• Neon visuals, arcade music and sounds
• Collectible styles for the colours and the ball, from common to legendary: some unlock with your best scores
• Share a picture of your best run and challenge your friends

Free to play with ads. After a fall you can watch a short video to carry on from where you were, once per run.

Optional purchases: styles for the colours and the ball, tokens to continue without a video, Remove Ads (no ads and unlimited runs) and the Full Collection with every style. You always buy exactly what you see, no mystery boxes, and nothing you buy helps you win.

---

## Screenshot da rifare

Gli store mostrano i primi 2–3 screenshot nei risultati di ricerca: lì si decide se uno apre la scheda. Uno screenshot per idea, con una **didascalia grande in alto** (font Bungee, colore neon del gioco) sopra la schermata vera. Ordine consigliato:

| # | Schermata da catturare | Didascalia IT | Didascalia EN |
|---|---|---|---|
| 1 | ZIGZAG in partita, con PERFETTO ×3 a schermo | UN DITO. OGNI TAP CONTA. | ONE FINGER. EVERY TAP COUNTS. |
| 2 | AIR HOCKEY 2 contro 2 in partita | AIR HOCKEY CON GLI AMICI | AIR HOCKEY WITH FRIENDS |
| 3 | Game over della SFIDA con il punteggio | SFIDA DEL GIORNO: BATTI I TUOI AMICI | DAILY CHALLENGE: BEAT YOUR FRIENDS |
| 4 | TORRE in partita, a metà di un salto | SALTA I BUCHI DELLA TORRE | JUMP THE HOLES IN THE TOWER |
| 5 | DINO in partita, sopra un gruppo di cactus | DINO: ANCHE SENZA INTERNET | DINO: NO INTERNET NEEDED |
| 6 | Lobby di AIR HOCKEY con le squadre e il codice | WI-FI O ONLINE, SENZA ACCOUNT | WI-FI OR ONLINE, NO ACCOUNT |
| 7 | Negozio con uno stile leggendario provato sul gioco | STILI DA COLLEZIONARE | COLLECT NEON STYLES |

Anche la **grafica in evidenza** di Google Play (1024×500) va rifatta con le quattro modalità, per esempio la pallina di ZIGZAG a sinistra e il tavolo di AIR HOCKEY a destra, con "3 GIOCHI A UN DITO + AIR HOCKEY".

## Video di anteprima

Facoltativo ma utile: su Play è un video YouTube (orizzontale o verticale, 30 s–2 min, link in Play Console), sull'App Store un "App Preview" (15–30 s, registrato dal telefono, senza mani né cornici). Scaletta da 25 secondi:

1. 0–4 s: ZIGZAG, catena di PERFETTO col suono che sale (il gancio: si capisce in un attimo)
2. 4–9 s: TORRE, una catena di buchi saltata a ritmo
3. 9–13 s: DINO, salto sopra un gruppo di cactus
4. 13–20 s: AIR HOCKEY 2 contro 2, un gol
5. 20–25 s: game over della SFIDA DEL GIORNO, poi il logo

Per l'App Store la musica deve essere quella del gioco. Su YouTube attenzione al Content ID dei brani Pixabay (vedi la sezione Musica del README).

---

## Altri campi

- **Categoria**: Giochi → Arcade (Play) · Giochi → Arcade, secondaria Casual (App Store)
- **Tag di Google Play** (*Presenza nello store → Tag dello store*): Arcade, Casual, Multiplayer, Offline, Single player
- **Contiene annunci**: Sì
- **Acquisti in-app**: Sì, da 0,99 € a 9,99 € (prodotti e ID in `PUBBLICAZIONE.md`, passo 7)
- **Sito web / email di supporto**: `https://sindi98.github.io/one-more-tap/` · [EMAIL DI CONTATTO]
- **Informativa privacy**: `https://sindi98.github.io/one-more-tap/privacy.html`
- **Note per la revisione Apple**: "Free arcade game with AdMob ads. Ads never appear during play. Interstitials appear only when a run has ended (at most every 3 runs and 90 seconds); a banner shows on the mode selection screen only. Each run costs one of 5 lives, which come back over time or all at once with an optional rewarded video; another optional rewarded video lets the player continue a run once. No login required. In-app purchases are in STILI on the start screen: cosmetic styles (non-consumable), Remove Ads (non-consumable: no ads, no banner and no lives limit from then on), Full Collection (non-consumable) and token packs (consumable, one token continues a run without a video). RIPRISTINA restores purchases. The third mode, DINO, opens after the game is opened on three days in a row; the other two modes are available at once. SFIDA (next to STILI) turns on the daily challenge: the same track for every player that day, with no continue. AIR HOCKEY (next to SFIDA) is a multiplayer mode: one player creates a lobby, on the same Wi-Fi (WI-FI: direct, no server; the others join from the list or with its 4-character code) or online (ONLINE: through our relay server; the others type its 5-character code). Online lobbies are private, joined by code only, with no chat. Empty places are played by the CPU, so it can be tried on a single device: AIR HOCKEY, then WI-FI or ONLINE, then INIZIA. The Local Network permission is used only for Wi-Fi lobbies."
