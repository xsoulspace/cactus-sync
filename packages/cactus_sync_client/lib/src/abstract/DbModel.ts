import { Version } from 'dexie'
import { CactusSync } from './CactusSync'

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
    // TODO: replace with graphql fields
    return Object.keys(schemaModel)
  }
  get table() {
    return this.db.table<TModel, string>(this.__typename)
  }
  collection() {
    return this.table.toCollection()
  }
}
