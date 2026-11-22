const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const emptyLibrary = () => ({ routines: [], activeRoutineId: null });

let config;
let session;
let library = emptyLibrary();
let selectedDay = (new Date().getDay() + 6) % 7 + 1;
let saving = false;
let revision = 0;
let pendingEmail = '';

const $ = (selector) => document.querySelector(selector);
const status = $('#status');
const setupView = $('#setup-view');
const authView = $('#auth-view');
const builderView = $('#builder-view');

function showStatus(message, isError = false) {
  status.textContent = message;
  status.style.color = isError ? 'var(--danger)' : 'var(--muted)';
}

function activeRoutine() {
  return library.routines.find((routine) => routine.id === library.activeRoutineId) || library.routines[0];
}

function currentBlocks() {
  const routine = activeRoutine();
  if (!routine) return [];
  routine.days ||= {};
  routine.days[String(selectedDay)] ||= [];
  return routine.days[String(selectedDay)];
}

async function request(path, options = {}, authenticated = true) {
  const headers = {
    apikey: config.supabaseAnonKey,
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };
  if (authenticated) headers.Authorization = `Bearer ${session.access_token}`;
  const response = await fetch(`${config.supabaseUrl}${path}`, { ...options, headers });
  const bodyText = await response.text();
  if (!response.ok) {
    let body = {};
    try { body = JSON.parse(bodyText || '{}'); } catch (_) {}
    throw new Error(body.msg || body.message || body.error_description || 'The request could not be completed.');
  }
  return bodyText ? JSON.parse(bodyText) : null;
}

async function refreshSession() {
  if (!session?.refresh_token) throw new Error('Your sign-in session has expired.');
  const response = await fetch(`${config.supabaseUrl}/auth/v1/token?grant_type=refresh_token`, {
    method: 'POST',
    headers: {
      apikey: config.supabaseAnonKey,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ refresh_token: session.refresh_token }),
  });
  if (!response.ok) throw new Error('Your sign-in session has expired.');
  session = await response.json();
  await chrome.storage.local.set({ session });
}

async function clearExpiredSession() {
  await chrome.storage.local.remove('session');
  session = undefined;
  builderView.hidden = true;
  $('#cloud-state').hidden = true;
  $('#sign-out').hidden = true;
  authView.hidden = false;
  showStatus('Your session expired. Sign in again to continue.');
}

async function loadLibrary() {
  const userId = session.user.id;
  const rows = await request(`/rest/v1/workout_routines?select=library&user_id=eq.${encodeURIComponent(userId)}`);
  library = rows[0]?.library || emptyLibrary();
  if (!library.routines.length) createRoutine('My routine');
  normalizeLibrary();
  if (!currentBlocks().length) {
    selectedDay = weekdays.findIndex((_, i) => activeRoutine().days[i + 1]?.length) + 1 || selectedDay;
  }
  setCloudState('Cloud ready');
  showStatus('');
  renderBuilder();
}

function normalizeLibrary() {
  library.routines ||= [];
  if (!library.activeRoutineId && library.routines[0]) library.activeRoutineId = library.routines[0].id;
  library.routines.forEach((routine) => { routine.days ||= {}; });
}

function createRoutine(name = 'New routine') {
  const routine = { id: crypto.randomUUID(), name, days: {} };
  library.routines.push(routine);
  library.activeRoutineId = routine.id;
}

function createBlock() {
  return {
    type: 'normal',
    exercises: [{ exerciseName: '', muscleGroup: '', sets: 3, reps: 10, weightKg: 0 }],
  };
}

function desiredExercises(type) {
  return type === 'triset' ? 3 : type === 'superset' ? 2 : 1;
}

function button(text, className, onClick) {
  const element = document.createElement('button');
  element.type = 'button';
  element.className = className;
  element.textContent = text;
  element.addEventListener('click', onClick);
  return element;
}

function setCloudState(text) {
  const pill = $('#cloud-state');
  pill.hidden = false;
  pill.textContent = `● ${text}`;
}

function changed() {
  revision++;
  setCloudState('Unsaved');
  showStatus('');
  updateDayStats();
}

function updateDayStats() {
  const blocks = currentBlocks();
  const count = blocks.reduce((total, block) => total + block.exercises.reduce((n, exercise) => n + Number(exercise.sets || 0), 0), 0);
  $('#day-stats').textContent = `${blocks.length} blks · ${count} sets`;
  document.querySelectorAll('.day-tab').forEach((tab, i) => {
    const size = activeRoutine()?.days?.[i + 1]?.length || 0;
    tab.lastElementChild.textContent = size ? `${size} blks` : 'Rest';
  });
}

