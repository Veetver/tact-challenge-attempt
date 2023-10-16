import "@stdlib/deploy";
message Add {
  queryId: Int as uint64;
  number: Int as uint32;
}
message Subtract {
  queryId: Int as uint64;
  number: Int as uint32;
}

extends mutates fun addToCounter(self: Int, c: Int) {
  self = self + c;
}

extends mutates fun subCounter(self: Int, c: Int) {
  self = self - c;
}
contract Task1 with Deployable {
    counter: Int as int32 = 0;

init() {

}

    receive(msg: Add) {
      self.counter.addToCounter(msg.number);
    }    
    receive(msg: Subtract) {
      self.counter.subCounter(msg.number);
    }
    get fun counter(): Int {
      return self.counter;
    }
}
