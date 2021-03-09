import Dexie from 'dexie'
import { GraphQLSchema } from 'graphql-compose/lib/graphql'
import { Todo } from '../../../../../resources/generatedTypes'
import { GraphbackRunner } from './GraphbackRunner'

Dexie.dependencies.indexedDB = require('fake-indexeddb')
Dexie.dependencies.IDBKeyRange = require('fake-indexeddb/lib/FDBKeyRange')
interface CreateTodoResult {
  createTodo: Todo
}
interface UpdateTodoResult {
  updateTodo: Todo
}
interface DeleteTodoResult {
  deleteTodo: Todo
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
    expect(result.data?.createTodo).toEqual(expectingTodo)
  })
  test('should verify CRUD', async () => {
    const runner = await init()
    const createMutation = `
      mutation{
        createTodo(input: {_version: 1, _lastUpdatedAt: 1244, title: "Hello World!"}){
          _id
          _clientId
          _version
          _lastUpdatedAt
          title
        }
      }
    `
    const created = await runner.execute<CreateTodoResult>(createMutation)
    const createdTodo = created.data?.createTodo
    expect(createdTodo?.title).toEqual('Hello World!')

    const updateMutation = `
      mutation($_version: Int, $_id: GraphbackObjectID!){
        updateTodo(input: {_version: $_version, _id: $_id }){
          _id
          _clientId
          _version
          _lastUpdatedAt
          title
        }
      }
    `
    const updated = await runner.execute<UpdateTodoResult>(updateMutation, {
      _id: createdTodo?._id,
      _version: 2,
    })
    const updatedTodo = updated.data?.updateTodo
    expect(updatedTodo?._version).toEqual(2)

    const deleteMutation = `
      mutation($_id: GraphbackObjectID!){
        deleteTodo(input: {_id: $_id }){
          _id
          _clientId
          _version
          _lastUpdatedAt
          title
        }
      }
    `
    const deleted = await runner.execute<DeleteTodoResult>(deleteMutation, {
      _id: updatedTodo?._id,
    })
    const deletedTodo = deleted.data?.deleteTodo
    expect(deletedTodo?._version).toEqual(2)
  })
})
