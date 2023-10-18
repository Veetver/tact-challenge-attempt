import "@stdlib/deploy";

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining; 
}

message(0x5fcc3d14) Transfer { 
    queryId: Int as uint64;            
    newOwner: Address; 
    responseDestination: Address; 
    customPayload: Cell?; 
    forwardAmount: Int as coins; 
    forwardPayload: Slice as remaining; 
}

message NftWithdrawal {
  queryId: Int as uint64;
  nftAddress: Address;
}

contract Task4 with Deployable {
  seed: Int as uint128;
  owner: Address? = null;
  nft: Address? = null;
  lockedTill: Int = 0;
  
  init(seed: Int) {
    self.seed = seed;
  }

  receive(msg: OwnershipAssigned) {
    if (self.nft == null) {
      self.nft = sender();
      self.owner = msg.prevOwner;
      self.lockedTill = now() + msg.forwardPayload.loadUint(32);
    } else {
      send(SendParameters{
        to: sender(),
        value: 0,
        mode: SendRemainingValue,
        body: Transfer {
          queryId: msg.queryId, 
          newOwner: msg.prevOwner,
          responseDestination: msg.prevOwner, 
          customPayload: null, 
          forwardAmount: 0, 
          forwardPayload: emptySlice() 
        }.toCell()
      });
    }
  }

  receive(msg: NftWithdrawal) {
    require(sender() == self.owner, "Invalid sender");
    if (now() >= self.lockedTill) {
      self.nft = null;
      self.owner = null;
      self.lockedTill = 0; 

      send(SendParameters{
        to: msg.nftAddress,
        value: 0,
        mode: SendRemainingValue,
        body: Transfer {
          queryId: msg.queryId,
          newOwner: sender(),
          responseDestination: sender(), 
          customPayload: null, 
          forwardAmount: 0, 
          forwardPayload: emptySlice() 
        }.toCell()
      });

      send(SendParameters{
            to: sender(),
            bounce: true,
            value: 0,
            mode: SendRemainingBalance + SendIgnoreErrors
      });
    } else {
      self.reply("NFT is still locked".asComment());
    }
  }

  get fun time(): Int {
    return self.lockedTill - now();
  }

  get fun nft(): Address? {
    return self.nft;
  }

  get fun owner(): Address? {
    return self.owner;
  }
}
