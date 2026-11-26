-- Audit log of the betting actions (create, place, resolve, refund, caution flag), one row per action.
-- BET_ID and ACCOUNT_ID have no foreign keys on purpose: the log must outlive and never block what it describes.
-- ACCOUNT_ID is null for actions of the system (caution flag) and of the internal team (refund).
-- AMOUNT is the wei the action moved when it is known (the stake of a placed bet), else null.
CREATE TABLE IF NOT EXISTS BETTING_LOG(
    BETTING_LOG_ID      INT             NOT NULL,
    BET_ID              INT,
    ACTION              VARCHAR(32)     NOT NULL,
    ACCOUNT_ID          INT,
    WALLET_ADDRESS      VARCHAR(42),
    BET_OPTION          VARCHAR(1),
    AMOUNT              NUMERIC(78, 0),
    TX_HASH             VARCHAR(66),
    DETAIL              VARCHAR(512),
    CREATED_AT          TIMESTAMP       NOT NULL DEFAULT NOW()
    );
CREATE SEQUENCE IF NOT EXISTS SEQ_BETTING_LOG START 100;
ALTER TABLE BETTING_LOG ADD CONSTRAINT PK_BETTING_LOG PRIMARY KEY (BETTING_LOG_ID);
CREATE INDEX IF NOT EXISTS IDX_BETTING_LOG_BET_ID ON BETTING_LOG (BET_ID);
CREATE INDEX IF NOT EXISTS IDX_BETTING_LOG_ACCOUNT_ID ON BETTING_LOG (ACCOUNT_ID);