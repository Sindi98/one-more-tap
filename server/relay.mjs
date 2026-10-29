// One More Tap — the AIR HOCKEY relay, for matches over the internet.
//
// Phones on different networks can't reach each other directly, so this
// server passes their packets along. One phone opens a room: it is the host
// (peer 1) and runs the match. Friends join it with the room's 5-character
// code. Nothing is stored: a room lives as long as its host is connected.
//
// Text messages (JSON) open, join and manage rooms. Binary messages carry the
// game, with a 6-byte header: the peer id (int32, little-endian), the channel
// and the transfer mode (one byte each), then the payload. From the host, the
// id says who gets it (0: every guest, -n: every guest but n, n: guest n);
// guests can only talk to the host. The relay replaces the id with the
// sender's before passing the message on. The game side is
// scripts/relay_peer.gd.

import { randomInt } from "node:crypto";
import http from "node:http";
import { pathToFileURL } from "node:url";
import { WebSocket, WebSocketServer } from "ws";

export const PROTOCOL = 1; // bumped when this exchange changes, with RelayPeer.PROTOCOL
export const CODE_CHARS = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"; // no 0/O, 1/I
export const CODE_LENGTH = 5;
export const MAX_GUESTS = 5; // a full 2 vs 2 has 3: room for those being turned away
const HEADER = 6;
const DEFAULTS = {
  port: 47620,
  maxRooms: 2000,
  maxMessage: 4096, // bytes
  rate: 200, // messages per second per connection, on average...
  burst: 400, // ...with this many at once
  joinsPerMinute: 30, // per address: codes can't be found by trying them all
  helloTimeout: 10_000, // ms to open or join a room after connecting
  pingEvery: 15_000, // ms; a connection that doesn't answer is dropped
  maxBuffered: 1 << 20, // bytes waiting for a slow phone before it is dropped
};

// Close codes, read by the game.
export const CLOSED = 4000; // the host left: the room is gone
export const REFUSED = 4001; // see the "error" message sent just before
export const KICKED = 4003;
export const TOO_FAST = 4008;

