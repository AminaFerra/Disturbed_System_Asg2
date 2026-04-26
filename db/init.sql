-- Database schema for audit logs and state tracking

-- Table for tracking request states
CREATE TABLE IF NOT EXISTS requests (
    id SERIAL PRIMARY KEY,
    request_id UUID UNIQUE NOT NULL,
    service_name VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    source VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table for audit logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    request_id UUID NOT NULL,
    service_name VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    source VARCHAR(100),
    details JSONB,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_audit_request_id ON audit_logs(request_id);
CREATE INDEX IF NOT EXISTS idx_audit_logged_at ON audit_logs(logged_at);
CREATE INDEX IF NOT EXISTS idx_audit_state ON audit_logs(state);
CREATE INDEX IF NOT EXISTS idx_requests_request_id ON requests(request_id);
CREATE INDEX IF NOT EXISTS idx_requests_status ON requests(status);

-- Simple view
CREATE OR REPLACE VIEW request_flow_view AS
SELECT 
    r.request_id,
    r.service_name as current_service,
    r.status as current_status,
    r.source as current_source,
    r.created_at as request_start,
    COUNT(a.id) as total_audit_entries
FROM requests r
LEFT JOIN audit_logs a ON r.request_id = a.request_id
GROUP BY r.request_id, r.service_name, r.status, r.source, r.created_at
ORDER BY r.created_at DESC;

-- Function to get request timeline
CREATE OR REPLACE FUNCTION get_request_timeline(p_request_id UUID)
RETURNS TABLE(
    event_time TIMESTAMP,
    service_name VARCHAR(50),
    event_state VARCHAR(50),
    event_action VARCHAR(50),
    event_status VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT a.logged_at, a.service_name, a.state, a.action, a.status
    FROM audit_logs a
    WHERE a.request_id = p_request_id
    ORDER BY a.logged_at;
END;
$$ LANGUAGE plpgsql;
