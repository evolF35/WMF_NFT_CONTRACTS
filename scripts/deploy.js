const { ethers } = require("hardhat");
const hre = require("hardhat");
require("@nomiclabs/hardhat-web3");

async function main() {

    const contractAddress = '0x7a05Fe195A30d1A72fFaA3F28bF14E33794236da'; // Replace with the actual address of the deployed contract

    const Lock = await hre.ethers.getContractFactory("WMF_NFT4");
    // Create an instance of the deployed contract
    const lockInstance = await Lock.attach(contractAddress);

    const uri = 'https://bafybeidbyvjkqm5biyeymlihgdmqufkz4n3igue4stenn3fvel6e5xsqxy.ipfs.nftstorage.link/?filename=AFRICANCLASSICAL.png1';
    const tokenUris = Array(50).fill(uri);
    // Call the `setTokenUris` function with the generated array

      const tx = await lockInstance.setTokenUris(tokenUris);
      const receipt = await tx.wait();
      console.log('Transaction successful:', receipt.transactionHash);
  
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