export function startRelay(options = {}) {
  const cfg = { ...DEFAULTS, ...options };
  const rooms = new Map(); // code -> { code, host, guests: Map(id -> socket), locked }
  const joins = new Map(); // address -> { count, since }

  const server = http.createServer((_req, res) => {
    res.writeHead(200, { "content-type": "text/plain" });
    res.end("One More Tap relay: ok\n"); // for the host's health checks
  });
  const wss = new WebSocketServer({ server, maxPayload: cfg.maxMessage });

  wss.on("connection", (ws, req) => {
    ws.address = clientAddress(req);
    ws.alive = true;
    ws.tokens = cfg.burst;
    ws.last = Date.now();
    ws.room = null;
    ws.peer = 0;
    ws.hello = setTimeout(() => {
      if (!ws.room) ws.close(REFUSED, "timeout");
    }, cfg.helloTimeout);
    ws.on("pong", () => {
      ws.alive = true;
    });
    ws.on("message", (data, isBinary) => {
      if (!spend(ws)) {
        ws.close(TOO_FAST, "too fast");
        return;
      }
      if (isBinary) relay(ws, data);
      else control(ws, data.toString());
    });
    ws.on("close", () => leave(ws));
    ws.on("error", () => {});
  });

  const heartbeat = setInterval(() => {
    for (const ws of wss.clients) {
      if (!ws.alive) {
        ws.terminate();
        continue;
      }
      ws.alive = false;
      ws.ping();
    }
    const now = Date.now();
    for (const [address, j] of joins) {
      if (now - j.since > 60_000) joins.delete(address);
    }
  }, cfg.pingEvery);

  function control(ws, text) {
    let msg;
    try {
      msg = JSON.parse(text);
    } catch {
      msg = null;
    }
    if (!msg || typeof msg !== "object") return refuse(ws, "bad");
    if (ws.room) {
      // In a room, only the host has something to say.
      if (ws.peer !== 1) return;
      if (msg.t === "kick") ws.room.guests.get(msg.id)?.close(KICKED, "kicked");
      else if (msg.t === "lock") ws.room.locked = Boolean(msg.on);
      return;
    }
    if (msg.v !== PROTOCOL) return refuse(ws, "version");
    if (msg.t === "host") return openRoom(ws);
    if (msg.t === "join") return joinRoom(ws, msg);
    refuse(ws, "bad");
  }

  function openRoom(ws) {
    if (rooms.size >= cfg.maxRooms) return refuse(ws, "busy");
    let code;
    do {
      code = Array.from({ length: CODE_LENGTH }, () => CODE_CHARS[randomInt(CODE_CHARS.length)]).join("");
    } while (rooms.has(code));
    const room = { code, host: ws, guests: new Map(), locked: false };
    rooms.set(code, room);
    enter(ws, room, 1);
    send(ws, { t: "hosted", code });
  }

  function joinRoom(ws, msg) {
    const now = Date.now();
    const j = joins.get(ws.address) ?? { count: 0, since: now };
    if (now - j.since > 60_000) {
      j.count = 0;
      j.since = now;
    }
    j.count += 1;
    joins.set(ws.address, j);
    if (j.count > cfg.joinsPerMinute) return refuse(ws, "busy");
    const room = rooms.get(String(msg.code ?? "").trim().toUpperCase());
    if (!room) return refuse(ws, "not_found");
    if (room.locked) return refuse(ws, "playing");
    if (room.guests.size >= MAX_GUESTS) return refuse(ws, "full");
    const id = msg.id;
    if (!Number.isInteger(id) || id < 2 || id > 0x7fffffff || room.guests.has(id)) {
      return refuse(ws, "bad");
    }
    room.guests.set(id, ws);
    enter(ws, room, id);
    send(ws, { t: "joined" });
    send(room.host, { t: "peer", id, on: true });
  }

  function enter(ws, room, peer) {
    clearTimeout(ws.hello);
    ws.room = room;
    ws.peer = peer;
  }

  function relay(ws, data) {
    const room = ws.room;
    if (!room || data.length < HEADER) return;
    const out = Buffer.from(data);
    if (ws.peer !== 1) {
      out.writeInt32LE(ws.peer, 0);
      forward(room.host, out);
      return;
    }
    const target = data.readInt32LE(0);
    out.writeInt32LE(1, 0);
    if (target > 1) {
      const guest = room.guests.get(target);
      if (guest) forward(guest, out);
      return;
    }
    for (const [id, guest] of room.guests) {
      if (target === 0 || (target < 0 && id !== -target)) forward(guest, out);
    }
  }

  function forward(to, data) {
    if (to.readyState !== WebSocket.OPEN) return;
    if (to.bufferedAmount > cfg.maxBuffered) {
      to.terminate(); // too far behind to play
      return;
    }
    to.send(data, { binary: true });
  }

  function leave(ws) {
    clearTimeout(ws.hello);
    const room = ws.room;
    if (!room) return;
    ws.room = null;
    if (ws.peer === 1) {
      rooms.delete(room.code);
      for (const guest of room.guests.values()) guest.close(CLOSED, "closed");
      return;
    }
    if (room.guests.get(ws.peer) !== ws) return;
    room.guests.delete(ws.peer);
    send(room.host, { t: "peer", id: ws.peer, on: false });
  }

  function refuse(ws, reason) {
    send(ws, { t: "error", reason });
    ws.close(REFUSED, reason);
  }

  // Each connection gets `rate` messages a second, saved up to `burst`.
  function spend(ws) {
    const now = Date.now();
    ws.tokens = Math.min(cfg.burst, ws.tokens + ((now - ws.last) / 1000) * cfg.rate);
    ws.last = now;
    if (ws.tokens < 1) return false;
    ws.tokens -= 1;
    return true;
  }

  return new Promise((resolve) => {
    server.listen(cfg.port, () => {
      resolve({
        port: server.address().port,
        rooms,
        close() {
          clearInterval(heartbeat);
          for (const ws of wss.clients) ws.terminate();
          wss.close();
          return new Promise((done) => server.close(done));
        },
      });
    });
  });
}

function send(ws, msg) {
  if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(msg));
}

// Behind a hosting provider's proxy the phone's address is in x-forwarded-for.
function clientAddress(req) {
  const forwarded = req.headers["x-forwarded-for"];
  if (typeof forwarded === "string" && forwarded.length > 0) {
    return forwarded.split(",")[0].trim();
  }
  return req.socket.remoteAddress ?? "";
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  const port = Number(process.env.PORT) || DEFAULTS.port;
  startRelay({ port }).then(({ port: p }) => {
    console.log(`One More Tap relay listening on port ${p}`);
  });
}
