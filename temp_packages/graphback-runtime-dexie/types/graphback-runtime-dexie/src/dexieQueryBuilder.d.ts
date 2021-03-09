import { QueryFilter, TableID } from '@graphback/core';
import { Collection } from 'dexie';
import { Maybe } from 'graphql/jsutils/Maybe';
import { DexieDBDataProvider } from './DexieDBDataProvider';
export declare enum RootQueryOperator {
    'and' = "and",
    'or' = "or",
    'not' = "not"
}
export declare enum GraphbackQueryOperator {
    'eq' = "eq",
    'ne' = "ne",
    'lt' = "lt",
    'le' = "le",
    'gt' = "gt",
    'ge' = "ge",
    'between' = "between",
    'in' = "in",
    'contains' = "contains",
    'startsWith' = "startsWith",
    'endsWith' = "endsWith"
}
export declare type DexieWhereClauses = keyof Dexie.WhereClause;
export declare enum DexieFilterTypes {
    'Filter' = "Filter",
    'WhereClause' = "WhereClause"
}
export interface DexieQueryMapParam {
    isIndexed: boolean;
    filterType: DexieFilterTypes;
    whereClauseOperator?: Maybe<DexieWhereClauses>;
    queryOperator?: Maybe<GraphbackQueryOperator>;
    rootOperator?: Maybe<RootQueryOperator>;
    value: Maybe<unknown>;
    fieldName: string;
}
export interface DexieQueryMap {
    [fieldName: string]: Maybe<Maybe<DexieQueryMapParam>[]>;
}
interface QueryBuilder<TType> {
    filter: Maybe<QueryFilter<TType>>;
    idField: TableID;
    provider: DexieDBDataProvider<TType>;
}
/**
 * Work principle:
 * 1. Flat filter to DexieQueryMap (QueryBuilder)
 * 2. Execute DexieQueryMap (QueryRunner)
 * @param filter
 */
export declare const queryBuilder: <TType>({ filter, idField, provider, }: QueryBuilder<TType>) => Maybe<DexieQueryMap>;
/**
 * Build a Dexie query from a Graphback filter.
 * To run query use runQuery
 *
 * @param {QueryFilter} filter
 */
export declare const buildQuery: <TType = any>(arg: QueryBuilder<TType>) => Maybe<DexieQueryMap>;
interface RunQuery<TType> {
    query: DexieQueryMap;
    provider: DexieDBDataProvider<TType>;
}
export declare const runQuery: <TType = any>({ provider, query, }: RunQuery<TType>) => Collection<TType, string>;
export declare function convertFieldQueryToStringCondition({ condition, fieldQuery, tableValue, }: {
    tableValue: unknown;
    condition: string;
    fieldQuery: DexieQueryMapParam;
}): {
    condition: string;
    postfix: string;
};
export declare function validateTableEntry<TType = any>({ tableEntry, queryEntires, }: {
    tableEntry: TType;
    queryEntires: [
        DexieQueryMapParam['fieldName'],
        Maybe<Maybe<DexieQueryMapParam>[]>
    ][];
}): any;
export {};
//# sourceMappingURL=dexieQueryBuilder.d.ts.map