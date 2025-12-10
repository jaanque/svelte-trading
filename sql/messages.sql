-- Enable pgcrypto extension for encryption
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create messages table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id UUID REFERENCES auth.users(id) NOT NULL,
    receiver_id UUID REFERENCES auth.users(id) NOT NULL,
    encrypted_content BYTEA NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own messages"
    ON public.messages FOR SELECT
    USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can insert messages as sender"
    ON public.messages FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

-- Function to send an encrypted message
CREATE OR REPLACE FUNCTION send_message(
    p_receiver_id UUID,
    p_content TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_message_id UUID;
BEGIN
    INSERT INTO public.messages (sender_id, receiver_id, encrypted_content)
    VALUES (
        auth.uid(),
        p_receiver_id,
        pgp_sym_encrypt(p_content, 'app-encryption-key')
    )
    RETURNING id INTO v_message_id;

    RETURN v_message_id;
END;
$$;

-- Function to get messages for a conversation
CREATE OR REPLACE FUNCTION get_messages(
    p_other_user_id UUID
)
RETURNS TABLE (
    id UUID,
    sender_id UUID,
    receiver_id UUID,
    content TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.id,
        m.sender_id,
        m.receiver_id,
        pgp_sym_decrypt(m.encrypted_content, 'app-encryption-key')::TEXT as content,
        m.created_at
    FROM public.messages m
    WHERE (m.sender_id = auth.uid() AND m.receiver_id = p_other_user_id)
       OR (m.sender_id = p_other_user_id AND m.receiver_id = auth.uid())
    ORDER BY m.created_at ASC;
END;
$$;

-- Function to get conversation list with latest message
CREATE OR REPLACE FUNCTION get_conversations()
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    full_name TEXT,
    avatar_url TEXT,
    last_message TEXT,
    last_message_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH my_messages AS (
        SELECT
            m.id,
            m.sender_id,
            m.receiver_id,
            m.created_at,
            m.encrypted_content
        FROM public.messages m
        WHERE m.sender_id = auth.uid() OR m.receiver_id = auth.uid()
    ),
    last_msg_per_user AS (
        SELECT DISTINCT ON (
            CASE WHEN mm.sender_id = auth.uid() THEN mm.receiver_id ELSE mm.sender_id END
        )
            mm.id,
            CASE WHEN mm.sender_id = auth.uid() THEN mm.receiver_id ELSE mm.sender_id END AS other_user_id,
            mm.created_at
        FROM my_messages mm
        ORDER BY
            CASE WHEN mm.sender_id = auth.uid() THEN mm.receiver_id ELSE mm.sender_id END,
            mm.created_at DESC
    )
    SELECT
        lu.other_user_id,
        p.username,
        p.full_name,
        p.avatar_url,
        pgp_sym_decrypt(m.encrypted_content, 'app-encryption-key')::TEXT as last_message,
        lu.created_at
    FROM last_msg_per_user lu
    JOIN public.messages m ON m.id = lu.id
    JOIN public.profiles p ON p.id = lu.other_user_id
    ORDER BY lu.created_at DESC;
END;
$$;
