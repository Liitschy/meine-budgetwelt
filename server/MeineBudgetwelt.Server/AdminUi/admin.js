"use strict";

const state = {
  me: null,
  users: [],
  groups: [],
  invitations: [],
  members: new Map(),
  health: null,
  activeView: "overview",
};

const loginView = document.querySelector("#login-view");
const adminApp = document.querySelector("#admin-app");
const toast = document.querySelector("#toast");
let toastTimer = 0;

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function initials(name) {
  const parts = String(name ?? "").trim().split(/\s+/).filter(Boolean);
  return (parts.length ? parts.map((part) => part[0]).join("") : "A")
    .slice(0, 2)
    .toLocaleUpperCase("de-DE");
}

function roleName(role) {
  return ({ owner: "Eigentümer", manager: "Verwalter", member: "Mitglied" })[role] ?? role;
}

function formatDate(value) {
  if (!value) return "–";
  return new Intl.DateTimeFormat("de-DE", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}

function greetingFor(name) {
  const hour = new Date().getHours();
  const greeting = hour < 11 ? "Guten Morgen" : hour < 18 ? "Guten Tag" : "Guten Abend";
  return `${greeting}, ${name}`;
}

function setBusy(button, busy) {
  if (!button) return;
  button.disabled = busy;
  if (busy) {
    button.dataset.originalText = button.textContent;
    button.textContent = "Bitte warten …";
  } else if (button.dataset.originalText) {
    button.textContent = button.dataset.originalText;
    delete button.dataset.originalText;
  }
}

function showToast(message, isError = false) {
  window.clearTimeout(toastTimer);
  toast.textContent = message;
  toast.classList.toggle("error", isError);
  toast.hidden = false;
  toastTimer = window.setTimeout(() => { toast.hidden = true; }, 5000);
}

async function api(path, options = {}) {
  const response = await fetch(path, {
    credentials: "include",
    ...options,
    headers: {
      Accept: "application/json",
      ...(options.body ? { "Content-Type": "application/json" } : {}),
      ...(options.headers ?? {}),
    },
  });

  if (response.status === 401) {
    if (!path.endsWith("/login")) showLogin("Deine Sitzung ist abgelaufen. Bitte melde dich erneut an.");
    throw new Error("Anmeldung erforderlich.");
  }
  if (!response.ok) {
    let message = `Anfrage fehlgeschlagen (${response.status}).`;
    try {
      const problem = await response.json();
      message = problem.errors?.account?.[0] ?? problem.detail ?? problem.title ?? message;
    } catch { /* Antwort ohne JSON */ }
    throw new Error(message);
  }
  if (response.status === 204) return null;
  const contentType = response.headers.get("content-type") ?? "";
  return contentType.includes("json") ? response.json() : response.text();
}

function showLogin(message = "") {
  state.me = null;
  adminApp.hidden = true;
  loginView.hidden = false;
  document.querySelector("#login-error").textContent = message;
  document.querySelector("#login-password").value = "";
  window.setTimeout(() => document.querySelector("#login-email").focus(), 20);
}

function showAdmin() {
  loginView.hidden = true;
  adminApp.hidden = false;
  const displayName = state.me.displayName;
  document.querySelector("#greeting").textContent = greetingFor(displayName);
  document.querySelector("#sidebar-name").textContent = displayName;
  document.querySelector("#sidebar-avatar").textContent = initials(displayName);
  document.title = `Administration · ${displayName} · Meine Budgetwelt`;
}

async function loadHealth() {
  state.health = await api("/health");
  const checked = new Intl.DateTimeFormat("de-DE", { hour: "2-digit", minute: "2-digit", second: "2-digit" }).format(new Date());
  document.querySelector("#metric-version").textContent = `Version ${state.health.version}`;
  document.querySelector("#last-health-check").textContent = checked;
  document.querySelector("#overview-database").textContent = state.health.database === "ok" ? "Bereit" : "Fehler";
  document.querySelector("#server-service").textContent = state.health.service;
  document.querySelector("#server-version").textContent = state.health.version;
  document.querySelector("#server-database").textContent = state.health.database === "ok" ? "Bereit" : state.health.database;
  document.querySelector("#update-current-version").textContent = `Aktuelle Version: ${state.health.version}`;
  const updatesEnabled = state.health.automaticUpdates === true;
  document.querySelector("#update-status-icon").classList.toggle("good", updatesEnabled);
  document.querySelector("#update-status-icon").classList.toggle("pending", !updatesEnabled);
  document.querySelector("#update-status-title").textContent = updatesEnabled
    ? "Signierter Updatekanal aktiv"
    : "Automatische Updates deaktiviert";
  document.querySelector("#update-status-description").textContent = updatesEnabled
    ? "Geprüft wird beim Serverstart sowie täglich. Vor jeder Installation entsteht automatisch eine Datensicherung; bei einem fehlerhaften Start wird die bisherige Programmversion wiederhergestellt."
    : "Dieser Entwicklungsstand installiert Updates nicht automatisch. Im regulären Server-Setup wird der signierte Updatekanal aktiviert.";
}

async function loadAdminData() {
  const [users, groups, invitations] = await Promise.all([
    api("/api/admin/users"),
    api("/api/admin/groups"),
    api("/api/admin/invitations"),
    loadHealth(),
  ]);
  state.users = users;
  state.groups = groups;
  state.invitations = invitations;
  const memberEntries = await Promise.all(groups.map(async (group) => [
    group.id,
    await api(`/api/admin/groups/${encodeURIComponent(group.id)}/members`),
  ]));
  state.members = new Map(memberEntries);
  renderAll();
}

function renderMetrics() {
  const activeUsers = state.users.filter((user) => user.isActive).length;
  const openInvitations = state.invitations.filter((invitation) =>
    !invitation.isAccepted && !invitation.isRevoked && new Date(invitation.expiresUtc) > new Date()).length;
  document.querySelector("#metric-users").textContent = state.users.length;
  document.querySelector("#metric-active").textContent = `${activeUsers} aktiv`;
  document.querySelector("#metric-invites").textContent = openInvitations;
  document.querySelector("#overview-group-count").textContent = state.groups.length;
  const badge = document.querySelector("#invite-badge");
  badge.textContent = openInvitations;
  badge.hidden = openInvitations === 0;
}

function compactUserMarkup(user) {
  return `<div class="compact-user">
    <span class="avatar">${escapeHtml(initials(user.displayName))}</span>
    <span><strong>${escapeHtml(user.displayName)}</strong><small>${user.isSystemAdmin ? "Administrator" : "Mitglied"}</small></span>
    <span class="email-cell"><strong>${escapeHtml(user.email)}</strong><small>Konto</small></span>
    <span class="status-label ${user.isActive ? "" : "inactive"}">${user.isActive ? "Aktiv" : "Gesperrt"}</span>
  </div>`;
}

function renderOverviewUsers() {
  const target = document.querySelector("#overview-users");
  target.innerHTML = state.users.length
    ? state.users.slice(0, 4).map(compactUserMarkup).join("")
    : '<p class="empty-state">Noch keine Benutzer vorhanden.</p>';
}

function renderUsers() {
  const target = document.querySelector("#users-list");
  target.innerHTML = state.users.length ? state.users.map((user) => {
    const self = user.id === state.me.id;
    return `<article class="user-row">
      <span class="avatar">${escapeHtml(initials(user.displayName))}</span>
      <span><strong>${escapeHtml(user.displayName)}</strong><small>${user.isSystemAdmin ? "Systemadministrator" : "Benutzerkonto"}</small></span>
      <span class="email-cell"><strong>${escapeHtml(user.email)}</strong><small>Erstellt ${escapeHtml(formatDate(user.createdUtc))}</small></span>
      <span class="role-cell">${user.isSystemAdmin ? "Administrator" : "Mitglied"}</span>
      <span class="status-label ${user.isActive ? "" : "inactive"}">${user.isActive ? "Aktiv" : "Gesperrt"}</span>
      <span class="user-actions">
        <button class="icon-button" type="button" data-toggle-user="${escapeHtml(user.id)}" data-next-active="${String(!user.isActive)}" aria-label="${user.isActive ? "Konto sperren" : "Konto aktivieren"}" ${self ? "disabled" : ""}>
          <svg><use href="#icon-${user.isActive ? "lock" : "unlock"}"></use></svg>
        </button>
      </span>
    </article>`;
  }).join("") : '<p class="empty-state">Noch keine Benutzer vorhanden.</p>';
}

function userOptions(selectedId = "") {
  return state.users.map((user) =>
    `<option value="${escapeHtml(user.id)}" ${user.id === selectedId ? "selected" : ""}>${escapeHtml(user.displayName)} · ${escapeHtml(user.email)}</option>`).join("");
}

function renderGroups() {
  const target = document.querySelector("#groups-list");
  target.innerHTML = state.groups.length ? state.groups.map((group) => {
    const members = state.members.get(group.id) ?? [];
    const memberMarkup = members.length ? members.map((member) => `<div class="member-row">
      <span><strong>${escapeHtml(member.displayName)}</strong><small>${escapeHtml(member.email)}</small></span>
      <small>${escapeHtml(roleName(member.role))}</small>
    </div>`).join("") : '<p class="empty-state">Noch keine Mitglieder.</p>';
    return `<article class="group-card glass-card">
      <header><div><h3>${escapeHtml(group.name)}</h3><p>${members.length} ${members.length === 1 ? "Mitglied" : "Mitglieder"}</p></div><span class="status-label">Synchronisiert</span></header>
      <div class="member-list">${memberMarkup}</div>
      <form class="assign-form" data-group-id="${escapeHtml(group.id)}">
        <label>Benutzer<select name="userId">${userOptions()}</select></label>
        <label>Rolle<select name="role"><option value="member">Mitglied</option><option value="manager">Verwalter</option><option value="owner">Eigentümer</option></select></label>
        <button class="secondary-button" type="submit">Zuordnen</button>
      </form>
    </article>`;
  }).join("") : '<p class="empty-state">Noch keine Budgetgruppen vorhanden.</p>';
}

function renderInvitations() {
  const groupSelect = document.querySelector("#invite-group");
  const selected = groupSelect.value;
  groupSelect.innerHTML = '<option value="">Keine Zuordnung</option>' + state.groups.map((group) =>
    `<option value="${escapeHtml(group.id)}">${escapeHtml(group.name)}</option>`).join("");
  groupSelect.value = selected;

  const target = document.querySelector("#invitations-list");
  target.innerHTML = state.invitations.length ? state.invitations.map((invitation) => {
    const group = state.groups.find((item) => item.id === invitation.groupId);
    const expired = new Date(invitation.expiresUtc) <= new Date();
    const status = invitation.isAccepted ? "Angenommen" : invitation.isRevoked ? "Widerrufen" : expired ? "Abgelaufen" : "Offen";
    const done = status !== "Offen";
    return `<article class="invitation-row">
      <span><strong>${escapeHtml(invitation.name)}</strong><small>${group ? escapeHtml(group.name) : "Ohne Budgetgruppe"}${invitation.role ? ` · ${escapeHtml(roleName(invitation.role))}` : ""}</small></span>
      <span class="invite-email"><strong>${escapeHtml(invitation.email)}</strong><small>Gültig bis ${escapeHtml(formatDate(invitation.expiresUtc))}</small></span>
      <span>${invitation.role ? escapeHtml(roleName(invitation.role)) : "–"}</span>
      <span class="invitation-state ${done ? "done" : ""}">${status}</span>
    </article>`;
  }).join("") : '<p class="empty-state">Noch keine Einladungen vorhanden.</p>';
}

function renderAll() {
  renderMetrics();
  renderOverviewUsers();
  renderUsers();
  renderGroups();
  renderInvitations();
}

function switchView(viewName) {
  state.activeView = viewName;
  document.querySelectorAll("[data-view-panel]").forEach((panel) => {
    const active = panel.dataset.viewPanel === viewName;
    panel.hidden = !active;
    panel.classList.toggle("active-view", active);
  });
  document.querySelectorAll(".nav-item[data-view]").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === viewName);
  });
  window.scrollTo({ top: 0, behavior: "smooth" });
}

