# Pubblicare One More Tap su Google Play, App Store e itch.io

Il codice è pronto. Quello che resta sono account, chiavi e moduli che solo tu puoi compilare. Segui i passi in ordine: ognuno dice dove cliccare e cosa scrivere. Gli aspetti legali e burocratici (i tuoi dati nei documenti, operatore commerciale, tasse, marchio) sono in **[LEGALE.md](LEGALE.md)**: leggilo prima del passo 2.

## Cosa c'è già nel progetto

| Cosa | Dove |
|---|---|
| Plugin AdMob (Poing Studios v5.1.0), già attivo | `addons/admob/` |
| Annunci: consenso GDPR, interstitial a fine partita, banner nel menu, video "Continua" e "Ricarica", vite | `scripts/ads.gd`, `scripts/admob_backend.gd`, `scripts/ad_pacing.gd` |
| Negozio: stili con rarità, gettoni, Rimuovi annunci, Collezione completa, ripristino | `scripts/catalog.gd`, `scripts/shop.gd`, `scripts/iap_backend.gd`, `scripts/shop_panel.gd` |
| Plugin acquisti in-app godot-iap 4.2.0, già attivo | `addons/godot-iap/` |
| Plugin di condivisione e recensione in-app (Android e iOS), già attivi | `addons/SharePlugin/`, `addons/InappReviewPlugin/`, `ios/plugins/` |
| AIR HOCKEY a squadre in Wi-Fi, senza server: permesso Android per gli annunci delle lobby e testo del permesso "Rete locale" di iOS già nei preset | `scripts/net.gd`, `export_presets.cfg` |
| AIR HOCKEY via Internet: il relay da mettere online (passo 10) | `server/`, `scripts/relay_peer.gd` |
| Preset di export Android (AAB firmato), iOS (progetto Xcode) e Web (itch.io) | `export_presets.cfg` |
| Icone (iOS 1024, Android adattiva e monocromatica) | `assets/icons/` (le rigeneri con `tools/make_icons.gd`) |
| Pagina del gioco (dove porta il link condiviso), informativa privacy e termini d'uso (IT + EN), da pubblicare online | `docs/index.html`, `docs/privacy.html`, `docs/terms.html` |
| Schermata INFO nel gioco: privacy, termini, contatti, crediti e licenze di terzi | `scripts/info_panel.gd` |
| Aspetti legali e burocrazia, con il registro dei trattamenti | `LEGALE.md` |
| Testi, screenshot, icona 512 e grafica 1024×500 per gli store, in italiano e inglese | `store/` |

Finché non inserisci i tuoi ID, il gioco mostra **annunci di prova di Google**. Nelle build di debug li mostra sempre, anche dopo. È voluto: toccare i tuoi annunci veri può far sospendere l'account AdMob.

## Come funzionano gli annunci nel gioco

- **Video "Continua"**: dopo una caduta compare il pulsante CONTINUA, se un video è pronto e la partita valeva almeno 5 punti. Se guardi il video fino in fondo, la pallina torna all'inizio della piattaforma dove sei caduto e riparte rallentata. Vale una volta per partita.
- **Interstitial**: compare appena finisce una partita, a gioco fermo, prima del pannello col punteggio. Al massimo uno ogni 3 partite e ogni 90 secondi, e mai subito dopo un video. Le soglie sono in cima a `scripts/ad_pacing.gd`.
- **Vite**: 5, una per partita; ne torna una ogni 15 minuti. Quando finiscono, il pulsante RICARICA mostra un video con premio che le ridà tutte.
- **Banner**: solo nella schermata iniziale, dove si sceglie la modalità. Sta lungo il bordo in basso, con uno spazio tra lui e i pulsanti: in un gioco a un dito un banner vicino ai controlli prende tocchi per sbaglio, e le regole di AdMob li vietano. Durante la partita e negli altri pannelli è nascosto.
- **Mai durante una partita.**
- **Consenso**: al primo avvio, in UE, Regno Unito e Svizzera, compare il modulo di Google. Il pulsante CONSENSO nei menu lo riapre (è obbligatorio). INFO, accanto, porta all'informativa e ai termini.
- **Dal editor (F5)** vedi annunci finti disegnati dal plugin, così puoi provare tutto il giro senza telefono.
- **Rimuovi annunci** (o la Collezione completa): niente più annunci né banner, e dall'avvio dopo l'SDK di Google non parte nemmeno. Niente vite, si gioca senza limiti. CONTINUA usa i gettoni.

