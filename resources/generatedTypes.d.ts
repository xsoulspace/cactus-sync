export declare type Maybe<T> = T | null;
export declare type Exact<T extends {
    [key: string]: unknown;
}> = {
    [K in keyof T]: T[K];
};
export declare type MakeOptional<T, K extends keyof T> = Omit<T, K> & {
    [SubKey in K]?: Maybe<T[SubKey]>;
};
export declare type MakeMaybe<T, K extends keyof T> = Omit<T, K> & {
    [SubKey in K]: Maybe<T[SubKey]>;
};
/** All built-in and custom scalars, mapped to their actual values */
export declare type Scalars = {
    ID: string;
    String: string;
    Boolean: boolean;
    Int: number;
    Float: number;
};
/**
 * @model
 * @cactusSync
 * This model keeps all changes for every model any made
 * FIXME: Maybe schema needs to work this way (first open, after offline):
 * client queried CactusSyncTimestamp first.
 * If new timestamps occured, then request changes
 */
export declare type CactusSyncTimestamp = {
    __typename?: 'CactusSyncTimestamp';
    id: Scalars['ID'];
    /**
     * The id, which will be created, if
     * the model was created offline
     */
    _clientId?: Maybe<Scalars['ID']>;
    timestamp?: Maybe<Scalars['String']>;
    changeType: DatabaseChangeType;
    /** model __typename */
    modelTypename?: Maybe<Scalars['String']>;
    modelId: Scalars['ID'];
};
export declare type CactusSyncTimestampFilter = {
    id?: Maybe<IdInput>;
    _clientId?: Maybe<IdInput>;
    timestamp?: Maybe<StringInput>;
    changeType?: Maybe<StringInput>;
    modelTypename?: Maybe<StringInput>;
    modelId?: Maybe<IdInput>;
    and?: Maybe<Array<CactusSyncTimestampFilter>>;
    or?: Maybe<Array<CactusSyncTimestampFilter>>;
    not?: Maybe<CactusSyncTimestampFilter>;
};
export declare type CactusSyncTimestampResultList = {
    __typename?: 'CactusSyncTimestampResultList';
    items: Array<Maybe<CactusSyncTimestamp>>;
    offset?: Maybe<Scalars['Int']>;
    limit?: Maybe<Scalars['Int']>;
    count?: Maybe<Scalars['Int']>;
};
export declare type CactusSyncTimestampSubscriptionFilter = {
    and?: Maybe<Array<CactusSyncTimestampSubscriptionFilter>>;
    or?: Maybe<Array<CactusSyncTimestampSubscriptionFilter>>;
    not?: Maybe<CactusSyncTimestampSubscriptionFilter>;
    id?: Maybe<IdInput>;
    _clientId?: Maybe<IdInput>;
    timestamp?: Maybe<StringInput>;
    changeType?: Maybe<StringInput>;
    modelTypename?: Maybe<StringInput>;
    modelId?: Maybe<IdInput>;
};
export declare type CreateCactusSyncTimestampInput = {
    _clientId?: Maybe<Scalars['ID']>;
    timestamp?: Maybe<Scalars['String']>;
    changeType: DatabaseChangeType;
    modelTypename?: Maybe<Scalars['String']>;
    modelId: Scalars['ID'];
};
export declare type CreateTodoInput = {
    _clientId?: Maybe<Scalars['ID']>;
    _version: Scalars['Int'];
    _lastUpdatedAt: Scalars['String'];
    title?: Maybe<Scalars['String']>;
    userId?: Maybe<Scalars['ID']>;
};
export declare type CreateUserInput = {
    _clientId?: Maybe<Scalars['ID']>;
    _version: Scalars['Int'];
    _lastUpdatedAt: Scalars['String'];
    name?: Maybe<Scalars['String']>;
};
/** Named according to spec: https://graphql-rules.com/rules/naming-enum */
export declare enum DatabaseChangeType {
    Create = "CREATE",
    Update = "UPDATE",
    Delete = "DELETE"
}
export declare type IdInput = {
    ne?: Maybe<Scalars['ID']>;
    eq?: Maybe<Scalars['ID']>;
    le?: Maybe<Scalars['ID']>;
    lt?: Maybe<Scalars['ID']>;
    ge?: Maybe<Scalars['ID']>;
    gt?: Maybe<Scalars['ID']>;
    in?: Maybe<Array<Scalars['ID']>>;
};
export declare type IntInput = {
    ne?: Maybe<Scalars['Int']>;
    eq?: Maybe<Scalars['Int']>;
    le?: Maybe<Scalars['Int']>;
    lt?: Maybe<Scalars['Int']>;
    ge?: Maybe<Scalars['Int']>;
    gt?: Maybe<Scalars['Int']>;
    in?: Maybe<Array<Scalars['Int']>>;
    between?: Maybe<Array<Scalars['Int']>>;
};
export declare type MutateCactusSyncTimestampInput = {
    id: Scalars['ID'];
    _clientId?: Maybe<Scalars['ID']>;
    timestamp?: Maybe<Scalars['String']>;
    changeType?: Maybe<DatabaseChangeType>;
    modelTypename?: Maybe<Scalars['String']>;
    modelId?: Maybe<Scalars['ID']>;
};
export declare type MutateTodoInput = {
    id: Scalars['ID'];
    _clientId?: Maybe<Scalars['ID']>;
    _version?: Maybe<Scalars['Int']>;
    _lastUpdatedAt?: Maybe<Scalars['String']>;
    title?: Maybe<Scalars['String']>;
    userId?: Maybe<Scalars['ID']>;
};
export declare type MutateUserInput = {
    id: Scalars['ID'];
    _clientId?: Maybe<Scalars['ID']>;
    _version?: Maybe<Scalars['Int']>;
    _lastUpdatedAt?: Maybe<Scalars['String']>;
    name?: Maybe<Scalars['String']>;
};
export declare type Mutation = {
    __typename?: 'Mutation';
    createTodo?: Maybe<Todo>;
    updateTodo?: Maybe<Todo>;
    deleteTodo?: Maybe<Todo>;
    createUser?: Maybe<User>;
    updateUser?: Maybe<User>;
    deleteUser?: Maybe<User>;
    createCactusSyncTimestamp?: Maybe<CactusSyncTimestamp>;
    updateCactusSyncTimestamp?: Maybe<CactusSyncTimestamp>;
    deleteCactusSyncTimestamp?: Maybe<CactusSyncTimestamp>;
};
export declare type MutationCreateTodoArgs = {
    input: CreateTodoInput;
};
export declare type MutationUpdateTodoArgs = {
    input: MutateTodoInput;
};
export declare type MutationDeleteTodoArgs = {
    input: MutateTodoInput;
};
export declare type MutationCreateUserArgs = {
    input: CreateUserInput;
};
export declare type MutationUpdateUserArgs = {
    input: MutateUserInput;
};
export declare type MutationDeleteUserArgs = {
    input: MutateUserInput;
};
export declare type MutationCreateCactusSyncTimestampArgs = {
    input: CreateCactusSyncTimestampInput;
};
export declare type MutationUpdateCactusSyncTimestampArgs = {
    input: MutateCactusSyncTimestampInput;
};
export declare type MutationDeleteCactusSyncTimestampArgs = {
    input: MutateCactusSyncTimestampInput;
};
export declare type OrderByInput = {
    field: Scalars['String'];
    order?: Maybe<SortDirectionEnum>;
};
export declare type PageRequest = {
    limit?: Maybe<Scalars['Int']>;
    offset?: Maybe<Scalars['Int']>;
};
export declare type Query = {
    __typename?: 'Query';
    getTodo?: Maybe<Todo>;
    findTodos: TodoResultList;
    getUser?: Maybe<User>;
    findUsers: UserResultList;
    getCactusSyncTimestamp?: Maybe<CactusSyncTimestamp>;
    findCactusSyncTimestamps: CactusSyncTimestampResultList;
};
export declare type QueryGetTodoArgs = {
    id: Scalars['ID'];
};
export declare type QueryFindTodosArgs = {
    filter?: Maybe<TodoFilter>;
    page?: Maybe<PageRequest>;
    orderBy?: Maybe<OrderByInput>;
};
export declare type QueryGetUserArgs = {
    id: Scalars['ID'];
};
export declare type QueryFindUsersArgs = {
    filter?: Maybe<UserFilter>;
    page?: Maybe<PageRequest>;
    orderBy?: Maybe<OrderByInput>;
};
export declare type QueryGetCactusSyncTimestampArgs = {
    id: Scalars['ID'];
};
export declare type QueryFindCactusSyncTimestampsArgs = {
    filter?: Maybe<CactusSyncTimestampFilter>;
    page?: Maybe<PageRequest>;
    orderBy?: Maybe<OrderByInput>;
};
export declare enum SortDirectionEnum {
    Desc = "DESC",
    Asc = "ASC"
}
export declare type StringInput = {
    ne?: Maybe<Scalars['String']>;
    eq?: Maybe<Scalars['String']>;
    le?: Maybe<Scalars['String']>;
    lt?: Maybe<Scalars['String']>;
    ge?: Maybe<Scalars['String']>;
    gt?: Maybe<Scalars['String']>;
    in?: Maybe<Array<Scalars['String']>>;
    contains?: Maybe<Scalars['String']>;
    startsWith?: Maybe<Scalars['String']>;
    endsWith?: Maybe<Scalars['String']>;
};
export declare type Subscription = {
    __typename?: 'Subscription';
    newTodo: Todo;
    updatedTodo: Todo;
    deletedTodo: Todo;
    newUser: User;
    updatedUser: User;
    deletedUser: User;
    newCactusSyncTimestamp: CactusSyncTimestamp;
    updatedCactusSyncTimestamp: CactusSyncTimestamp;
    deletedCactusSyncTimestamp: CactusSyncTimestamp;
};
export declare type SubscriptionNewTodoArgs = {
    filter?: Maybe<TodoSubscriptionFilter>;
};
export declare type SubscriptionUpdatedTodoArgs = {
    filter?: Maybe<TodoSubscriptionFilter>;
};
export declare type SubscriptionDeletedTodoArgs = {
    filter?: Maybe<TodoSubscriptionFilter>;
};
export declare type SubscriptionNewUserArgs = {
    filter?: Maybe<UserSubscriptionFilter>;
};
export declare type SubscriptionUpdatedUserArgs = {
    filter?: Maybe<UserSubscriptionFilter>;
};
export declare type SubscriptionDeletedUserArgs = {
    filter?: Maybe<UserSubscriptionFilter>;
};
export declare type SubscriptionNewCactusSyncTimestampArgs = {
    filter?: Maybe<CactusSyncTimestampSubscriptionFilter>;
};
export declare type SubscriptionUpdatedCactusSyncTimestampArgs = {
    filter?: Maybe<CactusSyncTimestampSubscriptionFilter>;
};
export declare type SubscriptionDeletedCactusSyncTimestampArgs = {
    filter?: Maybe<CactusSyncTimestampSubscriptionFilter>;
};
/**
 * @model
 * @cactusSync
 * TODO: make directive hasId
 * @hasId
 */
