import { Version } from 'dexie'
import { DocumentNode, GraphQLFieldMap } from 'graphql'
import { GraphQLObjectType } from 'graphql-compose/lib/graphql'
import { ExecutionResult, Maybe } from 'graphql-tools'
import {
  DefautlGqlOperations,
  DefautlGqlOperationType,
  getDefautlGqlOperations,
} from '../graphql/DefautlGqlOperations'
import { CactusSync } from './CactusSync'
import { GraphbackRunner } from './GraphbackRunner'

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
  TFindResult,
  TPageRequest,
  TOrderByInput
>

type FindInput<TFilter, TPageRequest, TOrderByInput> = {
  filter?: Maybe<TFilter>
  pageRequest?: Maybe<TPageRequest>
  orderBy?: Maybe<TOrderByInput>
}

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
  TFilter,
  TResult,
  TPageRequest = Maybe<unknown>,
  TOrderByInput = Maybe<unknown>,
  TFilterInput = FindInput<TFilter, TPageRequest, TOrderByInput>
> = (
  arg?: Maybe<TFilterInput>,
  gql?: Maybe<OperationFunctionGql>
) => Promise<ExecutionResult<TResult>>

export class CactusModel<
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
> {
  modelName: string
  protected _defaultGqlOperations: DefautlGqlOperations
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
    this._defaultGqlOperations = getDefautlGqlOperations({
      modelFields: this._modelFields,
      modelName: this.modelName,
    })
    if (upgrade) upgrade(db.version(dbVersion).upgrade)
  }

  static init<
    TModel,
    TCreateInput = Maybe<TModel>,
    TCreateResult = Maybe<TModel>,
    TUpdateInput = Maybe<TModel>,
    TUpdateResult = Maybe<TModel>,
    TDeleteInput = Maybe<TModel>,
    TDeleteResult = Maybe<TModel>,
    TGetInput = Maybe<TModel>,
    TGetResult = Maybe<TModel>,
    TFindInput = Maybe<TModel>,
    TFindResult = Maybe<TModel>,
    TPageRequest = Maybe<unknown>,
    TOrderByInput = Maybe<unknown>
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
    TFindResult,
    TPageRequest,
    TOrderByInput
  > {
    return (dbInit: CactusModelDbInitI) =>
      new CactusModel({ ...arg, ...dbInit })
  }
  protected _graphqlRunner(): GraphbackRunner {
    const runner = this.db.graphqlRunner
    if (runner == null)
      throw Error(
        `Graphql runner is not defined! 
        Maybe you forgot to run "CactusSync.init()"
        before "CactusSync.createModel"`
      )
    return runner
  }
  protected async _execute<TVariables, TResult>(
    query: string,
    variableValues?: TVariables | undefined
  ) {
    return await this._graphqlRunner().execute<TModel, TVariables, TResult>(
      query,
      variableValues
    )
  }
  protected async _executeMiddleware<TInput, TResult>(arg: {
    operationInput: OperationInput<TInput>
    operationType: DefautlGqlOperationType
  }) {
    const { operationType, operationInput } = arg
    const { input, gql } = operationInput
    /**
     * If we receive fragmentGql, we concat it with default query
     * If we receive stringGql we replace default by stringGql
     * If class has default fragment it will be use it
     * And then it will be use default fields
     */
    const finalGql = (() => {
      if (gql?.stringGql) return gql.stringGql
      const fragment = gql?.fragmentGql ?? this.defaultModelFragment
      if (fragment) {
        return getDefautlGqlOperations({
          modelName: this.modelName,
          modelFragment: fragment,
        })[operationType]
      }
      return this._defaultGqlOperations[operationType]
    })()
    const result = await this._execute<TInput, TResult>(finalGql, input)
    return result
  }
  add: OperationFunction<TCreateInput, TCreateResult> = async (input, gql) => {
    return await this._executeMiddleware({
      operationInput: {
        gql,
        input,
      },
      operationType: DefautlGqlOperationType.create,
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
      operationType: DefautlGqlOperationType.update,
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
      operationType: DefautlGqlOperationType.remove,
    })
  }
  get: OperationFunction<TGetInput, TGetResult> = async (input, gql) => {
    return await this._executeMiddleware({
      operationInput: {
        gql,
        input,
      },
      operationType: DefautlGqlOperationType.get,
    })
  }
  find: QueryOperationFunction<
    TFindInput,
    TFindResult,
    TPageRequest,
    TOrderByInput
  > = async (arg, gql) => {
    return await this._executeMiddleware({
      operationInput: {
        gql,
        input: arg ?? undefined,
      },
      operationType: DefautlGqlOperationType.find,
    })
  }
}
