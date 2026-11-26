-- Amount in wei, set for the receipts that move a known amount (bet payouts to the internal account); null otherwise.
ALTER TABLE TRANSACTION_RECEIPTS ADD COLUMN IF NOT EXISTS AMOUNT NUMERIC(78, 0);
