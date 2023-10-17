import "@stdlib/deploy";

/*
  TASK 4 - NFT locker
  Implement a smart contract that will lock NFT for a period of time specified by the owner.
  Smart conrtact should contain logic to process following messages and getters: 

  Messages: 
  * OwnershipAssigned
   - Recives nft + time (in a forwardPayload message as uint32) for which this nft will be locked + address of the sender of the nft (prevOwner).
   - If the smart contract already holds an nft then return the incoming nft back to the sender
  * NftWithdrawal
   - Request withdrawal of the locked nft
   - If sender is not the owner (that came from OwnershipAssigned as prevOwner address) then throw "Invalid sender" 
   - If time has not passed then send message back to the sender with the comment "NFT is still locked" according to the TON's "message with text comment" standard 
   - Otherwise (all good) send the locked nft back to the owner with all the remaining TON balance
   Note that the order of checks is important
   (in case: "sender is not the owner" and "time has not passed" at the same time, "Invalid sender" error takes priority)

  Getters:
  * time
   - get how much lock time is left
  * nft
   - get the address of the locked nft 
  * owner
   - get the owner of the locked nft (that came from OwnershipAssigned as prevOwner)
*/

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
  // Текущий владелец nft
  owner: Address? = null;
  // Текущий nft
  nft: Address? = null;
  // Заблокировано до
  lockedTill: Int = 0;

  
  init(seed: Int) {
    self.seed = seed; // needed to deploy multiple smart contracts copies from one admin address
  }

  receive(msg: OwnershipAssigned) {
    // Проверяем есть ли в Task4 nft?
    if (self.nft == null) {
      // nft нет, добавляем. Присваиваем nft
      self.nft = sender();
      // Присваиваем владельца
      self.owner = msg.prevOwner;
      // Заблокировано до
      self.lockedTill = now() + msg.forwardPayload.loadUint(32);
    } else {
      // nft есть, нужно отправить обратно nft
      send(SendParameters{
        to: sender(),
        value: 0,
        mode: SendRemainingValue,
        body: Transfer {
          queryId: 0, 
          newOwner: msg.prevOwner,
          responseDestination: myAddress(), 
          customPayload: null, 
          forwardAmount: ton("0.01"), 
          forwardPayload: emptySlice() 
        }.toCell()
      });
    }
  }

  // Вывод nft
  receive(msg: NftWithdrawal) {
    // Проверяем, является ли sender() владельцем nft?
    require(sender() == self.owner, "Invalid sender");

    // Проверяем, заблокирован ли nft?
    if (now() < self.lockedTill) {
      // nft заблокирован, отправляем коммент
      self.reply("NFT is still locked".asComment());
    } else {

      // ТУТ ГДЕ_ТО ОШИБКА
      // nft не заблокирован, отправляем nft
      send(SendParameters{
        to: msg.nftAddress,
        value: 0,
        mode: SendRemainingValue,
        body: Transfer {
          queryId: 0, 
          newOwner: sender(),
          responseDestination: myAddress(), 
          customPayload: null, 
          forwardAmount: ton("0.01"), 
          forwardPayload: emptySlice() 
        }.toCell()
      });
      self.reply("return remaining TON balance".asComment());

      // обнуляем Task4
      self.nft = null;
      self.owner = null;
      self.lockedTill = 0;
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
