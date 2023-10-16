import "@stdlib/deploy";

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64; // Бесполезное число
    amount: Int as coins;  // Кол-во полученных жетонов
    from: Address;         // Адрес пользователя отправившего жетоны
    forwardPayload: Slice as remaining; // что-то
}
// To simplify the testing process and the specificity of the messages being sent, we decided to add clear default values in this transaction
message(0xf8a7ea5) TokenTransfer {
     queryId: Int as uint64; // should be 0
     amount: Int as coins; // should be amount of jettons to send
     destination: Address; // should be user address / TokenNotification.from
     responseDestination: Address?; // should be myAddress()
     customPayload: Cell?; // should be null
     forwardTonAmount: Int as coins; // should be ton("0.01")
     forwardPayload: Slice as remaining; // should be emptySlice()
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
