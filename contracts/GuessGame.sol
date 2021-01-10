// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./SafeMath.sol";

contract GuessGame {
    using SafeMath for uint256;
    mapping(address => uint256) public balance;
    mapping(address => uint256) public gameFreezen;

    struct Game {
        uint8 state;
        uint256 inputHashA;
        uint256 inputHashB;
        uint256 originInputA;
        uint256 originInputB;
        uint256 wagerAmount;
        address payable addressA;
        address payable addressB;
        address winner;
    }

    Game[] games;

    uint256 public lastIndex = 0;

    event GameCreate(address indexed creator, uint256 wagerAmount);
    event JoinGame(uint256 gameIndex, address indexed joiner);
    event ReavelGame(address indexed winner, uint256 amount, uint256 gameIndex);

    function deposite() public payable {
        balance[msg.sender] = balance[msg.sender].add(msg.value);
    }

    function createGame(uint256 wagerAmount, uint256 numberHash) public {
        require(balance[msg.sender] >= wagerAmount, "balance is not enough");
        balance[msg.sender] = balance[msg.sender].sub(wagerAmount);
        gameFreezen[msg.sender] = gameFreezen[msg.sender].add(wagerAmount);
        Game memory game =
            Game(
                0,
                numberHash,
                0,
                0,
                0,
                wagerAmount,
                msg.sender,
                address(0),
                address(0)
            );
        lastIndex = games.push(game);
        emit GameCreate(msg.sender, wagerAmount);
    }

    function joinGame(uint256 numberHash) public {
        require(lastIndex > 0, "no game created");
        Game storage game = games[lastIndex - 1];
        require(game.addressA != msg.sender, "you can not join yourself");
        require(game.state == 0, "game state error");
        require(
            balance[msg.sender] >= game.wagerAmount,
            "deposit is not enough"
        );
        balance[msg.sender] = balance[msg.sender].sub(game.wagerAmount);
        gameFreezen[msg.sender] = gameFreezen[msg.sender].add(game.wagerAmount);
        game.addressB = msg.sender;
        game.inputHashB = numberHash;
        game.state = 1;
        emit JoinGame(lastIndex, msg.sender);
    }

    function revealNumber(uint256 index, uint256 number) public {
        require(index > 0, "index invalid");
        Game storage game = games[index - 1];
        require(game.state == 1, "game state error");
        require(
            msg.sender == game.addressA || msg.sender == game.addressB,
            "invalid address"
        );

        if (msg.sender == game.addressA) {
            //A reveal
            require(game.originInputA == 0, "A already have reveal");
            require(
                game.inputHashA == uint256(keccak256(abi.encodePacked(number))),
                "number check failed"
            );
            game.originInputA = number;
            if (game.originInputB != 0) {
                // B already reveal
                awardWinner(index - 1);
            }
        } else if (msg.sender == game.addressB) {
            //B reveal
            require(game.originInputB == 0, "B already have reveal");
            require(
                game.inputHashB == uint256(keccak256(abi.encodePacked(number))),
                "number check failed"
            );
            game.originInputB = number;
            if (game.originInputA != 0) {
                // A already reveal
                awardWinner(index - 1);
            }
        }
    }

    function awardWinner(uint256 gameIndex) private {
        Game storage game = games[gameIndex];
        address payable winner =
            uint256(
                keccak256(
                    abi.encodePacked(game.originInputA, game.originInputB)
                )
            ) > 2**255 - 1
                ? game.addressA
                : game.addressB;
        gameFreezen[game.addressA] = gameFreezen[game.addressA].sub(
            game.wagerAmount
        );
        gameFreezen[game.addressB] = gameFreezen[game.addressB].sub(
            game.wagerAmount
        );
        uint256 value = game.wagerAmount.mul(2);
        winner.transfer(value);
        game.state = 2;
        emit ReavelGame(winner, value, gameIndex);
    }
}
