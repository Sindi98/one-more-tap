# Relay di AIR HOCKEY

Il piccolo server che permette di giocare ad AIR HOCKEY **via Internet**, con amici su reti diverse (un'altra casa, il 4G). Sulla stessa Wi-Fi non serve: lì i telefoni si parlano direttamente.

I telefoni non possono collegarsi tra loro attraverso Internet, perché i router e gli operatori non lo permettono. Allora si collegano tutti a questo server, che passa i pacchetti dall'uno all'altro:

- Chi tocca **LOBBY ONLINE** apre una stanza e riceve un **codice di 5 caratteri**. Il suo telefono è l'host e fa girare la partita, come in Wi-Fi.
- Gli amici scrivono il codice in **ENTRA** (il pulsante **COPIA** nella lobby prepara un invito da incollare in chat).
- Il server inoltra solo i messaggi tra l'host e gli ospiti, tra ospiti mai. Non salva niente: quando l'host esce, la stanza sparisce.
- Le lobby online non sono elencate pubblicamente: si entra solo con il codice, quindi si gioca solo con chi lo riceve.

È un file solo, `relay.mjs` (Node.js, un'unica dipendenza: [`ws`](https://github.com/websockets/ws)). Dal lato del gioco lo usa `scripts/relay_peer.gd`.

## Provarlo sul computer

Serve [Node.js](https://nodejs.org) 18 o successivo.

```
cd server
npm install
npm start
```

Il relay ascolta sulla porta 47620. Con `RELAY_URL` vuoto in `scripts/net.gd`, le build di debug (F5 dall'editor) usano proprio questo, `ws://127.0.0.1:47620`: avvia due istanze del gioco (*Debug → Customize Run Instances…*), in una tocca AIR HOCKEY → LOBBY ONLINE, nell'altra scrivi il codice.

Test del server: `npm test`. Con il relay avviato, anche `godot --headless --path . --script res://tests/test_relay_peer.gd` (dalla cartella del progetto) lo prova insieme al codice del gioco.

## Metterlo online

Il relay deve stare su un server raggiungibile da Internet, con **HTTPS** (i telefoni si collegano con `wss://`; la versione web su itch.io non accetta altro). Qualsiasi servizio che faccia girare Node.js o Docker e supporti i WebSocket va bene. Due strade:

### Render (la più semplice)

1. Crea un account su [render.com](https://render.com) e collegalo a GitHub.
2. *New → Web Service*, scegli il repository `one-more-tap`.
3. **Root Directory**: `server`. **Runtime**: Node. **Build Command**: `npm ci`. **Start Command**: `npm start`.
4. Scegli il piano. Quello **gratuito** va bene per provare, ma dopo un po' senza traffico il servizio si addormenta e la prima connessione può metterci circa un minuto: in quel caso LOBBY ONLINE può dire "Server non raggiungibile", e al secondo tentativo funziona. Per la pubblicazione conviene un piano a pagamento sempre acceso (verifica prezzi e condizioni attuali sul sito).
5. *Create Web Service*. Render dà un indirizzo come `https://omt-relay.onrender.com`: aprilo nel browser, deve dire `One More Tap relay: ok`.

### Docker, su qualunque server

```
cd server
docker build -t omt-relay .
docker run -d --restart unless-stopped -p 47620:47620 omt-relay
```

Funziona su Fly.io, Railway, un VPS, ecc. Il relay legge la porta da `PORT`, se il servizio la imposta. Davanti serve qualcosa che dia l'HTTPS: lo fanno già i servizi gestiti; su un VPS, per esempio, [Caddy](https://caddyserver.com) con `reverse_proxy localhost:47620`.

### Poi, nel gioco

In `scripts/net.gd` scrivi l'indirizzo in `RELAY_URL`, con `wss://` al posto di `https://`:

```gdscript
const RELAY_URL := "wss://omt-relay.onrender.com"
```

Da quel momento LOBBY ONLINE c'è in tutte le build, anche nella versione web (che in Wi-Fi non può giocare). Finché `RELAY_URL` è vuoto, le build di release non mostrano le lobby online.

## Limiti e protezioni

Le costanti sono in cima a `relay.mjs`:

- 5 ospiti al massimo per stanza (una partita 2 contro 2 ne usa 3), 2000 stanze in tutto.
- Messaggi fino a 4 KB, 200 al secondo per telefono (in partita ne servono circa 30-60).
- 30 tentativi di ingresso al minuto per indirizzo, così i codici non si indovinano provandoli tutti (32⁵ = più di 33 milioni).
- 10 secondi per aprire o raggiungere una stanza dopo il collegamento; un telefono che non risponde ai ping per una trentina di secondi viene scollegato; uno troppo lento a ricevere viene lasciato andare.

Il server non scrive log delle partite e non conserva nulla. Passano da lui, solo per la durata della partita, gli indirizzi IP dei telefoni (come per qualunque connessione) e il nome scelto da ciascun giocatore, che il gioco manda all'host. Per l'informativa privacy vedi [PUBBLICAZIONE.md](../PUBBLICAZIONE.md).

## Il protocollo

- Messaggi di testo (JSON): `{"t":"host","v":1}` apre una stanza → `{"t":"hosted","code":"K7Q2M"}`. `{"t":"join","code":"K7Q2M","id":12345,"v":1}` entra con un id scelto dal telefono → `{"t":"joined"}`, e l'host riceve `{"t":"peer","id":12345,"on":true}` (`false` quando esce). I rifiuti arrivano come `{"t":"error","reason":"not_found|full|playing|version|busy|bad"}`, poi il server chiude.
- Messaggi binari: 6 byte di intestazione (id del peer, int32 little-endian; canale; modalità di invio) e poi i dati del multiplayer di Godot. Dall'host l'id dice a chi va (0: a tutti, -n: a tutti tranne n); il relay lo sostituisce con l'id di chi l'ha mandato.
- Codici di chiusura: 4000 l'host è uscito, 4001 rifiutato, 4003 allontanato dall'host, 4008 troppi messaggi.

Se cambi il protocollo, aumenta `PROTOCOL` sia qui sia in `scripts/relay_peer.gd`.
