import { QueryResult } from '@apollo/client'
import {
  ApolloQueryResult,
  FetchResult,
  OperationVariables,
} from '@apollo/client/core'
import { Version } from 'dexie'
import {
  DocumentNode,
  ExecutionResult,
  GraphQLFieldMap,
  GraphQLObjectType,
} from 'graphql'
import {
  AllGqlOperationsType,
  DefaultGqlOperations,
  DefaultGqlOperationType,
  getDefaultGqlOperations,
  SubscribeGqlOperationType,
} from '../graphql/DefaultGqlOperations'
import {
  ApolloRunner,
  ApolloRunnerExecute,
  ApolloSubscription,
} from './ApolloRunner'
import { Maybe } from './BasicTypes'
import { CactusSync } from './CactusSync'

interface CactusModelInitI {
  graphqlModelType: Maybe<GraphQLObjectType>
  defaultModelFragment?: Maybe<DocumentNode>
  // TODO: upgrade for versions like hooks?
  upgrade?(upgrade: Version['upgrade']): void
}

interface CactusModelDbInitI {
  db: CactusSync
  dbVersion: number
}

export interface CactusModelI extends CactusModelInitI, CactusModelDbInitI {}

export type CactusModelBuilder<
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
> = (
  arg: CactusModelDbInitI
) => CactusModel<
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

type OperationFunctionGql = {
  stringGql?: Maybe<string>
  fragmentGql?: Maybe<DocumentNode>
}

type OperationInput<TInput> = {
  input: TInput
  gql?: Maybe<OperationFunctionGql>
}

export type OperationFunction<TInput, TResult> = (
  input: TInput,
  gql?: Maybe<OperationFunctionGql>
) => Promise<ExecutionResult<TResult>>

export type QueryOperationFunction<
  TData = any,
  TFilter = OperationVariables,
  TResult = QueryResult<TData, TFilter>
> = (
  arg?: Maybe<TFilter>,
  gql?: Maybe<OperationFunctionGql>
) => Promise<ExecutionResult<TResult>>

