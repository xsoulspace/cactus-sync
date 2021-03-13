/* eslint-disable */
import { buildSchema, GraphQLObjectType } from 'graphql'
import {
  CactusModel,
  CactusSync,
  Maybe,
  VueStateModel,
} from '../../../../packages/cactus-sync-client/dist'
import {
  CactusSyncTimestamp,
  CactusSyncTimestampResultList,
  MutationCreateCactusSyncTimestampArgs,
  MutationCreateTodoArgs,
  MutationCreateUserArgs,
  MutationDeleteCactusSyncTimestampArgs,
  MutationDeleteTodoArgs,
  MutationDeleteUserArgs,
  MutationUpdateCactusSyncTimestampArgs,
  MutationUpdateTodoArgs,
  MutationUpdateUserArgs,
  QueryFindCactusSyncTimestampsArgs,
  QueryFindTodosArgs,
  QueryFindUsersArgs,
  QueryGetCactusSyncTimestampArgs,
  QueryGetTodoArgs,
  QueryGetUserArgs,
  Todo,
  TodoResultList,
  User,
  UserResultList,
} from '../../../../resources/generatedTypes'
import { useCactusSyncInit } from './config'
import strSchema from './models.graphql?raw'

useCactusSyncInit()

const schema = buildSchema(strSchema)

export const todoModel = CactusSync.attachModel(
  CactusModel.init<
    Todo,
    MutationCreateTodoArgs,
    { createTodo: Maybe<Todo> },
    MutationUpdateTodoArgs,
    { updateTodo: Maybe<Todo> },
    MutationDeleteTodoArgs,
    { deleteTodo: Maybe<Todo> },
    QueryGetTodoArgs,
    { getTodo: Maybe<Todo> },
    QueryFindTodosArgs,
    { findTodos: TodoResultList }
  >({ graphqlModelType: schema.getType('Todo') as Maybe<GraphQLObjectType> })
)
export const useTodoState = () => new VueStateModel({ cactusModel: todoModel })
export type TodoState = VueStateModel<
  Todo,
  MutationCreateTodoArgs,
  { createTodo: Maybe<Todo> },
  MutationUpdateTodoArgs,
  { updateTodo: Maybe<Todo> },
  MutationDeleteTodoArgs,
  { deleteTodo: Maybe<Todo> },
  QueryGetTodoArgs,
  { getTodo: Maybe<Todo> },
  QueryFindTodosArgs,
  { findTodos: TodoResultList }
>
export const userModel = CactusSync.attachModel(
  CactusModel.init<
    User,
    MutationCreateUserArgs,
    { createUser: Maybe<User> },
    MutationUpdateUserArgs,
    { updateUser: Maybe<User> },
    MutationDeleteUserArgs,
    { deleteUser: Maybe<User> },
    QueryGetUserArgs,
    { getUser: Maybe<User> },
    QueryFindUsersArgs,
    { findUsers: UserResultList }
  >({ graphqlModelType: schema.getType('User') as Maybe<GraphQLObjectType> })
)
export const useUserState = () => new VueStateModel({ cactusModel: userModel })
export type UserState = VueStateModel<
  User,
  MutationCreateUserArgs,
  { createUser: Maybe<User> },
  MutationUpdateUserArgs,
  { updateUser: Maybe<User> },
  MutationDeleteUserArgs,
  { deleteUser: Maybe<User> },
  QueryGetUserArgs,
  { getUser: Maybe<User> },
  QueryFindUsersArgs,
  { findUsers: UserResultList }
>
export const cactusSyncTimestampModel = CactusSync.attachModel(
  CactusModel.init<
    CactusSyncTimestamp,
    MutationCreateCactusSyncTimestampArgs,
    { createCactusSyncTimestamp: Maybe<CactusSyncTimestamp> },
    MutationUpdateCactusSyncTimestampArgs,
    { updateCactusSyncTimestamp: Maybe<CactusSyncTimestamp> },
    MutationDeleteCactusSyncTimestampArgs,
    { deleteCactusSyncTimestamp: Maybe<CactusSyncTimestamp> },
    QueryGetCactusSyncTimestampArgs,
    { getCactusSyncTimestamp: Maybe<CactusSyncTimestamp> },
    QueryFindCactusSyncTimestampsArgs,
    { findCactusSyncTimestamps: CactusSyncTimestampResultList }
  >({
    graphqlModelType: schema.getType(
      'CactusSyncTimestamp'
    ) as Maybe<GraphQLObjectType>,
  })
)
export const useCactusSyncTimestampState = () =>
  new VueStateModel({ cactusModel: cactusSyncTimestampModel })
export type CactusSyncTimestampState = VueStateModel<
  CactusSyncTimestamp,
  MutationCreateCactusSyncTimestampArgs,
  { createCactusSyncTimestamp: Maybe<CactusSyncTimestamp> },
  MutationUpdateCactusSyncTimestampArgs,
  { updateCactusSyncTimestamp: Maybe<CactusSyncTimestamp> },
  MutationDeleteCactusSyncTimestampArgs,
  { deleteCactusSyncTimestamp: Maybe<CactusSyncTimestamp> },
  QueryGetCactusSyncTimestampArgs,
  { getCactusSyncTimestamp: Maybe<CactusSyncTimestamp> },
  QueryFindCactusSyncTimestampsArgs,
  { findCactusSyncTimestamps: CactusSyncTimestampResultList }
>

console.log('Cactus Sync hooks initialized')
