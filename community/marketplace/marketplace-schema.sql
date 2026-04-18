-- Scenario Marketplace Database Schema

CREATE TABLE scenarios (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    version VARCHAR(50) NOT NULL,
    type VARCHAR(50) NOT NULL, -- attack, defense, monitoring
    category VARCHAR(100),
    difficulty VARCHAR(20), -- beginner, intermediate, expert
    description TEXT,
    author VARCHAR(255),
    author_email VARCHAR(255),
    tags TEXT[], -- Array of tags
    prerequisites TEXT[], -- Array of prerequisites
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    downloads INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.0,
    verified BOOLEAN DEFAULT FALSE
);

CREATE TABLE scenario_files (
    id SERIAL PRIMARY KEY,
    scenario_id INTEGER REFERENCES scenarios(id) ON DELETE CASCADE,
    filename VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    file_type VARCHAR(50) -- yaml, json, go, etc.
);

CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    scenario_id INTEGER REFERENCES scenarios(id) ON DELETE CASCADE,
    user_id VARCHAR(255), -- Could be GitHub username
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id VARCHAR(255) PRIMARY KEY, -- GitHub username
    name VARCHAR(255),
    email VARCHAR(255),
    avatar_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_scenarios_type ON scenarios(type);
CREATE INDEX idx_scenarios_category ON scenarios(category);
CREATE INDEX idx_scenarios_author ON scenarios(author);
CREATE INDEX idx_scenarios_tags ON scenarios USING GIN(tags);
CREATE INDEX idx_scenario_files_scenario_id ON scenario_files(scenario_id);
CREATE INDEX idx_reviews_scenario_id ON reviews(scenario_id);

-- Update rating function
CREATE OR REPLACE FUNCTION update_scenario_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE scenarios
    SET rating = (
        SELECT AVG(rating)::DECIMAL(3,2)
        FROM reviews
        WHERE scenario_id = NEW.scenario_id
    )
    WHERE id = NEW.scenario_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_rating_trigger
    AFTER INSERT OR UPDATE OR DELETE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_scenario_rating();
