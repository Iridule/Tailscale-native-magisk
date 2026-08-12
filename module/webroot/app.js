const HELPER = "/data/adb/modules/native_tailscale/webui.sh";
const $ = (q) => document.querySelector(q);
const $$ = (q) => [...document.querySelectorAll(q)];

function shellQuote(value) {
  return `'${String(value).replace(/'/g, `'\\''`)}'`;
}

let callbackId = 0;
let sessionRestoreUntil = 0;
window.__nativeTailscaleCallbacks = {};

function execHelper(args) {
  if (!window.ksu || typeof window.ksu.exec !== "function") {
    return Promise.reject(new Error("KsuWebUIStandalone bridge is unavailable."));
  }
  return new Promise((resolve, reject) => {
    const id = `callback${++callbackId}`;
    const timer = setTimeout(() => {
      delete window.__nativeTailscaleCallbacks[id];
      reject(new Error("The root command timed out."));
    }, 240000);
    window.__nativeTailscaleCallbacks[id] = (code, stdout, stderr) => {
      clearTimeout(timer);
      delete window.__nativeTailscaleCallbacks[id];
      if (code === 0) resolve(stdout);
      else reject(new Error(stderr || stdout || `Command failed (${code}).`));
    };
    window.ksu.exec(`${HELPER} ${args}`, null, `window.__nativeTailscaleCallbacks.${id}`);
  });
}

function parseFields(output) {
  return Object.fromEntries(String(output).split(/\r?\n/).filter(Boolean).map((line) => {
    const index = line.indexOf("=");
    return index < 0 ? [line, ""] : [line.slice(0, index), line.slice(index + 1)];
  }));
}

function bool(value) { return value === "true"; }
function setText(id, value, fallback = "—") { $(id).textContent = value || fallback; }

function showAlert(message, type = "warn") {
  const box = $("#alertBox");
  box.textContent = message;
  box.classList.toggle("hidden", !message);
  box.dataset.type = type;
}

function renderStatus(data) {
  const state = data.backend_state || "Unavailable";
  setText("#backendState", state);
  setText("#ipAddress", data.ipv4 || data.ipv6, bool(data.running) ? "No Tailscale IP assigned" : "Native daemon is stopped");
  setText("#interfaceState", `TUN ${data.interface || "down"}`);
  setText("#commit", data.upstream_commit);
  setText("#tailscaleVersion", data.tailscale_version);
  setText("#moduleVersion", data.module_version);
  setText("#pid", data.pid, "Not running");

  const orb = $("#statusOrb");
  orb.className = "status-orb " + (state === "Running" ? "good" : /Needs|Starting/.test(state) ? "warn" : "bad");
  const integrity = $("#integrityState");
  integrity.textContent = data.integrity || "Unknown";
  integrity.className = "integrity " + (data.integrity === "verified" ? "good" : data.integrity === "modified" ? "bad" : "");

  $$('[data-setting]').forEach((input) => {
    const key = input.dataset.setting.replace(/-([a-z])/g, (_, c) => "_" + c);
    if (data[key] !== "") input.checked = bool(data[key]);
    input.disabled = !bool(data.running);
  });
  if (document.activeElement !== $("#hostname")) $("#hostname").value = data.hostname || "";

  const loginButton = $("#loginButton");
  const restoringSession = bool(data.running) && /Starting|NeedsLogin|NoState/.test(state) && Date.now() < sessionRestoreUntil;
  const signedIn = bool(data.running) && state === "Running";
  $("#loginButtonLabel").textContent = signedIn ? "Signed in" : restoringSession ? "Restoring" : "Sign in";
  $("#loginButtonIcon").setAttribute("d", signedIn ? "m5 12 4 4L19 6" : "M10 17 15 12 10 7M15 12H3M14 4h6v16h-6");
  loginButton.classList.toggle("signed-in", signedIn);
  loginButton.disabled = signedIn || restoringSession || !bool(data.running) || state === "Starting";

  if (bool(data.official_vpn)) showAlert("The official Tailscale Android VPN is active. Disconnect it before starting the native daemon.");
  else if (data.integrity === "modified") showAlert("Binary integrity check failed. Updates are blocked until the installation is reviewed.", "bad");
  else if (/NeedsLogin|NoState/.test(state) && Date.now() < sessionRestoreUntil) showAlert("Restoring the saved Tailscale session…");
  else if (/NeedsLogin|NoState/.test(state)) showAlert("This device needs authentication. Tap Sign in to open the Tailscale authentication page.");
  else showAlert("");
}

async function refreshStatus(force = false, scheduleFollowup = force) {
  try {
    const data = parseFields(await execHelper(force ? "status refresh" : "status"));
    renderStatus(data);
    if (scheduleFollowup) setTimeout(() => refreshStatus(false), 1200);
    return data;
  } catch (error) {
    showAlert(error.message, "bad");
    setText("#backendState", "Unavailable");
    return null;
  }
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function refreshAfterServiceStart() {
  sessionRestoreUntil = Date.now() + 20000;
  // A new daemon can briefly report NeedsLogin until it receives a fresh
  // network map. This is the same recovery request as the header refresh.
  let data = await refreshStatus(true, false);

  while (data && bool(data.running) && /Starting|NeedsLogin|NoState/.test(data.backend_state || "") && Date.now() < sessionRestoreUntil) {
    await delay(1200);
    data = await refreshStatus(true, false);
  }

  sessionRestoreUntil = 0;
  if (data && /NeedsLogin|NoState/.test(data.backend_state || "")) renderStatus(data);
}

function setBusy(enabled, text = "Working…") {
  $("#busyText").textContent = text;
  $("#busy").classList.toggle("hidden", !enabled);
}

function showOutput(title, output) {
  $("#dialogTitle").textContent = title;
  $("#dialogOutput").textContent = output || "Completed successfully.";
  $("#loginLink").classList.add("hidden");
  $("#loginLink").removeAttribute("href");
  $("#loginUrlBox").classList.add("hidden");
  $("#loginUrlText").textContent = "";
  $("#outputDialog").showModal();
}

function showLoginOutput(output) {
  const match = String(output).match(/^login_url=(https:\/\/\S+)/m);
  if (!match) {
    showOutput("Tailscale sign in", output);
    return;
  }
  const message = String(output).replace(/^login_url=.*(?:\r?\n)?/m, "").trim();
  showOutput("Tailscale sign in", message || "Open the authentication page, finish signing in, then return here.");
  $("#loginLink").href = match[1];
  $("#loginLink").classList.remove("hidden");
  $("#loginUrlText").textContent = match[1];
  $("#loginUrlBox").classList.remove("hidden");
}

async function runAction(action, title) {
  setBusy(true, `${title}…`);
  try {
    const output = await execHelper(action);
    if (action === "login") showLoginOutput(output);
    else if (action === "open-admin") { /* Browser opened by the allowlisted helper. */ }
    else showOutput(title, output);
  } catch (error) {
    showOutput(`${title} failed`, error.message);
  } finally {
    setBusy(false);
    if (action === "start" || action === "restart") await refreshAfterServiceStart();
    else refreshStatus(false);
    if (action === "clear-logs") loadLogs();
  }
}

$("#refresh").addEventListener("click", () => refreshStatus(true));
$("#closeDialog").addEventListener("click", () => $("#outputDialog").close());
$$('[data-action]').forEach((button) => button.addEventListener("click", () => {
  const labels = { start: "Starting service", stop: "Stopping service", restart: "Restarting service", login: "Tailscale sign in", verify: "Verifying binaries", "binary-update": "Updating Tailscale binaries", "open-admin": "Opening Tailnet Admin", "clear-logs": "Clearing daemon log", diagnostics: "Diagnostics" };
  runAction(button.dataset.action, labels[button.dataset.action] || button.dataset.action);
}));

$$('[data-setting]').forEach((input) => input.addEventListener("change", () => {
  const title = input.closest("label").querySelector("strong").textContent;
  runAction(`set ${input.dataset.setting} ${input.checked}`, `Updating ${title}`);
}));

$("#saveHostname").addEventListener("click", () => {
  const hostname = $("#hostname").value.trim();
  if (!/^[A-Za-z0-9](?:[A-Za-z0-9.-]{0,61}[A-Za-z0-9])?$/.test(hostname) || hostname.includes("..")) {
    showOutput("Invalid hostname", "Use 1–63 letters, numbers, dots, or hyphens. Do not begin or end with punctuation.");
    return;
  }
  runAction(`set hostname ${shellQuote(hostname)}`, "Updating hostname");
});

async function loadLogs() {
  try { $("#logs").textContent = await execHelper("logs") || "No log entries yet."; }
  catch (error) { $("#logs").textContent = error.message; }
}
$("#loadLogs").addEventListener("click", loadLogs);
$(".logs-card").addEventListener("toggle", (event) => { if (event.target.open) loadLogs(); });

refreshStatus(false).then(() => {
  if ($("#integrityState").textContent === "recorded") {
    execHelper("verify").catch(() => {}).finally(() => refreshStatus(false));
  }
});
