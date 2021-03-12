import Dexie from 'dexie'
import { GraphQLSchema } from 'graphql'
import { Todo, User } from '../../../../resources/generatedTypes'
import { GraphbackRunner } from '../../lib'

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
interface FindTodoResult {
  findTodos: { items: Todo[] }
}
interface CreateUserResult {
  createUser: User
}
interface GetUserResult {
  getUser: User
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

  test('can init graphql runtime context and schema', async () => {
    const runner = await init()
    expect(runner.context).toBeTruthy()
    expect(runner.schema).toBeInstanceOf(GraphQLSchema)
  })
  test('can create and get', async () => {
    const runner = await init()
    const createMutation = `
      mutation{
        createTodo(input: {_version: 1, _lastUpdatedAt: "1244", title: "Hello World!"}){
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
      _lastUpdatedAt: '1244',
      title: 'Hello World!',
    }
    expect(result.data?.createTodo).toEqual(expectingTodo)
  })
  const todoCreateMutation = `
      mutation{
        createTodo(input: {_version: 1, _lastUpdatedAt: "1244", title: "Hello World!"}){
          id
          _clientId
          _version
          _lastUpdatedAt
          title
        }
      }
    `
  test('can make CRUD', async () => {
    const runner = await init()

    const created = await runner.execute<CreateTodoResult>(todoCreateMutation)
    const createdTodo = created.data?.createTodo
    expect(createdTodo?.title).toEqual('Hello World!')

    const updateMutation = `
      mutation($_version: Int, $id: ID!){
        updateTodo(input: {_version: $_version, id: $id }){
          id
          _clientId
          _version
          _lastUpdatedAt
          title
        }
      }
    `
    const updated = await runner.execute<UpdateTodoResult>(updateMutation, {
      id: createdTodo?.id,
      _version: 2,
    })
    const updatedTodo = updated.data?.updateTodo
    expect(updatedTodo?._version).toEqual(2)

    const deleteMutation = `
      mutation($id: ID!){
        deleteTodo(input: {id: $id }){
          id
          _clientId
          _version
          _lastUpdatedAt
          title
        }
      }
    `
    const deleted = await runner.execute<DeleteTodoResult>(deleteMutation, {
      id: updatedTodo?.id,
    })
    const deletedTodo = deleted.data?.deleteTodo
    expect(deletedTodo?._version).toEqual(2)
  })
  test('can make relationships', async () => {
    const runner = await init()
    const createdTodo = await runner.execute<CreateTodoResult>(
      todoCreateMutation
    )
    expect(createdTodo.data?.createTodo.title).toEqual('Hello World!')
    const userCreateMutation = `
      mutation{
        createUser(input: {_version: 1, _lastUpdatedAt: "1244", name: "Spiderman"}){
          id
          _clientId
          _version
          _lastUpdatedAt
          name
        }
      }
    `
    const createdUser = await runner.execute<CreateUserResult>(
      userCreateMutation
    )
    expect(createdUser.data?.createUser.name).toEqual('Spiderman')

    const updateTodoMutation = `
      mutation($userId: ID!, $id: ID!){
        updateTodo(input: {userId: $userId, id: $id }){
          id
          _clientId
          _version
          _lastUpdatedAt
          title
          user {
            id
            name
          }
        }
      }
    `
    const updatedTodo = await runner.execute<UpdateTodoResult>(
      updateTodoMutation,
      {
        id: createdTodo?.data?.createTodo.id,
        userId: createdUser.data?.createUser.id.toString(),
      }
    )
    expect(updatedTodo?.data?.updateTodo.user?.name).toEqual('Spiderman')

    const getUserQuery = `
      query($id : ID!){
        getUser(id: $id){
          id
          _clientId
          _version
          _lastUpdatedAt
          name
          todos {
            id
            title
          }
        }
      }
    `
    const userResult = await runner.execute<GetUserResult>(getUserQuery, {
      id: createdUser.data?.createUser.id,
    })
    const user = userResult.data?.getUser
    expect(user?.todos.length).toEqual(1)
    expect(user?.todos[0]?.title).toEqual('Hello World!')
  })
  test('can find with no parameters', async () => {
    const runner = await init()
    const createdTodo = await runner.execute<CreateTodoResult>(
      todoCreateMutation
    )
    expect(createdTodo.data?.createTodo.title).toEqual('Hello World!')
    const findTodosQuery = `
      query{
        findTodos{
          items {
            id
            _clientId
            _version
            _lastUpdatedAt
            title
          }
        }
      }
    `
    const findTodosResult = await runner.execute<FindTodoResult>(findTodosQuery)

    expect(findTodosResult.data?.findTodos.items.length).toEqual(1)
    expect(findTodosResult.data?.findTodos.items[0].title).toEqual(
      'Hello World!'
    )
  })
})
