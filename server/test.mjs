// Tests for the relay, against a real one on a free local port:
//   npm test
import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import { WebSocket } from "ws";
import { CLOSED, CODE_CHARS, CODE_LENGTH, KICKED, PROTOCOL, REFUSED, TOO_FAST, startRelay } from "./relay.mjs";

let relay;
let url;

before(async () => {
  relay = await startRelay({ port: 0, helloTimeout: 300, joinsPerMinute: 1000 });
  url = `ws://127.0.0.1:${relay.port}`;
});

after(() => relay.close());

// A phone: a socket, with every message it gets queued for the test to read.
function phone(address = url) {
  const ws = new WebSocket(address);
  ws.inbox = [];
  ws.waiting = [];
  ws.on("message", (data, isBinary) => {
    const msg = isBinary ? Buffer.from(data) : JSON.parse(data.toString());
    const next = ws.waiting.shift();
    if (next) next(msg);
    else ws.inbox.push(msg);
  });
  ws.closed = new Promise((resolve) => ws.on("close", (code) => resolve(code)));
  return new Promise((resolve, reject) => {
    ws.on("open", () => resolve(ws));
    ws.on("error", reject);
  });
}

function next(ws, ms = 1000) {
  if (ws.inbox.length > 0) return Promise.resolve(ws.inbox.shift());
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("no message")), ms);
    ws.waiting.push((msg) => {
      clearTimeout(timer);
      resolve(msg);
    });
  });
}

// Nothing more arrives within `ms`.
async function quiet(ws, ms = 150) {
  await new Promise((r) => setTimeout(r, ms));
  assert.equal(ws.inbox.length, 0, `unexpected: ${JSON.stringify(ws.inbox)}`);
}

function packet(peer, channel, mode, text) {
  const payload = Buffer.from(text);
  const out = Buffer.alloc(6 + payload.length);
  out.writeInt32LE(peer, 0);
  out[4] = channel;
  out[5] = mode;
  payload.copy(out, 6);
  return out;
}

function read(buf) {
  return { peer: buf.readInt32LE(0), channel: buf[4], mode: buf[5], text: buf.subarray(6).toString() };
}

async function room() {
  const host = await phone();
  host.send(JSON.stringify({ t: "host", v: PROTOCOL }));
  const hosted = await next(host);
  assert.equal(hosted.t, "hosted");
  return { host, code: hosted.code };
}

async function guest(code, id) {
  const ws = await phone();
  ws.send(JSON.stringify({ t: "join", code, id, v: PROTOCOL }));
  return ws;
}

async function joined(host, code, id) {
  const ws = await guest(code, id);
  assert.deepEqual(await next(ws), { t: "joined" });
  assert.deepEqual(await next(host), { t: "peer", id, on: true });
  return ws;
}

test("answers health checks", async () => {
  const res = await fetch(`http://127.0.0.1:${relay.port}/`);
  assert.equal(res.status, 200);
});

test("a room gets a code of the right characters", async () => {
  const { host, code } = await room();
  assert.equal(code.length, CODE_LENGTH);
  for (const c of code) assert.ok(CODE_CHARS.includes(c), c);
  host.close();
});

test("packets go from a guest to the host, with the guest's id", async () => {
  const { host, code } = await room();
  const g = await joined(host, code, 777);
  g.send(packet(99, 1, 2, "finger"), { binary: true });
  assert.deepEqual(read(await next(host)), { peer: 777, channel: 1, mode: 2, text: "finger" });
  host.close();
});

test("the host reaches one guest, all of them, or all but one", async () => {
  const { host, code } = await room();
  const a = await joined(host, code, 10);
  const b = await joined(host, code, 20);
  const c = await joined(host, code, 30);
  host.send(packet(20, 0, 2, "to b"), { binary: true });
  assert.deepEqual(read(await next(b)), { peer: 1, channel: 0, mode: 2, text: "to b" });
  host.send(packet(0, 1, 0, "to all"), { binary: true });
  for (const ws of [a, b, c]) assert.equal(read(await next(ws)).text, "to all");
  host.send(packet(-10, 1, 0, "not a"), { binary: true });
  assert.equal(read(await next(b)).text, "not a");
  assert.equal(read(await next(c)).text, "not a");
  await quiet(a);
  host.send(packet(1, 0, 0, "to self"), { binary: true });
  host.send(packet(12345, 0, 0, "nobody"), { binary: true });
  await quiet(host);
  await quiet(b);
  host.close();
});

test("guests never reach each other", async () => {
  const { host, code } = await room();
  const a = await joined(host, code, 10);
  const b = await joined(host, code, 20);
  a.send(packet(20, 0, 0, "psst"), { binary: true });
  assert.equal(read(await next(host)).peer, 10);
  await quiet(b);
  host.close();
});

