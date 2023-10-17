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
    require((context().sender == self.jettonAddressA) || (context().sender == self.jettonAddressB), "unknown jetton");

    if (msg.from == self.owner) {
      if (sender() == self.jettonAddressA) {
        self.aAmount = self.aAmount + msg.amount;
      } else {
        self.bAmount = self.bAmount + msg.amount;
      }
    } else {
      let coinsToSend: Int = 0;
      let isEnough: Bool = false;
      let jettonReciever: Address = self.jettonAddressA;


      if (sender() == self.jettonAddressA) {
        coinsToSend = (self.bAmount * self.decimal / self.aAmount) * msg.amount / self.decimal;
        isEnough = coinsToSend <= self.bAmount;
        jettonReciever = self.jettonAddressB;
      } else {
        coinsToSend = (self.aAmount * self.decimal / self.bAmount) * msg.amount / self.decimal;
        isEnough = coinsToSend <= self.aAmount;
        jettonReciever = self.jettonAddressA;
      }
      if (isEnough) {
        if (jettonReciever == self.jettonAddressA) {
          self.bAmount = self.bAmount - coinsToSend;
          self.aAmount = self.aAmount + msg.amount;
        } else {
        self.aAmount = self.aAmount - coinsToSend;
        self.bAmount = self.bAmount + msg.amount;
        }
        send(SendParameters{
        to: jettonReciever,
        value: 0,
        mode: SendRemainingValue,
        body: TokenTransfer {
          queryId: 0,
          amount: coinsToSend,
          destination: msg.from,
          responseDestination: myAddress(),
          customPayload: null,
          forwardTonAmount: ton("0.01"),
          forwardPayload: emptySlice()
          }.toCell()
      });

      } else {
        send(SendParameters{
        to: sender(),
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
  
  get fun price(jetton: Address): Int {
    require((sender() == self.jettonAddressA) || (sender() == self.jettonAddressB), "unknown jetton");
      if (jetton == self.jettonAddressA) {
          return self.bAmount * self.decimal / self.aAmount;
      } else {
          return self.aAmount * self.decimal / self.bAmount;
      }
  }
  
  get fun balance(jetton: Address): Int { 
    require((sender() == self.jettonAddressA) || (sender() == self.jettonAddressB), "unknown jetton");
      if (jetton == self.jettonAddressA) {
          return self.aAmount;
      } else {
          return self.bAmount;
      }
  }
}