function field(label, value, onChange, options = {}) {
  const input = document.createElement('input');
  input.setAttribute('aria-label', label);
  input.placeholder = options.placeholder || '';
  input.value = value ?? '';
  if (options.min != null) {
    input.type = 'number';
    input.min = options.min;
    input.step = options.step ?? 1;
  }
  input.addEventListener('input', () => {
    if (input.type === 'number' && (!input.validity.valid || input.value === '')) return;
    onChange(input.type === 'number' ? input.valueAsNumber : input.value);
    changed();
  });
  input.addEventListener('blur', () => {
    if (input.type === 'number' && (!input.validity.valid || input.value === '')) input.value = options.read();
  });
  return input;
}

function text(tag, value, className) {
  const element = document.createElement(tag);
  element.textContent = value;
  if (className) element.className = className;
  return element;
}

function renderBuilder() {
  setupView.hidden = true;
  authView.hidden = true;
  builderView.hidden = false;
  $('#sign-out').hidden = false;
  $('#account-email').textContent = session.user.email;
  $('#account-email').title = session.user.email;

  const routine = activeRoutine();
  const select = $('#routine-select');
  select.replaceChildren(...library.routines.map(item => new Option(item.name || 'Untitled routine', item.id, false, item.id === routine.id)));
  const tabs = $('#day-tabs');
  tabs.replaceChildren();
  weekdays.forEach((name, index) => {
    const day = index + 1;
    const tab = button('', 'day-tab', () => {
      selectedDay = day;
      renderBuilder();
      $('.editor-scroll').scrollTop = 0;
      tabs.children[index].focus();
    });
    tab.append(text('span', name.slice(0, 3).toUpperCase()), text('span', '', 'day-caption'));
    tab.setAttribute('aria-pressed', String(day === selectedDay));
    tab.setAttribute('aria-label', name);
    tabs.append(tab);
  });
  $('#day-title').textContent = weekdays[selectedDay - 1];
  const blocks = currentBlocks();
  $('#blocks').replaceChildren(...blocks.map(renderBlock));
  $('#empty-day').hidden = blocks.length > 0;
  updateDayStats();
}

function renderBlock(block, index) {
  const card = text('article', '', `exercise-block ${block.type === 'normal' ? 'straight' : 'linked'}`);
  const header = text('div', '', 'block-header');
  header.append(text('span', block.type === 'normal' ? `BLOCK ${index + 1}` : block.type.toUpperCase(), 'block-tag'));
  const kind = document.createElement('select');
  kind.setAttribute('aria-label', `Block ${index + 1} type`);
  [['normal', 'Straight sets'], ['superset', 'Superset'], ['triset', 'Triset']].forEach(([value, label]) => {
    kind.append(new Option(label, value, false, block.type === value));
  });
  kind.addEventListener('change', () => {
    const count = desiredExercises(kind.value);
    if (count < block.exercises.length && !confirm('Changing block type removes the extra exercises. Continue?')) {
      kind.value = block.type;
      return;
    }
    block.type = kind.value;
    while (block.exercises.length < count) block.exercises.push(createBlock().exercises[0]);
    block.exercises.length = count;
    changed();
    renderBuilder();
  });
  const remove = button('×', 'icon-button remove-block', () => {
    if (!confirm(`Delete block ${index + 1}?`)) return;
    currentBlocks().splice(index, 1);
    changed();
    renderBuilder();
  });
  remove.setAttribute('aria-label', `Delete block ${index + 1}`);
  remove.title = 'Delete block';
  header.append(kind, remove);
  card.append(header);
  block.exercises.forEach((exercise, i) => {
    const body = text('div', '', 'exercise-body');
    const identity = text('div', '', 'exercise-identity');
    if (block.type !== 'normal') identity.append(text('span', `${index + 1}${String.fromCharCode(65 + i)}`, 'exercise-index'));
    const names = text('div', '', 'exercise-names');
    names.append(
      field('Exercise name', exercise.exerciseName, v => { exercise.exerciseName = v; }, { placeholder: 'Exercise name' }),
      field('Muscle group', exercise.muscleGroup, v => { exercise.muscleGroup = v; }, { placeholder: 'Muscle group' }),
    );
    identity.append(names);
    body.append(identity);
    const grid = text('div', '', 'exercise-matrix');
    for (const [label, key, min, step] of [['Sets', 'sets', 1, 1], ['Load (kg)', 'weightKg', 0, 'any'], ['Target reps', 'reps', 1, 1]]) {
      const group = text('label', label);
      group.append(field(label, exercise[key], v => { exercise[key] = v; }, { min, step, read: () => exercise[key] }));
      grid.append(group);
    }
    body.append(grid);
    card.append(body);
  });
  return card;
}

async function saveLibrary() {
  const routine = activeRoutine();
  if (!routine.name.trim()) throw new Error('Give the routine a name before saving.');
  for (const item of library.routines) {
    for (const blocks of Object.values(item.days)) {
      if (blocks.some(block => block.exercises.some(exercise => !exercise.exerciseName.trim()))) {
        throw new Error(`Fill in every exercise name in ${item.name} before saving.`);
      }
    }
  }
  await request('/rest/v1/workout_routines?on_conflict=user_id', {
    method: 'POST',
    headers: { Prefer: 'resolution=merge-duplicates,return=minimal' },
    body: JSON.stringify({ user_id: session.user.id, library }),
  });
}

