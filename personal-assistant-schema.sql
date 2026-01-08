-- ============================================================================
-- Personal Assistant AI Agent - Supabase Database Schema
-- ============================================================================
-- This schema provides persistent memory for an n8n-based AI assistant
-- Designed for easy migration and comprehensive context tracking
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector"; -- For semantic search

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- -----------------------------------------------------------------------------
-- Conversations: Full conversation history with embeddings
-- Extends existing n8n_chat_histories with better structure
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id VARCHAR(255) NOT NULL,
    message JSONB NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    embedding vector(1536), -- OpenAI embedding size
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_conversations_session ON conversations(session_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_timestamp ON conversations(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_embedding ON conversations USING ivfflat (embedding vector_cosine_ops);

-- -----------------------------------------------------------------------------
-- Tasks: Action items with status tracking
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'blocked', 'cancelled')),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    deadline TIMESTAMPTZ,

    -- Context
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,

    -- Relationships
    parent_task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id) ON DELETE SET NULL,

    -- Metadata
    tags TEXT[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}',

    -- For semantic search
    embedding vector(1536)
);

CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status, deadline NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_tasks_deadline ON tasks(deadline) WHERE deadline IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_updated ON tasks(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_tasks_embedding ON tasks USING ivfflat (embedding vector_cosine_ops);

-- -----------------------------------------------------------------------------
-- Decisions: Important choices and their rationale
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS decisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    decision TEXT NOT NULL,
    rationale TEXT,

    -- Context
    made_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    context JSONB DEFAULT '{}',

    -- Relationships
    conversation_id UUID REFERENCES conversations(id) ON DELETE SET NULL,
    related_task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,

    -- Categorization
    category VARCHAR(100),
    tags TEXT[] DEFAULT '{}',

    -- For semantic search
    embedding vector(1536),

    -- Status tracking
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'revisited', 'reversed', 'archived'))
);

CREATE INDEX IF NOT EXISTS idx_decisions_made_at ON decisions(made_at DESC);
CREATE INDEX IF NOT EXISTS idx_decisions_category ON decisions(category);
CREATE INDEX IF NOT EXISTS idx_decisions_status ON decisions(status);
CREATE INDEX IF NOT EXISTS idx_decisions_embedding ON decisions USING ivfflat (embedding vector_cosine_ops);

-- -----------------------------------------------------------------------------
-- Patterns: Learned behaviors and insights
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pattern_type VARCHAR(100) NOT NULL,
    pattern_name TEXT NOT NULL,
    description TEXT NOT NULL,
    confidence DECIMAL(3,2) DEFAULT 0.5 CHECK (confidence BETWEEN 0 AND 1),

    -- Evidence
    evidence JSONB NOT NULL DEFAULT '[]',
    occurrences INTEGER DEFAULT 1,
    first_observed TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_observed TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Metadata
    metadata JSONB DEFAULT '{}',

    -- Status
    is_active BOOLEAN DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_patterns_type ON patterns(pattern_type);
CREATE INDEX IF NOT EXISTS idx_patterns_confidence ON patterns(confidence DESC);
CREATE INDEX IF NOT EXISTS idx_patterns_last_observed ON patterns(last_observed DESC);
CREATE INDEX IF NOT EXISTS idx_patterns_active ON patterns(is_active) WHERE is_active = true;

