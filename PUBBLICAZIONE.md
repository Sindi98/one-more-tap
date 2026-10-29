# Pubblicare One More Tap su Google Play e App Store

Il codice è pronto. Quello che resta sono account, chiavi e moduli che solo tu puoi compilare. Segui i passi in ordine: ognuno dice dove cliccare e cosa scrivere.

## Cosa c'è già nel progetto

| Cosa | Dove |
|---|---|
| Plugin AdMob (Poing Studios v5.1.0), già attivo | `addons/admob/` |
| Annunci: consenso GDPR, interstitial tra le partite, video "Continua" | `scripts/ads.gd`, `scripts/admob_backend.gd`, `scripts/ad_pacing.gd` |
| Negozio: stili con rarità, gettoni, Rimuovi annunci, Collezione completa, ripristino | `scripts/catalog.gd`, `scripts/shop.gd`, `scripts/iap_backend.gd`, `scripts/shop_panel.gd` |
| Preset di export Android (AAB firmato) e iOS (progetto Xcode) | `export_presets.cfg` |
| Icone (iOS 1024, Android adattiva e monocromatica) | `assets/icons/` (le rigeneri con `tools/make_icons.gd`) |
| Informativa privacy (IT + EN), da pubblicare online | `docs/privacy.html` |
| Testi, screenshot, icona 512 e grafica 1024×500 per gli store | `store/` |

Finché non inserisci i tuoi ID, il gioco mostra **annunci di prova di Google**. Nelle build di debug li mostra sempre, anche dopo. È voluto: toccare i tuoi annunci veri può far sospendere l'account AdMob.

## Come funzionano gli annunci nel gioco

- **Video "Continua"**: dopo una caduta compare il pulsante CONTINUA, se un video è pronto e la partita valeva almeno 5 punti. Se guardi il video fino in fondo, la pallina torna all'inizio della piattaforma dove sei caduto e riparte rallentata. Vale una volta per partita.
- **Interstitial**: compare solo quando tocchi RIPROVA. Al massimo uno ogni 3 partite e ogni 90 secondi, e mai subito dopo un video. Le soglie sono in cima a `scripts/ad_pacing.gd`.
- **Mai durante una partita**, niente banner: in un gioco a un dito un banner prende tocchi per sbaglio, e le regole di AdMob li vietano.
- **Consenso**: al primo avvio, in UE, Regno Unito e Svizzera, compare il modulo di Google. Il pulsante CONSENSO nei menu lo riapre (è obbligatorio). PRIVACY apre l'informativa.
- **Dal editor (F5)** vedi annunci finti disegnati dal plugin, così puoi provare tutto il giro senza telefono.
- **Rimuovi annunci** (o la Collezione completa): niente più annunci, e dall'avvio dopo l'SDK di Google non parte nemmeno. CONTINUA usa i gettoni.

---

## 1. Decidi l'identificativo dell'app (una volta sola)

Nei preset è impostato `com.sindi98.onemoretap`. Dopo la prima pubblicazione **non si può più cambiare**. Se vuoi un altro nome (per esempio `it.tuonome.onemoretap`), cambialo adesso in *Project → Export*:

- Android → *Package → Unique Name*
- iOS → *Application → Bundle Identifier*

## 2. Informativa privacy online

Entrambi gli store la chiedono, e il gioco la apre dal pulsante PRIVACY.

1. Apri `docs/privacy.html` e `docs/index.html` e sostituisci `[NOME E COGNOME DELLO SVILUPPATORE]`, `[DEVELOPER FULL NAME]`, `[EMAIL DI CONTATTO]` e `[CONTACT EMAIL]`. Ti consiglio un indirizzo dedicato al gioco. È un modello: se hai dubbi legali, fallo controllare.
2. Su GitHub: *Settings → Pages → Build and deployment → Deploy from a branch → `main` / `/docs`*. Dopo un minuto la pagina è su `https://sindi98.github.io/one-more-tap/privacy.html`.
   - Con un repository privato, GitHub Pages richiede un piano a pagamento. In alternativa carica i due file su un altro hosting.
3. Se l'indirizzo è diverso, aggiorna `PRIVACY_URL` in `scripts/ads.gd`.

## 3. AdMob

1. Crea l'account su [admob.google.com](https://admob.google.com) e inserisci i dati di pagamento.
2. *App → Aggiungi app*, due volte: una per **Android** e una per **iOS**. Alla domanda "è già su uno store?" rispondi no; collegherai lo store dopo la pubblicazione.
3. In ogni app crea due **unità pubblicitarie**:
   - **Interstitial**, nome "Tra le partite"
   - **Con premio** (Rewarded), nome "Continua", premio `1` `continue`
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
   - **Classificazione dei contenuti**: questionario IARC, categoria Gioco. Nessuna violenza, nessuna interazione tra utenti. Acquisti digitali: **sì**; oggetti casuali a pagamento (loot box): **no**.
   - **Pubblico di destinazione**: scegli solo fasce **13 anni e oltre**. Se includi i minori di 13 anni si applicano le norme Famiglie, con regole molto più rigide sugli annunci.
   - **Sicurezza dei dati**: dichiara quello che raccoglie l'SDK di Google, come indicato in [questa pagina di Google](https://developers.google.com/admob/android/privacy/play-data-disclosure). In pratica: dati raccolti e condivisi, cifrati in transito. Tipi: *Posizione approssimativa* (dall'IP), *ID dispositivo o altri ID*, *Attività nell'app* (interazioni), *Informazioni e prestazioni dell'app* (arresti anomali, diagnostica). Finalità: pubblicità o marketing, analisi, prevenzione delle frodi. Il gioco non ha account, quindi non c'è un meccanismo di cancellazione dati.
