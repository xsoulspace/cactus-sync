import Dexie, { DexieOptions } from 'dexie'
import 'dexie-observable'
import {
  DatabaseChangeType,
  ICreateChange,
  IDatabaseChange,
  IDeleteChange,
  IUpdateChange,
} from 'dexie-observable/api'
import Maybe from 'graphql/tsutils/Maybe'
import { DbModelBuilder } from './DbModel'

interface CactusSyncI {
  dbName?: Maybe<string>
  dbVersion?: Maybe<number>
  dexieOptions: DexieOptions
}

/**
 * Function type to run remote server create/update/delete after local db change
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
  static db: CactusSync
  dbVersion: number
  // include enumeration for models map
  constructor({ dbName, dexieOptions, dbVersion }: CactusSyncI) {
    super(dbName ?? 'cactusSyncDb', dexieOptions)
    const db = this
    this.dbVersion = dbVersion ?? 1

    db.version(this.dbVersion)
    db.on('changes', this.handleOnCactusSyncChanges)
  }
  /**
   * Start point to initialize CactusSyncDb
   * @param arg
   */
  static init(arg: CactusSyncI) {
    CactusSync.db = new CactusSync(arg)
  }
  /**
   * Start point to include Model into db
   * Model must be created from GraphQl schema
   * //TODO: add cud hanlders to update remote server?
   * @param modelBuilder
   * @returns
   */
  static createModel<TModel>(modelBuilder: DbModelBuilder<TModel>) {
    const db = CactusSync.db
    const model = modelBuilder({ db, dbVersion: db.dbVersion })
    // TODO: add cud hanlders to update remote server?
    CactusSync.db.version(db.dbVersion).stores({
      [model.__typename]: model._dexieTableFields(),
    })
    return model
  }

  // TODO: rethink
  createHooks: Maybe<HandleModelChange<ICreateChange>>[] = []
  updateHooks: Maybe<HandleModelChange<IUpdateChange>>[] = []
  deleteHooks: Maybe<HandleModelChange<IDeleteChange>>[] = []

  // TODO: how to handle offline/online updates??
  // maybe it needs to be sended and queued only inside
  // model changes (create, update, delete) as hooks?
  handleOnCactusSyncChanges(changes: IDatabaseChange[], partial: boolean) {
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