document.querySelector("#login-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const button = event.submitter;
  const error = document.querySelector("#login-error");
  error.textContent = "";
  setBusy(button, true);
  try {
    const result = await api("/api/auth/login", {
      method: "POST",
      body: JSON.stringify({
        email: document.querySelector("#login-email").value.trim(),
        password: document.querySelector("#login-password").value,
        rememberMe: document.querySelector("#login-remember").checked,
      }),
    });
    if (!result.user?.isSystemAdmin) {
      await api("/api/auth/logout", { method: "POST" });
      throw new Error("Dieses Konto besitzt keine Administrationsrechte.");
    }
    state.me = result.user;
    showAdmin();
    await loadAdminData();
  } catch (errorObject) {
    error.textContent = errorObject.message === "Anmeldung erforderlich." ? "E-Mail oder Kennwort ist falsch." : errorObject.message;
  } finally {
    setBusy(button, false);
  }
});

document.querySelector("#logout-button").addEventListener("click", async () => {
  try { await api("/api/auth/logout", { method: "POST" }); } catch { /* lokal immer abmelden */ }
  showLogin("Du wurdest sicher abgemeldet.");
});

document.querySelectorAll(".password-toggle").forEach((button) => {
  button.addEventListener("click", () => {
    const input = document.getElementById(button.dataset.passwordTarget);
    input.type = input.type === "password" ? "text" : "password";
    button.setAttribute("aria-label", input.type === "password" ? "Kennwort anzeigen" : "Kennwort verbergen");
  });
});

