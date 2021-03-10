import Dexie, { DexieOptions } from 'dexie'
import {
  DatabaseChangeType,
  ICreateChange,
  IDatabaseChange,
  IDeleteChange,
  IUpdateChange,
} from 'dexie-observable/api'
import { Maybe } from 'graphql-tools'
import { CactusModelBuilder } from './CactusModel'
import { GraphbackRunner } from './GraphbackRunner'

interface CactusSyncI {
  dbName?: Maybe<string>
  dbVersion?: Maybe<number>
  dexieOptions?: Maybe<DexieOptions>
}
/**
 * Function type to run after CactusSync(Dexie) change
 */
export type HandleModelChange<TIDatabaseChange extends IDatabaseChange> = ({
  change,
}: {
  change: TIDatabaseChange
}) => void

const useRunHooks = <TIDatabaseChange extends IDatabaseChange>({
  hooks,
  change,
}: {
  change: TIDatabaseChange
  hooks: Maybe<HandleModelChange<TIDatabaseChange>>[]
}) => {
  for (const hook of hooks) {
    if (hook) hook({ change })
  }
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
  static attachModel<
    TModel,
    TCreateInput,
    TCreateResult,
    TUpdateInput,
    TUpdateResult,
    TDeleteInput,
    TDeleteResult,
    TGetInput,
    TGetResult,
    TFindInput,
    TFindResult,
    TPageRequest,
    TOrderByInput
  >(
    modelBuilder: CactusModelBuilder<
      TModel,
      TCreateInput,
      TCreateResult,
      TUpdateInput,
      TUpdateResult,
      TDeleteInput,
      TDeleteResult,
      TGetInput,
      TGetResult,
      TFindInput,
      TFindResult,
      TPageRequest,
      TOrderByInput
    >
  ) {
    const db = CactusSync.db
    if (db == null)
      throw Error(`
      You don't have CactusSync db instance! Be aware: 
      CactusSync.init(...) should be called before attachModel!`)
    const model = modelBuilder({ db, dbVersion: db.dbVersion })
    return model
  }

  createHooks: Maybe<HandleModelChange<ICreateChange>>[] = []
  updateHooks: Maybe<HandleModelChange<IUpdateChange>>[] = []
  deleteHooks: Maybe<HandleModelChange<IDeleteChange>>[] = []

  handleOnCactusSyncChanges(changes: IDatabaseChange[], _partial: boolean) {
    for (const change of changes) {
      switch (change.type) {
        case DatabaseChangeType.Create: // CREATED
          console.log('An object was created: ' + JSON.stringify(change.obj))
          useRunHooks({ change, hooks: this.createHooks })
          break
        case DatabaseChangeType.Update: // UPDATED
          console.log(
            'An object with key ' +
              change.key +
              ' was updated with modifications: ' +
              JSON.stringify(change?.mods)
          )
          useRunHooks({ change, hooks: this.updateHooks })
          break
        case DatabaseChangeType.Delete: // DELETED
          console.log('An object was deleted: ' + JSON.stringify(change.oldObj))
          useRunHooks({ change, hooks: this.deleteHooks })
          break
      }
    }
  }
}
