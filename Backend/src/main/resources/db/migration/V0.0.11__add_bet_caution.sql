-- CLOSE_TIME is a copy of the (immutable) close time stored in the smart contract, so the caution check can find
-- overdue bets without reading every bet from the chain.
-- CAUTION marks a bet the bookie has not resolved for too long, for the internal team; it is off-chain only.
-- CAUTION_CHECKED_AT is set once the check has looked at the bet after its deadline.
ALTER TABLE BETS ADD COLUMN IF NOT EXISTS CLOSE_TIME TIMESTAMP;
ALTER TABLE BETS ADD COLUMN IF NOT EXISTS CAUTION BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE BETS ADD COLUMN IF NOT EXISTS CAUTION_CHECKED_AT TIMESTAMP;