export declare type Todo = {
    __typename?: 'Todo';
    id: Scalars['ID'];
    /**
     * The id, which will be created, if
     * the model was created offline
     */
    _clientId?: Maybe<Scalars['ID']>;
    _version: Scalars['Int'];
    _lastUpdatedAt: Scalars['String'];
    title?: Maybe<Scalars['String']>;
    /**
     * @manyToOne(field: 'todos', key: 'userId')
     * @manyToOne(field: 'todos')
     */
    user?: Maybe<User>;
};
export declare type TodoFilter = {
    id?: Maybe<IdInput>;
    _clientId?: Maybe<IdInput>;
    _version?: Maybe<IntInput>;
    _lastUpdatedAt?: Maybe<StringInput>;
    title?: Maybe<StringInput>;
    userId?: Maybe<IdInput>;
    and?: Maybe<Array<TodoFilter>>;
    or?: Maybe<Array<TodoFilter>>;
    not?: Maybe<TodoFilter>;
};
export declare type TodoResultList = {
    __typename?: 'TodoResultList';
    items: Array<Maybe<Todo>>;
    offset?: Maybe<Scalars['Int']>;
    limit?: Maybe<Scalars['Int']>;
    count?: Maybe<Scalars['Int']>;
};
export declare type TodoSubscriptionFilter = {
    and?: Maybe<Array<TodoSubscriptionFilter>>;
    or?: Maybe<Array<TodoSubscriptionFilter>>;
    not?: Maybe<TodoSubscriptionFilter>;
    id?: Maybe<IdInput>;
    _clientId?: Maybe<IdInput>;
    _version?: Maybe<IntInput>;
    _lastUpdatedAt?: Maybe<StringInput>;
    title?: Maybe<StringInput>;
};
/**
 * @model
 * @cactusSync
 */
