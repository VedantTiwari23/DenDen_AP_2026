

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Users table (authentication & credentials)
CREATE TABLE users (
    user_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username        VARCHAR(50) NOT NULL UNIQUE,
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_username_length CHECK (length(trim(username)) >= 3)
);

-- 2. User Profiles (presence & social info)
CREATE TABLE user_profiles (
    user_id         UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    display_name    VARCHAR(100) NOT NULL,
    avatar_url      TEXT,
    bio             TEXT,
    is_online       BOOLEAN NOT NULL DEFAULT FALSE,
    last_seen       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Friendships (bidirectional social graph)
CREATE TABLE friendships (
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    friend_id       UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    status          VARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'ACCEPTED', 'BLOCKED')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, friend_id),
    CONSTRAINT chk_no_self_friendship CHECK (user_id <> friend_id)
);

-- 4. Conversations (1-on-1 and Group chats)
CREATE TABLE conversations (
    conversation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           VARCHAR(100),
    is_group        BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 5. Conversation Participants
CREATE TABLE conversation_participants (
    conversation_id UUID NOT NULL REFERENCES conversations(conversation_id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    role            VARCHAR(20) NOT NULL DEFAULT 'MEMBER' CHECK (role IN ('ADMIN', 'MEMBER')),
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (conversation_id, user_id)
);

-- 6. Messages
CREATE TABLE messages (
    message_id      BIGSERIAL PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES conversations(conversation_id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    message_type    VARCHAR(20) NOT NULL DEFAULT 'TEXT' CHECK (message_type IN ('TEXT', 'IMAGE', 'FILE', 'SYSTEM')),
    content         TEXT NOT NULL,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 7. Call Records (WebRTC Audio/Video)
CREATE TABLE call_records (
    call_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    caller_id       UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    receiver_id     UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    call_type       VARCHAR(10) NOT NULL CHECK (call_type IN ('AUDIO', 'VIDEO')),
    status          VARCHAR(20) NOT NULL CHECK (status IN ('INITIATED', 'COMPLETED', 'MISSED', 'REJECTED')),
    started_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at        TIMESTAMPTZ,
    CONSTRAINT chk_call_timing CHECK (ended_at IS NULL OR ended_at >= started_at),
    CONSTRAINT chk_no_self_call CHECK (caller_id <> receiver_id)
);

-- 8. Live Streams
CREATE TABLE streams (
    stream_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    streamer_id     UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    title           VARCHAR(255) NOT NULL,
    stream_key      VARCHAR(100) NOT NULL UNIQUE,
    status          VARCHAR(20) NOT NULL DEFAULT 'LIVE' CHECK (status IN ('LIVE', 'ENDED')),
    started_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at        TIMESTAMPTZ,
    CONSTRAINT chk_stream_timing CHECK (ended_at IS NULL OR ended_at >= started_at)
);

-- 9. Stream Viewers
CREATE TABLE stream_viewers (
    stream_id       UUID NOT NULL REFERENCES streams(stream_id) ON DELETE CASCADE,
    viewer_id       UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (stream_id, viewer_id)
);