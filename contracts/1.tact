import "@stdlib/deploy";
message Add {
  queryId: Int as uint64;
  number: Int as uint32;
}
message Subtract {
  queryId: Int as uint64;
  number: Int as uint32;
}

extends mutates fun modifyCounter(self: Int, c: Int, mode: Int) {
  self = self + (mode * c);
}

contract Task1 with Deployable {
    counter: Int as int32 = 0;

    init() {
    }

    receive(msg: Add) {
      self.counter.modifyCounter(msg.number, 1);
    }    
    receive(msg: Subtract) {
      self.counter.modifyCounter(msg.number, -1);
    }
    get fun counter(): Int {
      return self.counter;
    }
}