function setAuthenticatedView() {
  loadLibrary().catch(async (error) => {
    if (error.message === 'JWT expired') {
      await clearExpiredSession();
      return;
    }
    showStatus(error.message, true);
  });
}

async function initialize() {
  ({ config, session } = await chrome.storage.local.get(['config', 'session']));
  if (!config?.supabaseUrl || !config?.supabaseAnonKey) {
    setupView.hidden = false;
    return;
  }
  if (session?.access_token && session?.user?.id) {
    try {
      await refreshSession();
    } catch (_) {
      await clearExpiredSession();
      return;
    }
    setAuthenticatedView();
    return;
  }
  authView.hidden = false;
}

for (const id of ['#open-options', '#open-settings']) $(id).addEventListener('click', () => chrome.runtime.openOptionsPage());
$('#email-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  const email = $('#email').value.trim();
  $('#email-error').textContent = '';
  if (!email) { $('#email-error').textContent = 'Enter your email address.'; return; }
  try {
    await request('/auth/v1/otp', { method: 'POST', body: JSON.stringify({ email, create_user: true }) }, false);
    pendingEmail = email;
    $('#email-form').hidden = true;
    $('#code-form').hidden = false;
    $('#code').focus();
    showStatus('Code sent. Check your inbox.');
  } catch (error) { $('#email-error').textContent = error.message; }
});
$('#code-form').addEventListener('submit', async (event) => {
  event.preventDefault();
  $('#code-error').textContent = '';
  try {
    session = await request('/auth/v1/verify', { method: 'POST', body: JSON.stringify({ email: pendingEmail, token: $('#code').value.trim(), type: 'email' }) }, false);
    await chrome.storage.local.set({ session });
    showStatus('Signed in. Loading your routines...');
    setAuthenticatedView();
  } catch (error) { $('#code-error').textContent = error.message; }
});
$('#change-email').addEventListener('click', () => { $('#code-form').hidden = true; $('#email-form').hidden = false; $('#email').focus(); });
$('#sign-out').addEventListener('click', async () => { await chrome.storage.local.remove('session'); window.location.reload(); });
$('#routine-select').addEventListener('change', event => {
  library.activeRoutineId = event.target.value;
  changed();
  renderBuilder();
});
const routineDialog = $('#routine-dialog');
function openRoutineSettings() {
  routineDialog.returnValue = '';
  $('#routine-name').value = activeRoutine().name;
  routineDialog.showModal();
  $('#routine-name').select();
}
$('#routine-settings').addEventListener('click', openRoutineSettings);
routineDialog.querySelector('form').addEventListener('submit', event => {
  if (event.submitter?.value !== 'apply') return;
  event.preventDefault();
  const name = $('#routine-name').value.trim();
  if (name) {
    activeRoutine().name = name;
    routineDialog.close('apply');
    changed();
    renderBuilder();
  }
});
$('#new-routine').addEventListener('click', () => {
  createRoutine('New routine');
  changed();
  renderBuilder();
  openRoutineSettings();
});
$('#delete-routine').addEventListener('click', () => {
  if (!confirm('Delete this routine from the draft? The change will take effect when you save.')) return;
  library.routines = library.routines.filter(routine => routine.id !== activeRoutine().id);
  if (!library.routines.length) createRoutine('My routine');
  library.activeRoutineId = library.routines[0].id;
  routineDialog.close();
  changed();
  renderBuilder();
});
$('#add-block').addEventListener('click', () => {
  currentBlocks().push(createBlock());
  changed();
  renderBuilder();
  $('#blocks').lastElementChild.querySelector('input').focus();
});
async function pushRoutine() {
  if (saving || builderView.hidden || routineDialog.open) return;
  if ([...builderView.querySelectorAll('input[type="number"]')].some(input => !input.validity.valid || input.value === '')) {
    showStatus('Enter valid sets, reps and load before saving.', true);
    return;
  }
  const saveRevision = revision;
  saving = true;
  $('#save-library').disabled = true;
  setCloudState('Saving…');
  try {
    await saveLibrary();
    setCloudState(revision === saveRevision ? 'Cloud saved' : 'Unsaved');
    showStatus(revision === saveRevision
      ? 'Saved. In Myfit, open Weekly routine → Reload routines.'
      : 'Earlier changes saved. Save again to include your latest edits.');
  } catch (error) {
    setCloudState('Not saved');
    showStatus(error.message, true);
  } finally {
    saving = false;
    $('#save-library').disabled = false;
  }
}
$('#save-library').addEventListener('click', pushRoutine);
$('#save-shortcut').textContent = /Mac/.test(navigator.platform) ? '⌘ S' : 'Ctrl S';
document.addEventListener('keydown', event => {
  if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 's' && !builderView.hidden && !routineDialog.open) {
    event.preventDefault();
    pushRoutine();
  }
});

initialize().catch(error => showStatus(error.message, true));
