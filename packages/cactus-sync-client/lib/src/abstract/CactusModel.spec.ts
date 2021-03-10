import { GraphQLFileLoader } from '@graphql-tools/graphql-file-loader'
import { loadSchema } from '@graphql-tools/load'
import { GraphQLSchema, isObjectType } from 'graphql-compose/lib/graphql'
import gql from 'graphql-tag'
import { Maybe } from 'graphql-tools'
import path from 'path'
import {
  MutationCreateTodoArgs,
  MutationCreateUserArgs,
  MutationDeleteTodoArgs,
  MutationDeleteUserArgs,
  MutationUpdateTodoArgs,
  MutationUpdateUserArgs,
  QueryGetUserArgs,
  Todo,
  User,
} from '../../../../../resources/generatedTypes'
import { CactusModel } from './CactusModel'
import { CactusSync } from './CactusSync'
CactusSync.dependencies.indexedDB = require('fake-indexeddb')
CactusSync.dependencies.IDBKeyRange = require('fake-indexeddb/lib/FDBKeyRange')

describe('CactusModel', () => {
  const schemaPath = path.resolve(
    __dirname,
    '../../../../../resources/schema.graphql'
  )
  let schema: GraphQLSchema
  let cactusSync: CactusSync

  afterEach(async () => {
    await cactusSync?.delete()
  })

  beforeAll(async () => {
    schema = await loadSchema(schemaPath, {
      loaders: [new GraphQLFileLoader()],
    })
  })
  test('can init with default graphql operations', async () => {
    const type = schema.getType('Todo')
    cactusSync = new CactusSync({})
    if (isObjectType(type)) {
      const builder = CactusModel.init<Todo>({
        graphqlModelType: type,
      })
      const model = builder({ db: cactusSync, dbVersion: 1 })
      expect(model.modelName).toEqual('Todo')
      expect(model['_modelFields']).toEqual([
        'id',
        '_clientId',
        '_version',
        '_lastUpdatedAt',
        'title',
      ])
    } else {
      expect(true).toBeFalsy() //should not be here
    }
  })
  const todoFragment = gql`
    fragment TodoFragment on Todo {
      id
      title
      user {
        id
        name
      }
    }
  `
  test('can use default gql fragments', async () => {
    const todoType = schema.getType('Todo')
    const userType = schema.getType('User')
    if (isObjectType(todoType) && isObjectType(userType)) {
      await CactusSync.init({})
      expect(CactusSync.db).toBeDefined()

      if (CactusSync.db) cactusSync = CactusSync.db

      const todoModel = CactusSync.attachModel(
        CactusModel.init<
          Todo,
          MutationCreateTodoArgs,
          { createTodo: Maybe<Todo> },
          MutationUpdateTodoArgs,
          { updateTodo: Maybe<Todo> },
          MutationDeleteTodoArgs,
          { deleteTodo: Maybe<Todo> }
        >({ graphqlModelType: todoType, defaultModelFragment: todoFragment })
      )
      expect(todoModel.modelName).toEqual('Todo')

      const userModel = CactusSync.attachModel(
        CactusModel.init<
          User,
          MutationCreateUserArgs,
          { createUser: Maybe<User> },
          MutationUpdateUserArgs,
          { updateUser: Maybe<User> },
          MutationDeleteUserArgs,
          { deleteUser: Maybe<User> },
          QueryGetUserArgs,
          { getUser: Maybe<User> }
        >({ graphqlModelType: userType })
      )
      expect(userModel.modelName).toEqual('User')

      const userResult = await userModel.add({
        input: {
          _lastUpdatedAt: '1',
          _version: 1,
          name: 'Spiderman',
        },
      })
      const user = userResult.data?.createUser
      expect(user?.name).toEqual('Spiderman')

      const todoResult = await todoModel.add({
        input: { _lastUpdatedAt: 'sfd', _version: 1, userId: user?.id },
      })
      expect(todoResult.data?.createTodo?.user?.name).toEqual('Spiderman')
    } else {
      expect(true).toBeFalsy() //should not be here
    }
  })
  test('can perform CRUD with relationships', async () => {
    const todoType = schema.getType('Todo')
    const userType = schema.getType('User')
    await CactusSync.init({})
    expect(CactusSync.db).toBeDefined()
    if (CactusSync.db) cactusSync = CactusSync.db
    if (isObjectType(todoType) && isObjectType(userType)) {
      const todoModel = CactusSync.attachModel(
        CactusModel.init<
          Todo,
          MutationCreateTodoArgs,
          { createTodo: Maybe<Todo> },
          MutationUpdateTodoArgs,
          { updateTodo: Maybe<Todo> },
          MutationDeleteTodoArgs,
          { deleteTodo: Maybe<Todo> }
        >({ graphqlModelType: todoType })
      )
      expect(todoModel.modelName).toEqual('Todo')

      const userModel = CactusSync.attachModel(
        CactusModel.init<
          User,
          MutationCreateUserArgs,
          { createUser: Maybe<User> },
          MutationUpdateUserArgs,
          { updateUser: Maybe<User> },
          MutationDeleteUserArgs,
          { deleteUser: Maybe<User> },
          QueryGetUserArgs,
          { getUser: Maybe<User> }
        >({ graphqlModelType: userType })
      )
      expect(userModel.modelName).toEqual('User')

      const createResult = await todoModel.add({
        input: {
          _lastUpdatedAt: '1',
          _version: 1,
          title: 'Hello World!',
        },
      })
      expect(createResult.data?.createTodo?.title).toEqual('Hello World!')

      const userResult = await userModel.add({
        input: {
          _lastUpdatedAt: '1',
          _version: 1,
          name: 'Spiderman',
        },
      })
      const user = userResult.data?.createUser
      expect(user?.name).toEqual('Spiderman')
      const todoId = createResult.data?.createTodo?.id
      if (todoId == null) throw Error('todoId should exist')
      const userId = user?.id
      if (userId == null) throw Error('userId should exist')
      const updateResult = await todoModel.update({
        input: {
          id: todoId,
          _lastUpdatedAt: '1',
          _version: 1,
          title: 'Hello World! With spiderman!',
          userId,
        },
      })
      expect(updateResult.data?.updateTodo?.title).toEqual(
        'Hello World! With spiderman!'
      )
      const getUserResult = await userModel.get(
        {
          id: userId,
        },
        {
          stringGql: `
            query ($id: ID!){
              getUser(id: $id){
                name,
                todos {
                  id
                  title
                }
              }
            }
            `,
        }
      )
      const updatedUser = getUserResult.data?.getUser
      expect(updatedUser?.name).toEqual('Spiderman')
      expect(updatedUser?.todos.length).toEqual(1)
      expect(updatedUser?.todos[0]?.title).toEqual(
        'Hello World! With spiderman!'
      )

      const deleteResult = await todoModel.remove(
        {
          input: {
            id: todoId,
          },
        },
        {
          fragmentGql: todoFragment,
        }
      )
      expect(deleteResult.data?.deleteTodo?.title).toEqual(
        'Hello World! With spiderman!'
      )
      expect(deleteResult.data?.deleteTodo?.user?.name).toEqual('Spiderman')
    } else {
      expect(true).toBeFalsy() //should not be here
    }
  })
})
