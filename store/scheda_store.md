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

## Español

**Name** (30)
One More Tap: Arcade & Hockey

**App Store subtitle** (30)
Juegos sin internet con amigos

**Google Play short description** (80)
3 juegos arcade de un dedo y AIR HOCKEY con amigos. Reto diario. Sin internet.

**App Store keywords** (100)
air,mesa,multijugador,2,jugadores,dino,offline,wifi,reto,diario,dedo,toque,reflejos,zigzag,torre

**App Store promotional text** (170)
Nuevo: ¡el RETO del día! La misma pista para todos, una nueva cada día. Haz tu puntuación y manda el reto a tus amigos.

**Full description**

Juegos arcade de un dedo y AIR HOCKEY con amigos, en una sola app. Se aprende en tres segundos y se juega sin internet.

ZIGZAG: la bola sube sola y tienes un solo control. Toca y gira 90°. Gira dentro de la esquina: demasiado pronto y caes por un lado, demasiado tarde y sales volando de la plataforma. Justo en el centro de la esquina haces un PERFECTO: punto extra y el combo sube de nota. Las plataformas se estrechan, la bola acelera, los colores cambian.

TORRE: sube una espiral alrededor de una torre que gira y salta los huecos de la rampa, cada vez más rápido, al ritmo.

DINO: corre y salta cactus y pájaros, como en el juego del navegador sin internet. Se abre jugando tres días seguidos.

AIR HOCKEY con amigos: crea una sala en el mismo Wi-Fi (no hace falta internet) u online y manda el código por chat. Se juega por equipos, 1 contra 1 o 2 contra 2: arrastra tu paleta y mete gol. Si falta alguien, juega la CPU, así también puedes entrenar solo. Sin cuenta.

RETO DEL DÍA: cada día una pista nueva, la misma para todos. Sin CONTINUAR: solo cuenta tu habilidad. Haz tu puntuación y reta a tus amigos a superarla.

• Tres modos arcade de un dedo, cada uno con su récord
• AIR HOCKEY multijugador con amigos, por Wi-Fi o por internet, sin cuenta
• Reto diario: la misma pista para todos, una nueva cada día
• Juegos sin internet: ZIGZAG, TORRE y DINO funcionan offline, sin wifi
• Partidas de pocos segundos, perfectas para una pausa
• PERFECTO y combos musicales para quien busca precisión
• Gráficos neón, música y sonidos arcade
• Estilos coleccionables para los colores y la bola, de común a legendario: algunos se desbloquean con tus récords
• Comparte la imagen de tu récord y reta a tus amigos

Juego gratis con anuncios. Después de una caída puedes ver un video corto para seguir desde donde estabas, una vez por partida.

Compras opcionales: estilos para los colores y la bola, fichas para continuar sin video, Sin anuncios (cero publicidad y partidas ilimitadas) y la Colección completa con todos los estilos. Siempre compras exactamente lo que ves, sin cajas sorpresa, y ninguna compra ayuda a ganar.

---

## Português (Brasil)

**Name** (30)
One More Tap: Arcade & Hockey

**App Store subtitle** (30)
Jogos sem internet com amigos

**Google Play short description** (80)
3 jogos arcade de um dedo e AIR HOCKEY com amigos. Desafio diário. Offline.

**App Store keywords** (100)
air,aero,hoquei,multiplayer,2,jogadores,dino,offline,wifi,desafio,diario,dedo,reflexo,zigzag,torre

**App Store promotional text** (170)
Novidade: o DESAFIO do dia! O mesmo percurso para todos, um novo a cada dia. Faça sua pontuação e mande o desafio para os amigos.

**Full description**

Jogos arcade de um dedo e AIR HOCKEY com amigos, em um só app. Você aprende em três segundos e joga até sem internet.

ZIGZAG: a bola sobe sozinha e você tem um só comando. Toque, e ela vira 90°. Vire dentro da curva: cedo demais e você cai de lado, tarde demais e voa para fora da plataforma. Bem no centro da curva você faz um PERFEITO: ponto extra e o combo sobe de nota. As plataformas ficam mais estreitas, a bola acelera, as cores mudam.

TORRE: suba uma espiral em volta de uma torre que gira e pule os buracos da rampa, cada vez mais rápido, no ritmo.

