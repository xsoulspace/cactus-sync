import Dexie, { DexieOptions } from 'dexie'
interface CactusSyncI {
  dbName: string
  dbVersion: number
  dexieOptions: DexieOptions
}

/**
 * To init class use `CactusSync.init()`
 * */
export class CactusSync extends Dexie {
  // include enumeration for models map
  constructor({ dbName, dexieOptions, dbVersion }: CactusSyncI) {
    super(dbName, dexieOptions)
    const db = this
    db.version(dbVersion)
  }
  static init(arg: CactusSyncI) {
    return new CactusSync(arg)
  }
  static createModel() {}
}
