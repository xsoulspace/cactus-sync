import { Version } from 'dexie'
import { ExecutionResult } from 'graphql-tools'
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

export class DbModel<TModel> {
  __typename: string
  db: CactusSync
  schemaModel: unknown
  constructor({ schemaModel, db, upgrade, dbVersion }: DbModelI) {
    this.db = db
    this.schemaModel = schemaModel
    // TODO: get from schema model?
    this.__typename = ''
    if (upgrade) upgrade(db.version(dbVersion).upgrade)
  }
  static init<TModel>(arg: DbModelInitI): DbModelBuilder<TModel> {
    return (dbInit: DbModelDbInitI) =>
      new DbModel<TModel>({ ...arg, ...dbInit })
  }
  _dexieTableFields(): string {
    // TODO: replace with graphql fields names for model
    return Object.keys(schemaModel)
  }
  _graphqlRunner(): GraphbackRunner {
    const runner = this.db.graphqlRunner
    if (runner == null)
      throw Error(
        `Graphql runner is not defined! 
        Maybe you forgot to run "CactusSync.init()"
        before "CactusSync.createModel"`
      )
    return runner
  }
  _execute() {
    return this._graphqlRunner().execute
  }
  async save<TInput, TResult>(input: TInput) {
    // TODO: implememt make mutation
    const query: string = makeMutation(input)
    return (await this._execute()(query)) as ExecutionResult<TResult>
  }
  async update<TInput, TResult>(input: TInput) {
    // TODO: implememt make mutation
    const query: string = makeMutation(input)
    return (await this._execute()(query)) as ExecutionResult<TResult>
  }
  async remove<TInput, TResult>(input: TInput) {
    // TODO: implememt make mutation
    const query: string = makeMutation(input)
    return (await this._execute()(query)) as ExecutionResult<TResult>
  }
  async find<TInput, TResult>(input: TInput) {
    // TODO: implememt make mutation
    const query: string = makeQuery(input)
    return (await this._execute()(query)) as ExecutionResult<TResult>
  }
  async findOne<TInput, TResult>(input: TInput) {
    // TODO: implememt make mutation
    const query: string = makeQuery(input)
    return (await this._execute()(query)) as ExecutionResult<TResult>
  }
}