-- -----------------------------------------------------------------------------
-- Context: Current state and working memory
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS context (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    context_key VARCHAR(255) NOT NULL UNIQUE,
    context_value JSONB NOT NULL,
    context_type VARCHAR(100) NOT NULL,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,

    -- Metadata
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_context_key ON context(context_key);
CREATE INDEX IF NOT EXISTS idx_context_type ON context(context_type);
CREATE INDEX IF NOT EXISTS idx_context_expires ON context(expires_at) WHERE expires_at IS NOT NULL;

-- -----------------------------------------------------------------------------
-- Launch Timeline: Track 4-week launch plan
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS launch_timeline (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    week_number INTEGER NOT NULL CHECK (week_number BETWEEN 1 AND 4),
    milestone TEXT NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed', 'at_risk')),

    -- Dates
    target_date DATE NOT NULL,
    completed_date DATE,

    -- Relationships
    related_tasks UUID[] DEFAULT '{}',

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_launch_week ON launch_timeline(week_number);
CREATE INDEX IF NOT EXISTS idx_launch_status ON launch_timeline(status);
CREATE INDEX IF NOT EXISTS idx_launch_target ON launch_timeline(target_date);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- -----------------------------------------------------------------------------
-- Auto-update timestamps
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_context_updated_at ON context;
CREATE TRIGGER update_context_updated_at BEFORE UPDATE ON context
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_launch_timeline_updated_at ON launch_timeline;
CREATE TRIGGER update_launch_timeline_updated_at BEFORE UPDATE ON launch_timeline
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- Auto-set completion timestamp for tasks
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_task_completed_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        NEW.completed_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS task_completion_trigger ON tasks;
CREATE TRIGGER task_completion_trigger BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION set_task_completed_at();

-- -----------------------------------------------------------------------------
-- Vector similarity search function
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION search_similar_conversations(
    query_embedding vector(1536),
    match_threshold float DEFAULT 0.7,
    match_count int DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    session_id VARCHAR,
    message JSONB,
    role VARCHAR,
    msg_timestamp TIMESTAMPTZ,
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        conversations.id,
        conversations.session_id,
        conversations.message,
        conversations.role,
        conversations.timestamp,
        1 - (conversations.embedding <=> query_embedding) as similarity
    FROM conversations
    WHERE conversations.embedding IS NOT NULL
        AND 1 - (conversations.embedding <=> query_embedding) > match_threshold
    ORDER BY conversations.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- -----------------------------------------------------------------------------
-- Search similar tasks
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION search_similar_tasks(
    query_embedding vector(1536),
    match_threshold float DEFAULT 0.7,
    match_count int DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    description TEXT,
    status VARCHAR,
    priority VARCHAR,
    deadline TIMESTAMPTZ,
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        tasks.id,
        tasks.title,
        tasks.description,
        tasks.status,
        tasks.priority,
        tasks.deadline,
        1 - (tasks.embedding <=> query_embedding) as similarity
    FROM tasks
    WHERE tasks.embedding IS NOT NULL
        AND 1 - (tasks.embedding <=> query_embedding) > match_threshold
    ORDER BY tasks.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- -----------------------------------------------------------------------------
-- Search similar decisions
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION search_similar_decisions(
    query_embedding vector(1536),
    match_threshold float DEFAULT 0.7,
    match_count int DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    title TEXT,
    decision TEXT,
    rationale TEXT,
    made_at TIMESTAMPTZ,
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        decisions.id,
        decisions.title,
        decisions.decision,
        decisions.rationale,
        decisions.made_at,
        1 - (decisions.embedding <=> query_embedding) as similarity
    FROM decisions
    WHERE decisions.embedding IS NOT NULL
        AND 1 - (decisions.embedding <=> query_embedding) > match_threshold
        AND decisions.status = 'active'
    ORDER BY decisions.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- -----------------------------------------------------------------------------
-- Get current context snapshot
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_current_context()
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_object_agg(context_key, context_value)
    INTO result
    FROM context
    WHERE (expires_at IS NULL OR expires_at > NOW());

    RETURN COALESCE(result, '{}'::jsonb);
END;
$$;

-- -----------------------------------------------------------------------------
-- Pattern tracking - increment occurrences
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION record_pattern_occurrence(
    p_pattern_type VARCHAR,
    p_pattern_name TEXT,
    p_evidence JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    pattern_id UUID;
BEGIN
    -- Try to update existing pattern
    UPDATE patterns
    SET
        occurrences = occurrences + 1,
        last_observed = NOW(),
        evidence = CASE
            WHEN p_evidence IS NOT NULL THEN evidence || p_evidence
            ELSE evidence
        END,
        confidence = LEAST(1.0, confidence + 0.1) -- Increase confidence
    WHERE pattern_type = p_pattern_type
        AND pattern_name = p_pattern_name
        AND is_active = true
    RETURNING id INTO pattern_id;

    -- If no existing pattern, this will return NULL
    RETURN pattern_id;
END;
$$;

-- -----------------------------------------------------------------------------
-- Mental Health Patterns: CBT-focused tracking
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mental_health_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Pattern identification
    pattern_type VARCHAR(50) NOT NULL CHECK (pattern_type IN ('distortion', 'avoidance', 'win', 'reframe', 'trigger')),
    distortion_category VARCHAR(100), -- 'catastrophizing', 'all_or_nothing', 'mind_reading', 'fortune_telling', 'discounting_positives', 'should_statements', 'imposter_syndrome', 'rejection_sensitivity'

    -- Content
    original_thought TEXT NOT NULL,
    reframe TEXT,
    accepted BOOLEAN DEFAULT NULL, -- NULL = not yet responded, TRUE = accepted reframe, FALSE = rejected

    -- Context
    context TEXT,
    trigger_type VARCHAR(100), -- What triggered this pattern (e.g., 'task_deadline', 'social_interaction', 'performance_review')

    -- Relationships
    conversation_id UUID REFERENCES conversations(id) ON DELETE SET NULL,
    task_id UUID REFERENCES tasks(id) ON DELETE SET NULL,

    -- Metadata
    severity VARCHAR(20) CHECK (severity IN ('low', 'medium', 'high')), -- How severe was the distortion
    resolved BOOLEAN DEFAULT false, -- Did the user work through this successfully?
    notes TEXT,
    metadata JSONB DEFAULT '{}',

    -- For semantic search
    embedding vector(1536)
);

CREATE INDEX IF NOT EXISTS idx_mh_patterns_created ON mental_health_patterns(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mh_patterns_type ON mental_health_patterns(pattern_type);
CREATE INDEX IF NOT EXISTS idx_mh_patterns_distortion ON mental_health_patterns(distortion_category);
CREATE INDEX IF NOT EXISTS idx_mh_patterns_accepted ON mental_health_patterns(accepted) WHERE accepted IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_mh_patterns_trigger ON mental_health_patterns(trigger_type);
CREATE INDEX IF NOT EXISTS idx_mh_patterns_embedding ON mental_health_patterns USING ivfflat (embedding vector_cosine_ops);

-- -----------------------------------------------------------------------------
-- Search similar mental health patterns
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION search_similar_mental_health_patterns(
    query_embedding vector(1536),
    match_threshold float DEFAULT 0.7,
    match_count int DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    pattern_type VARCHAR,
    distortion_category VARCHAR,
    original_thought TEXT,
    reframe TEXT,
    accepted BOOLEAN,
    created_at TIMESTAMPTZ,
    similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        mhp.id,
        mhp.pattern_type,
        mhp.distortion_category,
        mhp.original_thought,
        mhp.reframe,
        mhp.accepted,
        mhp.created_at,
        1 - (mhp.embedding <=> query_embedding) as similarity
    FROM mental_health_patterns mhp
    WHERE mhp.embedding IS NOT NULL
        AND 1 - (mhp.embedding <=> query_embedding) > match_threshold
    ORDER BY mhp.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- -----------------------------------------------------------------------------
-- Get distortion frequency stats
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_distortion_stats(
    days_back int DEFAULT 30
)
RETURNS TABLE (
    distortion_category VARCHAR,
    occurrence_count BIGINT,
    acceptance_rate NUMERIC,
    avg_severity NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        mhp.distortion_category,
        COUNT(*) as occurrence_count,
        ROUND(
            (COUNT(*) FILTER (WHERE mhp.accepted = true)::NUMERIC /
            NULLIF(COUNT(*) FILTER (WHERE mhp.accepted IS NOT NULL), 0)) * 100,
            2
        ) as acceptance_rate,
        ROUND(AVG(
            CASE mhp.severity
                WHEN 'low' THEN 1
                WHEN 'medium' THEN 2
                WHEN 'high' THEN 3
                ELSE NULL
            END
        ), 2) as avg_severity
    FROM mental_health_patterns mhp
    WHERE mhp.pattern_type = 'distortion'
        AND mhp.created_at > NOW() - (days_back || ' days')::INTERVAL
        AND mhp.distortion_category IS NOT NULL
    GROUP BY mhp.distortion_category
    ORDER BY occurrence_count DESC;
END;
$$;

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- -----------------------------------------------------------------------------
-- Active tasks with deadlines approaching
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW upcoming_tasks AS
SELECT
    id,
    title,
    description,
    status,
    priority,
    deadline,
    EXTRACT(EPOCH FROM (deadline - NOW())) / 3600 as hours_until_deadline
FROM tasks
WHERE status NOT IN ('completed', 'cancelled')
    AND deadline IS NOT NULL
    AND deadline > NOW()
ORDER BY deadline ASC;

-- -----------------------------------------------------------------------------
-- Recent decisions
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW recent_decisions AS
SELECT
    id,
    title,
    decision,
    rationale,
    made_at,
    category,
    tags
FROM decisions
WHERE status = 'active'
ORDER BY made_at DESC
LIMIT 20;

-- -----------------------------------------------------------------------------
-- Active patterns
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW active_patterns AS
SELECT
    pattern_type,
    pattern_name,
    description,
    confidence,
    occurrences,
    last_observed
FROM patterns
WHERE is_active = true
ORDER BY confidence DESC, occurrences DESC;

-- -----------------------------------------------------------------------------
-- Launch progress
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW launch_progress AS
SELECT
    week_number,
    milestone,
    status,
    target_date,
    completed_date,
    CASE
        WHEN status = 'completed' THEN 100
        WHEN target_date < CURRENT_DATE AND status != 'completed' THEN -1
        ELSE 0
    END as progress_indicator
FROM launch_timeline
ORDER BY week_number, target_date;

-- -----------------------------------------------------------------------------
-- Recent mental health patterns
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW recent_mental_health_patterns AS
SELECT
    id,
    pattern_type,
    distortion_category,
    original_thought,
    reframe,
    accepted,
    severity,
    resolved,
    created_at
FROM mental_health_patterns
ORDER BY created_at DESC
LIMIT 50;

-- ============================================================================
-- INITIAL DATA & SETUP
-- ============================================================================

-- Set up initial context keys
INSERT INTO context (context_key, context_value, context_type) VALUES
    ('current_focus', '{"focus": "4-week launch preparation"}', 'goal'),
    ('work_hours', '{"typical_start": "09:00", "typical_end": "17:00"}', 'pattern'),
    ('launch_start_date', to_jsonb(CURRENT_DATE::text), 'timeline')
ON CONFLICT (context_key) DO NOTHING;

-- ============================================================================
-- GRANTS (Adjust based on your auth setup)
-- ============================================================================
-- Grant access to authenticated users (adjust role as needed)
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO postgres;

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================
COMMENT ON TABLE conversations IS 'Full conversation history with semantic search capability';
COMMENT ON TABLE tasks IS 'Action items with status tracking and deadline management';
COMMENT ON TABLE decisions IS 'Important choices with rationale - searchable by semantic similarity';
COMMENT ON TABLE patterns IS 'Learned behaviors and insights about work patterns';
COMMENT ON TABLE context IS 'Current state and working memory - key-value store with expiration';
COMMENT ON TABLE launch_timeline IS 'Track 4-week launch plan milestones and progress';
COMMENT ON TABLE mental_health_patterns IS 'CBT-focused cognitive distortion tracking and reframing with ADHD/entrepreneurship focus';

COMMENT ON FUNCTION search_similar_conversations IS 'Semantic search across conversation history';
COMMENT ON FUNCTION search_similar_tasks IS 'Find similar tasks using vector embeddings';
COMMENT ON FUNCTION search_similar_decisions IS 'Search decisions by semantic similarity';
COMMENT ON FUNCTION get_current_context IS 'Get all active context as a single JSON object';
COMMENT ON FUNCTION record_pattern_occurrence IS 'Track pattern occurrences and update confidence';
COMMENT ON FUNCTION search_similar_mental_health_patterns IS 'Find similar cognitive distortions and patterns';
COMMENT ON FUNCTION get_distortion_stats IS 'Get frequency and acceptance rate statistics for cognitive distortions';
