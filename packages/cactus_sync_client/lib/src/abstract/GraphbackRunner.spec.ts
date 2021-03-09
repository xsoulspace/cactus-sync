import Dexie from 'dexie'
import { GraphQLSchema } from 'graphql-compose/lib/graphql'
import { Todo } from '../../../../../resources/generatedTypes'
import { GraphbackRunner } from './GraphbackRunner'

Dexie.dependencies.indexedDB = require('fake-indexeddb')
Dexie.dependencies.IDBKeyRange = require('fake-indexeddb/lib/FDBKeyRange')
interface CreateTodoResult {
  createTodo: Todo
}
describe('graphback runner', () => {
  let db: Dexie
  const init = async () => {
    db = new Dexie('testDb')
    const runner = await GraphbackRunner.init({ db })
    return runner
  }
  afterEach(async () => {
    await db?.delete()
  })

  test('should init', async () => {
    const runner = await init()
    expect(runner.context).toBeTruthy()
    expect(runner.schema).toBeInstanceOf(GraphQLSchema)
  })
  test('should create and get', async () => {
    const runner = await init()
    const createMutation = `
      mutation{
        createTodo(input: {_version: 1, _lastUpdatedAt: 1244, title: "Hello World!"}){
          _clientId,
          _version,
          _lastUpdatedAt
          title
        }
      }
    `
    const result = await runner.execute<CreateTodoResult>(createMutation)
    const expectingTodo: Partial<Todo> = {
      _clientId: null,
      _version: 1,
      _lastUpdatedAt: 1244,
      title: 'Hello World!',
    }
    // FIXME: it works but table is not exists as expected,
    // so, resolve it after Service will be able to create table
    expect(result.data?.createTodo).toEqual(expectingTodo)
  })
})