export class CactusModel<
  TModel = any,
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
> {
  modelName: string
  protected _defaultGqlOperations: DefaultGqlOperations
  protected _modelFields: (keyof TModel)[]
  defaultModelFragment?: Maybe<DocumentNode>
  db: CactusSync
  protected _graphqlModelType: GraphQLObjectType
  /**
   * We will remove any relationships by default for safety
   * User anyway in anytime may call it with custom gql
   * @param fields
   * @returns
   */
  protected _getModelFieldNames(fields: GraphQLFieldMap<any, any>) {
    return Object.values(fields)
      .filter(
        (el) =>
          !el.description?.includes('manyToOne') &&
          !el.description?.includes('oneToMany') &&
          !el.description?.includes('oneToOne')
      )
      .map((el) => el.name) as (keyof TModel)[]
  }
  constructor({
    graphqlModelType,
    db,
    upgrade,
    dbVersion,
    defaultModelFragment,
  }: CactusModelI) {
    if (graphqlModelType == null)
      throw Error(
        'graphqlModelType for CactusModel is not defined. Check type that you put in init functon'
      )
    this.defaultModelFragment = defaultModelFragment
    const fields = graphqlModelType.getFields()
    if (fields == null)
      throw Error(`no fields defined for ${graphqlModelType.name} model`)
    this._modelFields = this._getModelFieldNames(fields)
    this.db = db
    this._graphqlModelType = graphqlModelType
    this.modelName = graphqlModelType.name
    this._defaultGqlOperations = getDefaultGqlOperations({
      modelFields: this._modelFields,
      modelName: this.modelName,
    })
    if (upgrade) upgrade(db.version(dbVersion).upgrade)
  }

  static init<
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
  >(
    arg: CactusModelInitI
  ): CactusModelBuilder<
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
  > {
    return (dbInit: CactusModelDbInitI) =>
      new CactusModel({ ...arg, ...dbInit })
  }
  protected _graphqlRunner(): ApolloRunner<any> {
    const runner = this.db.graphqlRunner
    if (runner == null)
      throw Error(
        `Graphql runner is not defined! 
        Try to run "CactusSync.init()" in your app root
        before "CactusSync.createModel"`
      )
    return runner
  }
  protected async _execute<TVariables, TResult>(
    arg: ApolloRunnerExecute<TVariables>
  ) {
    return await this._graphqlRunner().execute<TModel, TVariables, TResult>(arg)
  }

  protected _resolveGql({
    fragmentGql,
    stringGql,
    operationType,
  }: {
    operationType: AllGqlOperationsType
    fragmentGql?: Maybe<DocumentNode>
    stringGql?: Maybe<string>
  }) {
    if (stringGql) return stringGql
    const fragment = fragmentGql ?? this.defaultModelFragment
    if (fragment) {
      return getDefaultGqlOperations({
        modelName: this.modelName,
        modelFragment: fragment,
      })[operationType]
    }
    return this._defaultGqlOperations[operationType]
  }
  protected async _executeMiddleware<TInput, TResult>(arg: {
    operationInput: OperationInput<TInput>
    operationType: DefaultGqlOperationType
  }) {
    const { operationType, operationInput } = arg
    const { input: variableValues, gql } = operationInput
    /**
     * If we receive fragmentGql, we concat it with default query
     * If we receive stringGql we replace default by stringGql
     * If class has default fragment it will be use it
     * And then it will be use default fields
     */
    const query = this._resolveGql({
      operationType,
      fragmentGql: gql?.fragmentGql,
      stringGql: gql?.stringGql,
    })
    const result = await this._execute<TInput, TResult>({
      variableValues,
      query,
      operationType,
    })
    return result
  }
  add: OperationFunction<TCreateInput, TCreateResult> = async (input, gql) => {
    return await this._executeMiddleware({
      operationInput: {
        gql,
        input,
      },
      operationType: DefaultGqlOperationType.create,
    })
  }
  update: OperationFunction<TUpdateInput, TUpdateResult> = async (
    input,
    gql
  ) => {
    return await this._executeMiddleware({
      operationInput: {
        gql,
        input,
      },
      operationType: DefaultGqlOperationType.update,
    })
  }
  remove: OperationFunction<TDeleteInput, TDeleteResult> = async (
    input,
    gql
  ) => {
    return await this._executeMiddleware({
      operationInput: {
        gql,
        input,
      },
      operationType: DefaultGqlOperationType.remove,
    })
  }
  get: OperationFunction<TGetInput, TGetResult> = async (input, gql) => {
    return await this._executeMiddleware({
      operationInput: {
        gql,
        input,
      },
      operationType: DefaultGqlOperationType.get,
    })
  }
  find: QueryOperationFunction<TModel, TFindInput, TFindResult> = async (
    arg,
    gql
  ) => {
    return await this._executeMiddleware({
      operationInput: {
        gql,
        input: arg ?? undefined,
      },
      operationType: DefaultGqlOperationType.find,
    })
  }

  /// ================= Replication section ========================
  protected get _allReplicationQueries() {
    const queries = Object.values(SubscribeGqlOperationType).map((type) =>
      this._resolveGql({
        operationType: type,
      })
    )
    return queries
  }
  async startReplication() {
    return await this.db.startModelReplication({
      modelName: this.modelName,
      queries: this._allReplicationQueries,
    })
  }
  async stopReplication() {
    return await this.db.startModelReplication({
      modelName: this.modelName,
      queries: this._allReplicationQueries,
    })
  }
  get isReplicating(): boolean {
    return this.db.isModelReplicating({ modelName: this.modelName })
  }
  get graphqlSubscriptions(): Maybe<
    ApolloSubscription<TCreateResult | TUpdateResult | TDeleteResult>
  >[] {
    return (
      this.db.graphqlRunner?.getModelSubscriptions({
        modelName: this.modelName,
      }) ?? []
    )
  }
}
