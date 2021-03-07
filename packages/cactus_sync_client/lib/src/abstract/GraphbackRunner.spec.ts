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
  test('should init', async () => {
    const db = new Dexie('testDb')
    const runner = await GraphbackRunner.init({ db })
    expect(runner.context).toBeTruthy()
    expect(runner.schema).toBeInstanceOf(GraphQLSchema)
  })
  test('should create and get', async () => {
    const db = new Dexie('testDb')
    const runner = await GraphbackRunner.init({ db })
    const createMutation = `
      mutation{
        createTodo(input: {_version: 1, _lastUpdatedAt: 1244, title: "Hello World!"}){
          _id,
          _clientId,
          _version,
          _lastUpdatedAt
          title
        }
      }
    `
    const result = await runner.execute<CreateTodoResult>(createMutation)
    const expectingTodo: CreateTodoResult = {
      createTodo: {
        _id: '6044b744942bd3a748d1f5bc',
        _clientId: null,
        _version: 1,
        _lastUpdatedAt: 1244,
        title: 'Hello World!',
      },
    }
    // FIXME: it works but table is not exists as expected,
    // so, resolve it after Service will be able to create table
    expect(result.data).toEqual(expectingTodo)
  })
})
