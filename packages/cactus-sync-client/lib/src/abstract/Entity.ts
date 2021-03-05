import uuid4 from 'uuid4'

export abstract class AbstractEntity {
  constructor(public _id?: string) {
    _id ? (this._id = _id) : (this._id = uuid4)
  }
  static equal(e1: AbstractEntity, e2: AbstractEntity) {
    return e1._id === e2._id
  }
}
