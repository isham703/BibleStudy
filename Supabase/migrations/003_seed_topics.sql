-- Bible Study App - Seed Topics Data

-- Sample topics (20 topics)
INSERT INTO topics (slug, name, description, level) VALUES
('salvation', 'Salvation', 'God''s plan to redeem humanity through faith', 0),
('faith', 'Faith', 'Trust and belief in God', 0),
('love', 'Love', 'God''s love and how we should love others', 0),
('prayer', 'Prayer', 'Communication with God', 0),
('wisdom', 'Wisdom', 'Divine wisdom and understanding', 0),
('forgiveness', 'Forgiveness', 'God''s forgiveness and forgiving others', 0),
('holy-spirit', 'Holy Spirit', 'The third person of the Trinity', 0),
('creation', 'Creation', 'God as creator of all things', 0),
('covenant', 'Covenant', 'God''s promises and agreements with His people', 0),
('prophecy', 'Prophecy', 'Divine revelation about future events', 0),
('grace', 'Grace', 'Unmerited favor from God', 1),
('redemption', 'Redemption', 'Being bought back from sin', 1),
('justification', 'Justification', 'Being declared righteous', 1),
('sanctification', 'Sanctification', 'Process of becoming holy', 1),
('repentance', 'Repentance', 'Turning away from sin', 1),
('obedience', 'Obedience', 'Following God''s commands', 1),
('worship', 'Worship', 'Honoring and praising God', 1),
('discipleship', 'Discipleship', 'Following and learning from Jesus', 1),
('suffering', 'Suffering', 'Trials and their purpose', 1),
('hope', 'Hope', 'Confident expectation in God''s promises', 1);

-- Topic edges (hierarchy)
INSERT INTO topic_edges (parent_id, child_id)
SELECT p.id, c.id FROM topics p, topics c
WHERE (p.slug = 'salvation' AND c.slug IN ('grace', 'redemption', 'justification', 'sanctification'))
   OR (p.slug = 'faith' AND c.slug IN ('repentance', 'obedience'))
   OR (p.slug = 'love' AND c.slug IN ('forgiveness', 'grace'))
   OR (p.slug = 'prayer' AND c.slug IN ('worship'));

-- Sample topic-verse mappings
INSERT INTO topic_verses (topic_id, book_id, chapter, verse_start, verse_end, relevance_score)
SELECT t.id, v.book_id, v.chapter, v.verse_start, v.verse_end, v.score
FROM topics t
CROSS JOIN (VALUES
    -- Salvation verses
    ('salvation', 43, 3, 16, 16, 1.0),  -- John 3:16
    ('salvation', 49, 2, 8, 9, 1.0),     -- Ephesians 2:8-9
    -- Faith verses
    ('faith', 58, 11, 1, 1, 1.0),        -- Hebrews 11:1
    ('faith', 58, 11, 6, 6, 0.9),        -- Hebrews 11:6
    -- Love verses
    ('love', 46, 13, 4, 7, 1.0),         -- 1 Corinthians 13:4-7
    ('love', 62, 4, 8, 8, 1.0),          -- 1 John 4:8
    -- Creation verses
    ('creation', 1, 1, 1, 1, 1.0),       -- Genesis 1:1
    ('creation', 1, 1, 27, 27, 0.9)      -- Genesis 1:27
) AS v(topic_slug, book_id, chapter, verse_start, verse_end, score)
WHERE t.slug = v.topic_slug;

-- Function for semantic topic search
CREATE OR REPLACE FUNCTION search_topics(
    query_embedding vector(1536),
    match_count INT DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    slug TEXT,
    name TEXT,
    description TEXT,
    level INT,
    similarity FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.id,
        t.slug,
        t.name,
        t.description,
        t.level,
        1 - (te.embedding <=> query_embedding) AS similarity
    FROM topics t
    JOIN topic_embeddings te ON te.topic_id = t.id
    ORDER BY te.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;
