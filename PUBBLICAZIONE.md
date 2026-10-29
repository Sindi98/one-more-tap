# Pubblicare One More Tap su Google Play, App Store e itch.io

Il codice è pronto. Quello che resta sono account, chiavi e moduli che solo tu puoi compilare. Segui i passi in ordine: ognuno dice dove cliccare e cosa scrivere.

## Cosa c'è già nel progetto

| Cosa | Dove |
|---|---|
| Plugin AdMob (Poing Studios v5.1.0), già attivo | `addons/admob/` |
| Annunci: consenso GDPR, interstitial a fine partita, banner nel menu, video "Continua" e "Ricarica", vite | `scripts/ads.gd`, `scripts/admob_backend.gd`, `scripts/ad_pacing.gd` |
| Plugin di condivisione e recensione in-app (Android e iOS), già attivi | `addons/SharePlugin/`, `addons/InappReviewPlugin/`, `ios/plugins/` |
| Preset di export Android (AAB firmato), iOS (progetto Xcode) e Web (itch.io) | `export_presets.cfg` |
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
4. Finché l'app non è sugli store, la pagina del gioco dice "In arrivo su Google Play e App Store". I link li aggiungi dopo la pubblicazione (passo 8).

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
   - **Classificazione dei contenuti**: questionario IARC, categoria Gioco. Nessuna violenza, nessuna interazione tra utenti, nessun acquisto.
   - **Pubblico di destinazione**: scegli solo fasce **13 anni e oltre**. Se includi i minori di 13 anni si applicano le norme Famiglie, con regole molto più rigide sugli annunci.
   - **Sicurezza dei dati**: dichiara quello che raccoglie l'SDK di Google, come indicato in [questa pagina di Google](https://developers.google.com/admob/android/privacy/play-data-disclosure). In pratica: dati raccolti e condivisi, cifrati in transito. Tipi: *Posizione approssimativa* (dall'IP), *ID dispositivo o altri ID*, *Attività nell'app* (interazioni), *Informazioni e prestazioni dell'app* (arresti anomali, diagnostica). Finalità: pubblicità o marketing, analisi, prevenzione delle frodi. Il gioco non ha account, quindi non c'è un meccanismo di cancellazione dati.
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
- **Inglese**: in alto a destra nella pagina della versione, *Italiano → Aggiungi lingua → Inglese (USA)*, poi i testi inglesi della scheda e gli screenshot `store/screenshots/iphone_en/`.
- **Note per la revisione**: c'è un testo pronto in `store/scheda_store.md`.
- Seleziona la build caricata e *Invia per la revisione*.
- Dopo la pubblicazione, collega l'app iOS alla scheda in AdMob.

## 6. Ogni aggiornamento

1. Alza la versione in *Project Settings → Application → Config → Version* (per esempio `1.0.1`). La usano entrambi gli store.
2. Android: in *Export → Android* aumenta **Version → Code** di 1. Play rifiuta un codice già usato.
3. iOS: lo stesso numero di versione non si può caricare due volte. Alza la versione oppure imposta *Application → Version* (il numero di build) a `1.0.1.1`, `1.0.1.2`, …
4. Lancia i test (vedi README) e prova sul telefono prima di caricare.

## 7. Versione web su itch.io

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

## 8. Dopo la pubblicazione

1. Apri `docs/index.html` e in fondo, in `LINKS`, inserisci i link a Google Play, App Store e alla pagina itch.io (gli esempi sono nel commento sopra). I pulsanti compaiono da soli, con lo store del visitatore per primo.
2. Su itch.io aggiungi i link agli store nella descrizione.

## Controllo finale prima di inviare

- [ ] ID app AdMob nelle Project Settings, ID unità in `LIVE_IDS`
- [ ] Messaggio GDPR pubblicato in AdMob
- [ ] Informativa online con i tuoi dati, `PRIVACY_URL` corretto
- [ ] Build di **release** provata su telefono: compare il consenso, il video "Continua" fa ripartire, l'interstitial compare a fine partita, il banner c'è solo nel menu, RICARICA ridà le vite, PRIVACY e CONSENSO si aprono, CONDIVIDI apre il menu di condivisione con l'immagine della partita
- [ ] Gioco provato con il telefono in inglese (testi inglesi) e in italiano
- [ ] Schede degli store compilate in italiano e in inglese
- [ ] Keystore Android salvato in un posto sicuro
- [ ] Versione aumentata

## Più avanti (facoltativo)

- **Richiesta di tracciamento iOS (ATT)**: aumenta i ricavi su iPhone. In AdMob crea il messaggio "IDFA" (Privacy e messaggi). Aggiungi al preset iOS, in *Additional Plist Content*, la chiave `NSUserTrackingUsageDescription`, per esempio "Usiamo questo identificatore per mostrarti annunci più pertinenti". Infine collega il framework `AppTrackingTransparency` in Xcode. Il modulo di Google mostra poi il popup al momento giusto.
- **"Rimuovi annunci" a pagamento**: un acquisto in-app che disattiva gli interstitial. Richiede i plugin di fatturazione di Google Play e StoreKit.
- **Mediazione** (altre reti pubblicitarie in AdMob), quando hai abbastanza giocatori: si attiva dalle Project Settings del plugin.
