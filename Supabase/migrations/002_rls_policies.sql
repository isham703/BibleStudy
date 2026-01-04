-- Bible Study App - Row Level Security Policies

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE highlights ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_ai_explanations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_edges ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_verses ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_embeddings ENABLE ROW LEVEL SECURITY;

-- Profiles: users can only access their own
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Highlights: user-private
CREATE POLICY "Users can view own highlights" ON highlights
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own highlights" ON highlights
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own highlights" ON highlights
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own highlights" ON highlights
    FOR DELETE USING (auth.uid() = user_id);

-- Notes: user-private
CREATE POLICY "Users can view own notes" ON notes
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own notes" ON notes
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own notes" ON notes
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own notes" ON notes
    FOR DELETE USING (auth.uid() = user_id);

-- Saved explanations: user-private
CREATE POLICY "Users can view own explanations" ON saved_ai_explanations
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own explanations" ON saved_ai_explanations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Chat threads: user-private
CREATE POLICY "Users can view own threads" ON chat_threads
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own threads" ON chat_threads
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own threads" ON chat_threads
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own threads" ON chat_threads
    FOR DELETE USING (auth.uid() = user_id);

-- Chat messages: via thread ownership
CREATE POLICY "Users can view own messages" ON chat_messages
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM chat_threads WHERE id = thread_id AND user_id = auth.uid())
    );
CREATE POLICY "Users can insert own messages" ON chat_messages
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM chat_threads WHERE id = thread_id AND user_id = auth.uid())
    );

-- Reading plans: user-private (custom) or public (system)
CREATE POLICY "Users can view own plans" ON reading_plans
    FOR SELECT USING (auth.uid() = user_id OR is_custom = false);
CREATE POLICY "Users can insert own plans" ON reading_plans
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own plans" ON reading_plans
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own plans" ON reading_plans
    FOR DELETE USING (auth.uid() = user_id);

-- Reading progress: user-private
CREATE POLICY "Users can view own progress" ON reading_progress
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own progress" ON reading_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own progress" ON reading_progress
    FOR UPDATE USING (auth.uid() = user_id);

-- Topic feedback: user-private
CREATE POLICY "Users can view own feedback" ON topic_feedback
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own feedback" ON topic_feedback
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Topics, edges, verses, embeddings: public read
CREATE POLICY "Anyone can read topics" ON topics FOR SELECT USING (true);
CREATE POLICY "Anyone can read topic_edges" ON topic_edges FOR SELECT USING (true);
CREATE POLICY "Anyone can read topic_verses" ON topic_verses FOR SELECT USING (true);
CREATE POLICY "Anyone can read topic_embeddings" ON topic_embeddings FOR SELECT USING (true);
