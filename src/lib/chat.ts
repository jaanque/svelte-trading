import { supabase } from './supabase';

export interface ChatMessage {
    id: string;
    sender_id: string;
    receiver_id: string;
    content: string;
    created_at: string;
}

export interface Conversation {
    user_id: string;
    username: string;
    full_name: string;
    avatar_url: string;
    last_message: string;
    last_message_at: string;
}

export async function sendMessage(receiverId: string, content: string) {
    const { data, error } = await supabase.rpc('send_message', {
        p_receiver_id: receiverId,
        p_content: content
    });
    if (error) throw error;
    return data;
}

export async function getMessages(otherUserId: string) {
    const { data, error } = await supabase.rpc('get_messages', {
        p_other_user_id: otherUserId
    });
    if (error) throw error;
    return data as ChatMessage[];
}

export async function getConversations() {
    const { data, error } = await supabase.rpc('get_conversations');
    if (error) throw error;
    return data as Conversation[];
}
