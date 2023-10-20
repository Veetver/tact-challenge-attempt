import "@stdlib/deploy";

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) TokenTransfer {
     queryId: Int as uint64;
     amount: Int as coins;
     destination: Address;
     responseDestination: Address?;
     customPayload: Cell?;
     forwardTonAmount: Int as coins;
     forwardPayload: Slice as remaining;
}

contract Task3 with Deployable {
  owner: Address;
  aAmount: Int as uint64;
  bAmount: Int as uint64;
  jettonAddressA: Address;
  jettonAddressB: Address;

  init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
    self.owner = admin;
    self.jettonAddressA = newJettonAddressA;
    self.jettonAddressB = newJettonAddressB;
    self.aAmount = 0;
    self.bAmount = 0;
  }

  receive(msg: TokenNotification) {
    require((sender() == self.jettonAddressA) || (sender() == self.jettonAddressB), "unknown jetton");
    if (msg.from == self.owner) {
      if (sender() == self.jettonAddressA) {
        self.aAmount = self.aAmount + msg.amount;
      } else {
        self.bAmount = self.bAmount + msg.amount;
      }
    } 
    else {
      if (sender() == self.jettonAddressA) {
        let amountOfJettonBToSend: Int = (self.bAmount * 1000000000 / self.aAmount) * msg.amount / 1000000000;

        if (self.bAmount >= amountOfJettonBToSend) {
          send(SendParameters{
          to: self.jettonAddressB,
          value: 0,
          mode: SendRemainingValue,
          body: TokenTransfer {
            queryId: 0,
            amount: amountOfJettonBToSend,
            destination: msg.from,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: 10000000,
            forwardPayload: emptySlice()
            }.toCell()
          });
        self.bAmount = self.bAmount - amountOfJettonBToSend;
        self.aAmount = self.aAmount + msg.amount;

        } else {
          send(SendParameters{
            to: self.jettonAddressA,
            value: 0,
            mode: SendRemainingValue,
            body: TokenTransfer {
              queryId: 0,
              amount: msg.amount,
              destination: msg.from,
              responseDestination: myAddress(),
              customPayload: null,
              forwardTonAmount: 10000000,
              forwardPayload: emptySlice()
              }.toCell()
          });
        }
      } else {
        let amountOfJettonAToSend: Int = (self.aAmount * 1000000000 / self.bAmount) * msg.amount / 1000000000;
        if (self.aAmount >= amountOfJettonAToSend) {
          send(SendParameters{
          to: self.jettonAddressA,
          value: 0,
          mode: SendRemainingValue,
          body: TokenTransfer {
            queryId: 0,
            amount: amountOfJettonAToSend,
            destination: msg.from,
            responseDestination: myAddress(),
            customPayload: null,
            forwardTonAmount: 10000000,
            forwardPayload: emptySlice()
            }.toCell()
          });
          self.bAmount = self.bAmount + msg.amount;
          self.aAmount = self.aAmount - amountOfJettonAToSend;

        } else {
          send(SendParameters{
            to: self.jettonAddressB,
            value: 0,
            mode: SendRemainingValue,
            body: TokenTransfer {
              queryId: 0,
              amount: msg.amount,
              destination: msg.from,
              responseDestination: myAddress(),
              customPayload: null,
              forwardTonAmount: 10000000,
              forwardPayload: emptySlice()
              }.toCell()
          });
        }
      }
    }
  } 
  
  get fun price(jetton: Address): Int {
    if (jetton == self.jettonAddressA) {
      return self.bAmount * 1000000000 / self.aAmount;
    } else {
      return self.aAmount * 1000000000 / self.bAmount;
    }
  }
  
  get fun balance(jetton: Address): Int { 
    if (jetton == self.jettonAddressA) {
      return self.aAmount;
    } else {
      return self.bAmount;
    }
  }
}