test("refusals say why", async () => {
  const { host, code } = await room();
  const cases = [
    [{ t: "join", code: "ZZZZZ", id: 5, v: PROTOCOL }, "not_found"],
    [{ t: "join", code, id: 5, v: PROTOCOL + 1 }, "version"],
    [{ t: "join", code, id: 1, v: PROTOCOL }, "bad"],
    [{ t: "join", code, id: 2.5, v: PROTOCOL }, "bad"],
    [{ t: "dance", v: PROTOCOL }, "bad"],
  ];
  for (const [msg, reason] of cases) {
    const ws = await phone();
    ws.send(JSON.stringify(msg));
    assert.deepEqual(await next(ws), { t: "error", reason });
    assert.equal(await ws.closed, REFUSED);
  }
  const junk = await phone();
  junk.send("{{{");
  assert.deepEqual(await next(junk), { t: "error", reason: "bad" });
  host.close();
});

test("a lowercase code with spaces still finds the room", async () => {
  const { host, code } = await room();
  const ws = await guest(` ${code.toLowerCase()} `, 44);
  assert.deepEqual(await next(ws), { t: "joined" });
  host.close();
});

test("ids are not shared and rooms are not overfilled", async () => {
  const { host, code } = await room();
  await joined(host, code, 10);
  const twin = await guest(code, 10);
  assert.deepEqual(await next(twin), { t: "error", reason: "bad" });
  for (let id = 11; id < 15; id++) await joined(host, code, id);
  const late = await guest(code, 99);
  assert.deepEqual(await next(late), { t: "error", reason: "full" });
  host.close();
});

test("a locked room turns newcomers away", async () => {
  const { host, code } = await room();
  host.send(JSON.stringify({ t: "lock", on: true }));
  await new Promise((r) => setTimeout(r, 50));
  const ws = await guest(code, 8);
  assert.deepEqual(await next(ws), { t: "error", reason: "playing" });
  host.send(JSON.stringify({ t: "lock", on: false }));
  await new Promise((r) => setTimeout(r, 50));
  await joined(host, code, 9);
  host.close();
});

test("the host hears when a guest leaves or is sent away", async () => {
  const { host, code } = await room();
  const a = await joined(host, code, 10);
  const b = await joined(host, code, 20);
  a.close();
  assert.deepEqual(await next(host), { t: "peer", id: 10, on: false });
  host.send(JSON.stringify({ t: "kick", id: 20 }));
  assert.equal(await b.closed, KICKED);
  assert.deepEqual(await next(host), { t: "peer", id: 20, on: false });
  host.close();
});

test("when the host leaves the room closes for everyone", async () => {
  const { host, code } = await room();
  const a = await joined(host, code, 10);
  host.close();
  assert.equal(await a.closed, CLOSED);
  await new Promise((r) => setTimeout(r, 50));
  assert.ok(!relay.rooms.has(code));
  const ws = await guest(code, 11);
  assert.deepEqual(await next(ws), { t: "error", reason: "not_found" });
});

test("guests can't run the room", async () => {
  const { host, code } = await room();
  const a = await joined(host, code, 10);
  const b = await joined(host, code, 20);
  a.send(JSON.stringify({ t: "kick", id: 20 }));
  a.send(JSON.stringify({ t: "lock", on: true }));
  await quiet(b);
  await joined(host, code, 30);
  host.close();
});

test("a phone that says nothing is let go", async () => {
  const ws = await phone();
  assert.equal(await ws.closed, REFUSED);
});

test("a flood is cut off", async () => {
  const { host, code } = await room();
  const a = await joined(host, code, 10);
  for (let i = 0; i < 2000; i++) a.send(packet(1, 0, 0, "x"), { binary: true });
  assert.equal(await a.closed, TOO_FAST);
  host.close();
});

test("oversized messages are refused", async () => {
  const { host, code } = await room();
  const a = await joined(host, code, 10);
  a.send(Buffer.alloc(10_000), { binary: true });
  assert.equal(await a.closed, 1009);
  host.close();
});

test("trying codes in a hurry is stopped", async () => {
  const strict = await startRelay({ port: 0, joinsPerMinute: 3 });
  const at = `ws://127.0.0.1:${strict.port}`;
  const reasons = [];
  for (let i = 0; i < 5; i++) {
    const ws = await phone(at);
    ws.send(JSON.stringify({ t: "join", code: "AAAAA", id: 5, v: PROTOCOL }));
    reasons.push((await next(ws)).reason);
  }
  assert.deepEqual(reasons, ["not_found", "not_found", "not_found", "busy", "busy"]);
  await strict.close();
});
