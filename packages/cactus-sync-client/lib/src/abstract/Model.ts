import { ModelSchema } from './ModelSchema'

export class Model<TModel> {
  name: string
  constructor(schema: ModelSchema<TModel>) {
    // TODO:
    this.name = ''
  }
}
