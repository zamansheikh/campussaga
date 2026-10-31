-- +goose Up
-- An admin can end every open share on a route (a fake or stuck bus).
ALTER TABLE bus_live_sessions DROP CONSTRAINT bus_live_sessions_end_reason_check;
ALTER TABLE bus_live_sessions ADD CONSTRAINT bus_live_sessions_end_reason_check
  CHECK (end_reason IN ('stopped', 'arrived', 'expired', 'replaced', 'off_route', 'admin'));

-- +goose Down
UPDATE bus_live_sessions SET end_reason = 'stopped' WHERE end_reason = 'admin';
ALTER TABLE bus_live_sessions DROP CONSTRAINT bus_live_sessions_end_reason_check;
ALTER TABLE bus_live_sessions ADD CONSTRAINT bus_live_sessions_end_reason_check
  CHECK (end_reason IN ('stopped', 'arrived', 'expired', 'replaced', 'off_route'));
