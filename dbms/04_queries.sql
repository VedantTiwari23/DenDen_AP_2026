-- R1: User login by email
-- READ
SELECT u.user_id, u.username, u.password_hash, p.display_name, p.avatar_url
FROM users u
JOIN user_profiles p ON p.user_id = u.user_id
WHERE lower(u.email) = 'alex@gmail.com';

-- R2: Search users by username
-- READ
SELECT u.user_id, u.username, p.display_name, p.avatar_url
FROM users u
JOIN user_profiles p ON p.user_id = u.user_id
WHERE u.username ILIKE 'sam%'
LIMIT 10;

-- R3: Get user profile details
-- READ
SELECT u.user_id, u.username, u.email, p.display_name, p.bio, p.avatar_url, p.is_online, p.last_seen
FROM users u
JOIN user_profiles p ON p.user_id = u.user_id
WHERE u.user_id = '11111111-1111-1111-1111-111111111111';

-- R4: Get user friends list with online status
-- READ
SELECT u.user_id, u.username, p.display_name, p.avatar_url, p.is_online, p.last_seen
FROM friendships f
JOIN users u ON u.user_id = f.friend_id
JOIN user_profiles p ON p.user_id = u.user_id
WHERE f.user_id = '11111111-1111-1111-1111-111111111111' 
  AND f.status = 'ACCEPTED'
ORDER BY p.is_online DESC, p.last_seen DESC;

-- R5: Pending incoming friend requests
-- READ
SELECT f.user_id AS requester_id, u.username, p.display_name, p.avatar_url, f.created_at
FROM friendships f
JOIN users u ON u.user_id = f.user_id
JOIN user_profiles p ON p.user_id = u.user_id
WHERE f.friend_id = '11111111-1111-1111-1111-111111111111' 
  AND f.status = 'PENDING';

-- R6: Get conversations for a user
-- READ
SELECT c.conversation_id, c.title, c.is_group, cp.role, cp.joined_at
FROM conversation_participants cp
JOIN conversations c ON c.conversation_id = cp.conversation_id
WHERE cp.user_id = '11111111-1111-1111-1111-111111111111'
ORDER BY c.created_at DESC;

-- R7: Fetch last 50 chat messages in a conversation
-- READ
SELECT m.message_id, m.sender_id, u.username, p.display_name, m.content, m.message_type, m.sent_at
FROM messages m
JOIN users u ON u.user_id = m.sender_id
JOIN user_profiles p ON p.user_id = u.user_id
WHERE m.conversation_id = '22222222-2222-2222-2222-222222222222'
ORDER BY m.sent_at DESC
LIMIT 50;

-- R8: List group conversation members
-- READ
SELECT u.user_id, u.username, p.display_name, cp.role, cp.joined_at
FROM conversation_participants cp
JOIN users u ON u.user_id = cp.user_id
JOIN user_profiles p ON p.user_id = u.user_id
WHERE cp.conversation_id = '22222222-2222-2222-2222-222222222222'
ORDER BY cp.joined_at ASC;

-- R9: Call log history for a user
-- READ
SELECT c.call_id, c.caller_id, c.receiver_id, c.call_type, c.status, c.started_at, c.ended_at,
       u.username AS other_user
FROM call_records c
JOIN users u ON (u.user_id = CASE WHEN c.caller_id = '11111111-1111-1111-1111-111111111111' THEN c.receiver_id ELSE c.caller_id END)
WHERE c.caller_id = '11111111-1111-1111-1111-111111111111' 
   OR c.receiver_id = '11111111-1111-1111-1111-111111111111'
ORDER BY c.started_at DESC;

-- R10: Active live streams with streamer info and viewer count
-- READ
SELECT s.stream_id, s.title, s.started_at, u.username AS streamer_name,
       p.display_name, p.avatar_url,
       COUNT(sv.viewer_id) AS viewer_count
FROM streams s
JOIN users u ON u.user_id = s.streamer_id
JOIN user_profiles p ON p.user_id = u.user_id
LEFT JOIN stream_viewers sv ON sv.stream_id = s.stream_id
WHERE s.status = 'LIVE'
GROUP BY s.stream_id, s.title, s.started_at, u.username, p.display_name, p.avatar_url
ORDER BY viewer_count DESC, s.started_at DESC;

-- W1: Register new user
-- WRITE
INSERT INTO users (user_id, username, email, password_hash)
VALUES ('33333333-3333-3333-3333-333333333333', 'johndoe', 'johndoe@example.com', '$2b$12$e8rUqL6K...hash');

-- W2: Update user profile status and presence
-- WRITE
UPDATE user_profiles
SET is_online = TRUE, last_seen = CURRENT_TIMESTAMP
WHERE user_id = '11111111-1111-1111-1111-111111111111';

-- W3: Send a message in a conversation
-- WRITE
INSERT INTO messages (conversation_id, sender_id, message_type, content)
VALUES ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'TEXT', 'Hello everyone!');

-- W4: Send or accept a friend request
-- WRITE
INSERT INTO friendships (user_id, friend_id, status)
VALUES ('11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'ACCEPTED')
ON CONFLICT (user_id, friend_id)
DO UPDATE SET status = EXCLUDED.status;

-- W5: Log an audio/video call
-- WRITE
INSERT INTO call_records (caller_id, receiver_id, call_type, status, started_at)
VALUES ('11111111-1111-1111-1111-111111111111', '44444444-4444-4444-4444-444444444444', 'VIDEO', 'INITIATED', CURRENT_TIMESTAMP);
