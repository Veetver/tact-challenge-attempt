import "@stdlib/deploy";
message(0x44) Refund {
  queryId: Int as uint64;
  sender: Address;
}
contract Task2 with Deployable {
  admin: Address;

  init(admin: Address) {
    self.admin = admin;
  }
  receive(msg: Refund) {
    require(sender() == self.admin, "Only admin allows to refund");
    send(SendParameters{
      to: msg.sender,
      mode: SendRemainingValue
    });
  }
  receive(msg: Slice) {
    send(SendParameters{
      to: self.admin,
      mode: SendRemainingValue,
      body: beginCell().storeRef(msg.asCell()).storeAddress(sender()).endCell()
    });
  }
}
