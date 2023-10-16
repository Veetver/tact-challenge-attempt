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
const MIN_FUEL: Int = ton("0.01");
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

  fun onlyAnB(){
        require((context().sender == self.jettonAddressA) || (context().sender == self.jettonAddressB), "unknown jetton");
  }

  fun convertJettonsAndSend(jettonAddress: Address, coinsToSend: Int, destination: Address) {
        send(SendParameters{
        to: jettonAddress,
        value: 0,
        mode: SendRemainingValue,
        body: TokenTransfer {
          queryId: 0,
          amount: coinsToSend, // should be amount of jettons to send
          destination: destination,
          responseDestination: myAddress(),
          customPayload: null,
          forwardTonAmount: MIN_FUEL,
          forwardPayload: emptySlice()
          }.toCell()
      });
  }

  receive(msg: TokenNotification) {
    self.onlyAnB();

    if (msg.from == self.owner) {
      if (context().sender == self.jettonAddressA) {
        self.aAmount = self.aAmount + msg.amount;
      } else {
        self.bAmount = self.bAmount + msg.amount;
      }
    } else {
      let coinsToSend: Int = 0;
      let isEnough: Bool = false;
      let jettonReciever: Address = self.jettonAddressA;
      if (context().sender == self.jettonAddressA) {
        // amountOfBJettonToSend in A->B
        coinsToSend = (self.bAmount * self.decimal / self.aAmount) * msg.amount / self.decimal;
        isEnough = self.bAmount >= coinsToSend;
        jettonReciever = self.jettonAddressB;
      } else {
        // amountOfAJettonToSend in B->A
        coinsToSend = (self.aAmount * self.decimal / self.bAmount) * msg.amount / self.decimal;
        isEnough = self.aAmount >= coinsToSend;
        jettonReciever = self.jettonAddressA;
      }

      // Проверка наличия достаточного кол-ва монет 
      if (isEnough) {
        // Сконвертировать монеты
        self.convertJettonsAndSend(jettonReciever, coinsToSend, msg.from);
        // Обновить значения Task3
        if (jettonReciever == self.jettonAddressA) {
          self.bAmount = self.bAmount - coinsToSend;
          self.aAmount = self.aAmount + msg.amount;
        } else {
        self.aAmount = self.aAmount - coinsToSend;
        self.bAmount = self.bAmount + msg.amount;
        }

      } else {
        // Вернуть монеты владельцу **Работает**
        send(SendParameters{
        to: context().sender,
        value: 0,
        mode: SendRemainingValue,
        body: TokenTransfer {
          queryId: 0,
          amount: msg.amount,
          destination: msg.from,
          responseDestination: myAddress(),
          customPayload: null,
          forwardTonAmount: MIN_FUEL,
          forwardPayload: emptySlice()
          }.toCell()
      });
      }
    }
  } 
  
  get fun price(jetton: Address): Int { 
      if (jetton == self.jettonAddressA) {
          return self.bAmount * self.decimal / self.aAmount;
      }
      if (jetton == self.jettonAddressB) {
          return self.aAmount * self.decimal / self.bAmount;
      }
      return -1;
  }
  
  get fun balance(jetton: Address): Int { 
      if (jetton == self.jettonAddressA) {
          return self.aAmount;
      }
      if (jetton == self.jettonAddressB) {
          return self.bAmount;
      }
      return -1;
  }
}
