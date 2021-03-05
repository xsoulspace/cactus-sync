import Maybe from 'graphql/tsutils/Maybe'
import uuid4 from 'uuid4'

export const validateUuid4 = (_id?: Maybe<string>): boolean =>
  _id == null ? false : uuid4(_id)
