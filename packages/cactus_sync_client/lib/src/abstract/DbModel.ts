import { Version } from 'dexie'
import { Maybe } from 'graphql-tools'
import {
  DefautlGqlOperations,
  getDefautlGqlOperations,
} from '../graphql/DefautlGqlOperations'
import { CactusSync } from './CactusSync'
import { GraphbackRunner } from './GraphbackRunner'

interface DbModelInitI {
  // TODO:
  schemaModel: unknown
  // TODO: upgrade for versions like hooks?
  upgrade?(upgrade: Version['upgrade']): void
}

interface DbModelDbInitI {
  db: CactusSync
  dbVersion: number
}

interface DbModelI extends DbModelInitI, DbModelDbInitI {}

export type DbModelBuilder<TModel> = (arg: DbModelDbInitI) => DbModel<TModel>

type OperationInput<TInput> = { input: TInput; gql?: Maybe<string> }
type FindInput<TFilter, TPageRequest, TOrderByInput> = {
  filter?: Maybe<TFilter>
  pageRequest?: Maybe<TPageRequest>
  orderBy?: Maybe<TOrderByInput>
}

export class DbModel<TModel> {
  modelName: string
  protected _defaultGqlOperations: DefautlGqlOperations
  db: CactusSync
  protected _schemaModel: unknown
  constructor({ schemaModel, db, upgrade, dbVersion }: DbModelI) {
    this.db = db
    this._schemaModel = schemaModel
    const modelFields = ['']
    this.modelName = ''
    this._defaultGqlOperations = getDefautlGqlOperations({
      modelFields,
      modelName: this.modelName,
    })
    if (upgrade) upgrade(db.version(dbVersion).upgrade)
  }
  static init<TModel>(arg: DbModelInitI): DbModelBuilder<TModel> {
    return (dbInit: DbModelDbInitI) =>
      new DbModel<TModel>({ ...arg, ...dbInit })
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
  async add<TInput, TResult>(input: TInput, gql: Maybe<string>) {
    return this._executeMiddleware<TInput, TResult>(
      {
        gql,
        input,
      },
      this._defaultGqlOperations.create
    )
  }
  async update<TInput, TResult>(input: TInput, gql: Maybe<string>) {
    return this._executeMiddleware<TInput, TResult>(
      {
        gql,
        input,
      },
      this._defaultGqlOperations.update
    )
  }
  async remove<TInput, TResult>(input: TInput, gql: Maybe<string>) {
    return this._executeMiddleware<TInput, TResult>(
      {
        gql,
        input,
      },
      this._defaultGqlOperations.delete
    )
  }
  async get<TInput, TResult>(input: TInput, gql: Maybe<string>) {
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
  >(arg: TFilterInput, gql?: Maybe<string>) {
    return this._execute<TFilterInput, TResult>(
      gql ?? this._defaultGqlOperations.find,
      arg
    )
  }
}
