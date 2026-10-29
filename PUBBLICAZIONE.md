# Pubblicare One More Tap su Google Play, App Store e itch.io

Il codice è pronto. Quello che resta sono account, chiavi e moduli che solo tu puoi compilare. Segui i passi in ordine: ognuno dice dove cliccare e cosa scrivere.

## Cosa ti serve

| Cosa | Costo | A cosa serve |
|---|---|---|
| Account [Google Play Console](https://play.google.com/console) | 25 $ una volta sola, più verifica dell'identità | Pubblicare su Android |
| [Apple Developer Program](https://developer.apple.com/programs/) | 99 € all'anno | Pubblicare su iPhone |
| Account [AdMob](https://admob.google.com) | Gratis | Gli annunci (e i ricavi) |
| Un indirizzo email per il gioco e il tuo nome | — | Informativa privacy e contatti nelle schede degli store |
| Un telefono Android e un iPhone (anche di amici) | — | Provare le build prima di pubblicarle |
| Godot 4.7 sul tuo computer | Gratis | Inserire gli ID AdMob e provare il gioco |

**Non servono un Mac né Android Studio**: le build firmate per i due store le fa GitHub sui suoi computer (passo 10). Su un repository pubblico è gratis; su uno privato usa i minuti gratuiti del piano (2.000 al mese, e i minuti sui Mac contano 10 volte: lancia la build iOS solo quando serve).

Se invece hai un Mac con Xcode e preferisci fare tutto a mano dall'editor, i passi 4 e 5 spiegano anche quella strada.

## Cosa c'è già nel progetto

| Cosa | Dove |
|---|---|
| Plugin AdMob (Poing Studios v5.1.0), già attivo | `addons/admob/` |
| Annunci: consenso GDPR, interstitial a fine partita, banner nel menu, video "Continua" e "Ricarica", vite | `scripts/ads.gd`, `scripts/admob_backend.gd`, `scripts/ad_pacing.gd` |
| Negozio: stili con rarità, gettoni, Rimuovi annunci, Collezione completa, ripristino | `scripts/catalog.gd`, `scripts/shop.gd`, `scripts/iap_backend.gd`, `scripts/shop_panel.gd` |
| Plugin acquisti in-app godot-iap 4.2.0, già attivo | `addons/godot-iap/` |
| Plugin di condivisione e recensione in-app (Android e iOS), già attivi | `addons/SharePlugin/`, `addons/InappReviewPlugin/`, `ios/plugins/` |
| Preset di export Android (AAB firmato), iOS (progetto Xcode) e Web (itch.io) | `export_presets.cfg` |
| Build automatiche su GitHub: test, AAB firmato, IPA firmata, caricamento su Google Play e TestFlight | `.github/workflows/mobile.yml`, `tools/ci/` |
| Script per creare la chiave Android e il certificato Apple senza Mac | `tools/make_android_keystore.sh`, `tools/make_ios_certificate.sh` |
| Icone (iOS 1024, Android adattiva e monocromatica) | `assets/icons/` (le rigeneri con `tools/make_icons.gd`) |
| Pagina del gioco (dove porta il link condiviso) e informativa privacy (IT + EN), da pubblicare online | `docs/index.html`, `docs/privacy.html` |
| Testi, screenshot, icona 512 e grafica 1024×500 per gli store, in italiano e inglese | `store/` |

Finché non inserisci i tuoi ID, il gioco mostra **annunci di prova di Google**. Nelle build di debug li mostra sempre, anche dopo. È voluto: toccare i tuoi annunci veri può far sospendere l'account AdMob.

## Come funzionano gli annunci nel gioco

- **Video "Continua"**: dopo una caduta compare il pulsante CONTINUA, se un video è pronto e la partita valeva almeno 5 punti. Se guardi il video fino in fondo, la pallina torna all'inizio della piattaforma dove sei caduto e riparte rallentata. Vale una volta per partita.
- **Interstitial**: compare appena finisce una partita, a gioco fermo, prima del pannello col punteggio. Al massimo uno ogni 3 partite e ogni 90 secondi, e mai subito dopo un video. Le soglie sono in cima a `scripts/ad_pacing.gd`.
- **Vite**: 5, una per partita; ne torna una ogni 15 minuti. Quando finiscono, il pulsante RICARICA mostra un video con premio che le ridà tutte.
- **Banner**: solo nella schermata iniziale, dove si sceglie la modalità. Sta lungo il bordo in basso, con uno spazio tra lui e i pulsanti: in un gioco a un dito un banner vicino ai controlli prende tocchi per sbaglio, e le regole di AdMob li vietano. Durante la partita e negli altri pannelli è nascosto.
- **Mai durante una partita.**
- **Consenso**: al primo avvio, in UE, Regno Unito e Svizzera, compare il modulo di Google. Il pulsante CONSENSO nei menu lo riapre (è obbligatorio). PRIVACY apre l'informativa.
- **Dal editor (F5)** vedi annunci finti disegnati dal plugin, così puoi provare tutto il giro senza telefono.
- **Rimuovi annunci** (o la Collezione completa): niente più annunci né banner, e dall'avvio dopo l'SDK di Google non parte nemmeno. Niente vite, si gioca senza limiti. CONTINUA usa i gettoni.

Il gioco è in italiano per chi ha il telefono in italiano e in inglese per tutti gli altri. Per questo le schede degli store vanno compilate in tutte e due le lingue (passi 4 e 5).

---

## 1. Decidi l'identificativo dell'app (una volta sola)

Nei preset è impostato `com.sindi98.onemoretap`. Dopo la prima pubblicazione **non si può più cambiare**. Se vuoi un altro nome (per esempio `it.tuonome.onemoretap`), cambialo adesso in *Project → Export*:

- Android → *Package → Unique Name*
- iOS → *Application → Bundle Identifier*

## 2. Informativa privacy e pagina del gioco online

Entrambi gli store chiedono l'informativa, e il gioco la apre dal pulsante PRIVACY. La pagina `index.html` è quella del gioco: ci arriva chi riceve un punteggio condiviso, e ci porta il pulsante SCARICA della versione web.

1. Apri `docs/privacy.html` e `docs/index.html` e sostituisci `[NOME E COGNOME DELLO SVILUPPATORE]`, `[DEVELOPER FULL NAME]`, `[EMAIL DI CONTATTO]` e `[CONTACT EMAIL]`. Ti consiglio un indirizzo dedicato al gioco. È un modello: se hai dubbi legali, fallo controllare.
2. Su GitHub: *Settings → Pages → Build and deployment → Deploy from a branch → `master` / `/docs`*. Dopo un minuto le pagine sono su `https://sindi98.github.io/one-more-tap/` e `https://sindi98.github.io/one-more-tap/privacy.html`.
   - Con un repository privato, GitHub Pages richiede un piano a pagamento. In alternativa carica i due file su un altro hosting.
3. Se l'indirizzo è diverso, aggiorna `PRIVACY_URL` in `scripts/ads.gd` e `SITE_URL` in `scripts/social.gd`.
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

**Con le build su GitHub** (passo 10) salta *Preparare Godot*, *Chiave di firma* ed *Esportare*: la chiave la crei con lo script del passo 10 e l'AAB lo trovi già firmato tra i risultati della build. Riprendi da *Play Console*.

### Preparare Godot (una volta)

1. *Editor → Manage Export Templates → Download and Install* (4.7).
2. Installa **JDK 17** e **Android SDK** (il modo più semplice è installare Android Studio), poi impostali in *Editor → Editor Settings → Export → Android* (Java SDK Path e Android SDK Path).
3. *Project → Install Android Build Template*. Serve perché il plugin AdMob richiede la build Gradle. La cartella `android/` creata non va su git (è già in `.gitignore`).
4. *Project → Tools → AdMob Manager → Android → Download & Install*. Di solito lo fa da solo all'apertura del progetto.

### Chiave di firma (una volta, poi custodiscila)

```bash
keytool -genkeypair -v -keystore one-more-tap-upload.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

(Senza Java va bene anche `tools/make_android_keystore.sh`, che usa solo openssl: è la stessa chiave che userà GitHub, passo 10.)

Tienila **fuori dal repository**, con la password, in un posto sicuro (gestore di password più backup). Se la perdi, Google può reimpostarla ma ci vogliono giorni.

In *Project → Export → Android → Keystore → Release* inserisci file, alias (`upload`) e password. Godot salva queste credenziali in `.godot/export_credentials.cfg`, che non finisce su git.

### Esportare

1. Prova prima sul telefono: debug USB attivo, poi il pulsante Android in alto a destra nell'editor. Vedrai annunci etichettati "Test Ad" e, in Italia, il modulo del consenso.
2. *Project → Export → Android → Export Project*, togli la spunta "Export With Debug" e salva `one-more-tap.aab`.

### Play Console

1. Registrati su [play.google.com/console](https://play.google.com/console): 25 $ una tantum, più verifica dell'identità.
2. *Crea app*: nome "One More Tap", lingua predefinita italiano, Gioco, Gratuito.
3. **Account personali nuovi**: prima della produzione Google chiede un **test chiuso con almeno 12 tester per 14 giorni di fila**. Carica l'AAB in *Test → Test chiuso*, invita amici e familiari (email o Google Group) e aspetta i 14 giorni. Poi chiedi l'accesso alla produzione.
   - Il **primo** AAB va caricato a mano dalla Play Console (anche quello fatto da GitHub): è così che Google registra il nome del pacchetto. Dopo, la build su GitHub può caricare da sola le versioni successive nel test interno (passo 10).
4. *Contenuti dell'app* (menu Policy):
   - **Norme sulla privacy**: l'URL del passo 2.
   - **Annunci**: Sì, l'app contiene annunci.
   - **Accesso all'app**: tutte le funzionalità sono disponibili senza restrizioni.
   - **ID pubblicità**: Sì, lo usa (AdMob), per Pubblicità, Analisi e Prevenzione frodi. Il permesso `AD_ID` lo aggiunge già l'SDK.
   - **Classificazione dei contenuti**: questionario IARC, categoria Gioco. Nessuna violenza, nessuna interazione tra utenti. Acquisti digitali: **sì**; oggetti casuali a pagamento (loot box): **no**.
   - **Pubblico di destinazione**: scegli solo fasce **13 anni e oltre**. Se includi i minori di 13 anni si applicano le norme Famiglie, con regole molto più rigide sugli annunci.
   - **Sicurezza dei dati**: dichiara quello che raccoglie l'SDK di Google, come indicato in [questa pagina di Google](https://developers.google.com/admob/android/privacy/play-data-disclosure). In pratica: dati raccolti e condivisi, cifrati in transito. Tipi: *Posizione approssimativa* (dall'IP), *ID dispositivo o altri ID*, *Attività nell'app* (interazioni), *Informazioni e prestazioni dell'app* (arresti anomali, diagnostica). Finalità: pubblicità o marketing, analisi, prevenzione delle frodi. Il gioco non ha account, quindi non c'è un meccanismo di cancellazione dati.
5. *Scheda dello store principale*: testi in `store/scheda_store.md`, icona `store/icon_512.png`, grafica `store/feature_graphic_1024x500.png`, screenshot `store/screenshots/android/`.
   - Poi *Gestisci traduzioni → Aggiungi traduzioni → Inglese (Stati Uniti)* (e, se vuoi, Inglese (Regno Unito)): testi inglesi dalla stessa scheda, grafica `store/feature_graphic_1024x500_en.png`, screenshot `store/screenshots/android_en/`.
6. *Produzione → Crea nuova release*, carica l'AAB e invia per la revisione (di solito da qualche ora a qualche giorno).
7. Torna in AdMob e collega l'app Android alla scheda Play.

## 5. App Store (iOS)

### Cosa serve

- **Apple Developer Program**: 99 € all'anno, su [developer.apple.com/programs](https://developer.apple.com/programs/).
- **Oppure** un Mac con **Xcode 26 o successivo** (dall'aprile 2026 App Store Connect rifiuta le build fatte con versioni precedenti), **oppure** le build su GitHub del passo 10, che girano su un Mac di GitHub con Xcode 26: in quel caso fai qui solo il punto 3 di *Preparare*, salta *Esportare e caricare* e riprendi da *App Store Connect*.

### Preparare (una volta)

1. In Godot sul Mac: export templates come sopra, poi *Project → Tools → AdMob Manager → iOS → Download & Install*. I plugin di condivisione e recensione sono già in `ios/plugins/` e già spuntati nel preset iOS (*Plugins*).
2. *Project → Export → iOS*: in **App Store Team ID** metti il Team ID (lo trovi in developer.apple.com → Account → Membership).
3. Su [App Store Connect](https://appstoreconnect.apple.com): *App → + → Nuova app*, piattaforma iOS, nome "One More Tap", lingua italiano, bundle ID `com.sindi98.onemoretap` (se non compare, prima registralo in developer.apple.com → Identifiers), SKU a piacere.

### Esportare e caricare

1. *Project → Export → iOS → Export Project* in una cartella vuota fuori dal progetto, per esempio `~/Build/OneMoreTap`. Il preset crea solo il progetto Xcode; il plugin AdMob aggiunge da solo SDK, ID app e voci SKAdNetwork.
2. Apri il `.xcodeproj`. In *Signing & Capabilities* scegli il tuo team con "Automatically manage signing".
3. Prova su un iPhone collegato (Run): annunci "Test Ad" e modulo consenso.
4. *Product → Archive*, poi *Distribute App → App Store Connect → Upload*.

### App Store Connect

- **Privacy dell'app** ("etichette nutrizionali"): dichiara i dati dell'SDK di Google, come da [questa pagina](https://developers.google.com/admob/ios/privacy/data-disclosure): *Posizione approssimativa*, *ID dispositivo*, *Dati pubblicitari*, *Interazione con il prodotto*, *Dati sugli arresti anomali*, *Dati sulle prestazioni*, *Altri dati diagnostici*. Finalità: pubblicità di terze parti e analisi; non collegati all'identità. Questa versione **non** mostra la richiesta di tracciamento di Apple (ATT), quindi l'SDK non accede all'IDFA. Se marchi dei dati come "usati per il tracciamento", Apple pretende il popup ATT (vedi "Più avanti").
- **URL informativa privacy** e **URL di supporto** (la pagina `index.html`).
- **Classificazione per età**: compila il questionario. Il gioco non ha contenuti sensibili, ma gli annunci di terzi possono alzare la fascia: rispondi in modo coerente. Nel codice gli annunci sono limitati a contenuti per tutti con supervisione (`MAX_AD_CONTENT_RATING_PG`).
- **Crittografia**: già dichiarata (`ITSAppUsesNonExemptEncryption = NO`, la scrive Godot nell'Info.plist), App Store Connect non chiede nulla.
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

Con le build su GitHub (passo 10) i punti 2 e 3 li fa la build: version code Android e numero di build iOS sono il numero della build, che cresce sempre. Basta il punto 1, poi un commit e una nuova build; i test li lancia lei.

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

1. *Accordi, imposte e banche*: firma l'accordo **App a pagamento**, inserisci conto bancario e moduli fiscali. Senza, i prodotti restano "in attesa".
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

## 10. Build automatiche su GitHub (senza Mac e senza Android Studio)

Il workflow `.github/workflows/mobile.yml` fa sui computer di GitHub (Linux per Android, un Mac con Xcode 26 per iOS) quello che altrimenti faresti con Android Studio e Xcode: lancia i test, esporta l'**AAB firmato** per Google Play e l'**IPA firmata** per l'App Store e, se vuoi, li carica nel **test interno di Google Play** e su **TestFlight**.

Le chiavi stanno nei **secret** di GitHub: cifrati, nessuno li può rileggere, nemmeno tu. Si creano nel repository in *Settings → Secrets and variables → Actions → New repository secret*, con il nome scritto esattamente come nelle tabelle qui sotto.

Gli script si lanciano dalla cartella del progetto, in un terminale: Linux, macOS o *Git Bash* su Windows (arriva con [Git per Windows](https://git-scm.com/download/win)). Usano solo `openssl` e mettono i file nella tua cartella home, mai nel repository.

### 10.1 Android

1. Crea la chiave di caricamento (una volta sola, poi custodiscila):

   ```bash
   tools/make_android_keystore.sh
   ```

   Crea `~/one-more-tap-upload.p12` e il file `.base64.txt` da incollare nel secret. Se hai già una chiave fatta con `keytool` (passo 4, alias `upload`), usa quella: `base64 < one-more-tap-upload.keystore | tr -d '\n' > ~/chiave.base64.txt`.

2. I secret:

   | Secret | Cosa metterci |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | il contenuto del file `.base64.txt` |
   | `ANDROID_KEYSTORE_PASSWORD` | la password della chiave |

3. (Facoltativo) Caricamento automatico su Google Play:
   1. Su [Google Cloud Console](https://console.cloud.google.com) crea un progetto (per esempio "one-more-tap"), poi *API e servizi → Libreria → Google Play Android Developer API → Abilita*.
   2. *IAM e amministrazione → Account di servizio → Crea account di servizio*, nome "github-play", nessun ruolo. Aprilo, *Chiavi → Aggiungi chiave → Crea nuova chiave → JSON*: si scarica un file `.json`.
   3. Nella Play Console, *Utenti e autorizzazioni → Invita nuovi utenti*: l'email dell'account di servizio (finisce con `iam.gserviceaccount.com`), poi *Autorizzazioni app → One More Tap* con il permesso di rilasciare nei canali di test. Invia l'invito.
   4. Secret `PLAY_SERVICE_ACCOUNT_JSON`: tutto il contenuto del file `.json`.
   5. Il **primo** AAB va comunque caricato a mano dalla Play Console (passo 4): scaricalo dagli *Artifacts* di una build (10.3).

### 10.2 iOS

Tutto dal browser, su [developer.apple.com/account](https://developer.apple.com/account) → *Certificates, IDs & Profiles*.

1. **Identificativo dell'app**: *Identifiers → +* → *App IDs* → *App* → descrizione "One More Tap", *Explicit* `com.sindi98.onemoretap`. Non serve spuntare niente: gli acquisti in-app sono già attivi.
2. **Certificato di distribuzione** (dura un anno):

   ```bash
   tools/make_ios_certificate.sh csr
   ```

   Chiede email e nome e crea la richiesta in `~/one-more-tap-ios`. Poi *Certificates → +* → **Apple Distribution** → carica `ios_distribution.csr` → scarica `distribution.cer`, e:

   ```bash
   tools/make_ios_certificate.sh p12 ~/Downloads/distribution.cer
   ```

3. **Profilo di distribuzione**: *Profiles → +* → *Distribution* → **App Store Connect** → l'App ID del punto 1 → il certificato del punto 2 → nome `One More Tap App Store` (solo lettere, numeri e spazi) → *Generate* → scarica il file `.mobileprovision`, e:

   ```bash
   tools/make_ios_certificate.sh profile ~/Downloads/One_More_Tap_App_Store.mobileprovision
   ```

4. **L'app su App Store Connect**: passo 5, *Preparare*, punto 3. Senza, TestFlight rifiuta il caricamento.
5. (Per il caricamento su TestFlight) **Chiave API**: su [App Store Connect](https://appstoreconnect.apple.com), *Utenti e accesso → Integrazioni → API di App Store Connect → Chiavi del team → +*, nome "GitHub", accesso **App Manager**. Scarica il file `AuthKey_….p8`: si può scaricare **una volta sola**. La prima volta il titolare dell'account deve chiedere l'accesso alle API, sulla stessa pagina.

I secret:

| Secret | Cosa metterci |
|---|---|
| `IOS_CERTIFICATE_P12_BASE64` | il contenuto di `~/one-more-tap-ios/ios_distribution.p12.base64.txt` |
| `IOS_CERTIFICATE_PASSWORD` | la password scelta al passo `p12` |
| `IOS_PROFILE_BASE64` | il contenuto di `~/one-more-tap-ios/profile.base64.txt` |
| `ASC_KEY_ID` | l'ID della chiave API (10 caratteri, nella tabella delle chiavi) |
| `ASC_ISSUER_ID` | l'Issuer ID (sopra la tabella delle chiavi) |
| `ASC_KEY_P8` | tutto il contenuto del file `.p8`, comprese le righe `BEGIN` ed `END` |

Il Team ID non serve: la build lo legge dal profilo. Conserva la cartella `~/one-more-tap-ios` in un posto sicuro e cancella i file `.base64.txt` dopo averli incollati.

Ogni anno, quando il certificato scade (Apple ti avvisa per email), rifai i punti 2 e 3 e aggiorna i tre secret `IOS_…`. Le versioni già pubblicate non ne risentono.

### 10.3 Lanciare una build

1. Su GitHub: *Actions → Build Android e iOS → Run workflow*.
2. Scegli cosa costruire. Con **Carica sugli store** spuntato:
   - l'AAB va nel **test interno** di Google Play come bozza: lo pubblichi ai tester dalla Play Console (*Test interno → Modifica release → Avvia implementazione*);
   - l'IPA va su App Store Connect: dopo qualche minuto di elaborazione la trovi in *TestFlight*, pronta per i tester e da scegliere al momento di inviare la versione in revisione.
3. A fine build, in fondo alla pagina, sotto *Artifacts*, ci sono `one-more-tap-android-N` (l'AAB) e `one-more-tap-ios-N` (l'IPA), per caricarli a mano se preferisci.

Cosa sapere:

- Il **version code** Android e il **numero di build** iOS sono il numero della build su GitHub (`N`), che cresce sempre. Se carichi anche a mano dall'editor, usa un numero più alto dell'ultima build.
- Se manca un secret, la build si ferma subito e dice quale. Se gli ID AdMob sono ancora quelli di prova, la build va avanti ma lo segnala tra gli avvisi: per i tester va benissimo, per la produzione no (passo 3).
- Le librerie native del plugin AdMob (non sono nel repository) le scarica la build da sola, nella stessa versione del plugin.

Se qualcosa va storto:

- **Android, password o chiave non valida**: controlla `ANDROID_KEYSTORE_PASSWORD` e che l'alias della chiave sia `upload`.
- **Google Play, app non trovata o permesso negato**: il primo AAB va caricato a mano; l'account di servizio deve essere invitato nella Play Console con i permessi su One More Tap.
- **iOS, "Il profilo … è per …"** oppure **"è di sviluppo o Ad Hoc"**: rifai il profilo del punto 3 con l'App ID giusto e il tipo *App Store Connect*.
- **iOS, "Nel certificato non c'è un'identità Apple Distribution valida"**: il certificato è scaduto, revocato o di tipo *Development*: rifai il punto 2.
- **iOS, "doesn't include signing certificate" durante *Archivia e firma***: il profilo è stato creato con un altro certificato: rifallo scegliendo quello attuale e aggiorna `IOS_PROFILE_BASE64`.

## Controllo finale prima di inviare

- [ ] ID app AdMob nelle Project Settings, ID unità in `LIVE_IDS`
- [ ] Messaggio GDPR pubblicato in AdMob
- [ ] Informativa online con i tuoi dati, `PRIVACY_URL` corretto
- [ ] Build di **release** provata su telefono: compare il consenso, il video "Continua" fa ripartire, l'interstitial compare a fine partita, il banner c'è solo nel menu, RICARICA ridà le vite, PRIVACY e CONSENSO si aprono, CONDIVIDI apre il menu di condivisione con l'immagine della partita
- [ ] Gioco provato con il telefono in inglese (testi inglesi) e in italiano
- [ ] Schede degli store compilate in italiano e in inglese
- [ ] Chiave Android (e, per le build su GitHub, la cartella `~/one-more-tap-ios`) salvate in un posto sicuro
- [ ] (Build su GitHub) Secret creati e una build con *Carica sugli store* arrivata nel test interno di Google Play e su TestFlight
- [ ] Versione aumentata
- [ ] Prodotti creati e attivi su entrambi gli store, con gli stessi ID della tabella del passo 7
- [ ] Acquisto, ripristino e Rimuovi annunci provati con un account di test

## Più avanti (facoltativo)

- **Richiesta di tracciamento iOS (ATT)**: aumenta i ricavi su iPhone. In AdMob crea il messaggio "IDFA" (Privacy e messaggi). Aggiungi al preset iOS, in *Additional Plist Content*, la chiave `NSUserTrackingUsageDescription`, per esempio "Usiamo questo identificatore per mostrarti annunci più pertinenti". Infine collega il framework `AppTrackingTransparency` in Xcode. Il modulo di Google mostra poi il popup al momento giusto.
- **Mediazione** (altre reti pubblicitarie in AdMob), quando hai abbastanza giocatori: si attiva dalle Project Settings del plugin.
