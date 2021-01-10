const GuessGame = artifacts.require("GuessGame");
const Web3 = require('web3');
var numberA, numberB

contract('GuessGame', (accounts) => {
  it('accountA deposit 2 eth', async () => {
    const accountA = accounts[0];
    const guessGameInstance = await GuessGame.deployed();
    await guessGameInstance.deposite({ from: accountA, value: web3.utils.toWei('2', 'ether') });
    const balance = await guessGameInstance.balance.call(accountA)

    assert.equal(balance.valueOf(), web3.utils.toWei('2', 'ether'), "deposit amount error");
  });

  it('accountB deposit 3 eth', async () => {
    const accountB = accounts[1];
    const guessGameInstance = await GuessGame.deployed();
    await guessGameInstance.deposite({ from: accountB, value: web3.utils.toWei('3', 'ether') });
    const balance = await guessGameInstance.balance.call(accountB)

    assert.equal(balance.valueOf(), web3.utils.toWei('3', 'ether'), "deposit amount error");
  });

  it('Player A creates a game with a wager amount of 0.5 ETH', async () => {
    const accountA = accounts[0];
    const guessGameInstance = await GuessGame.deployed();

    const wagerAmount = web3.utils.toWei('0.5', 'ether');
    numberA = Math.ceil(Math.random() * 10);
    console.log('    player A input number---' + numberA);
    const numberHash = web3.utils.sha3(web3.eth.abi.encodeParameter('uint256', numberA + ''));
    const uint256Str = web3.utils.toBN(numberHash).toString();

    const result = await guessGameInstance.createGame(wagerAmount, uint256Str, { from: accountA });

    assert.equal(result.receipt.status, true, "create game success");
  });

  it('Player B joined', async () => {
    const accountB = accounts[1];
    const guessGameInstance = await GuessGame.deployed();

    numberB = Math.ceil(Math.random() * 10);
    console.log('    player B input number---' + numberB);
    const numberHash = web3.utils.sha3(web3.eth.abi.encodeParameter('uint256', numberB + ''));
    const uint256Str = web3.utils.toBN(numberHash).toString();

    const result = await guessGameInstance.joinGame(uint256Str, { from: accountB });

    assert.equal(result.receipt.status, true, "joined game success");
  });

  it('Player A revealing', async () => {
    const accountA = accounts[0];
    const guessGameInstance = await GuessGame.deployed();
    const result = await guessGameInstance.revealNumber('1', numberA, { from: accountA });

    assert.equal(result.receipt.status, true, "revealing game success");
  });

  it('Player B revealing', async () => {
    const accountB = accounts[1];
    const guessGameInstance = await GuessGame.deployed();
    const result = await guessGameInstance.revealNumber('1', numberB, { from: accountB });
    // console.log(result.logs[0].args)
    const event = result.logs[0].args
    const winner = event.winner === accountB ? 'B' : 'A'
    console.log('    the winner is ' + winner)
    const winAmount = event.amount
    assert.equal(winAmount.valueOf(), web3.utils.toWei('1', 'ether'), "award amount right");

  });


});
