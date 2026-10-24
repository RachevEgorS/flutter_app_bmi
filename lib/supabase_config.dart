// Client-side publishable key. Never place a secret/service_role key here.
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://dtisombcspixbigdwcex.supabase.co',
);
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable__T2mOpuiLL0uNjhUO6eBkw_dshvWlQj',
);
