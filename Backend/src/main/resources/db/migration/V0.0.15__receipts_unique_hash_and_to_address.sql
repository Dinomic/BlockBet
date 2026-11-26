-- One transaction can pay several addresses (a bet's resolve pays every winner), so a hash alone is no longer
-- unique: it is unique together with the receiving address. The old constraint was created inline in
-- V0.0.2 (HASH ... UNIQUE) with a generated name, so it is looked up instead of named.
DO $$
DECLARE
    old_constraint TEXT;
BEGIN
    FOR old_constraint IN
        SELECT con.conname
        FROM pg_constraint con
                 JOIN pg_class rel ON rel.oid = con.conrelid
                 JOIN pg_namespace ns ON ns.oid = rel.relnamespace
        WHERE rel.relname = 'transaction_receipts'
          AND ns.nspname = current_schema()
          AND con.contype = 'u'
          AND array_length(con.conkey, 1) = 1
          AND (SELECT att.attname FROM pg_attribute att
               WHERE att.attrelid = rel.oid AND att.attnum = con.conkey[1]) = 'hash'
    LOOP
        EXECUTE format('ALTER TABLE TRANSACTION_RECEIPTS DROP CONSTRAINT %I', old_constraint);
    END LOOP;
END
$$;

ALTER TABLE TRANSACTION_RECEIPTS
    ADD CONSTRAINT UQ_TRANSACTION_RECEIPTS_HASH_TO UNIQUE (HASH, TO_ADDRESS);
