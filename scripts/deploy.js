const { ethers } = require("hardhat");
const hre = require("hardhat");
require("@nomiclabs/hardhat-web3");

async function main() {

    const Lock = await hre.ethers.getContractFactory("WMF_NFT");
    const lock = await Lock.deploy("1","1","0x10328D18901bE2278f8105D9ED8a2DbdE08e709f");    

    await lock.deployed();

    console.log(
      `deployed to ${lock.address}`
      );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

