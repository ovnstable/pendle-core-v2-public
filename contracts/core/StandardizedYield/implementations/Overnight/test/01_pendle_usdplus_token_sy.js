const {deployProxy} = require("@overnight-contracts/common/utils/deployProxy");
const {ethers} = require("hardhat");

module.exports = async ({getNamedAccounts, deployments}) => {
    const {save} = deployments;

    const usdPlusAddress = '0x73cb180bf0521828d8849bc8CF2B920918e23032';
    const exchanredAddress = '0xe80772Eaf6e2E18B651F160Bc9158b2A5caFCA65';
    const baseAssetAddress = '0x7F5c764cBc14f9669B88837ca1490cCa17c31607';

    let pendleUsdPlusTokenSY = await deploy("PendleUsdPlusTokenSY", {
        from: deployer,
        args: ['Pendle USD+', 'USD+SY', usdPlusAddress, exchanredAddress, baseAssetAddress],
        log: true,
        skipIfAlreadyDeployed: false
    });

    console.log("PendleUsdPlusTokenSY created");
};

module.exports.tags = ['PendleUsdPlusTokenSY'];
