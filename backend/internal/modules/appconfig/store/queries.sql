-- name: ListConfig :many
SELECT key, value FROM app_config ORDER BY key;
