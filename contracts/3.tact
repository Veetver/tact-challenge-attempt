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
  aAmount: Int;
  bAmount: Int;
  jettonAddressA: Address;
  jettonAddressB: Address;
  decimal: Int;

  init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
    self.owner = admin;
    self.jettonAddressA = newJettonAddressA;
    self.jettonAddressB = newJettonAddressB;
    self.aAmount = 0;
    self.bAmount = 0;
    self.decimal = 1000000000;
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
        let amountOfJettonBToSend: Int = (self.bAmount * self.decimal / self.aAmount) * msg.amount / self.decimal;

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
            forwardTonAmount: ton("0.01"),
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
              forwardTonAmount: ton("0.01"),
              forwardPayload: emptySlice()
              }.toCell()
          });
        }
      } else {
        let amountOfJettonAToSend: Int = (self.aAmount * self.decimal / self.bAmount) * msg.amount / self.decimal;
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
            forwardTonAmount: ton("0.01"),
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
              forwardTonAmount: ton("0.01"),
              forwardPayload: emptySlice()
              }.toCell()
          });
        }
      }
    }
  } 
  
  get fun price(jetton: Address): Int {
    if (jetton == self.jettonAddressA) {
      return ton(self.bAmount / self.aAmount);
    } else {
      return ton(self.aAmount / self.bAmount);
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