5. *Scheda dello store principale*: testi in `store/scheda_store.md`, icona `store/icon_512.png`, grafica `store/feature_graphic_1024x500.png`, screenshot `store/screenshots/android/`.
6. *Produzione → Crea nuova release*, carica l'AAB e invia per la revisione (di solito da qualche ora a qualche giorno).
7. Torna in AdMob e collega l'app Android alla scheda Play.

## 5. App Store (iOS)

### Cosa serve

- Un **Mac** con l'ultima versione di **Xcode**. L'export iOS di Godot produce un progetto Xcode, e il caricamento si fa da lì.
- **Apple Developer Program**: 99 € all'anno, su [developer.apple.com/programs](https://developer.apple.com/programs/).

### Preparare (una volta)

1. In Godot sul Mac: export templates come sopra, poi *Project → Tools → AdMob Manager → iOS → Download & Install*.
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
- **Crittografia**: già dichiarata nel preset (`ITSAppUsesNonExemptEncryption = NO`), Xcode non chiede nulla.
- **Screenshot**: `store/screenshots/iphone/` (6,9", 1320×2868). L'app è solo per iPhone, quindi non servono quelli per iPad.
- **Note per la revisione**: c'è un testo pronto in `store/scheda_store.md`.
- Seleziona la build caricata e *Invia per la revisione*.
- Dopo la pubblicazione, collega l'app iOS alla scheda in AdMob.

## 6. Ogni aggiornamento

1. Alza la versione in *Project Settings → Application → Config → Version* (per esempio `1.0.1`). La usano entrambi gli store.
2. Android: in *Export → Android* aumenta **Version → Code** di 1. Play rifiuta un codice già usato.
3. iOS: lo stesso numero di versione non si può caricare due volte. Alza la versione oppure imposta *Application → Version* (il numero di build) a `1.0.1.1`, `1.0.1.2`, …
4. Lancia i test (vedi README) e prova sul telefono prima di caricare.

## 7. Acquisti in-app

Il negozio nel gioco è pronto (regole e prezzi nel [README](README.md#acquisti-in-app)). Mancano tre cose: il plugin, i prodotti negli store e una prova con un account di test.

### Installare il plugin (una volta)

Il gioco usa [godot-iap](https://github.com/hyodotdev/openiap/tree/main/libraries/godot-iap) (OpenIAP, licenza MIT): Google Play Billing su Android, StoreKit 2 su iOS, una sola API. Finché non c'è, il negozio mostra gli stili ma niente è in vendita.

1. Scarica `godot-iap-4.2.0.zip` dalla [pagina della release](https://github.com/hyodotdev/openiap/releases/tag/godot-iap-4.2.0) ed estrai la cartella `addons/godot-iap/` dentro la cartella `addons/` del progetto (accanto ad `admob`). Copia tutta la cartella, binari compresi.
2. *Project → Project Settings → Plugins*: attiva **GodotIap**. Aggiunge da solo l'autoload `GodotIapPlugin`, che il gioco cerca all'avvio.
3. *Project → Export → iOS → Application → Min iOS Version*: **17.0**. I framework del plugin richiedono iOS 17 (iPhone XS/XR e successivi): con un valore più basso l'app si chiude all'avvio.
4. *Project → Export → Android*, sezione **Openiap**: *Android Store* = `play`.
5. Android: il plugin vuole AGP 8.9.1+, Gradle 8.11.1+, Android SDK 36 e JDK 17. Durante l'export aggiorna il template da solo; se si ferma, il messaggio dice quale versione di Gradle serve.
6. iOS: se dopo l'export Xcode dice `Library not loaded: @rpath/GodotIap.framework`, dalla cartella del progetto lancia `IOS_EXPORT_DIR=~/Build/OneMoreTap ./addons/godot-iap/scripts/fix_ios_embed.sh` (o la cartella dove hai esportato).

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
- Rimuovi annunci: niente interstitial, CONTINUA usa i gettoni (10 in regalo). Chiudi e riapri il gioco: il modulo del consenso non compare più.
- Finiti i gettoni, CONTINUA porta al negozio; comprati, si torna al game over e si continua.

## Controllo finale prima di inviare

- [ ] ID app AdMob nelle Project Settings, ID unità in `LIVE_IDS`
- [ ] Messaggio GDPR pubblicato in AdMob
- [ ] Informativa online con i tuoi dati, `PRIVACY_URL` corretto
- [ ] Build di **release** provata su telefono: compare il consenso, il video "Continua" fa ripartire, l'interstitial compare tra le partite, PRIVACY e CONSENSO si aprono
- [ ] Keystore Android salvato in un posto sicuro
- [ ] Versione aumentata
- [ ] Plugin godot-iap attivo, iOS minimo 17.0, prodotti creati e attivi su entrambi gli store con gli stessi ID
- [ ] Acquisto, ripristino e Rimuovi annunci provati con un account di test

## Più avanti (facoltativo)

- **Richiesta di tracciamento iOS (ATT)**: aumenta i ricavi su iPhone. In AdMob crea il messaggio "IDFA" (Privacy e messaggi). Aggiungi al preset iOS, in *Additional Plist Content*, la chiave `NSUserTrackingUsageDescription`, per esempio "Usiamo questo identificatore per mostrarti annunci più pertinenti". Infine collega il framework `AppTrackingTransparency` in Xcode. Il modulo di Google mostra poi il popup al momento giusto.
- **Traduzione inglese** dell'interfaccia, per allargare il pubblico.
- **Mediazione** (altre reti pubblicitarie in AdMob), quando hai abbastanza giocatori: si attiva dalle Project Settings del plugin.