DINO: corra e pule cactos e pássaros, como no jogo do navegador sem internet. Ele é liberado quando você joga três dias seguidos.

AIR HOCKEY com amigos: crie uma sala no mesmo Wi-Fi (não precisa de internet) ou online, mande o código no chat, dividam-se em times, 1 contra 1 ou 2 contra 2, e arraste seu batedor. Se faltar alguém, a CPU joga, então dá para treinar sozinho também. Sem conta.

DESAFIO DO DIA: todo dia um percurso novo, o mesmo para todos. Sem CONTINUAR: só a sua habilidade conta. Faça sua pontuação e desafie os amigos a bater.

• Três modos arcade de um dedo, cada um com seu recorde
• AIR HOCKEY multiplayer com amigos, no Wi-Fi ou pela internet, sem conta
• Desafio diário: o mesmo percurso para todos, um novo todo dia
• Jogos offline: ZIGZAG, TORRE e DINO funcionam sem internet
• Partidas de poucos segundos, perfeitas para uma pausa
• PERFEITO e combos musicais para quem busca precisão
• Visual neon, música e sons de arcade
• Estilos colecionáveis para as cores e a bola, do comum ao lendário: alguns são liberados com seus recordes
• Compartilhe a imagem do seu recorde e desafie os amigos

Jogo gratuito com anúncios. Depois de uma queda, você pode ver um vídeo curto para continuar de onde estava, uma vez por partida.

Compras opcionais: estilos para as cores e a bola, fichas para continuar sem vídeo, Sem anúncios (zero publicidade e partidas sem limite) e a Coleção completa com todos os estilos. Você sempre compra exatamente o que vê, sem caixas surpresa, e nenhuma compra ajuda a vencer.

---

## Deutsch

**Name** (30)
One More Tap: Arcade & Hockey

**App Store subtitle** (30)
Offline-Spiele mit Freunden

**Google Play short description** (80)
3 Ein-Finger-Arcade-Spiele + AIR HOCKEY mit Freunden. Tages-Challenge. Offline.

**App Store keywords** (100)
air,airhockey,multiplayer,2,spieler,dino,ohne,internet,wlan,täglich,challenge,reaktion,zickzack

**App Store promotional text** (170)
Neu: TÄGLICH, die Tages-Challenge! Gleiche Strecke für alle, jeden Tag eine neue. Hol deinen Score und schick die Challenge an deine Freunde.

**Full description**

Arcade-Spiele für einen Finger und AIR HOCKEY mit Freunden, in einer App. In drei Sekunden gelernt, auch offline spielbar.

ZIGZAG: Der Ball steigt von allein, und du hast nur einen Befehl. Tippe, und er dreht um 90°. Lenk in der Ecke: zu früh und du fällst seitlich runter, zu spät und du fliegst über das Ende hinaus. Genau in der Mitte der Ecke gibt's ein PERFEKT: einen Extrapunkt, und die Combo steigt um einen Ton. Die Plattformen werden schmaler, der Ball schneller, die Farben wechseln.

TURM: Steig eine Spirale um einen drehenden Turm hinauf und spring über die Löcher in der Rampe, immer schneller, im Rhythmus.

DINO: Lauf und spring über Kakteen und Vögel, wie im Browserspiel ohne Internet. Er wird freigeschaltet, wenn du drei Tage in Folge spielst.

AIR HOCKEY mit Freunden: Erstell eine Lobby im selben WLAN (kein Internet nötig) oder online, schick den Code im Chat, teilt euch in Teams auf, 1 gegen 1 oder 2 gegen 2, und zieh deinen Schläger. Fehlt jemand, spielt die CPU, so kannst du auch allein trainieren. Ohne Konto.

TAGES-CHALLENGE: Tippe auf TÄGLICH und spiel die Strecke des Tages, für alle gleich und jeden Tag neu. Kein WEITER: Nur dein Können zählt. Hol deinen Score und fordere deine Freunde heraus, ihn zu schlagen.

• Drei Arcade-Modi für einen Finger, jeder mit eigenem Rekord
• Multiplayer-AIR HOCKEY mit Freunden, im WLAN oder übers Internet, ohne Konto
• Tages-Challenge: gleiche Strecke für alle, jeden Tag eine neue
• Spiele ohne Internet: ZIGZAG, TURM und DINO laufen offline
• Runden von wenigen Sekunden, perfekt für zwischendurch
• PERFEKT und musikalische Combos für alle, die Präzision lieben
• Neon-Grafik, Arcade-Musik und -Sounds
• Sammelbare Stile für Farben und Ball, von gewöhnlich bis legendär: Einige schaltest du mit deinen Rekorden frei
• Teile ein Bild deines Rekords und fordere deine Freunde heraus

