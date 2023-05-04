const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

import UsdcABI from "./usdcABI";

describe("NFT contract", function () {
    const assetUrl = '';
    const tokenAmount = 1000;
    const swapRouterAddress = '0xE592427A0AEce92De3Edee1F18E0157C05861564';
    const USDCAddress = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;'
    const ERC20TokensFixture = async () => {
        const initialSupply = 1000000;
        const Token_1 = await ethers.getContractFactory("Token_1");
        const Token_2 = await ethers.getContractFactory("Token_2");
        const Token_3 = await ethers.getContractFactory("Token_3");


        const token_1 = await Token_1.deploy(initialSupply);
        const token_2 = await Token_2.deploy(initialSupply);
        const token_3 = await Token_3.deploy(initialSupply);

        await token_1.deployed();
        await token_1.deployed();
        await token_1.deployed();

        return { tokens: [token_1, token_2, token_3], initialSupply };
    }

    const NFTDeployFixture = async () => {
        const { tokens, ...rest } = await loadFixture(ERC20TokensFixture);

        const NFT = await ethers.getContractFactory('NFT');

        const nft = await NFT.deploy(swapRouterAddress, tokens.map(({ address }: any) => address));

        await nft.deployed();

        return { nft, tokens, ...rest };
    }

    it("Deployment ERC20 tokens should assign owner all initial supply", async function () {
        const [owner] = await ethers.getSigners();
        const { tokens: [token_1, token_2, token_3], initialSupply } = await loadFixture(ERC20TokensFixture)


        expect(await token_1.balanceOf(owner.address)).to.equal(initialSupply);
        expect(await token_2.balanceOf(owner.address)).to.equal(initialSupply);
        expect(await token_3.balanceOf(owner.address)).to.equal(initialSupply);
    });

    it("Should create NFT and spend tokens", async function () {
        const [owner] = await ethers.getSigners();
        const { nft, tokens: [t1], initialSupply } = await loadFixture(NFTDeployFixture);

        await t1.approve(nft.address, tokenAmount);
        await nft.mint([t1.address], [tokenAmount], assetUrl);

        expect((await nft.holders(1)).flag).to.equal(true);
        expect((await t1.balanceOf(owner.address)).toNumber()).to.equal(initialSupply - tokenAmount);
    });

    it("Should burn NFT and return tokens without fee", async function () {
        const [owner] = await ethers.getSigners();
        const { nft, tokens: [t1], initialSupply } = await loadFixture(NFTDeployFixture);

        await t1.approve(nft.address, tokenAmount);

        await nft.mint([t1.address], [tokenAmount], assetUrl);

        expect((await nft.holders(1)).flag).to.equal(true);
        expect((await t1.balanceOf(owner.address)).toNumber()).to.equal(initialSupply - tokenAmount);

        await nft.burn(1);

        expect((await nft.holders(1)).flag).to.equal(false);
        expect((await t1.balanceOf(owner.address)).toNumber()).to.equal(initialSupply - ((tokenAmount / 100) * 0.5));
    })
});