document.querySelectorAll(".nav-item[data-view]").forEach((button) =>
  button.addEventListener("click", () => switchView(button.dataset.view)));
document.querySelector("#mobile-menu-button").addEventListener("click", () => switchView("server"));

const userDialog = document.querySelector("#user-dialog");
document.querySelectorAll("[data-open-user-dialog]").forEach((button) =>
  button.addEventListener("click", () => {
    document.querySelector("#user-form").reset();
    document.querySelector("#user-error").textContent = "";
    userDialog.showModal();
    document.querySelector("#user-name").focus();
  }));
document.querySelectorAll("[data-close-user-dialog]").forEach((button) =>
  button.addEventListener("click", () => userDialog.close()));

document.querySelector("#user-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const button = event.submitter;
  const error = document.querySelector("#user-error");
  error.textContent = "";
  setBusy(button, true);
  try {
    await api("/api/admin/users", {
      method: "POST",
      body: JSON.stringify({
        name: document.querySelector("#user-name").value.trim(),
        email: document.querySelector("#user-email").value.trim(),
        password: document.querySelector("#user-password").value,
        isSystemAdmin: document.querySelector("#user-admin").checked,
      }),
    });
    userDialog.close();
    await loadAdminData();
    showToast("Benutzerkonto wurde angelegt.");
  } catch (errorObject) {
    error.textContent = errorObject.message;
  } finally {
    setBusy(button, false);
  }
});

