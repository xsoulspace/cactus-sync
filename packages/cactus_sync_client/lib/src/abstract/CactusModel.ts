import { Version } from 'dexie'
import { GraphQLFieldMap } from 'graphql'
import { GraphQLObjectType } from 'graphql-compose/lib/graphql'
import { Maybe } from 'graphql-tools'
import {
  DefautlGqlOperations,
  getDefautlGqlOperations,
} from '../graphql/DefautlGqlOperations'
import { CactusSync } from './CactusSync'
import { GraphbackRunner } from './GraphbackRunner'

interface CactusModelInitI {
  graphqlModelType: GraphQLObjectType
  // TODO: upgrade for versions like hooks?
  upgrade?(upgrade: Version['upgrade']): void
}

interface CactusModelDbInitI {
  db: CactusSync
  dbVersion: number
}

interface CactusModelI extends CactusModelInitI, CactusModelDbInitI {}

export type CactusModelBuilder<TModel> = (
  arg: CactusModelDbInitI
) => CactusModel<TModel>

type OperationInput<TInput> = { input: TInput; gql?: Maybe<string> }
type FindInput<TFilter, TPageRequest, TOrderByInput> = {
  filter?: Maybe<TFilter>
  pageRequest?: Maybe<TPageRequest>
  orderBy?: Maybe<TOrderByInput>
}

export class CactusModel<TModel> {
  modelName: string
  protected _defaultGqlOperations: DefautlGqlOperations
  protected _modelFields: (keyof TModel)[]
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
  constructor({ graphqlModelType, db, upgrade, dbVersion }: CactusModelI) {
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

  static init<TModel>(arg: CactusModelInitI): CactusModelBuilder<TModel> {
    return (dbInit: CactusModelDbInitI) =>
      new CactusModel<TModel>({ ...arg, ...dbInit })
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
  protected _execute<TVariables, TResult>(
    query: string,
    variableValues?: TVariables | undefined
  ) {
    return this._graphqlRunner().execute<TModel, TVariables, TResult>(
      query,
      variableValues
    )
  }
  protected _executeMiddleware<TInput, TResult>(
    arg: OperationInput<TInput>,
    defaultGql: string
  ) {
    const { input, gql } = arg
    const result = this._execute<TInput, TResult>(gql ?? defaultGql, input)
    return result
  }
  async add<TInput, TResult = TModel>(input: TInput, gql?: Maybe<string>) {
    return this._executeMiddleware<TInput, TResult>(
      {
        gql,
        input,
      },
      this._defaultGqlOperations.create
    )
  }
  async update<TInput, TResult>(input: TInput, gql?: Maybe<string>) {
    return this._executeMiddleware<TInput, TResult>(
      {
        gql,
        input,
      },
      this._defaultGqlOperations.update
    )
  }
  async remove<TInput, TResult>(input: TInput, gql?: Maybe<string>) {
    return this._executeMiddleware<TInput, TResult>(
      {
        gql,
        input,
      },
      this._defaultGqlOperations.delete
    )
  }
  async get<TInput, TResult>(input: TInput, gql?: Maybe<string>) {
    return this._executeMiddleware<TInput, TResult>(
      {
        gql,
        input,
      },
      this._defaultGqlOperations.get
    )
  }
  async find<
    TFilter,
    TResult,
    TPageRequest = Maybe<unknown>,
    TOrderByInput = Maybe<unknown>,
    TFilterInput = FindInput<TFilter, TPageRequest, TOrderByInput>
  >(arg?: Maybe<TFilterInput>, gql?: Maybe<string>) {
    return this._execute<TFilterInput, TResult>(
      gql ?? this._defaultGqlOperations.find,
      arg ?? undefined
    )
  }
}
