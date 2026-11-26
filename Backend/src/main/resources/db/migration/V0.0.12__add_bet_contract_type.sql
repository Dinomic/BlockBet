-- Which kind of contract a deployment is (enum BetContractType). Every deployment so far is the two-option pool.
ALTER TABLE BET_CONTRACTS ADD COLUMN CONTRACT_TYPE VARCHAR(32) NOT NULL DEFAULT 'TWO_OPTION_POOL';
ALTER TABLE BET_CONTRACTS ALTER COLUMN CONTRACT_TYPE DROP DEFAULT;
