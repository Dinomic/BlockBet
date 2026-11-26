package com.dinomic.blockbet.services.impl;

import com.dinomic.blockbet.services.IBetContractService.WinnerPayout;
import org.junit.jupiter.api.Test;
import org.web3j.abi.EventEncoder;
import org.web3j.abi.FunctionEncoder;
import org.web3j.abi.TypeReference;
import org.web3j.abi.datatypes.Address;
import org.web3j.abi.datatypes.Bool;
import org.web3j.abi.datatypes.Event;
import org.web3j.abi.datatypes.generated.Uint256;
import org.web3j.protocol.core.methods.response.Log;
import org.web3j.utils.Numeric;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** The Payout event of BlockBetSimplePool.sol, as BetContractService reads it from a resolve receipt. */
class PayoutEventParsingTest {
    private static final String CONTRACT = "0x1111111111111111111111111111111111111111";
    private static final String WINNER_A = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    private static final String WINNER_B = "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";

    private static final Event PAYOUT = new Event("Payout", Arrays.asList(
        new TypeReference<Uint256>(true) {
        },
        new TypeReference<Address>(true) {
        },
        new TypeReference<Uint256>() {
        },
        new TypeReference<Bool>() {
        }));

    private static Log payoutLog(String contract, String eventTopic, String to, long amount, boolean paid) {
        Log log = new Log();
        log.setAddress(contract);
        log.setTopics(List.of(
            eventTopic,
            Numeric.toHexStringWithPrefixZeroPadded(BigInteger.ONE, 64),
            Numeric.toHexStringWithPrefixZeroPadded(Numeric.toBigInt(to), 64)));
        log.setData("0x" + FunctionEncoder.encodeConstructor(
            List.of(new Uint256(BigInteger.valueOf(amount)), new Bool(paid))));
        return log;
    }

    @Test
    void readsOnePayoutPerWinnerInOrder() {
        String topic = EventEncoder.encode(PAYOUT);

        List<WinnerPayout> payouts = BetContractService.parsePayouts(List.of(
            payoutLog(CONTRACT, topic, WINNER_A, 23, true),
            payoutLog(CONTRACT, topic, WINNER_B, 23, false)), CONTRACT);

        assertEquals(2, payouts.size());
        assertEquals(WINNER_A, payouts.get(0).to());
        assertEquals(BigInteger.valueOf(23), payouts.get(0).amount());
        assertTrue(payouts.get(0).paid());
        assertEquals(WINNER_B, payouts.get(1).to());
        assertFalse(payouts.get(1).paid());
    }

    @Test
    void ignoresEventsOfOtherContractsAndOtherEvents() {
        String topic = EventEncoder.encode(PAYOUT);
        Log otherContract = payoutLog("0x2222222222222222222222222222222222222222", topic, WINNER_A, 23, true);
        Log otherEvent = payoutLog(CONTRACT, "0x" + "ab".repeat(32), WINNER_A, 23, true);

        assertTrue(BetContractService.parsePayouts(List.of(otherContract, otherEvent), CONTRACT).isEmpty());
    }
}
