# One More Tap

Gioco arcade verticale a un dito, Godot 4.3+ / GDScript. MVP: modalità infinita, un solo controllo, piattaforme generate, game over, record locale, restart immediato, grafica neon.

## Aprire e giocare

1. Installa **Godot 4.3 o successivo** (versione Standard, non .NET).
2. Project Manager → **Import** → seleziona `project.godot`.
3. Al primo avvio Godot importa i font (qualche secondo). Poi **F5**.

Su desktop: clic sinistro, Spazio, Invio o Freccia su. Su telefono: tap ovunque.

## Regole

- La pallina sale da sola in diagonale. Ogni tap la fa girare di 90°.
- Bisogna girare **dentro l'angolo**: prima cade di lato ("Troppo presto"), dopo esce dalla fine della piattaforma ("Troppo tardi").
- Ogni piattaforma raggiunta vale 1 punto. Girare al centro esatto dell'angolo (±16% della larghezza) è un **PERFETTO**: +1 punto, la pallina si riallinea al centro e le combo salgono di nota.
- Piattaforme sempre più strette e pallina sempre più veloce. Il colore cambia ogni 12 punti.
- Quando cadi: anello rosso sull'angolo mancato + freccia nella direzione giusta. Riprova subito col pulsante o con un tap.

## Struttura

| File | Ruolo |
|---|---|
| `scripts/track.gd` | Regole pure (nessun nodo): generazione, tap, caduta con motivo, punteggio. **Tutte le costanti di difficoltà sono in cima.** |
| `scripts/world_view.gd` | Disegno: griglia, percorso neon, pallina, scia, particelle, marker dell'errore |
| `scripts/game.gd` | Flusso: stati, input, camera, shake, vibrazione, salvataggio |
| `scripts/hud.gd` | UI costruita in codice: punteggio, combo, start, game over, pausa |
| `scripts/sfx.gd` | Suoni sintetizzati all'avvio, nessun file audio |
| `tests/test_track.gd` | Test headless delle regole |

Renderer **Compatibility** (OpenGL): massima compatibilità con Android economici. Viewport 720×1280 verticale, si estende sui telefoni più lunghi.

## Test

```
godot --headless --path . --script res://tests/test_track.gd
```

Controllano che un giocatore perfetto sopravviva su 60 percorsi diversi, che gli angoli restino sempre nello schermo, che "presto/tardi" sia corretto, il conteggio dei perfetti e la rampa di difficoltà. Durano qualche secondo.

## Export su telefono

**Android**
1. Editor → *Manage Export Templates* → scarica i template.
2. Installa JDK 17 e Android SDK, impostali in *Editor Settings → Export → Android*.
3. *Project → Export → Add → Android*. Spunta il permesso **VIBRATE** (serve per la vibrazione).
4. Con il telefono in debug USB, il pulsante Android in alto a destra installa e avvia il gioco.

**iOS**: serve un Mac con Xcode. Per pubblicare serve l'Apple Developer Program.

## Prossimi passi

1. Playtest su telefono vero: tarare `W_START`, `W_STEP`, `V_START`, `V_STEP`, `PERFECT_FRAC` in `track.gd`.
2. Continua con annuncio facoltativo (AdMob tramite plugin) solo dopo che il controllo convince.
3. Sfida giornaliera: `Track.new(width, height, seed)` accetta già un seed, basta derivarlo dalla data.

Font: Bungee e Chakra Petch, licenza SIL Open Font License (file in `assets/fonts`).
