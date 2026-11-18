const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const emptyLibrary = () => ({ routines: [], activeRoutineId: null });

let config;
let session;
let library = emptyLibrary();
let selectedDay = 1;
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
  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new Error(body.msg || body.message || body.error_description || 'The request could not be completed.');
  }
  return response.status === 204 ? null : response.json();
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

function labeledInput(labelText, value, type, onChange, className = '') {
  const label = document.createElement('label');
  label.textContent = labelText;
  const input = document.createElement('input');
  input.type = type;
  input.value = value ?? '';
  input.className = className;
  input.addEventListener('change', () => onChange(type === 'number' ? Number(input.value) : input.value));
  label.append(input);
  return label;
}

function renderBuilder() {
  setupView.hidden = true;
  authView.hidden = true;
  builderView.hidden = false;
  $('#sign-out').hidden = false;
  $('#account-email').textContent = session.user.email;

  const routine = activeRoutine();
  const select = $('#routine-select');
  select.replaceChildren();
  library.routines.forEach((item) => {
    const option = document.createElement('option');
    option.value = item.id;
    option.textContent = item.name || 'Untitled routine';
    option.selected = item.id === routine.id;
    select.append(option);
  });
  $('#routine-name').value = routine.name;

  const tabs = $('#day-tabs');
  tabs.replaceChildren();
  weekdays.forEach((name, index) => {
    const weekday = index + 1;
    const tab = button(name.slice(0, 3), 'day-tab', () => {
      selectedDay = weekday;
      renderBuilder();
    });
    tab.setAttribute('aria-selected', String(weekday === selectedDay));
    tab.setAttribute('aria-label', name);
    tabs.append(tab);
  });
  $('#day-title').textContent = weekdays[selectedDay - 1];

  const blocks = currentBlocks();
  const blocksElement = $('#blocks');
  blocksElement.replaceChildren();
  blocks.forEach((block, blockIndex) => blocksElement.append(renderBlock(block, blockIndex)));
  $('#empty-day').hidden = blocks.length > 0;
}

function renderBlock(block, blockIndex) {
  const card = document.createElement('article');
  card.className = 'exercise-block';
  const header = document.createElement('div');
  header.className = 'block-header';
  const typeSelect = document.createElement('select');
  [['normal', 'Single exercise'], ['superset', 'Superset'], ['triset', 'Triset']].forEach(([value, label]) => {
    const option = new Option(label, value, false, block.type === value);
    typeSelect.append(option);
  });
  typeSelect.setAttribute('aria-label', `Block ${blockIndex + 1} type`);
  typeSelect.addEventListener('change', () => {
    block.type = typeSelect.value;
    const count = desiredExercises(block.type);
    while (block.exercises.length < count) block.exercises.push(createBlock().exercises[0]);
    block.exercises.length = count;
    renderBuilder();
  });
  header.append(typeSelect, button('Remove block', 'danger-button', () => {
    currentBlocks().splice(blockIndex, 1);
    renderBuilder();
  }));
  card.append(header);

  block.exercises.forEach((exercise, exerciseIndex) => {
    const grid = document.createElement('div');
    grid.className = 'exercise-grid';
    grid.append(
      labeledInput('Exercise', exercise.exerciseName, 'text', (value) => { exercise.exerciseName = value; }),
      labeledInput('Muscle', exercise.muscleGroup, 'text', (value) => { exercise.muscleGroup = value; }),
      labeledInput('Sets', exercise.sets, 'number', (value) => { exercise.sets = value; }, 'number-input'),
      labeledInput('Reps', exercise.reps, 'number', (value) => { exercise.reps = value; }, 'number-input'),
      labeledInput('kg', exercise.weightKg, 'number', (value) => { exercise.weightKg = value; }, 'number-input'),
    );
    if (block.exercises.length > 1) {
      grid.append(button(`Remove ${exerciseIndex + 1}`, 'danger-button remove-exercise', () => {
        block.exercises.splice(exerciseIndex, 1);
        if (block.exercises.length === 1) block.type = 'normal';
        renderBuilder();
      }));
    }
    card.append(grid);
  });
  return card;
}

async function saveLibrary() {
  const routine = activeRoutine();
  if (!routine.name.trim()) throw new Error('Give the routine a name before saving.');
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

$('#open-options').addEventListener('click', () => chrome.runtime.openOptionsPage());
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
$('#routine-select').addEventListener('change', (event) => { library.activeRoutineId = event.target.value; renderBuilder(); });
$('#routine-name').addEventListener('change', (event) => { activeRoutine().name = event.target.value; renderBuilder(); });
$('#new-routine').addEventListener('click', () => { createRoutine('New routine'); renderBuilder(); });
$('#delete-routine').addEventListener('click', () => {
  if (!confirm('Delete this routine?')) return;
  library.routines = library.routines.filter((routine) => routine.id !== activeRoutine().id);
  if (!library.routines.length) createRoutine('My routine');
  library.activeRoutineId = library.routines[0].id;
  renderBuilder();
});
$('#add-block').addEventListener('click', () => { currentBlocks().push(createBlock()); renderBuilder(); });
$('#save-library').addEventListener('click', async () => {
  try { await saveLibrary(); showStatus('Saved. Myfit will load these routines for this account.'); }
  catch (error) { showStatus(error.message, true); }
});

initialize();