Kostenlos spielbar mit Werbung. Nach einem Sturz kannst du ein kurzes Video ansehen und dort weitermachen, wo du warst, einmal pro Runde.

Optionale Käufe: Stile für Farben und Ball, Münzen zum Weiterspielen ohne Video, Werbefrei (keine Werbung und unbegrenzt spielen) und die Komplette Kollektion mit allen Stilen. Du kaufst immer genau das, was du siehst, keine Überraschungskisten, und kein Kauf hilft beim Gewinnen.

---

## Français

**Name** (30)
One More Tap: Arcade & Hockey

**App Store subtitle** (30)
Jeux sans wifi et entre amis

**Google Play short description** (80)
3 jeux d'arcade à un doigt + AIR HOCKEY entre amis. Défi du jour. Hors ligne.

**App Store keywords** (100)
air,multijoueur,2,joueurs,dino,hors,ligne,internet,offline,défi,jour,quotidien,réflexe,zigzag,tour

**App Store promotional text** (170)
Nouveau : le DÉFI du jour ! Le même tracé pour tous, un nouveau chaque jour. Fais ton score et envoie le défi à tes amis.

**Full description**

Des jeux d'arcade à un doigt et l'AIR HOCKEY entre amis, dans une seule appli. On apprend en trois secondes, on joue même hors ligne.

ZIGZAG : la balle monte toute seule et tu n'as qu'une commande. Touche, et elle tourne de 90°. Tourne dans l'angle : trop tôt, tu tombes sur le côté ; trop tard, tu t'envoles au bout de la plateforme. Pile au centre de l'angle, c'est un PARFAIT : un point bonus, et le combo monte d'une note. Les plateformes rétrécissent, la balle accélère, les couleurs changent.

TOUR : grimpe une spirale autour d'une tour qui tourne et saute les trous de la rampe, de plus en plus vite, en rythme.

DINO : cours et saute par-dessus cactus et oiseaux, comme dans le jeu du navigateur sans internet. Il se débloque quand tu joues trois jours d'affilée.

