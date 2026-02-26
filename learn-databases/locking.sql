-- ============================================
-- FINANCE TABLES & CONCURRENCY (Locking)
-- ============================================
-- Self-contained: run against your Postgres DB (e.g. docker compose postgres).
-- Problem: Same account, multiple transfers at once → read balance then debit = race, overdraw.
-- Solution: One transaction, lock source row with FOR UPDATE, then check + ledger + update.

-- ----- Drop & create -----
DROP TABLE IF EXISTS ledger CASCADE;
DROP TABLE IF EXISTS balances CASCADE;

CREATE TABLE balances (
    account_id INT PRIMARY KEY,
    balance_cents BIGINT NOT NULL DEFAULT 0,
    version INT NOT NULL DEFAULT 1   -- for optimistic locking
);

CREATE TABLE ledger (
    ledger_id SERIAL PRIMARY KEY,
    from_account_id INT NOT NULL,
    to_account_id INT NOT NULL,
    amount_cents BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ----- Seed -----
INSERT INTO balances (account_id, balance_cents) VALUES
(1, 10000),   -- $100
(2, 5000);    -- $50

-- ============================================
-- CONCURRENCY: Same Account, Multiple Transfers
-- ============================================
-- Pessimistic: SELECT ... FOR UPDATE locks the row until commit; second transfer waits.
-- Optimistic: read balance + version, UPDATE ... WHERE version = ?; if 0 rows, retry.

-- ----- Reset (uncomment to re-run demo) -----
-- UPDATE balances SET balance_cents = 10000 WHERE account_id = 1;
-- UPDATE balances SET balance_cents = 5000 WHERE account_id = 2;
-- DELETE FROM ledger;

-- ----- Transfer with FOR UPDATE (run in one transaction) -----
-- Session 1 and Session 2 both run BEGIN; then SELECT ... FOR UPDATE on account 1.
-- Session 2 blocks until Session 1 commits or rolls back.
/*
BEGIN;
  SELECT balance_cents FROM balances WHERE account_id = 1 FOR UPDATE;
  -- App: if balance_cents < amount_cents then ROLLBACK; else:
  INSERT INTO ledger (from_account_id, to_account_id, amount_cents) VALUES (1, 2, 3000);
  UPDATE balances SET balance_cents = balance_cents - 3000 WHERE account_id = 1;
  UPDATE balances SET balance_cents = balance_cents + 3000 WHERE account_id = 2;
COMMIT;
*/

-- ----- Same logic in PL/pgSQL (uncomment to run a transfer) -----
/*
DO $$
DECLARE
  from_id INT := 1;
  to_id   INT := 2;
  amt     BIGINT := 3000;
  bal     BIGINT;
BEGIN
  SELECT balance_cents INTO bal FROM balances WHERE account_id = from_id FOR UPDATE;
  IF bal IS NULL OR bal < amt THEN
    RAISE EXCEPTION 'Insufficient balance or invalid account';
  END IF;
  INSERT INTO ledger (from_account_id, to_account_id, amount_cents) VALUES (from_id, to_id, amt);
  UPDATE balances SET balance_cents = balance_cents - amt WHERE account_id = from_id;
  UPDATE balances SET balance_cents = balance_cents + amt WHERE account_id = to_id;
END $$;
*/

-- ----- Verify -----
SELECT * FROM balances ORDER BY account_id;
SELECT * FROM ledger ORDER BY ledger_id;

-- ----- Optimistic locking (alternative) -----
-- UPDATE balances SET balance_cents = balance_cents - 3000, version = version + 1
-- WHERE account_id = 1 AND version = 1;
-- If rowcount = 0, another transfer won; retry read + update.
