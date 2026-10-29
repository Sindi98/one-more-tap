# One More Tap: aspetti legali e burocrazia

Tutto quello che serve oltre al codice per pubblicare il gioco in regola: documenti, dati da inserire, moduli degli store, privacy, consumatori, tasse. I passi pratici per pubblicare sono in **[PUBBLICAZIONE.md](PUBBLICAZIONE.md)**; qui c'è il perché e quello che PUBBLICAZIONE non copre.

I documenti nel progetto sono modelli scritti per questo gioco, com'è oggi. Non sono una consulenza legale: se hai dubbi falli controllare da un avvocato, e per tasse e partita IVA parla con un commercialista **prima del primo incasso**.

## In sintesi

| Cosa | Stato | Dove |
|---|---|---|
| Informativa privacy (IT + EN) | Pronta, mancano i tuoi dati | `docs/privacy.html` |
| Termini d'uso (IT + EN): licenza, acquisti, recesso, gettoni, comportamento, legge applicabile | Pronti, mancano i tuoi dati | `docs/terms.html` |
| Dati del titolare sul sito (nome, indirizzo, P.IVA, email) | Mancano i tuoi dati | `docs/index.html` |
| Schermata **INFO** nel gioco: versione, titolare, contatti, PRIVACY, TERMINI, crediti e licenze di terzi | Pronta, mancano nome ed email | `scripts/info_panel.gd` |
| Consenso agli annunci (GDPR) con il modulo di Google, pulsante CONSENSO | Pronto nel codice, il messaggio va pubblicato in AdMob | `scripts/admob_backend.gd`, [PUBBLICAZIONE.md](PUBBLICAZIONE.md#3-admob) |
| Avviso nel negozio: i gettoni restano sul telefono | Fatto | `assets/i18n/strings.csv` (`TOKENS_ABOUT`) |
| Copyright del progetto | Fatto, manca il nome | `LICENSE` |
| Registro dei trattamenti | Modello pronto | [in fondo a questo file](#registro-dei-trattamenti) |
| Stato di operatore commerciale (DSA) su Apple e Google | Da fare | [passo 5](#5-digital-services-act-sei-un-operatore-commerciale) |
| Partita IVA, moduli fiscali (W-8BEN), fatture | Da fare con il commercialista | [passo 6](#6-tasse) |
| Controllo del nome | Da fare | [passo 8](#8-nome-e-marchi) |

## 1. I dati da inserire

Ogni dato tra parentesi quadre va sostituito con il tuo, in tutti i file indicati. Sono gli stessi in italiano e in inglese.

| Segnaposto | Cosa scrivere | Dove |
|---|---|---|
| `[NOME E COGNOME DELLO SVILUPPATORE]`, `[DEVELOPER FULL NAME]` | Il tuo nome e cognome (o la ragione sociale, se un giorno aprirai una società) | `docs/privacy.html`, `docs/terms.html`, `docs/index.html`, `DEVELOPER` in `scripts/info_panel.gd`, `LICENSE` |
| `[INDIRIZZO]`, `[POSTAL ADDRESS]` | Un indirizzo postale dove ricevi la posta: via, CAP, città, paese | `docs/privacy.html`, `docs/terms.html`, `docs/index.html` |
| `[EMAIL DI CONTATTO]`, `[CONTACT EMAIL]` | Un indirizzo email dedicato al gioco, che leggi davvero | `docs/privacy.html`, `docs/terms.html`, `docs/index.html`, `CONTACT` in `scripts/info_panel.gd`, `store/scheda_store.md` |
| `[PARTITA IVA, SE PRESENTE]`, `[VAT NUMBER, IF ANY]` | `P.IVA 01234567890`, se ce l'hai. Se non ce l'hai, cancella il segnaposto (con il `·` o la virgola prima) | `docs/terms.html`, `docs/index.html` |
| `[FORNITORE DEL SERVER, PAESE]`, `[SERVER PROVIDER, COUNTRY]` | Chi ospita il relay di AIR HOCKEY, per esempio `Render Services, Inc., Stati Uniti (server a Francoforte)` | `docs/privacy.html` |

Se non metti online il relay, nella privacy togli i due paragrafi su AIR HOCKEY **Online** e sul fornitore del server (le lobby online non ci sono).

Per controllare che non ne sia rimasto nessuno, dalla cartella del progetto:

```bash
grep -rn "\[NOME\|\[INDIRIZZO\|\[EMAIL\|\[PARTITA\|\[FORNITORE\|\[DEVELOPER\|\[POSTAL\|\[CONTACT\|\[VAT\|\[SERVER" docs scripts store LICENSE
```

Due consigli:

- **L'indirizzo diventa pubblico**: lo chiedono il GDPR (chi è il titolare), la legge sul commercio elettronico e soprattutto Apple e Google, che lo mostrano sulla scheda dell'app in UE (passo 5). Se non vuoi mostrare casa tua, valuta prima un indirizzo professionale (per esempio la sede della tua attività o un servizio di domiciliazione), purché ci arrivi davvero la posta.
- **L'email** è anche il punto di contatto unico previsto dal Digital Services Act: rispondi entro tempi ragionevoli, anche alle richieste sulla privacy (entro un mese).

## 2. I documenti del progetto

### Informativa privacy (`docs/privacy.html`)

Copre quello che il gioco fa oggi: niente account, salvataggi sul telefono, AdMob con consenso, acquisti negli store, condivisione, recensioni, AIR HOCKEY in Wi-Fi e online, il sito su GitHub Pages, la versione web, le email, basi giuridiche, trasferimenti fuori dall'UE, tempi di conservazione, minori, diritti e reclamo al Garante.

Va aggiornata (con la data in alto) ogni volta che il gioco comincia a trattare dati in modo nuovo: un altro SDK (analisi, crash, mediazione pubblicitaria), la richiesta di tracciamento su iPhone (ATT), un server che salva qualcosa, un cambio del fornitore del relay. In quei casi aggiorna anche le dichiarazioni degli store (Sicurezza dei dati, Privacy dell'app).

### Termini d'uso (`docs/terms.html`)

Gli store non li impongono per un gioco senza abbonamenti, ma con acquisti e una modalità online servono a mettere per iscritto le regole: licenza d'uso, cosa si compra, che i gettoni restano sul telefono e non si ripristinano, rinuncia al recesso per i contenuti digitali forniti subito, rimborsi tramite gli store, garanzia legale, regole sui nomi in AIR HOCKEY, avviso sulla fotosensibilità, legge italiana con le tutele del consumatore, punto di contatto DSA. Per l'App Store resta valido il contratto di licenza standard di Apple: in App Store Connect lascia la licenza standard e non caricarne una tua.

### La pagina del gioco (`docs/index.html`)

In fondo ci sono i link a privacy e termini e i dati del titolare: la legge sul commercio elettronico (d.lgs. 70/2003, art. 7) chiede nome, indirizzo, email e, se ce l'hai, partita IVA, che va comunque indicata sul sito di chi ha un'attività (art. 35 del d.P.R. 633/1972). La stessa pagina fa da **URL di supporto** per gli store. Il sito non usa cookie né statistiche, quindi non serve il banner dei cookie: se un giorno aggiungi strumenti di analisi o contenuti di terzi che li usano, servirà.

### INFO nel gioco (`scripts/info_panel.gd`)

Il pulsante INFO nell'angolo in alto a sinistra (nella schermata iniziale, nel game over e nella pausa) apre una schermata con versione, titolare, email, i pulsanti PRIVACY e TERMINI (le pagine del sito) e i crediti e le licenze di tutto quello che è fatto da altri.

Le licenze non sono un vezzo: quasi tutto quello che c'è dentro il gioco chiede che il suo avviso arrivi a chi lo usa.

- **Godot** (licenza MIT) e le librerie che contiene: FreeType (chiede una frase precisa, presente), ENet (usata da AIR HOCKEY in Wi-Fi), mbedTLS (Apache 2.0, usata per il `wss://` del relay) e le altre. L'elenco e i testi completi li prende dal motore stesso (`Engine.get_copyright_info()`, `Engine.get_license_info()`), quindi restano giusti quando aggiorni Godot.
- **Plugin** AdMob, godot-iap, Share e In-App Review (MIT), SwiftGodotRuntime (MIT, iOS), AndroidX e Kotlin (Apache 2.0, Android).
- **Font** Bungee e Chakra Petch (SIL Open Font License).
- **Musica** di Pixabay: la licenza non chiede di citare gli autori, il gioco li cita lo stesso.

Quando aggiungi un plugin, un font, un brano o qualunque cosa di terzi, aggiungi una riga in `NOTICES` (o `MUSIC_AUTHORS`) in cima a `scripts/info_panel.gd`, con nome, copyright e licenza che trovi nel suo file LICENSE.

### LICENSE

Dice che il gioco è tuo e che tutti i diritti sono riservati, con l'elenco dei componenti di terzi che restano sotto le loro licenze. Senza una licenza il codice è comunque tuo per legge, ma se il repository è pubblico chiarisce che non è open source. Se un giorno vuoi rendere il codice open source, è il file da cambiare.

## 3. Privacy: cosa fare fuori dal codice

1. **AdMob, messaggio GDPR**: crealo e pubblicalo come spiegato in [PUBBLICAZIONE.md](PUBBLICAZIONE.md#3-admob), con l'URL della privacy. Usando AdMob accetti le norme di Google sul consenso degli utenti dell'UE (EU User Consent Policy): il messaggio pubblicato, il modulo al primo avvio e il pulsante CONSENSO servono a rispettarle. Lascia i partner pubblicitari predefiniti, oppure riducili: il modulo li elenca ai giocatori.
2. **AdMob, Stati Uniti** (consigliato): in *Privacy e messaggi* crea anche il messaggio per le **normative statali degli Stati Uniti**. Alcuni stati (California e altri) danno il diritto di opporsi alla "vendita o condivisione" dei dati per la pubblicità: il modulo di Google lo gestisce, e il pulsante CONSENSO compare da solo dove serve.
3. **Dichiarazioni degli store**: *Sicurezza dei dati* su Google Play e *Privacy dell'app* su App Store Connect, come in [PUBBLICAZIONE.md](PUBBLICAZIONE.md) (passi 4 e 5). Devono dire le stesse cose dell'informativa.
4. **Manifest privacy di iOS**: Apple vuole che l'app dichiari perché usa certe funzioni del sistema (orologio, spazio su disco, file). Godot crea il file `PrivacyInfo.xcprivacy` dalla sezione *Privacy* del preset iOS, con i motivi che servono al motore; i plugin (l'SDK di Google, StoreKit) portano il loro. Dopo l'*Archive* in Xcode, *Generate Privacy Report* mostra cosa viene dichiarato: se Apple segnala un motivo mancante, aggiungilo nella sezione *Privacy* del preset.
5. **Il fornitore del relay**: chi ospita il server tratta gli indirizzi IP per conto tuo, quindi serve un accordo sul trattamento dei dati (art. 28 GDPR, di solito si chiama *Data Processing Agreement* o *DPA*). I servizi come Render lo includono nelle condizioni o lo fanno accettare dal pannello: controlla che ci sia e, se l'azienda è fuori dall'UE, che preveda le clausole contrattuali standard. Se puoi, scegli una regione europea (Render ha Francoforte). Scrivi il fornitore nell'informativa.
6. **Registro dei trattamenti**: compila il [modello in fondo](#registro-dei-trattamenti) e tienilo aggiornato. Chi ha meno di 250 dipendenti è esentato solo se tratta dati in modo occasionale, e gli annunci lo fanno a ogni partita: meglio averlo, è una pagina.
7. **Se qualcuno ti scrive per i suoi dati** (accesso, cancellazione, opposizione): rispondi entro un mese. Il gioco non conserva dati sui giocatori, quindi di solito la risposta è che non hai dati suoi; spiega come cancellare quelli sul telefono (disinstallare il gioco), come cambiare il consenso (CONSENSO) e come gestire quelli pubblicitari (impostazioni del telefono, Google). Tieni nota delle richieste e delle risposte.
8. **Se succede un incidente** (per esempio qualcuno entra nella casella email del gioco o nel server del relay): valuta subito cosa è stato esposto. Se c'è un rischio per le persone, va notificato al Garante entro 72 ore, con la procedura online sul suo sito. Annota comunque ogni incidente, anche quelli che non notifichi (art. 33 GDPR). Proteggi email, account degli store, AdMob e hosting con password uniche e verifica in due passaggi.
9. **Minori**: il gioco non è per i bambini sotto i 13 anni (su Google Play scegli solo fasce dai 13 anni in su, vedi PUBBLICAZIONE). In Italia il consenso agli annunci personalizzati da soli si dà dai 14 anni: l'informativa invita i più giovani a scegliere con un genitore o a rifiutare. Nella grafica e nella scheda dello store non puntare ai bambini (niente personaggi o testi pensati per loro), altrimenti gli store applicano le regole per le app per famiglie.

## 4. Consumatori e acquisti

Gli acquisti li incassano Google e Apple, che mostrano il prezzo con le tasse e chiedono il consenso alla fornitura immediata. A te restano alcune regole del Codice del consumo e dei principi europei sulle valute di gioco:

- **Recesso**: per i contenuti digitali forniti subito si perde, se il consumatore lo accetta prima di pagare (art. 59, lett. o). Lo store lo chiede, i termini lo ripetono.
- **Garanzia legale**: un contenuto comprato che non funziona va sistemato o rimborsato (artt. 135-octies e seguenti). In pratica: se qualcuno scrive che uno stile comprato non si vede, aiutalo, o indicagli il rimborso dello store.
- **Informazioni chiare prima dell'acquisto**: il negozio dice cosa fa ogni oggetto e, per i gettoni, che restano su quel telefono; la scheda dello store e i termini lo ripetono. Non cambiare queste frasi in qualcosa di meno chiaro.
- **Valute di gioco**: nel 2025 la rete europea delle autorità per i consumatori (CPC) ha fissato dei principi per le monete virtuali nei giochi: prezzo sempre chiaro in euro, niente pacchetti fatti per lasciare avanzi da ricomprare, niente pressioni, attenzione ai minori. Oggi il gioco li rispetta: i gettoni si comprano solo con denaro vero, con il prezzo dello store, e nulla ha un prezzo in gettoni. Se un giorno vendessi oggetti in gettoni, mostra anche quanto costano in euro.
- **Niente casse a sorpresa**: il gioco non vende oggetti casuali, ed è meglio che resti così (in alcuni paesi, come il Belgio, sono vietate).
- **Scheda dello store**: descrivi il gioco per quello che è; le frasi come "nessun acquisto aiuta a vincere" devono restare vere.

## 5. Digital Services Act: sei un operatore commerciale?

Il Digital Services Act fa chiedere ad Apple e Google, a chi pubblica app nell'Unione europea, se è un **operatore commerciale** (*trader*). Chi guadagna dall'app (annunci, acquisti) di solito lo è, anche come persona fisica.

- **App Store Connect**: nella sezione *Business* c'è la voce sul Digital Services Act. Da operatore commerciale inserisci indirizzo, telefono ed email, che Apple verifica e **mostra sulla scheda dell'app** nei paesi UE. Senza questa dichiarazione, l'app non viene distribuita in UE.
- **Google Play Console**: nelle impostazioni dell'account sviluppatore dichiari lo stato di operatore commerciale. Da operatore commerciale, Google mostra sulla scheda dell'app nome, indirizzo e contatti.
- **Telefono ed email** saranno pubblici: un numero e un indirizzo dedicati al gioco sono una buona idea.
- Il punto di contatto per utenti e autorità (artt. 11 e 12 DSA) è l'email nei termini d'uso. Il relay di AIR HOCKEY si limita a trasmettere i messaggi tra i giocatori senza conservarli: per il DSA è un semplice trasporto (art. 4): bastano il punto di contatto e le regole d'uso nei termini, che ci sono già.

## 6. Tasse

Da discutere con un commercialista prima del primo pagamento: qui ci sono solo le domande giuste da fargli.

- **Chi ti paga**: AdMob (Google Ireland), Google Play e Apple (società in Irlanda), una volta al mese, quando superi la soglia di pagamento. L'IVA sugli acquisti dei giocatori la versano gli store: tu fatturi (o ricevi i resoconti) da queste società.
- **Occasionale o abituale**: se gli incassi sono sporadici, possono essere *redditi diversi* da indicare nella dichiarazione dei redditi. Un gioco pubblicato che incassa ogni mese è di solito un'attività abituale, e serve la **partita IVA**.
- **Regime forfettario**: per chi incassa fino a 85.000 € l'anno; imposta sostitutiva del 15%, ridotta al 5% per i primi cinque anni per le nuove attività che hanno i requisiti.
- **Codice ATECO** (dal 1° aprile 2025 vale la classificazione ATECO 2025): edizione di videogiochi o produzione di software. La scelta conta: un'attività commerciale richiede l'iscrizione alla Camera di commercio e i contributi INPS da commerciante, con un minimo annuo; un'attività professionale va nella Gestione separata, in proporzione al reddito.
- **Fatture verso società europee**: i servizi a un'azienda di un altro paese UE si fatturano senza IVA italiana (art. 7-ter del d.P.R. 633/1972), con l'iscrizione al VIES e le comunicazioni previste. Il commercialista sa quali.
- **Moduli fiscali americani**: AdMob, Google Play e Apple chiedono il **W-8BEN** (persona fisica non statunitense). Compilalo indicando la convenzione Italia-Stati Uniti: senza, una parte degli incassi dagli utenti americani viene trattenuta alla fonte. In AdMob è in *Pagamenti → Impostazioni → Gestisci informazioni fiscali*; in App Store Connect nella sezione *Business* (un tempo *Accordi, imposte e banche*); su Google Play nel profilo pagamenti.
- **Conserva** i resoconti mensili di pagamento degli store e di AdMob per 10 anni.
- **Musica**: non serve una licenza SIAE, i brani hanno la licenza Pixabay, che ne permette l'uso nel gioco (vedi README).

## 7. I moduli legali degli store, in breve

I passi sono in [PUBBLICAZIONE.md](PUBBLICAZIONE.md); qui c'è cosa rispondere su ciò che ha a che fare con la legge.

| Modulo | Risposta |
|---|---|
| Google Play, *Norme sulla privacy* · App Store, *URL informativa privacy* | `https://sindi98.github.io/one-more-tap/privacy.html` |
| URL di supporto, sito web | `https://sindi98.github.io/one-more-tap/` |
| Google Play, *Annunci* | Sì |
| Google Play, *ID pubblicità* | Sì: pubblicità, analisi, prevenzione frodi |
| Google Play, *Pubblico di destinazione* | Solo fasce dai 13 anni in su; la scheda non punta ai bambini |
| Google Play, *Classificazione (IARC)* · App Store, *Classificazione per età* | Nessuna violenza, niente contenuti sensibili; acquisti in-app: sì; oggetti casuali: no; pubblicità: sì; interazione tra utenti: sì, solo nomi scelti in AIR HOCKEY, senza chat, con chi è sulla stessa Wi-Fi o ha il codice. Apple ha rinnovato le fasce d'età nel 2025 (4+, 9+, 13+, 16+, 18+): rispondi alle domande nuove, comprese quelle su controlli parentali e contenuti degli utenti |
| Google Play, *Sicurezza dei dati* · App Store, *Privacy dell'app* | Come in PUBBLICAZIONE; per il nome di AIR HOCKEY online, su App Store la categoria più vicina è *Contenuti di gioco*, non collegato all'identità, per la funzionalità dell'app |
| App Store, *Contratto di licenza* | Quello standard di Apple |
| App Store, *Crittografia* | Già dichiarata nel preset: solo crittografia esente (HTTPS) |
| Stato di operatore commerciale (DSA) | Passo 5 |
| Informazioni fiscali e bancarie | Passo 6 |

## 8. Nome e marchi

- **Prima di pubblicare** cerca "One More Tap" su [TMview](https://www.tmdn.org/tmview/) (marchi registrati in UE e in Italia), sugli store e su un motore di ricerca. Se c'è un gioco o un marchio con un nome uguale o molto simile, meglio cambiare ora: dopo la pubblicazione l'identificativo dell'app non si cambia più e il nome sì, ma perdi recensioni e riconoscibilità.
- **Registrare il marchio** è facoltativo. Se il gioco va bene, si registra all'UIBM (Italia) o all'EUIPO (tutta l'UE), nelle classi 9 (software e giochi scaricabili) e 41 (intrattenimento); le tariffe sono sui loro siti.
- **DINO** è un omaggio al gioco del browser senza connessione: gli sprite sono disegnati per questo gioco. Non usare nella scheda, negli screenshot o nei video il nome "Chrome", il logo o la grafica originale di Google; i termini dicono già che il gioco non è affiliato a Google.
- Le frasi "Google Play" e "App Store" e i loro badge si usano solo come indicano le linee guida di Google e Apple (per esempio sulla pagina del gioco).

## 9. Accessibilità

L'Atto europeo sull'accessibilità (in Italia d.lgs. 82/2022, in vigore dal 28 giugno 2025) riguarda alcuni prodotti e servizi, come il commercio elettronico. Le microimprese che offrono servizi (meno di 10 persone e fatturato fino a 2 milioni) sono escluse, e la vendita negli store la fanno Apple e Google. Non devi fare niente; resta buona pratica non affidare informazioni solo al colore e tenere i testi leggibili.

## 10. A ogni aggiornamento

- Nuovo SDK, statistiche, crash report, ATT, server che salva dati: aggiorna `docs/privacy.html`, le dichiarazioni degli store e il registro dei trattamenti.
- Nuovo plugin, font o brano: una riga in `NOTICES` o `MUSIC_AUTHORS` in `scripts/info_panel.gd` e nel README.
- Cambiano gli acquisti (nuovi prodotti, abbonamenti, prezzi in gettoni): aggiorna `docs/terms.html`. Per un abbonamento, Apple e Google chiedono anche i link a termini e privacy nella schermata d'acquisto.
- Cambi fornitore del relay: aggiorna l'informativa e l'accordo sul trattamento dei dati.
- In ogni documento cambiato, aggiorna la data "Ultimo aggiornamento".

## Registro dei trattamenti

Un modello già compilato per il gioco com'è oggi (art. 30 GDPR). Copialo in un documento tuo, completa i dati del titolare e tienilo aggiornato: va mostrato al Garante solo se lo chiede.

**Titolare**: [NOME E COGNOME DELLO SVILUPPATORE], [INDIRIZZO], [EMAIL DI CONTATTO]. **Data**: ___

| Trattamento | Finalità | Dati e interessati | Base giuridica | Chi li riceve | Fuori dall'UE | Conservazione | Sicurezza |
|---|---|---|---|---|---|---|---|
| Pubblicità (AdMob) | Mostrare e misurare annunci, prevenire frodi | Giocatori: ID pubblicità, IP, interazioni con gli annunci, dati diagnostici | Consenso (annunci personalizzati); consenso o legittimo interesse (il resto) | Google (titolare autonomo) e i partner elencati nel modulo di consenso | Sì, Google LLC (Data Privacy Framework) | Secondo le norme di Google | Consenso con il modulo di Google, CONSENSO per cambiarlo; niente SDK per chi compra Rimuovi annunci |
| Partite online (relay) | Far giocare insieme da reti diverse | Giocatori: IP, nome scelto, mosse | Esecuzione del servizio; legittimo interesse (limite ai tentativi) | Fornitore dell'hosting (responsabile, DPA) | Dipende dal fornitore (clausole contrattuali standard) | Durata della connessione; tentativi per circa 1 minuto; log tecnici del fornitore secondo la sua informativa | Connessione cifrata (`wss://`), niente scritto su disco, limiti a messaggi e tentativi |
| Email di supporto | Rispondere alle richieste | Chi scrive: email, contenuto | Esecuzione della richiesta | Fornitore della casella email | Dipende dal fornitore | Di regola fino a 24 mesi | Casella dedicata, verifica in due passaggi |
| Vendite negli store | Contabilità e obblighi fiscali | Acquirenti: resoconti di vendita (paese, prodotto, importo, ID ordine) | Obbligo di legge | Commercialista | No | 10 anni | Accesso agli store con verifica in due passaggi |
| Sito del gioco | Pubblicare pagina, informativa e termini | Visitatori: IP nei log di GitHub | Legittimo interesse (sicurezza) | GitHub (titolare autonomo) | Sì, GitHub Inc. (Data Privacy Framework) | Secondo le norme di GitHub | Niente cookie né statistiche |
