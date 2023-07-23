// for testing framework we are using mocha which running on nodejs
// we will use waffle and chai assertion libs to compare return values with expected value
// mocha and waffle need not be imported because hardhat injects it automatically in testing
const { expect } = require("chai");

const toWei = (num) => ethers.utils.parseEther(num.toString());
const fromWei = (num) => ethers.utils.formatEther(num);

describe("MusicNFTMarketplace", function () {
  let nftMarketplace;
  let deployer, artist, user1, user2, users;
  let royaltyFee = toWei(0.01); // 1 ether = 10^18 wei
  let URI =
    "https://bafybeidhjjbjonyqcahuzlpt7sznmh4xrlbspa3gstop5o47l6gsiaffee.ipfs.nftstorage.link/";
  let prices = [
    toWei(1),
    toWei(2),
    toWei(3),
    toWei(4),
    toWei(5),
    toWei(6),
    toWei(7),
    toWei(8),
  ];
  let deploymentFees = toWei(prices.length * 0.01);
  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    const NFTMarketplaceFactory = await ethers.getContractFactory(
      "MusicNFTMarketplace"
    );
    [deployer, artist, user1, user2, ...users] = await ethers.getSigners();

    // Deploy music nft marketplace contract
    nftMarketplace = await NFTMarketplaceFactory.deploy(
      royaltyFee,
      artist.address,
      prices,
      { value: deploymentFees }
    );
  });

  describe("Deployment", function () {
    it("Should track name, symbol, URI, royalty fee and artist", async function () {
      const nftName = "ShrodyBuck";
      const nftSymbol = "Shrody";
      expect(await nftMarketplace.name()).to.equal(nftName);
      expect(await nftMarketplace.symbol()).to.equal(nftSymbol);
      expect(await nftMarketplace.baseURI()).to.equal(URI);
      expect(await nftMarketplace.royaltyFee()).to.equal(royaltyFee);
      expect(await nftMarketplace.artist()).to.equal(artist.address);
    });

    it("Should mint then list all the music nfts", async function () {
      expect(await nftMarketplace.balanceOf(nftMarketplace.address)).to.equal(
        8
      );
      // Get each item from the marketItems array then check fields to ensure they are correct
      await Promise.all(
        prices.map(async (i, indx) => {
          const item = await nftMarketplace.marketItems(indx);
          expect(item.tokenId).to.equal(indx);
          expect(item.seller).to.equal(deployer.address);
          expect(item.price).to.equal(i);
        })
      );
    });
    it("Ether balance should equal deployment fees", async function () {
      expect(await ethers.provider.getBalance(nftMarketplace.address)).to.equal(
        deploymentFees
      );
    });
  });
  describe("Updating royalty fee", function () {
    it("Only deployer should be able to update royalty fee", async function () {
      const fee = toWei(0.02);
      await nftMarketplace.updateRoyaltyFee(fee);
      await expect(
        nftMarketplace.connect(user1).updateRoyaltyFee(fee)
      ).to.be.revertedWith("Ownable: caller is not the owner");
      expect(await nftMarketplace.royaltyFee()).to.equal(fee);
    });
  });
});
