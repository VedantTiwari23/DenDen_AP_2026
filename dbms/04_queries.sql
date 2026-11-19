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
ORDER BY c.started_