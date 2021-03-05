import Dexie, { DexieOptions } from 'dexie'
import { Model } from './Model'
interface CactusSyncI {
  dbName: string
  dbVersion: number
  dexieOptions: DexieOptions
}

/**
 * To init class use `CactusSync.init()`
 * */
export class CactusSync extends Dexie {
  static db: CactusSync
  // include enumeration for models map
  constructor({ dbName, dexieOptions, dbVersion }: CactusSyncI) {
    super(dbName, dexieOptions)
    const db = this
    db.version(dbVersion)
  }
  static init(arg: CactusSyncI) {
    CactusSync.db = new CactusSync(arg)
  }
  static createModel<TModel extends Model<TModel>>(model: TModel) {
    CactusSync.db.table(model.name)
  }
}
