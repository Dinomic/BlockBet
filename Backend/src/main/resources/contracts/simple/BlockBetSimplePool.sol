// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * Simple pool betting markets with 2 to 5 options (BetContractType.MULTIPLE_OPTION_SIMPLE_POOL).
 * One deployed contract holds many markets; every market has its own number of options.
 *
 * Compile for the private chain (genesis.json only enables forks up to Istanbul, so no PUSH0):
 *   solc --evm-version istanbul --optimize --bin --abi --overwrite -o <out> BlockBetSimplePool.sol
 * The backend deploys the contents of BlockBetSimplePool.bin (see src/main/resources/contracts/simple/).
 *
 * Options are numbered from 1 (1 = A, 2 = B, ... 5 = E); 0 means "none" (no winner yet / no bet).
 *
 * Rules:
 *  - the bookie creates a market: the names of its 2 to 5 options, the fixed stake every bettor must send (wei),
 *    and how long betting stays open
 *  - a bettor address can bet once per market, on one option, by sending exactly the stake
 *  - after the close time nobody can bet; only the bookie can then pick the winning option
 *  - on resolve, the whole pool is split equally between the addresses that bet on the winning option
 *    (one Payout event per winner). The division remainder goes to the internal account (InternalPayout event).
 *    If nobody bet on the winner, the whole pool does.
 *  - the internal account is whoever deploys the contract.
 *  - if the bookie has not resolved RESOLVE_DEADLINE after the close time, only the internal account can
 *    refund everybody (refundExpired). Flagging such bets for the internal team (CAUTION) is done off-chain.
 */
