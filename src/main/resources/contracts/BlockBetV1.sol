// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract BlockBetV1{

    address private bookie;
    uint public matchId;
    bool private isDone;

    uint private result1;
    uint private result2;

    address[] private listBet1;
    address[] private listBet2;
    address[] private listBet3;

    enum Choice {
        TEAM1,
        TEAM2,
        DRAW
    }

    modifier onlyBookie(){
        require(msg.sender == bookie, "Only bookie allowed");
        _;
    }


    modifier noBookie(){
        require(msg.sender != bookie, "No bookie allowed");
        _;
    }

    constructor(uint _matchId) {
        matchId = _matchId;
        isDone = false;
        result1 = 0;
        result2 = 0;
        bookie = msg.sender;
    }


    function bet(Choice _choice) public noBookie() {

        if (_choice == Choice.TEAM1) {
            listBet1.push(msg.sender);
        } else if (_choice == Choice.TEAM2) {
            listBet2.push(msg.sender);
        } else {
            listBet3.push(msg.sender);
        }
    }


    function updateResult(uint r1, uint r2) public onlyBookie() {

        //update new result
        result1 = r1;
        result2 = r2;

        //update bettor's tokens
        // for (uint i=1; i <= countBettor; i++){
        //     if (bettorList[i].hasBetted[m_id] == true){
        //         uint g1 = bettorList[i].goal1[m_id];
        //         uint g2 = bettorList[i].goal2[m_id];
                
        //         bettorList[i].tokenAmount -= bettorList[i].winAmount[m_id];
        //         bettorList[i].winAmount[m_id] = 0;

        //         if (r1 > r2){
        //             if (g1 > g2){
        //                 bettorList[i].winAmount[m_id] = bettorList[i].betAmount[m_id] * matchList[m_id].weightBet1;
        //             }
        //             if (g1 == r1 && g2 == r2){
        //                 bettorList[i].winAmount[m_id] = bettorList[i].betAmount[m_id] * matchList[m_id].weightBet2;
        //             }
        //         }
        //         else if (r1 < r2){
        //             if (g1 < g2){
        //                 bettorList[i].winAmount[m_id] = bettorList[i].betAmount[m_id] * matchList[m_id].weightBet1;
        //             }
        //             if (g1 == r1 && g2 == r2){
        //                 bettorList[i].winAmount[m_id] = bettorList[i].betAmount[m_id] * matchList[m_id].weightBet2;
        //             }
        //         }
        //         else if (r1 == r2){
        //             if (g1 == g2){
        //                 bettorList[i].winAmount[m_id] = bettorList[i].betAmount[m_id] * matchList[m_id].weightBet1;
        //             }
        //             if (g1 == r1 && g2 == r2){
        //                 bettorList[i].winAmount[m_id] = bettorList[i].betAmount[m_id] * matchList[m_id].weightBet2;
        //             }
        //         }
                
        //         bettorList[i].tokenAmount += bettorList[i].winAmount[m_id];
                
        //     }
        // }

        isDone = true;
    }


    function getBookieAddress() public view returns (address bookie_address){
        bookie_address = bookie;
    }

    function getBettorCount() public view returns (uint returned_count_bet){
        returned_count_bet = listBet1.length + listBet2.length + listBet3.length;
    }

    function getMatchInfo() public view returns (
        uint reid,
        bool reIsDone,
        uint reresult1,
        uint reresult2,
        uint recountBet1,
        uint recountBet2,
        uint recountBet3){
        
        reid = matchId;
        reIsDone = isDone;
        reresult1 = result1;
        reresult2 = result2;
        recountBet1 = listBet1.length;
        recountBet2 = listBet2.length;
        recountBet3 = listBet3.length;
    }
}






