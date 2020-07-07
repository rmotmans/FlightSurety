var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "morning nice random knock quiz joke virus camp wrestle embody priority forest";

module.exports = {
  networks: {
    development: {
      network_id: '*',
      // gas: 9999999
      host: '127.0.0.1',
      port: 7545
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};
