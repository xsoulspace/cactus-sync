import Dexie, { DexieOptions } from 'dexie'
import { Maybe } from 'graphql-tools'
import { DbModelBuilder } from './DbModel'
import { GraphbackRunner } from './GraphbackRunner'

interface CactusSyncI {
  dbName?: Maybe<string>
  dbVersion?: Maybe<number>
  dexieOptions?: Maybe<DexieOptions>
}

/**
 * To init class use `CactusSync.init()`
 *
 * This is main class to init db
 * */
export class CactusSync extends Dexie {
  /**
   * This is running Dexie db instance
   * To initialize db use:
   * 1. `CactusSync.init()`
   * 2. add models by `CactusSync.createModel()`
   * 3. use it anywehere in app via Model.(save/update/remove/find/get)
   *
   * Model will use `CactusSync.graphqlExecute` to run query and
   * will get results back
   */
  static db?: Maybe<CactusSync>

  graphqlRunner?: Maybe<GraphbackRunner>
  dbVersion: number
  // include enumeration for models map
  constructor({ dbName, dexieOptions, dbVersion }: CactusSyncI) {
    super(dbName ?? 'cactusSyncDb', dexieOptions ?? undefined)
    const db = this
    this.dbVersion = dbVersion ?? 1

    db.version(this.dbVersion)
    // maybe will need to @deprecate
  }
  /**
   * Start point to initialize CactusSyncDb to add new models
   *
   * You also should configure path for your graphql schema
   * See more about config: https://graphql-config.com/introduction/
   *
   * @param arg
   */
  static async init(arg: CactusSyncI) {
    CactusSync.db = new CactusSync(arg)
    CactusSync.db.graphqlRunner = await GraphbackRunner.init({
      db: CactusSync.db,
    })
  }
  /**
   * Start point to include Model into db
   * Model must be created from GraphQl schema
   * @param modelBuilder
   * @returns
   */
  static attachModel<TModel>(modelBuilder: DbModelBuilder<TModel>) {
    const db = CactusSync.db
    if (db == null)
      throw Error(`
      You don't have CactusSync db instance! Be aware: 
      CactusSync.init(...) should be called before attachModel!`)
    const model = modelBuilder({ db, dbVersion: db.dbVersion })
    return model
  }
}
