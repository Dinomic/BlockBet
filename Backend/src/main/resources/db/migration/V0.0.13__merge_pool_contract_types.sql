-- The two- and three-option contracts were replaced by one contract with 2 to 5 options per bet
-- (MULTIPLE_OPTION_SIMPLE_POOL). Old rows keep pointing at their old deployments, which use the old ABI, so bets
-- created on them can no longer be read by the backend: reset the dev database and chain.
UPDATE BET_CONTRACTS SET CONTRACT_TYPE = 'MULTIPLE_OPTION_SIMPLE_POOL'
    WHERE CONTRACT_TYPE IN ('TWO_OPTION_POOL', 'THREE_OPTION_POOL');
