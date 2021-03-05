import Dexie, { DexieOptions } from 'dexie'
import Maybe from 'graphql/tsutils/Maybe'
import { DbModelBuilder } from './DbModel'
interface CactusSyncI {
  dbName?: Maybe<string>
  dbVersion?: Maybe<number>
  dexieOptions: DexieOptions
}

/**
 * To init class use `CactusSync.init()`
 *
 * This is main class to init db
 * */
export class CactusSync extends Dexie {
  static db: CactusSync
  dbVersion: number
  // include enumeration for models map
  constructor({ dbName, dexieOptions, dbVersion }: CactusSyncI) {
    super(dbName ?? 'cactusDb', dexieOptions)
    const db = this
    this.dbVersion = dbVersion ?? 1
    db.version(this.dbVersion)
  }
  static init(arg: CactusSyncI) {
    CactusSync.db = new CactusSync(arg)
  }
  static createModel<TModel>(modelBuilder: DbModelBuilder<TModel>) {
    const db = CactusSync.db
    const model = modelBuilder({ db, dbVersion: db.dbVersion })
    CactusSync.db.version(db.dbVersion).stores({
      [model.__typename]: model._dexieTableFields(),
    })
    return model
  }
}