Il gioco è in italiano per chi ha il telefono in italiano e in inglese per tutti gli altri. Per questo le schede degli store vanno compilate in tutte e due le lingue (passi 4 e 5).

---

## 1. Decidi l'identificativo dell'app (una volta sola)

Nei preset è impostato `com.sindi98.onemoretap`. Dopo la prima pubblicazione **non si può più cambiare**. Se vuoi un altro nome (per esempio `it.tuonome.onemoretap`), cambialo adesso in *Project → Export*:

- Android → *Package → Unique Name*
- iOS → *Application → Bundle Identifier*

## 2. Informativa privacy, termini e pagina del gioco online

Entrambi gli store chiedono l'informativa, e il gioco la apre da INFO → PRIVACY, accanto ai termini d'uso (INFO → TERMINI). La pagina `index.html` è quella del gioco: ci arriva chi riceve un punteggio condiviso, ci porta il pulsante SCARICA della versione web, e fa da URL di supporto per gli store.

1. Inserisci i tuoi dati (nome, indirizzo, email, partita IVA se ce l'hai, fornitore del relay) in `docs/privacy.html`, `docs/terms.html`, `docs/index.html`, `scripts/info_panel.gd` e `LICENSE`: l'elenco dei segnaposto e il comando per trovare quelli rimasti sono in [LEGALE.md](LEGALE.md#1-i-dati-da-inserire). Ti consiglio un indirizzo email dedicato al gioco. Sono modelli: se hai dubbi legali, falli controllare.
2. Su GitHub: *Settings → Pages → Build and deployment → Deploy from a branch → `master` / `/docs`*. Dopo un minuto le pagine sono su `https://sindi98.github.io/one-more-tap/`, `https://sindi98.github.io/one-more-tap/privacy.html` e `https://sindi98.github.io/one-more-tap/terms.html`.
   - Con un repository privato, GitHub Pages richiede un piano a pagamento. In alternativa carica i file su un altro hosting.
3. Se l'indirizzo è diverso, aggiorna `PRIVACY_URL` in `scripts/ads.gd` e `SITE_URL` in `scripts/social.gd` (i termini sono `terms.html` accanto a `SITE_URL`).
4. Finché l'app non è sugli store, la pagina del gioco dice "In arrivo su Google Play e App Store". I link li aggiungi dopo la pubblicazione (passo 9).

## 3. AdMob

1. Crea l'account su [admob.google.com](https://admob.google.com) e inserisci i dati di pagamento.
2. *App → Aggiungi app*, due volte: una per **Android** e una per **iOS**. Alla domanda "è già su uno store?" rispondi no; collegherai lo store dopo la pubblicazione.
3. In ogni app crea tre **unità pubblicitarie**:
   - **Interstitial**, nome "Fine partita"
   - **Con premio** (Rewarded), nome "Continua e vite", premio `1` `continue` (la stessa unità serve sia per CONTINUA sia per RICARICA)
   - **Banner** (adattivo), nome "Menu"
4. Copia gli ID:
   - **ID app** (contiene `~`): *Project → Project Settings → General → Admob → General*, nei campi Android e iOS **App Id**.
   - **ID unità** (contengono `/`): `scripts/ads.gd`, costante `LIVE_IDS`.
5. **Messaggio GDPR** (obbligatorio per servire annunci in UE): *Privacy e messaggi → Normative europee → Crea messaggio*. Seleziona le due app, inserisci l'URL dell'informativa, lascia i partner pubblicitari predefiniti e **pubblica**. Senza messaggio pubblicato, il modulo di consenso non compare e in UE gli annunci restano quasi vuoti.
6. (Consigliato) **app-ads.txt**: AdMob ti dà una riga da pubblicare in `https://<tuo-sito>/app-ads.txt`. Il sito deve essere quello indicato nelle schede store e il file deve stare alla radice del dominio. Con GitHub Pages serve un repository chiamato `sindi98.github.io`. Senza il file gli annunci funzionano, ma rendono meno.

## 4. Google Play (Android)

### Preparare Godot (una volta)

1. *Editor → Manage Export Templates → Download and Install* (4.7).
2. Installa **JDK 17** e **Android SDK** (il modo più semplice è installare Android Studio), poi impostali in *Editor → Editor Settings → Export → Android* (Java SDK Path e Android SDK Path).
3. *Project → Install Android Build Template*. Serve perché il plugin AdMob richiede la build Gradle. La cartella `android/` creata non va su git (è già in `.gitignore`).
4. *Project → Tools → AdMob Manager → Android → Download & Install*. Di solito lo fa da solo all'apertura del progetto.

### Chiave di firma (una volta, poi custodiscila)

```bash
keytool -genkeypair -v -keystore one-more-tap-upload.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Tienila **fuori dal repository**, con la password, in un posto sicuro (gestore di password più backup). Se la perdi, Google può reimpostarla ma ci vogliono giorni.

In *Project → Export → Android → Keystore → Release* inserisci file, alias (`upload`) e password. Godot salva queste credenziali in `.godot/export_credentials.cfg`, che non finisce su git.

### Esportare

1. Prova prima sul telefono: debug USB attivo, poi il pulsante Android in alto a destra nell'editor. Vedrai annunci etichettati "Test Ad" e, in Italia, il modulo del consenso.
2. *Project → Export → Android → Export Project*, togli la spunta "Export With Debug" e salva `one-more-tap.aab`.

### Play Console

1. Registrati su [play.google.com/console](https://play.google.com/console): 25 $ una tantum, più verifica dell'identità.
2. *Crea app*: nome "One More Tap", lingua predefinita italiano, Gioco, Gratuito.
3. **Account personali nuovi**: prima della produzione Google chiede un **test chiuso con almeno 12 tester per 14 giorni di fila**. Carica l'AAB in *Test → Test chiuso*, invita amici e familiari (email o Google Group) e aspetta i 14 giorni. Poi chiedi l'accesso alla produzione.
4. *Contenuti dell'app* (menu Policy):
   - **Norme sulla privacy**: l'URL del passo 2.
   - **Annunci**: Sì, l'app contiene annunci.
   - **Accesso all'app**: tutte le funzionalità sono disponibili senza restrizioni.
   - **ID pubblicità**: Sì, lo usa (AdMob), per Pubblicità, Analisi e Prevenzione frodi. Il permesso `AD_ID` lo aggiunge già l'SDK.
   - **Classificazione dei contenuti**: questionario IARC, categoria Gioco. Nessuna violenza. Interazione tra utenti: **sì**, solo in AIR HOCKEY, tra telefoni sulla stessa Wi-Fi o, online, tra chi ha il codice della lobby: si vedono i nomi scelti dai giocatori, non c'è chat né scambio di contenuti, e non si incontrano sconosciuti (le lobby online non sono elencate). Acquisti digitali: **sì**; oggetti casuali a pagamento (loot box): **no**.
   - **Pubblico di destinazione**: scegli solo fasce **13 anni e oltre**. Se includi i minori di 13 anni si applicano le norme Famiglie, con regole molto più rigide sugli annunci.
   - **Stato di operatore commerciale** (Digital Services Act), nelle impostazioni dell'account sviluppatore: vedi [LEGALE.md](LEGALE.md#5-digital-services-act-sei-un-operatore-commerciale).
   - **Sicurezza dei dati**: dichiara quello che raccoglie l'SDK di Google, come indicato in [questa pagina di Google](https://developers.google.com/admob/android/privacy/play-data-disclosure). In pratica: dati raccolti e condivisi, cifrati in transito. Tipi: *Posizione approssimativa* (dall'IP), *ID dispositivo o altri ID*, *Attività nell'app* (interazioni), *Informazioni e prestazioni dell'app* (arresti anomali, diagnostica). Finalità: pubblicità o marketing, analisi, prevenzione delle frodi. Il gioco non ha account, quindi non c'è un meccanismo di cancellazione dati. Il nome scelto in AIR HOCKEY passa solo agli altri telefoni della lobby: in Wi-Fi direttamente; online attraverso il tuo relay (passo 10), che lo inoltra senza salvarlo, come l'indirizzo IP del telefono. Se pubblichi il relay, dichiara il nome come *Informazioni personali → Nome* (o *Altri dati*, se lo consideri un soprannome), facoltativo, usato per la funzionalità dell'app, **trattato in modo temporaneo** e non condiviso con terze parti; cifrato in transito (`wss://`). Senza relay, in Wi-Fi soltanto, di solito non va dichiarato.
5. *Scheda dello store principale*: testi in `store/scheda_store.md`, icona `store/icon_512.png`, grafica `store/feature_graphic_1024x500.png`, screenshot `store/screenshots/android/`.
   - Poi *Gestisci traduzioni → Aggiungi traduzioni → Inglese (Stati Uniti)* (e, se vuoi, Inglese (Regno Unito)): testi inglesi dalla stessa scheda, grafica `store/feature_graphic_1024x500_en.png`, screenshot `store/screenshots/android_en/`.
6. *Produzione → Crea nuova release*, carica l'AAB e invia per la revisione (di solito da qualche ora a qualche giorno).
7. Torna in AdMob e collega l'app Android alla scheda Play.

## 5. App Store (iOS)

### Cosa serve

- Un **Mac** con l'ultima versione di **Xcode**. L'export iOS di Godot produce un progetto Xcode, e il caricamento si fa da lì.
- **Apple Developer Program**: 99 € all'anno, su [developer.apple.com/programs](https://developer.apple.com/programs/).

### Preparare (una volta)

1. In Godot sul Mac: export templates come sopra, poi *Project → Tools → AdMob Manager → iOS → Download & Install*. I plugin di condivisione e recensione sono già in `ios/plugins/` e già spuntati nel preset iOS (*Plugins*).
2. *Project → Export → iOS*: in **App Store Team ID** metti il Team ID (lo trovi in developer.apple.com → Account → Membership).
3. **AIR HOCKEY su iPhone**: il preset ha già la frase per il permesso "Rete locale" che iOS chiede la prima volta. Per far comparire le lobby nell'elenco **LOBBY VICINE** anche su iPhone, Apple richiede l'entitlement *Multicast Networking*: chiedilo da [questo modulo](https://developer.apple.com/contact/request/networking-multicast) (spiega che il gioco annuncia le lobby in broadcast sulla rete locale). Quando arriva, in Xcode aggiungi `com.apple.developer.networking.multicast` al file degli entitlement. Senza, tutto funziona lo stesso: su iPhone si entra nelle lobby con il codice.
4. Su [App Store Connect](https://appstoreconnect.apple.com): *App → + → Nuova app*, piattaforma iOS, nome "One More Tap", lingua italiano, bundle ID `com.sindi98.onemoretap` (se non compare, prima registralo in developer.apple.com → Identifiers), SKU a piacere.

### Esportare e caricare

1. *Project → Export → iOS → Export Project* in una cartella vuota fuori dal progetto, per esempio `~/Build/OneMoreTap`. Il preset crea solo il progetto Xcode; il plugin AdMob aggiunge da solo SDK, ID app e voci SKAdNetwork.
2. Apri il `.xcodeproj`. In *Signing & Capabilities* scegli il tuo team con "Automatically manage signing".
3. Prova su un iPhone collegato (Run): annunci "Test Ad" e modulo consenso.
4. *Product → Archive*, poi *Distribute App → App Store Connect → Upload*.

### App Store Connect

- **Privacy dell'app** ("etichette nutrizionali"): dichiara i dati dell'SDK di Google, come da [questa pagina](https://developers.google.com/admob/ios/privacy/data-disclosure): *Posizione approssimativa*, *ID dispositivo*, *Dati pubblicitari*, *Interazione con il prodotto*, *Dati sugli arresti anomali*, *Dati sulle prestazioni*, *Altri dati diagnostici*. Finalità: pubblicità di terze parti e analisi; non collegati all'identità. Questa versione **non** mostra la richiesta di tracciamento di Apple (ATT), quindi l'SDK non accede all'IDFA. Se marchi dei dati come "usati per il tracciamento", Apple pretende il popup ATT (vedi "Più avanti").
- Il nome di AIR HOCKEY va solo agli altri telefoni della lobby (online passando dal tuo relay, senza essere salvato): vale quanto detto per Google Play. Con il relay pubblicato, dichiaralo come *Contenuti di gioco*, *non collegato all'identità*, usato per la *Funzionalità dell'app*, non per il tracciamento.
- **Digital Services Act**: nella sezione *Business* dichiara se sei un operatore commerciale; senza questa dichiarazione l'app non viene distribuita in UE. Indirizzo, telefono ed email diventano pubblici: vedi [LEGALE.md](LEGALE.md#5-digital-services-act-sei-un-operatore-commerciale).
- **Contratto di licenza**: lascia quello standard di Apple; i termini d'uso del gioco si aggiungono a quello.
- **URL informativa privacy** e **URL di supporto** (la pagina `index.html`).
- **Classificazione per età**: compila il questionario (dal 2025 con le fasce 4+, 9+, 13+, 16+, 18+ e domande nuove: le risposte sono in [LEGALE.md](LEGALE.md#7-i-moduli-legali-degli-store-in-breve)). Il gioco non ha contenuti sensibili, ma gli annunci di terzi possono alzare la fascia: rispondi in modo coerente. Nel codice gli annunci sono limitati a contenuti per tutti con supervisione (`MAX_AD_CONTENT_RATING_PG`).
- **Crittografia**: già dichiarata nel preset (`ITSAppUsesNonExemptEncryption = NO`), Xcode non chiede nulla.
- **Screenshot**: `store/screenshots/iphone/` (6,9", 1320×2868). L'app è solo per iPhone, quindi non servono quelli per iPad.
- **Inglese**: in alto a destra nella pagina della versione, *Italiano → Aggiungi lingua → Inglese (USA)*, poi i testi inglesi della scheda e gli screenshot `store/screenshots/iphone_en/`.
- **Note per la revisione**: c'è un testo pronto in `store/scheda_store.md`.
- Seleziona la build caricata e *Invia per la revisione*.
- Dopo la pubblicazione, collega l'app iOS alla scheda in AdMob.

## 6. Ogni aggiornamento

1. Alza la versione in *Project Settings → Application → Config → Version* (per esempio `1.0.1`). La usano entrambi gli store.
2. Android: in *Export → Android* aumenta **Version → Code** di 1. Play rifiuta un codice già usato.
3. iOS: lo stesso numero di versione non si può caricare due volte. Alza la versione oppure imposta *Application → Version* (il numero di build) a `1.0.1.1`, `1.0.1.2`, …
4. Lancia i test (vedi README) e prova sul telefono prima di caricare.

## 7. Acquisti in-app

Il negozio nel gioco è pronto (regole e prezzi nel [README](README.md#acquisti-in-app)) e il plugin è già nel progetto. Mancano i prodotti negli store e una prova con un account di test.

### Il plugin (già installato)

[godot-iap](https://github.com/hyodotdev/openiap/tree/main/libraries/godot-iap) 4.2.0 (OpenIAP, licenza MIT) in `addons/godot-iap`, dallo zip ufficiale della release: Google Play Billing su Android, StoreKit 2 su iOS, una sola API. È già attivo, con l'autoload `GodotIapPlugin` che il gioco cerca all'avvio. Nei preset sono già impostati iOS minimo **17.0** (i framework del plugin lo richiedono: iPhone XS/XR e successivi) e, per Android, lo store `play` ed esclusi i file iOS del plugin.

- **Nell'editor e su desktop** l'Output mostra all'avvio tre righe rosse "No GDExtension library found… godot_iap.gdextension": è normale, il plugin ha codice nativo solo per iOS e Android. Il gioco funziona, con gli acquisti finti.
- **Android**: il plugin vuole AGP 8.9.1+, Gradle 8.11.1+, Android SDK 36 e JDK 17. Durante l'export aggiorna il template da solo; se si ferma, il messaggio dice quale versione di Gradle serve.
- **iOS**: se Xcode all'avvio dice `Library not loaded: @rpath/GodotIap.framework`, dalla cartella del progetto lancia `IOS_EXPORT_DIR=~/Build/OneMoreTap ./addons/godot-iap/scripts/fix_ios_embed.sh` (o la cartella dove hai esportato).
- **Aggiornarlo**: scarica lo zip di una release più nuova da [GitHub](https://github.com/hyodotdev/openiap/releases?q=godot-iap), sostituisci la cartella `addons/godot-iap` e lancia i test (`tests/test_iap_backend.gd` controlla il collegamento).

### I prodotti

Stessi ID su Google Play e su App Store. Il prezzo che vede il giocatore lo prende il gioco dallo store, nella sua valuta: imposta la fascia indicata e lascia che lo store converta le altre valute.

| ID prodotto | Cosa | Tipo su App Store | Prezzo |
|---|---|---|---|
| `onemoretap.no_ads` | Rimuovi annunci (+10 gettoni in regalo) | Non consumabile | 2,99 € |
| `onemoretap.collection` | Collezione completa: tutti gli stili, anche futuri, e niente annunci | Non consumabile | 9,99 € |
| `onemoretap.tokens_10` | 10 gettoni | Consumabile | 0,99 € |
| `onemoretap.tokens_30` | 30 gettoni | Consumabile | 1,99 € |
| `onemoretap.tokens_100` | 100 gettoni | Consumabile | 4,99 € |
| `onemoretap.tramonto`, `onemoretap.acido` | Colori rari | Non consumabile | 0,99 € |
| `onemoretap.diamante`, `onemoretap.pixel` | Palline rare | Non consumabile | 0,99 € |
| `onemoretap.oro`, `onemoretap.cometa` | Colori e pallina epici | Non consumabile | 1,99 € |
| `onemoretap.arcobaleno`, `onemoretap.supernova` | Colori e pallina leggendari | Non consumabile | 3,99 € |

Gli ID non si possono più riusare dopo averli creati, nemmeno cancellando il prodotto: copiali esattamente. Uno stile nuovo in futuro = una riga in `LOOKS` di `scripts/catalog.gd` + un prodotto con lo stesso ID negli store. Chi ha la Collezione lo riceve senza fare niente.

### Google Play

1. *Impostazioni → Profilo pagamenti*: crea il profilo commerciante (serve per vendere, una volta per account).
2. Carica in un test (per esempio il test chiuso del passo 4) una build **con il plugin**: Play permette di creare prodotti solo dopo aver visto un'app che usa la fatturazione.
3. *Monetizza con Play → Prodotti → Prodotti in-app* (prodotti una tantum): per ogni riga della tabella **Crea prodotto** con ID, nome, descrizione e prezzo, poi **Attiva**. Su Play non si sceglie se è consumabile: lo decide il gioco.
4. *Impostazioni → Test delle licenze*: aggiungi i Gmail tuoi e dei tester. Comprano con carte di prova e non pagano nulla.
5. La scheda dello store mostra da sola "Acquisti in-app". Nella *Sicurezza dei dati* non c'è niente da aggiungere: il gioco non manda gli acquisti a nessun server, li gestisce Google Play.

### App Store

1. *Business* (un tempo *Accordi, imposte e banche*): firma l'accordo **App a pagamento**, inserisci conto bancario e moduli fiscali (il W-8BEN, vedi [LEGALE.md](LEGALE.md#6-tasse)). Senza, i prodotti restano "in attesa".
2. *App → Monetizzazione → Acquisti in-app → +*, per ogni riga della tabella: tipo (Consumabile o Non consumabile), nome di riferimento, ID prodotto, fascia di prezzo, nome e descrizione in italiano (e inglese), **screenshot per la revisione** (uno del negozio con quella scheda scelta, dall'editor va benissimo) e una nota se serve.
3. Al primo invio, nella pagina della versione, sezione *Acquisti in-app e abbonamenti*, seleziona tutti i prodotti: vengono rivisti insieme alla build.
4. *Utenti e accesso → Sandbox → Tester*: crea un account di prova. Su iPhone, *Impostazioni → App Store → Account sandbox*, accedi con quello e compra senza pagare.
5. **Privacy dell'app**: come per Play, il gioco non raccoglie gli acquisti (non li manda a un server): non va aggiunto "Acquisti". Se un giorno aggiungerai un server per verificarli, andrà dichiarato.
6. **Classificazione per età**: rispondi che ci sono acquisti in-app; casse o oggetti casuali: no.

### Prova sul telefono

Con un tester di Play o l'account sandbox di Apple, su una build di release:

- I prezzi compaiono sulle schede (al posto di "—"). Se restano "—", di solito il prodotto non è attivo o l'ID è scritto diverso.
- Uno stile comprato si indossa subito; disinstalla, reinstalla, apri il negozio: è ancora tuo (su iPhone, se non torna da solo, tocca RIPRISTINA).
- Rimuovi annunci: niente interstitial né banner, spariscono le vite, CONTINUA usa i gettoni (10 in regalo). Chiudi e riapri il gioco: il modulo del consenso non compare più.
- Finiti i gettoni, CONTINUA porta al negozio; comprati, si torna al game over e si continua.

## 8. Versione web su itch.io

Una versione da giocare nel browser, gratis e senza annunci: serve a far provare il gioco in un clic e a portare chi si diverte verso gli store (pulsante SCARICA in alto). Non ha vite e non mostra annunci; i record restano nel browser.

### Esportare

1. *Editor → Manage Export Templates*: se hai già scaricato i template per Android/iOS, ci sono anche quelli web.
2. *Project → Export → Web → Export Project*, togli la spunta "Export With Debug" e salva come `export/web/index.html` (la cartella `export/` non va su git).
3. Comprimi **il contenuto** della cartella `export/web` in uno zip (`index.html` deve stare alla radice dello zip, non dentro una sottocartella).

Il preset è senza thread: funziona su itch.io e su qualsiasi hosting senza intestazioni speciali, anche su iPhone.

### Caricarla su itch.io

1. Crea l'account su [itch.io](https://itch.io), poi *Dashboard → Create new project*.
2. **Kind of project**: HTML. Carica lo zip e spunta *This file will be played in the browser*.
3. **Embed options**: *Click to launch in fullscreen* no; *Viewport dimensions* `405 × 720`; spunta *Mobile friendly* (orientamento *Portrait*) e *Fullscreen button*. Lascia spenta *SharedArrayBuffer support*: non serve.
4. Titolo, descrizione breve, screenshot (`store/screenshots/android/` o `android_en/`), immagine di copertina (630×500: puoi ritagliare `store/feature_graphic_1024x500.png`), genere *Action*, tag come `arcade`, `one-button`, `casual`, `neon`, `endless`, `mobile`.
5. Nella descrizione metti i link agli store, quando ci sono.
6. *Visibility → Public* e salva.

Prova sul telefono: apri la pagina, gioca, poi CONDIVIDI (sul browser del telefono apre il menu di condivisione) e SCARICA.

Per gli aggiornamenti ripeti l'export e carica il nuovo zip al posto del vecchio. Con [butler](https://itch.io/docs/butler/) puoi farlo da riga di comando.

## 9. Dopo la pubblicazione

1. Apri `docs/index.html` e in fondo, in `LINKS`, inserisci i link a Google Play, App Store e alla pagina itch.io (gli esempi sono nel commento sopra). I pulsanti compaiono da soli, con lo store del visitatore per primo.
2. Su itch.io aggiungi i link agli store nella descrizione.

## 10. AIR HOCKEY online (il relay)

AIR HOCKEY in Wi-Fi funziona senza fare niente. Per giocare **via Internet** serve il relay, un piccolo server Node.js nella cartella `server/` che passa i pacchetti tra i telefoni. Se non lo metti online, le build pubblicate mostrano solo le lobby Wi-Fi.

1. Mettilo online, per esempio su Render: i passi sono in [server/README.md](server/README.md#metterlo-online). Aprendo l'indirizzo nel browser deve comparire `One More Tap relay: ok`.
2. In `scripts/net.gd` scrivi l'indirizzo in `RELAY_URL`, con `wss://`: per esempio `const RELAY_URL := "wss://omt-relay.onrender.com"`.
3. Prova con due telefoni su reti diverse (uno in Wi-Fi, uno col 4G): LOBBY ONLINE su uno, il codice in ENTRA sull'altro.
4. Nell'informativa privacy (`docs/privacy.html`, che descrive già il relay) scrivi chi ospita il server al posto di `[FORNITORE DEL SERVER, PAESE]`, accetta l'accordo sul trattamento dei dati del fornitore ([LEGALE.md](LEGALE.md#3-privacy-cosa-fare-fuori-dal-codice), punto 5) e aggiorna le dichiarazioni sui dati degli store (passi 4 e 5): online il nome e l'indirizzo IP passano dal tuo server.
5. Se cambi qualcosa nel modo in cui gioco e relay si parlano, aumenta `PROTOCOL` in `server/relay.mjs` e in `scripts/relay_peer.gd`, e aggiorna prima il server.

Con il piano gratuito di Render il server si addormenta dopo un po' senza traffico: la prima lobby online dopo una pausa può metterci un minuto (o fallire e riuscire al secondo tentativo). Per il gioco pubblicato conviene un piano sempre acceso.

## Controllo finale prima di inviare

- [ ] ID app AdMob nelle Project Settings, ID unità in `LIVE_IDS`
- [ ] Messaggio GDPR pubblicato in AdMob
- [ ] Informativa, termini e pagina del gioco online con i tuoi dati, `PRIVACY_URL` corretto, nessun segnaposto rimasto (comando in [LEGALE.md](LEGALE.md#1-i-dati-da-inserire))
- [ ] Nome ed email in `scripts/info_panel.gd`: INFO li mostra nel gioco
- [ ] Stato di operatore commerciale dichiarato su Play Console e App Store Connect
- [ ] Informazioni fiscali (W-8BEN) in AdMob, Play Console e App Store Connect; partita IVA decisa con il commercialista
- [ ] Build di **release** provata su telefono: compare il consenso, il video "Continua" fa ripartire, l'interstitial compare a fine partita, il banner c'è solo nel menu, RICARICA ridà le vite, INFO si apre (con PRIVACY e TERMINI che aprono le pagine, e le licenze che scorrono), CONSENSO si apre, CONDIVIDI apre il menu di condivisione con l'immagine della partita
- [ ] Gioco provato con il telefono in inglese (testi inglesi) e in italiano
- [ ] AIR HOCKEY provato con almeno due telefoni sulla stessa Wi-Fi: la lobby compare nell'elenco (su Android), si entra col codice, 2 contro 2 con la CPU nei posti vuoti, rivincita, e chi esce viene sostituito dalla CPU
- [ ] Se c'è il relay: `RELAY_URL` impostato con `wss://`, e una partita online provata tra due telefoni su reti diverse
- [ ] Schede degli store compilate in italiano e in inglese
- [ ] Keystore Android salvato in un posto sicuro
- [ ] Versione aumentata
- [ ] Prodotti creati e attivi su entrambi gli store, con gli stessi ID della tabella del passo 7
- [ ] Acquisto, ripristino e Rimuovi annunci provati con un account di test

## Più avanti (facoltativo)

- **Richiesta di tracciamento iOS (ATT)**: aumenta i ricavi su iPhone. In AdMob crea il messaggio "IDFA" (Privacy e messaggi). Aggiungi al preset iOS, in *Additional Plist Content*, la chiave `NSUserTrackingUsageDescription`, per esempio "Usiamo questo identificatore per mostrarti annunci più pertinenti". Infine collega il framework `AppTrackingTransparency` in Xcode. Il modulo di Google mostra poi il popup al momento giusto.
- **Mediazione** (altre reti pubblicitarie in AdMob), quando hai abbastanza giocatori: si attiva dalle Project Settings del plugin.