contract BlockBetSimplePool {
    // Derived, see _status(): OPEN -> CLOSED (betting time is over, waiting for the result) -> RESOLVED / REFUNDED.
    enum Status { OPEN, CLOSED, RESOLVED, REFUNDED }

    struct Market {
        address bookie;
        string[] options;
        uint256 stake;
        uint256 closeTime;
        bool settled;
        bool refunded;
        uint8 winner;
        uint256 bettorCount;
        mapping(uint8 => address[]) bettors;
    }

    uint256 public constant MIN_OPTIONS = 2;
    uint256 public constant MAX_OPTIONS = 5;
    uint256 public constant MAX_BETTORS = 200;      // keeps resolve() within the block gas limit
    uint256 public constant MAX_DURATION = 365 days;
    uint256 public constant RESOLVE_DEADLINE = 7 days;
    uint256 private constant PAY_GAS = 30000;       // a failing receiver cannot burn the resolver's gas

    /// Receives the division remainder and the pool of bets nobody won; the only one that can call refundExpired.
    address public immutable internalAccount;

    uint256 public marketCount;
    mapping(uint256 => Market) private markets;
    mapping(uint256 => mapping(address => uint8)) private choices;
    // payouts whose transfer failed; the owner pulls them with withdraw()
    mapping(address => uint256) public owed;

    event BetCreated(uint256 indexed betId, address indexed bookie, uint256 stake, uint256 closeTime);
    event BetPlaced(uint256 indexed betId, address indexed bettor, uint8 option);
    event BetResolved(uint256 indexed betId, uint8 winner, uint256 payoutEach, uint256 winners);
    event BetRefunded(uint256 indexed betId);
    /// Emitted whenever part of a pool goes to the internal account, so the backend can log it.
    event InternalPayout(uint256 indexed betId, address indexed to, uint256 amount);
    /// One per winner on resolve, so the backend can log who got what. paid = false: the transfer failed and the
    /// amount was kept in owed[to] for the winner to withdraw().
    event Payout(uint256 indexed betId, address indexed to, uint256 amount, bool paid);

    modifier exists(uint256 betId) {
        require(betId > 0 && betId <= marketCount, "Bet not found");
        _;
    }

    constructor() {
        internalAccount = msg.sender;
    }

    function createBet(
        string[] calldata options,
        uint256 stake,
        uint256 durationSeconds
    ) external returns (uint256 betId) {
        require(options.length >= MIN_OPTIONS && options.length <= MAX_OPTIONS, "Between 2 and 5 options");
        for (uint256 i = 0; i < options.length; i++) {
            require(bytes(options[i]).length > 0, "Option names required");
        }
        require(stake > 0, "Stake must be positive");
        require(durationSeconds > 0 && durationSeconds <= MAX_DURATION, "Invalid duration");

        betId = ++marketCount;
        Market storage m = markets[betId];
        m.bookie = msg.sender;
        for (uint256 i = 0; i < options.length; i++) {
            m.options.push(options[i]);
        }
        m.stake = stake;
        m.closeTime = block.timestamp + durationSeconds;

        emit BetCreated(betId, msg.sender, stake, m.closeTime);
    }

    function placeBet(uint256 betId, uint8 option) external payable exists(betId) {
        Market storage m = markets[betId];
        require(option >= 1 && option <= m.options.length, "Invalid option");
        require(!m.settled, "Bet already settled");
        require(block.timestamp < m.closeTime, "Betting closed");
        require(msg.value == m.stake, "Wrong stake amount");
        require(choices[betId][msg.sender] == 0, "Already bet");
        require(m.bettorCount < MAX_BETTORS, "Bet is full");

        choices[betId][msg.sender] = option;
        m.bettors[option].push(msg.sender);
        m.bettorCount++;

        emit BetPlaced(betId, msg.sender, option);
    }

    function resolve(uint256 betId, uint8 winner) external exists(betId) {
        Market storage m = markets[betId];
        require(msg.sender == m.bookie, "Only the bookie can resolve");
        require(!m.settled, "Bet already settled");
        require(block.timestamp >= m.closeTime, "Betting still open");
        require(winner >= 1 && winner <= m.options.length, "Invalid winner");

        m.settled = true;
        m.winner = winner;

        address[] storage winners = m.bettors[winner];
        uint256 count = winners.length;
        uint256 pool = m.stake * m.bettorCount;
        if (count == 0) {
            // nobody picked the winning option: the whole pool goes to the internal account
            if (pool > 0) {
                _pay(internalAccount, pool);
                emit InternalPayout(betId, internalAccount, pool);
            }
            emit BetResolved(betId, winner, 0, 0);
            return;
        }

        uint256 each = pool / count;
        uint256 remainder = pool - each * count;
        for (uint256 i = 0; i < count; i++) {
            bool paid = _pay(winners[i], each);
            emit Payout(betId, winners[i], each, paid);
        }
        if (remainder > 0) {
            _pay(internalAccount, remainder);
            emit InternalPayout(betId, internalAccount, remainder);
        }

        emit BetResolved(betId, winner, each, count);
    }

    /// Internal team only: refunds every bettor of a bet the bookie left unresolved for RESOLVE_DEADLINE.
    function refundExpired(uint256 betId) external exists(betId) {
        Market storage m = markets[betId];
        require(msg.sender == internalAccount, "Only the internal account can refund");
        require(!m.settled, "Bet already settled");
        require(block.timestamp >= m.closeTime + RESOLVE_DEADLINE, "Bookie still has time");

        m.settled = true;
        m.refunded = true;
        for (uint8 option = 1; option <= m.options.length; option++) {
            address[] storage bettors = m.bettors[option];
            for (uint256 i = 0; i < bettors.length; i++) {
                _pay(bettors[i], m.stake);
            }
        }

        emit BetRefunded(betId);
    }

    function withdraw() external {
        uint256 amount = owed[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        owed[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Withdraw failed");
    }

    // ----- views -----

    function getMarket(uint256 betId) external view exists(betId)
        returns (address bookie, string[] memory options, uint256 stake, uint256 closeTime)
    {
        Market storage m = markets[betId];
        return (m.bookie, m.options, m.stake, m.closeTime);
    }

    /// counts[i] = number of addresses that bet on option i + 1.
    function getState(uint256 betId) external view exists(betId)
        returns (uint8 state, uint8 winner, uint256[] memory counts)
    {
        Market storage m = markets[betId];
        counts = new uint256[](m.options.length);
        for (uint256 i = 0; i < counts.length; i++) {
            counts[i] = m.bettors[uint8(i + 1)].length;
        }
        return (uint8(_status(m)), m.winner, counts);
    }

    function choiceOf(uint256 betId, address bettor) external view exists(betId) returns (uint8) {
        return choices[betId][bettor];
    }

    // ----- internals -----

    function _status(Market storage m) private view returns (Status) {
        if (m.refunded) return Status.REFUNDED;
        if (m.settled) return Status.RESOLVED;
        if (block.timestamp >= m.closeTime) return Status.CLOSED;
        return Status.OPEN;
    }

    /// Returns false when the transfer failed; the amount is then kept in owed[to].
    function _pay(address to, uint256 amount) private returns (bool ok) {
        (ok, ) = to.call{value: amount, gas: PAY_GAS}("");
        if (!ok) {
            owed[to] += amount;
        }
    }
}
