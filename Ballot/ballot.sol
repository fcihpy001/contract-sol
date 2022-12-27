// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Ballot {
    // 选举人信息
    struct Voter {
        // 权重
        uint weight;
        // 是否投过票
        bool voted;
        // 委托人信息
        address delegate;
        // 投票的提案号
        uint vote;
    }

    // 提案信息
    struct Proposal {
        //提案名称
        bytes32 name;
        // 累计票数
        uint voteCount;
    }

    // 主席
    address public chairperson;
    // 投票信息
    mapping (address => Voter) public voters;
    // 提案的集合
    Proposal[] public proposals;

    // 构造函数，为每个提案名称创建一个投票池，生成提案的集合
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        for (uint i = 0; i < proposalNames.length; i ++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    // 对投票进行表决
    function giveRightToVote(address voter) public {
        require(msg.sender == chairperson, "Only charpeson can give right to vote");
        require(!voters[voter].voted, "The voter already voted");
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }
    // 把投票委托给某人
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You alread voted");
        require(to != msg.sender, "Self-delgation is disallowed.");
        while(voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        // 判断被委托者，是否已经投票
        if (delegate_.voted) {
            // 对提案号，增加投票数
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            //被委托者，还没投票，增加投票权利
            delegate_.weight += sender.weight;
        }
    }
    // 对提案号进行投票
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted");
        // 标记选民已经投过票
        sender.voted = true;
        sender.vote = proposal;
        // 对提案号的票数累加参与者的权重
        proposals[proposal].voteCount += sender.sender;
    }

    // 筛选投票数最多的提案
    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p ++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }
    // 根据提案索引获得提案的名称
    function winnerName() public view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name
    }
}