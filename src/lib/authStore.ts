import { writable } from 'svelte/store';
import { supabase } from './supabase';
import type { Session } from '@supabase/supabase-js';

export interface Profile {
  id: string;
  username: string;
  full_name: string;
  avatar_url: string;
  website?: string;
}

export const userSession = writable<Session | null>(null);
export const userProfile = writable<Profile | null>(null);

export async function initAuth() {
  // Get initial session
  const { data: { session } } = await supabase.auth.getSession();
  handleSession(session);

  // Listen for changes
  supabase.auth.onAuthStateChange((_event, session) => {
    handleSession(session);
  });
}

async function handleSession(session: Session | null) {
  userSession.set(session);

  if (session?.user) {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', session.user.id)
      .single();

    if (data && !error) {
      userProfile.set(data as Profile);
    } else {
      console.error('Error fetching profile:', error);
      // Fallback if profile doesn't exist yet (though trigger should handle it)
      userProfile.set({
        id: session.user.id,
        username: session.user.user_metadata?.username || 'user',
        full_name: session.user.user_metadata?.full_name || 'User',
        avatar_url: session.user.user_metadata?.avatar_url || '',
      });
    }
  } else {
    userProfile.set(null);
  }
}
