// import { GraphQLSchema, isObjectType } from 'graphql'
// import { GraphQLFileLoader, loadSchema } from 'graphql-tools'
// import {MockedProvider  } from "@apollo/client/testing";
// import path from 'path'
// import {
//   Maybe,
//   MutationCreateTodoArgs,
//   MutationDeleteTodoArgs,
//   MutationUpdateTodoArgs,
//   QueryFindTodosArgs,
//   QueryGetTodoArgs,
//   Todo
// } from '../../../../resources/generatedTypes'
// import { CactusModel, CactusSync, VueStateModel } from '../../lib'

// CactusSync.dependencies.indexedDB = require('fake-indexeddb')
// CactusSync.dependencies.IDBKeyRange = require('fake-indexeddb/lib/FDBKeyRange')

describe('VueStateModel', () => {
  //   const schemaPath = path.resolve(
  //     __dirname,
  //     '../../../../resources/schema.graphql'
  //   )
  //   let schema: GraphQLSchema
  //   let cactusSync: CactusSync
  //   afterEach(async () => {
  //     await cactusSync?.delete()
  //   })
  //   beforeAll(async () => {
  //     schema = await loadSchema(schemaPath, {
  //       loaders: [new GraphQLFileLoader()],
  //     })
  //   })
  //   test('can change state in response to CRUD operations', async () => {
  //     await CactusSync.init({schema,apolloOptions: {cache:, }})
  //     if (CactusSync.db) cactusSync = CactusSync.db
  //     const todoType = schema.getType('Todo')
  //     expect(CactusSync.db).toBeDefined()
  //     if (CactusSync.db) cactusSync = CactusSync.db
  //     if (isObjectType(todoType)) {
  //       const model = CactusSync.attachModel(
  //         CactusModel.init<
  //           Todo,
  //           MutationCreateTodoArgs,
  //           { createTodo: Maybe<Todo> },
  //           MutationUpdateTodoArgs,
  //           { updateTodo: Maybe<Todo> },
  //           MutationDeleteTodoArgs,
  //           { deleteTodo: Maybe<Todo> },
  //           QueryGetTodoArgs,
  //           { getTodo: Maybe<Todo> },
  //           QueryFindTodosArgs,
  //           { findTodos: { items: Maybe<Todo>[] } }
  //         >({ graphqlModelType: todoType })
  //       )
  //       const todoState = new VueStateModel({ cactusModel: model })
  //       await todoState.add({
  //         input: { _lastUpdatedAt: '1', _version: 1, title: 'Hello World!' },
  //       })
  //       const todo = todoState.list[0]
  //       expect(todoState.list.length).toEqual(1)
  //       if (todo == null) throw Error('created todo must exist')
  //       expect(todo?.title).toEqual('Hello World!')
  //       const date = Date.now().toString()
  //       await todoState.update({
  //         input: {
  //           id: todo.id,
  //           _lastUpdatedAt: date,
  //           _version: 2,
  //           title: 'Hey too!',
  //         },
  //       })
  //       const updatedTodo = todoState.list[0]
  //       if (updatedTodo == null) throw Error('updatedTodo must exist')
  //       expect(updatedTodo.title).toEqual('Hey too!')
  //       expect(updatedTodo._version).toEqual(2)
  //       expect(updatedTodo._lastUpdatedAt).toEqual(date)
  //       const getTodo = await todoState.get({
  //         id: todo.id,
  //       })
  //       expect(getTodo.data?.getTodo?.title).toEqual('Hey too!')
  //       const findTodo = await todoState.find()
  //       expect(findTodo.data?.findTodos.items.length).toEqual(1)
  //       expect(findTodo.data?.findTodos.items[0]?.title).toEqual('Hey too!')
  //       const removedTodo = await todoState.remove({
  //         input: {
  //           id: todo.id,
  //         },
  //       })
  //       expect(todoState.list.length).toEqual(0)
  //       expect(todoState.list[0]).toBeUndefined()
  //       expect(removedTodo.data?.deleteTodo?.title).toEqual('Hey too!')
  //     } else {
  //       expect(true).toBeFalsy() //should not be here
  //     }
  //   })
})
