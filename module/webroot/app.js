const HELPER = "/data/adb/modules/native_tailscale/webui.sh";
const $ = (q) => document.querySelector(q);
const $$ = (q) => [...document.querySelectorAll(q)];

function shellQuote(value) {
  return `'${String(value).replace(/'/g, `'\\''`)}'`;
}

let callbackId = 0;
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

  if (bool(data.official_vpn)) showAlert("The official Tailscale Android VPN is active. Disconnect it before starting the native daemon.");
  else if (data.integrity === "modified") showAlert("Binary integrity check failed. Updates are blocked until the installation is reviewed.", "bad");
  else if (/NeedsLogin|NoState/.test(state)) showAlert("This device needs authentication. Tap Sign in to display the login URL or QR code.");
  else showAlert("");
}

async function refreshStatus() {
  try {
    renderStatus(parseFields(await execHelper("status")));
  } catch (error) {
    showAlert(error.message, "bad");
    setText("#backendState", "Unavailable");
  }
}

function setBusy(enabled, text = "Working…") {
  $("#busyText").textContent = text;
  $("#busy").classList.toggle("hidden", !enabled);
}

function showOutput(title, output) {
  $("#dialogTitle").textContent = title;
  $("#dialogOutput").textContent = output || "Completed successfully.";
  $("#outputDialog").showModal();
}

async function runAction(action, title) {
  setBusy(true, `${title}…`);
  try {
    const output = await execHelper(action);
    showOutput(title, output);
  } catch (error) {
    showOutput(`${title} failed`, error.message);
  } finally {
    setBusy(false);
    refreshStatus();
  }
}

$("#refresh").addEventListener("click", refreshStatus);
$("#closeDialog").addEventListener("click", () => $("#outputDialog").close());
$$('[data-action]').forEach((button) => button.addEventListener("click", () => {
  const labels = { start: "Starting service", stop: "Stopping service", restart: "Restarting service", login: "Tailscale sign in", verify: "Verifying binaries", diagnostics: "Diagnostics" };
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

refreshStatus();