AIR HOCKEY entre amis : crée un salon sur le même Wi-Fi (pas besoin d'internet) ou en ligne, envoie le code dans un chat, formez les équipes, 1 contre 1 ou 2 contre 2, et fais glisser ton maillet. S'il manque quelqu'un, le CPU joue : tu peux aussi t'entraîner seul. Sans compte.

DÉFI DU JOUR : chaque jour un nouveau tracé, le même pour tous. Pas de CONTINUER : seul ton talent compte. Fais ton score et défie tes amis de le battre.

• Trois modes d'arcade à un doigt, chacun avec son record
• AIR HOCKEY multijoueur entre amis, en Wi-Fi ou par internet, sans compte
• Défi du jour : le même tracé pour tous, un nouveau chaque jour
• Jeux sans wifi ni internet : ZIGZAG, TOUR et DINO marchent hors ligne
• Des parties de quelques secondes, parfaites pour une pause
• PARFAIT et combos musicaux pour les joueurs précis
• Graphismes néon, musique et sons d'arcade
• Des styles à collectionner pour les couleurs et la balle, de commun à légendaire : certains se débloquent avec tes records
• Partage l'image de ton record et défie tes amis

Jeu gratuit avec publicités. Après une chute, tu peux regarder une courte vidéo pour repartir d'où tu étais, une fois par partie.

Achats facultatifs : des styles pour les couleurs et la balle, des jetons pour continuer sans vidéo, Sans pub (aucune publicité et parties illimitées) et la Collection complète avec tous les styles. Tu achètes toujours exactement ce que tu vois, pas de coffres surprise, et aucun achat n'aide à gagner.

---

## Screenshot da rifare

Gli store mostrano i primi 2–3 screenshot nei risultati di ricerca: lì si decide se uno apre la scheda. Uno screenshot per idea, con una **didascalia grande in alto** (font Bungee, colore neon del gioco) sopra la schermata vera. Ordine consigliato:

| # | Schermata da catturare | Didascalia IT | Didascalia EN | Didascalia ES | Didascalia PT | Didascalia DE | Didascalia FR |
|---|---|---|---|---|---|---|---|
| 1 | ZIGZAG in partita, con PERFETTO ×3 a schermo | UN DITO. OGNI TAP CONTA. | ONE FINGER. EVERY TAP COUNTS. | UN DEDO. CADA TOQUE CUENTA. | UM DEDO. CADA TOQUE CONTA. | EIN FINGER. JEDER TAP ZÄHLT. | UN DOIGT. CHAQUE TAP COMPTE. |
| 2 | AIR HOCKEY 2 contro 2 in partita | AIR HOCKEY CON GLI AMICI | AIR HOCKEY WITH FRIENDS | AIR HOCKEY CON AMIGOS | AIR HOCKEY COM AMIGOS | AIR HOCKEY MIT FREUNDEN | AIR HOCKEY ENTRE AMIS |
| 3 | Game over della SFIDA con il punteggio | SFIDA DEL GIORNO: BATTI I TUOI AMICI | DAILY CHALLENGE: BEAT YOUR FRIENDS | RETO DEL DÍA: GANA A TUS AMIGOS | DESAFIO DO DIA: VENÇA OS AMIGOS | TÄGLICH: SCHLAG DEINE FREUNDE | DÉFI DU JOUR : BATS TES AMIS |
| 4 | TORRE in partita, a metà di un salto | SALTA I BUCHI DELLA TORRE | JUMP THE HOLES IN THE TOWER | SALTA LOS HUECOS DE LA TORRE | PULE OS BURACOS DA TORRE | SPRING ÜBER DIE LÖCHER IM TURM | SAUTE LES TROUS DE LA TOUR |
| 5 | DINO in partita, sopra un gruppo di cactus | DINO: ANCHE SENZA INTERNET | DINO: NO INTERNET NEEDED | DINO: JUEGA SIN INTERNET | DINO: JOGUE SEM INTERNET | DINO: SPIELEN OHNE INTERNET | DINO : MÊME SANS WIFI |
| 6 | Lobby di AIR HOCKEY con le squadre e il codice | WI-FI O ONLINE, SENZA ACCOUNT | WI-FI OR ONLINE, NO ACCOUNT | WI-FI U ONLINE, SIN CUENTA | WI-FI OU ONLINE, SEM CONTA | WI-FI ODER ONLINE, OHNE KONTO | WI-FI OU ONLINE, SANS COMPTE |
| 7 | Negozio con uno stile leggendario provato sul gioco | STILI DA COLLEZIONARE | COLLECT NEON STYLES | COLECCIONA ESTILOS NEÓN | COLECIONE ESTILOS NEON | SAMMLE NEON-STILE | COLLECTIONNE DES STYLES NÉON |

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
- **Sito web / email di supporto**: `https://sindi98.github.io/one-more-tap/` · onemoretap1998@gmail.com
- **Informativa privacy**: `https://sindi98.github.io/one-more-tap/privacy.html`
- **Note per la revisione Apple**: "Free arcade game with AdMob ads. Ads never appear during play. Interstitials appear only when a run has ended (at most every 3 runs and 90 seconds); a banner shows on the mode selection screen only. Each run costs one of 5 lives, which come back over time or all at once with an optional rewarded video; another optional rewarded video lets the player continue a run once. No login required. In-app purchases are in STILI on the start screen: cosmetic styles (non-consumable), Remove Ads (non-consumable: no ads, no banner and no lives limit from then on), Full Collection (non-consumable) and token packs (consumable, one token continues a run without a video). RIPRISTINA restores purchases. The third mode, DINO, opens after the game is opened on three days in a row; the other two modes are available at once. SFIDA (next to STILI) turns on the daily challenge: the same track for every player that day, with no continue. AIR HOCKEY (next to SFIDA) is a multiplayer mode: one player creates a lobby, on the same Wi-Fi (WI-FI: direct, no server; the others join from the list or with its 4-character code) or online (ONLINE: through our relay server; the others type its 5-character code). Online lobbies are private, joined by code only, with no chat. Empty places are played by the CPU, so it can be tried on a single device: AIR HOCKEY, then WI-FI or ONLINE, then INIZIA. The Local Network permission is used only for Wi-Fi lobbies."
