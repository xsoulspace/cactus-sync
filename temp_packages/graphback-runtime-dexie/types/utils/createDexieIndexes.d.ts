import { Maybe } from '@graphback/core';
import Dexie, { IndexSpec } from 'dexie';
import { GraphQLField, GraphQLObjectType } from 'graphql';
interface DbTableCreate {
    db: Dexie;
    tableName: string;
}
interface ApplyIndexes extends DbTableCreate {
    indexes: Partial<IndexSpec>[];
}
interface FindAndCreateIndexes extends DbTableCreate {
    baseType: GraphQLObjectType;
}
export declare function findAndCreateIndexes({ baseType, db, tableName, }: FindAndCreateIndexes): Promise<void>;
/**
 * Should get correct indexes for filds based on
 * IndexSpec. See more at https://dexie.org/docs/Version/Version.stores()
 * @param indexes
 * @returns {string}
 */
export declare const getIndexedFieldsString: (indexes: Partial<IndexSpec>[]) => string;
export declare function applyIndexes({ tableName, db, indexes }: ApplyIndexes): Promise<void>;
export declare function getIndexFields(baseType: GraphQLObjectType): Partial<IndexSpec>[];
export declare function getCustomIndex(field: GraphQLField<any, any>): Maybe<Partial<IndexSpec>>;
export declare function getRelationIndex(field: GraphQLField<any, any>): Maybe<Partial<IndexSpec>>;
export declare const findDexieTableFieldIndex: ({ indexName, table, }: {
    table: Dexie.Table;
    indexName: string;
}) => Maybe<IndexSpec>;
export {};
//# sourceMappingURL=createDexieIndexes.d.ts.map