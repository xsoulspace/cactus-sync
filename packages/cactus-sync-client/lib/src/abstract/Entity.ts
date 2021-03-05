import uuid4 from 'uuid4'

export abstract class AbstractEntity {
  constructor(public gid?: string) {
    gid ? (this.gid = gid) : (this.gid = uuid4())
  }
  equals(e1: AbstractEntity, e2: AbstractEntity) {
    return e1.gid == e2.gid
  }
}
