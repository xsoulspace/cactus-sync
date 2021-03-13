import {
  ApolloClientOptions,
  ApolloQueryResult,
  FetchResult,
  OperationVariables,
} from '@apollo/client/core'
import Dexie, { DexieOptions } from 'dexie'
import {
  DatabaseChangeType,
  ICreateChange,
  IDatabaseChange,
  IDeleteChange,
  IUpdateChange,
} from 'dexie-observable/api'
import { GraphQLSchema } from 'graphql'
import { ApolloRunner } from './ApolloRunner'
import { Maybe } from './BasicTypes'
import { CactusModel, CactusModelBuilder } from './CactusModel'

interface CactusSyncI {
  dbName?: Maybe<string>
  dbVersion?: Maybe<number>
  dexieOptions?: Maybe<DexieOptions>
}
interface CactusSyncInitI<TCacheShape> extends CactusSyncI {
  schema: GraphQLSchema
  apolloOptions: ApolloClientOptions<TCacheShape>
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
export interface ModelReplicationI extends ModelNameReplicationI {
  queries: string[]
}
export type ModelNameReplicationI = {
  modelName: CactusModel['modelName']
}
/**
 * To init class use `CactusSync.init()`
 *
 * This is main class to init db
 * */
export class CactusSync<TCacheShape = any> extends Dexie {
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

  graphqlRunner?: Maybe<ApolloRunner<TCacheShape>>
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
  static init<TCacheShape>({
    schema,
    apolloOptions,
    dbName,
    dbVersion,
    dexieOptions,
  }: CactusSyncInitI<TCacheShape>) {
    CactusSync.db = new CactusSync<TCacheShape>({
      dbName,
      dbVersion,
      dexieOptions,
    })
    CactusSync.db.graphqlRunner = ApolloRunner.init({
      db: CactusSync.db,
      options: apolloOptions,
      schema,
    })
    console.log('Cactus Sync intialized')
  }
  /**
   * Start point to include Model into db
   * Model must be created from GraphQl schema
   * @param modelBuilder
   * @returns
   */
  static attachModel<
    TModel,
    TCreateInput = OperationVariables,
    TCreateResult = FetchResult<TModel>,
    TUpdateInput = OperationVariables,
    TUpdateResult = FetchResult<TModel>,
    TDeleteInput = OperationVariables,
    TDeleteResult = FetchResult<TModel>,
    TGetInput = OperationVariables,
    TGetResult = ApolloQueryResult<TModel>,
    TFindInput = OperationVariables,
    TFindResult = ApolloQueryResult<TModel>
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
      TFindResult
    >
  ) {
    const db = CactusSync.db
    if (db == null)
      throw Error(`
      You don't have CactusSync db instance! Be aware: 
      CactusSync.init(...) should be called before attachModel!`)
    const model = modelBuilder({ db, dbVersion: db.dbVersion })
    db.models.set(model.modelName, model)
    return model
  }

  /// ============== Replication section ================

  models: Map<
    CactusModel['modelName'],
    Maybe<CactusModel<any, any, any, any, any, any, any, any, any, any, any>>
  > = new Map()
  replicatingModels: Set<CactusModel['modelName']> = new Set()
  async startModelReplication({
    modelName,
    queries,
  }: ModelReplicationI): Promise<boolean> {
    console.log({ modelName, queries })
    const isReplicating = this.isModelReplicating({ modelName })
    if (isReplicating) {
      this.graphqlRunner?.subscribe({ modelName, queries })
      this.replicatingModels.add(modelName)
    }
    return this.isModelReplicating({ modelName })
  }
  async stopModelReplication({
    modelName,
  }: ModelReplicationI): Promise<boolean> {
    const isReplicating = this.isModelReplicating({ modelName })
    if (isReplicating) {
      this.graphqlRunner?.unsubscribe({ modelName })
      this.replicatingModels.delete(modelName)
    }
    return this.isModelReplicating({ modelName })
  }
  isModelReplicating({ modelName }: ModelNameReplicationI): boolean {
    return this.replicatingModels.has(modelName)
  }

  /// ============== OFFLINE / ONLINE ================

  // TODO: handle https://www.npmjs.com/package/apollo-link-queue

  /// ============== Dexie subscriptions ================

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
