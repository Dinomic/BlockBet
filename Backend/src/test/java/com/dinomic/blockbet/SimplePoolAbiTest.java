package com.dinomic.blockbet;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The calls BetContractService encodes must exist in the compiled contract. If BlockBetSimplePool.sol changes
 * and the .abi is recompiled, this fails when a signature the backend uses is gone or changed.
 */
class SimplePoolAbiTest {

    private static List<String> signatures() throws Exception {
        JsonNode abi = new ObjectMapper().readTree(
            new ClassPathResource("contracts/simple/BlockBetSimplePool.abi").getInputStream());
        List<String> result = new ArrayList<>();
        for (JsonNode entry : abi) {
            if (!"function".equals(entry.path("type").asText())) {
                continue;
            }
            List<String> types = new ArrayList<>();
            entry.path("inputs").forEach(input -> types.add(input.path("type").asText()));
            result.add(entry.path("name").asText() + "(" + String.join(",", types) + ")");
        }
        return result;
    }

    @Test
    void writeFunctionsMatchWhatTheBackendSends() throws Exception {
        List<String> signatures = signatures();
        assertTrue(signatures.contains("createBet(string[],uint256,uint256)"), signatures.toString());
        assertTrue(signatures.contains("placeBet(uint256,uint8)"), signatures.toString());
        assertTrue(signatures.contains("resolve(uint256,uint8)"), signatures.toString());
        assertTrue(signatures.contains("refundExpired(uint256)"), signatures.toString());
    }

    @Test
    void eventsMatchWhatTheBackendReads() throws Exception {
        JsonNode abi = new ObjectMapper().readTree(
            new ClassPathResource("contracts/simple/BlockBetSimplePool.abi").getInputStream());
        List<String> events = new ArrayList<>();
        for (JsonNode entry : abi) {
            if (!"event".equals(entry.path("type").asText())) {
                continue;
            }
            List<String> types = new ArrayList<>();
            entry.path("inputs").forEach(input -> types.add(input.path("type").asText()));
            events.add(entry.path("name").asText() + "(" + String.join(",", types) + ")");
        }
        assertTrue(events.contains("BetCreated(uint256,address,uint256,uint256)"), events.toString());
        assertTrue(events.contains("InternalPayout(uint256,address,uint256)"), events.toString());
        assertTrue(events.contains("Payout(uint256,address,uint256,bool)"), events.toString());
    }

    @Test
    void readFunctionsTakeTheBetId() throws Exception {
        List<String> signatures = signatures();
        assertTrue(signatures.contains("getMarket(uint256)"), signatures.toString());
        assertTrue(signatures.contains("getState(uint256)"), signatures.toString());
    }

    @Test
    void readFunctionsReturnWhatTheBackendDecodes() throws Exception {
        JsonNode abi = new ObjectMapper().readTree(
            new ClassPathResource("contracts/simple/BlockBetSimplePool.abi").getInputStream());
        for (JsonNode entry : abi) {
            List<String> outputs = new ArrayList<>();
            entry.path("outputs").forEach(output -> outputs.add(output.path("type").asText()));
            if ("getMarket".equals(entry.path("name").asText())) {
                assertTrue(outputs.equals(List.of("address", "string[]", "uint256", "uint256")), outputs.toString());
            }
            if ("getState".equals(entry.path("name").asText())) {
                assertTrue(outputs.equals(List.of("uint8", "uint8", "uint256[]")), outputs.toString());
            }
        }
    }
}