export declare type User = {
    __typename?: 'User';
    id: Scalars['ID'];
    /**
     * The id, which will be created, if
     * the model was created offline
     */
    _clientId?: Maybe<Scalars['ID']>;
    _version: Scalars['Int'];
    _lastUpdatedAt: Scalars['String'];
    name?: Maybe<Scalars['String']>;
    /**
     * @oneToMany(field: 'user', key: 'userId')
     * @oneToMany(field: 'user')
     */
    todos: Array<Maybe<Todo>>;
};
/**
 * @model
 * @cactusSync
 */
export declare type UserTodosArgs = {
    filter?: Maybe<TodoFilter>;
};
export declare type UserFilter = {
    id?: Maybe<IdInput>;
    _clientId?: Maybe<IdInput>;
    _version?: Maybe<IntInput>;
    _lastUpdatedAt?: Maybe<StringInput>;
    name?: Maybe<StringInput>;
    and?: Maybe<Array<UserFilter>>;
    or?: Maybe<Array<UserFilter>>;
    not?: Maybe<UserFilter>;
};
export declare type UserResultList = {
    __typename?: 'UserResultList';
    items: Array<Maybe<User>>;
    offset?: Maybe<Scalars['Int']>;
    limit?: Maybe<Scalars['Int']>;
    count?: Maybe<Scalars['Int']>;
};
export declare type UserSubscriptionFilter = {
    and?: Maybe<Array<UserSubscriptionFilter>>;
    or?: Maybe<Array<UserSubscriptionFilter>>;
    not?: Maybe<UserSubscriptionFilter>;
    id?: Maybe<IdInput>;
    _clientId?: Maybe<IdInput>;
    _version?: Maybe<IntInput>;
    _lastUpdatedAt?: Maybe<StringInput>;
    name?: Maybe<StringInput>;
};
