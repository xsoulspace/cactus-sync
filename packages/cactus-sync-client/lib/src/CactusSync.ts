import { Model } from './Model'

interface CactusSyncI {
  models: Map<Model['name'], Model>
}

/**
 * To init class use `CactusSync.init()`
 * */
export class CactusSync {
  models: Map<Model['name'], Model>
  constructor({ models }: CactusSyncI) {
    this.models = models
  }
  static init(arg: CactusSyncI) {
    return new CactusSync(arg)
  }
  static createModel() {}
}