document.querySelector("#users-list").addEventListener("click", async (event) => {
  const button = event.target.closest("[data-toggle-user]");
  if (!button) return;
  const nextActive = button.dataset.nextActive === "true";
  const verb = nextActive ? "aktivieren" : "sperren";
  if (!window.confirm(`Möchtest du dieses Konto wirklich ${verb}?`)) return;
  button.disabled = true;
  try {
    await api(`/api/admin/users/${encodeURIComponent(button.dataset.toggleUser)}/active`, {
      method: "PATCH",
      body: JSON.stringify({ isActive: nextActive }),
    });
    await loadAdminData();
    showToast(`Benutzerkonto wurde ${nextActive ? "aktiviert" : "gesperrt"}.`);
  } catch (errorObject) {
    showToast(errorObject.message, true);
    button.disabled = false;
  }
});

document.querySelector("#group-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const button = event.submitter;
  setBusy(button, true);
  try {
    await api("/api/admin/groups", {
      method: "POST",
      body: JSON.stringify({ name: document.querySelector("#group-name").value.trim() }),
    });
    event.currentTarget.reset();
    await loadAdminData();
    showToast("Budgetgruppe wurde angelegt.");
  } catch (errorObject) {
    showToast(errorObject.message, true);
  } finally {
    setBusy(button, false);
  }
});

document.querySelector("#groups-list").addEventListener("submit", async (event) => {
  const form = event.target.closest(".assign-form");
  if (!form) return;
  event.preventDefault();
  const button = event.submitter;
  setBusy(button, true);
  try {
    await api(`/api/admin/groups/${encodeURIComponent(form.dataset.groupId)}/members`, {
      method: "PUT",
      body: JSON.stringify({ userId: form.elements.userId.value, role: form.elements.role.value }),
    });
    await loadAdminData();
    showToast("Budgetgruppe wurde aktualisiert.");
  } catch (errorObject) {
    showToast(errorObject.message, true);
  } finally {
    setBusy(button, false);
  }
});

document.querySelector("#invitation-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const button = event.submitter;
  setBusy(button, true);
  try {
    const groupId = document.querySelector("#invite-group").value || null;
    await api("/api/admin/invitations", {
      method: "POST",
      body: JSON.stringify({
        name: document.querySelector("#invite-name").value.trim(),
        email: document.querySelector("#invite-email").value.trim(),
        groupId,
        role: groupId ? document.querySelector("#invite-role").value : null,
      }),
    });
    event.currentTarget.reset();
    await loadAdminData();
    showToast("Einladung wurde sicher versendet.");
  } catch (errorObject) {
    showToast(errorObject.message, true);
  } finally {
    setBusy(button, false);
  }
});

document.querySelector("#refresh-health").addEventListener("click", async (event) => {
  setBusy(event.currentTarget, true);
  try {
    await loadHealth();
    showToast("Serverstatus wurde aktualisiert.");
  } catch (errorObject) {
    showToast(errorObject.message, true);
  } finally {
    setBusy(event.currentTarget, false);
  }
});

async function boot() {
  try {
    const me = await api("/api/auth/me");
    if (!me.isSystemAdmin) {
      showLogin("Dieses Konto besitzt keine Administrationsrechte.");
      return;
    }
    state.me = me;
    showAdmin();
    await loadAdminData();
  } catch {
    showLogin();
  }
}

boot();
