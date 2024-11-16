# RWA Vault #

## Table of Contents
* [About](#about)
* [Frameworks and Tooling](#frameworks-and-tooling)
* [Repository Description](#repository-description)
* [Installation](#installation)
* [Configuration](#configuration)
* [Alternative Configuration: Using Private Keys instead of Mnemonics, and Alchemy instead of Infura](#alternative-configuration-using-private-keys-instead-of-mnemonics-and-alchemy-instead-of-infura)
* [Using Custom JSON-RPC Endpoint URL](#using-custom-json-rpc-endpoint-url)
* [Testing](#testing)
* [Test Coverage](#test-coverage)
* [Deployment](#deployment)
* [Address List](#address-list)

## About
Click [here](https://docs.google.com/document/d/17iDNe-t-ldUvwN2ELs6Rt5qYJghoa4KLTssKDb_1PzU/edit?usp=sharing) to read project description.

## Frameworks and Tooling
The project is built using
* [Hardhat](https://hardhat.org/), a popular Ethereum development environment
    * Why not standalone [Truffle](https://www.trufflesuite.com/truffle)?
        * Truffle runs the tests several times slower than Hardhat
        * Truffle + [ganache](https://trufflesuite.com/ganache/) fails to run big test suites,
        presumably it fails to close socket connections gracefully and causes open sockets overflow
    * Why not [Foundry](https://github.com/foundry-rs/foundry)?
        * Foundry forces the tests to be written in Solidity, which complicates
            * porting the existing tests from myriad of projects using JavaScript for tests,
            * getting help from the vast community of [Node.js](https://nodejs.org/en) developers in writing tests
* [Web3.js](https://web3js.readthedocs.io/), a collection of libraries that allows interacting with
local or remote Ethereum node using HTTP, IPC or WebSocket
* [Truffle](https://www.trufflesuite.com/truffle) as a Hardhat module (plugin)

Smart contracts deployment is configured to use [Infura](https://infura.io/) or [Alchemy](https://www.alchemy.com/)
and [HD Wallet](https://www.npmjs.com/package/@truffle/hdwallet-provider)

## Installation ##

Following steps were tested to work in macOS Catalina

1. Install [Node Version Manager (nvm)](https://github.com/nvm-sh/nvm) – latest  
    ```brew install nvm```
2. Install [Node package manager (npm)](https://www.npmjs.com/) and [Node.js](https://nodejs.org/) – version 16.20.0+  
    ```nvm install 16```
3. Activate node version installed  
    ```nvm use 16```
4. Install project dependencies  
    ```npm install```

### Notes on Ubuntu 20.04 LTS ###
- [How to install Node.js 16 on Ubuntu 20.04 LTS](https://joshtronic.com/2021/05/09/how-to-install-nodejs-16-on-ubuntu-2004-lts/)
- [How to Run Linux Commands in Background](https://linuxize.com/post/how-to-run-linux-commands-in-background/)

## Configuration ##
1.  Create or import 12-word mnemonics for
    1. Mainnet
    2. Mantle
    3. Linea
    4. Unichain
    5. Zircuit
    6. Morph

    You can use MetaMask to create mnemonics: https://metamask.io/

    > Note: you can use same mnemonic for test networks.
    Always use a separate one for mainnet, keep it secure.

    > Note: you can add more configurations to connect to the networks not listed above.
    Check and add configurations required into the [hardhat.config.js](hardhat.config.js).

    > Note: you can use private keys instead of mnemonics (see Alternative Configuration section below)

2.  Create an infura access key at https://infura.io/

    Note: you can use alchemy API key instead of infura access key (see Alternative Configuration section below)

3.  Create etherscan API key at https://etherscan.io/

4.  Export mnemonics, infura access key, and etherscan API key as system environment variables
    (they should be available for hardhat):

    | Name                 | Value                        |
    |----------------------|------------------------------|
    | MNEMONIC1            | Mainnet mnemonic             |
    | MNEMONIC5003         | Mantle testnet mnemonic      |
    | MNEMONIC59141        | Linea testnet mnemonic       |
    | MNEMONIC1301         | Unichain testnet mnemonic    |
    | MNEMONIC48899        | Zircuit testnet mnemonic     |
    | MNEMONIC2810         | Morph testnet mnemonic       |
    | INFURA_KEY           | Infura access key            |
    | ETHERSCAN_KEY        | Etherscan API key            |
    | ARBISCAN_KEY         | arbiscan API key             |
    
> Note:  
Read [How do I set an environment variable?](https://www.schrodinger.com/kb/1842) article for more info on how to
set up environment variables in Linux, Windows and macOS.

### Example Script: macOS Catalina ###
```
export MNEMONIC1="witch collapse practice feed shame open despair creek road again ice least"
export MNEMONIC5003="someone relief rubber remove donkey jazz segment nose spray century put beach"
export MNEMONIC59141="slush oyster cash hotel choice universe puzzle slot reflect sword intact fat"
export MNEMONIC1301="result mom hard lend adapt where result mule address ivory excuse embody"
export INFURA_KEY="000ba27dfb1b3663aadfc74c3ab092ae"
export ETHERSCAN_KEY="9GEEN6VPKUR7O6ZFBJEKCWSK49YGMPUBBG"
export ARBISCAN_KEY="VF9IZLVDRA03VE3K5S46EADMW6VNV0V73U"
```

## Alternative Configuration: Using Private Keys instead of Mnemonics, and Alchemy instead of Infura ##
Alternatively to using mnemonics, private keys can be used instead.
When both mnemonics and private keys are set in the environment variables, private keys are used.

Similarly, alchemy can be used instead of infura.
If both infura and alchemy keys are set, alchemy is used.

1.  Create or import private keys of the accounts for
    1. Mainnet
    2. Mantle
    3. Linea
    4. Unichain
    5. Zircuit
    6. Morph

    You can use MetaMask to export private keys: https://metamask.io/

2.  Create an alchemy API key at https://alchemy.com/

3.  Create etherscan API key at https://etherscan.io/

4.  Export private keys, infura access key, and etherscan API key as system environment variables
    (they should be available for hardhat):

    | Name          | Value                         |
    |---------------|-------------------------------|
    | P_KEY1        | Mainnet private key           |
    | P_KEY5003     | Mantle testnet private key    |
    | P_KEY59141    | Linea testnet private key     |
    | P_KEY1301     | Unichain testnet private key  |
    | P_KEY48899    | Zircuit testnet private key   |
    | P_KEY2810     | Morph testnet private key     |
    | ALCHEMY_KEY   | Alchemy API key               |
    | ETHERSCAN_KEY | Etherscan API key             |
    | ARBISCAN_KEY  | arbiscan API key              |
    
> Note: private keys should start with ```0x```

### Example Script: macOS Catalina ###
```
export P_KEY1="0x5ed21858f273023c7fc0683a1e853ec38636553203e531a79d677cb39b3d85ad"
export P_KEY5003="0xfb84b845b8ea672939f5f6c9a43b2ae53b3ee5eb8480a4bfc5ceeefa459bf20c"
export P_KEY59141="0x5ed21858f273023c7fc0683a1e853ec38636553203e531a79d677cb39b3d85ad"
export P_KEY1301="0xfb84b845b8ea672939f5f6c9a43b2ae53b3ee5eb8480a4bfc5ceeefa459bf20c"
export ALCHEMY_KEY="hLe1XqWAUlvmlW42Ka5fdgbpb97ENsMJ"
export ETHERSCAN_KEY="9GEEN6VPKUR7O6ZFBJEKCWSK49YGMPUBBG"
export ARBISCAN_KEY="VF9IZLVDRA03VE3K5S46EADMW6VNV0V73U"
```

## Using Custom JSON-RPC Endpoint URL ##
To use custom JSON-RPC endpoint instead of infura/alchemy public endpoints, set the corresponding RPC URL as
an environment variable:

| Name                | Value                                   |
|---------------------|-----------------------------------------|
| MAINNET_RPC_URL     | Mainnet JSON-RPC endpoint URL           |
| MANTLE_RPC_URL      | Mantle testnet JSON-RPC endpoint URL    |
| LINEA_RPC_URL       | Linea testnet JSON-RPC endpoint URL     |
| UNICHAIN_RPC_URL    | Unichain testnet JSON-RPC endpoint URL  |
| ZIRCUIT_RPC_URL     | Zircuit testnet JSON-RPC endpoint URL   |
| MORPH_RPC_URL       | Morph testnet JSON-RPC endpoint URL     |

## Compilation ##
Execute ```npx hardhat compile``` command to compile smart contracts.

Compilation settings are defined in [hardhat.config.js](./hardhat.config.js) ```solidity``` section.

Note: Solidity files *.sol use strict compiler version, you need to change all the headers when upgrading the
compiler to another version 

## Testing ##
Smart contract tests are built with Truffle – in JavaScript (ES6) and [web3.js](https://web3js.readthedocs.io/)

The tests are located in [test](./test) folder. 
They can be run with built-in [Hardhat Network](https://hardhat.org/hardhat-network/).

Run ```npx hardhat test``` to run all the tests or ```.npx hardhat test <test_file>``` to run individual test file.

## Test Coverage ##
Smart contracts test coverage is powered by [solidity-coverage] plugin.

Run `npx hardhat coverage` to run test coverage and generate the report.

## Deployment ##
Deployments are implemented via [hardhat-deploy plugin](https://github.com/wighawag/hardhat-deploy) by Ronan Sandford.

Deployment scripts perform smart contracts deployment itself and their setup configuration.
Executing a script may require several transactions to complete, which may fail. To help troubleshoot
partially finished deployment, the scripts are designed to be rerunnable and execute only the transactions
which were not executed in previous run(s).

Deployment scripts are located under [deploy](./deploy) folder.
Deployment execution state is saved under [deployments](./deployments) folder.

To run fresh deployment (<NETWORK_NAME>):

1. Delete [deployments/<NETWORK_NAME>](./deployments/<NETWORK_NAME>) folder contents.

2. Run the deployment of interest with the ```npx hardhat <TAG>``` command
    ```
    npx hardhat deploy --network <NETWORK_NAME> --tags <TAG>
    ```
    where ```<TAG>``` specifies the deployment script(s) tag to run,
    and ```--network <NETWORK_NAME>``` specifies the network to run script for
    (see [hardhat.config.js](./hardhat.config.js) for network definitions).

3. Verify source code on Etherscan with the ```npx hardhat etherscan-verify``` command
    ```
    npx hardhat etherscan-verify --network <network_name> --api-key $ETHERSCAN_KEY
    ```

To rerun the deployment script and continue partially completed script skip the first step
(do not cleanup the [deployments](./deployments) folder).

## Address List ##
The RWA smart contracts has been deployed to following testnets:

1. Mantle Sepolia
   * RWA Vault: [0x9004AFffF01e0c812BbCd062344D6d858b799B35](https://sepolia.mantlescan.xyz/address/0x9004AFffF01e0c812BbCd062344D6d858b799B35#code)
   * RWA Leverage: [0x0467D7C3c14E076D4bC412863A1edD3525D60015](https://sepolia.mantlescan.xyz/address/0x0467D7C3c14E076D4bC412863A1edD3525D60015#code)

2. Linea Sepolia
   * RWA Vault: [0x0467D7C3c14E076D4bC412863A1edD3525D60015](https://sepolia.lineascan.build/address/0x0467D7C3c14E076D4bC412863A1edD3525D60015#code)       
   * RWA Leverage: [0x3Ab503f2f8b9Cf3181fAddCBF79ad9B108D2947c](https://sepolia.lineascan.build/address/0x3Ab503f2f8b9Cf3181fAddCBF79ad9B108D2947c#code)

3. Unichain Sepolia
   * RWA Vault: [0x9004AFffF01e0c812BbCd062344D6d858b799B35](https://unichain-sepolia.blockscout.com/address/0x9004AFffF01e0c812BbCd062344D6d858b799B35?tab=contract)          
   * RWA Leverage: [0x0467D7C3c14E076D4bC412863A1edD3525D60015](https://unichain-sepolia.blockscout.com/address/0x0467D7C3c14E076D4bC412863A1edD3525D60015?tab=contract)

4. Zircuit Testnet
   * RWA Vault: [0x9004AFffF01e0c812BbCd062344D6d858b799B35](https://explorer.testnet.zircuit.com/address/0x9004AFffF01e0c812BbCd062344D6d858b799B35)         
   * RWA Leverage: [0x0467D7C3c14E076D4bC412863A1edD3525D60015](https://explorer.testnet.zircuit.com/address/0x0467D7C3c14E076D4bC412863A1edD3525D60015)

5. Morph Holesky
   * RWA Vault: [0x9004AFffF01e0c812BbCd062344D6d858b799B35](https://explorer-holesky.morphl2.io/address/0x9004AFffF01e0c812BbCd062344D6d858b799B35)          
   * RWA Leverage: [0x0467D7C3c14E076D4bC412863A1edD3525D60015](https://explorer-holesky.morphl2.io/address/0x0467D7C3c14E076D4bC412863A1edD3525D60015)

