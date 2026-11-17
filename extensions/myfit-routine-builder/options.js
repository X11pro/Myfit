const form = document.querySelector('#settings-form');
const urlInput = document.querySelector('#supabase-url');
const keyInput = document.querySelector('#supabase-anon-key');
const error = document.querySelector('#settings-error');
const status = document.querySelector('#settings-status');

async function initialize() {
  const { config = {} } = await chrome.storage.local.get('config');
  urlInput.value = config.supabaseUrl || '';
  keyInput.value = config.supabaseAnonKey || '';
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  error.textContent = '';
  status.textContent = '';
  const supabaseUrl = urlInput.value.trim().replace(/\/$/, '');
  const supabaseAnonKey = keyInput.value.trim();

  try {
    const parsed = new URL(supabaseUrl);
    if (parsed.protocol !== 'https:' || !parsed.hostname.endsWith('.supabase.co')) {
      throw new Error('Enter a valid https://*.supabase.co project URL.');
    }
    if (!supabaseAnonKey) {
      throw new Error('Enter the Supabase anonymous key.');
    }
    await chrome.storage.local.set({ config: { supabaseUrl, supabaseAnonKey } });
    status.textContent = 'Connection saved. Open the extension to sign in.';
  } catch (exception) {
    error.textContent = exception.message;
  }
});

initialize();
