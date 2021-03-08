import Dexie, { IndexSpec } from 'dexie';
import { GraphQLField, GraphQLObjectType } from 'graphql';
export declare function findAndCreateIndexes(baseType: GraphQLObjectType, table: Dexie.Table): Promise<void>;
export declare function applyIndexes(indexes: IndexSpec[], table: Dexie.Table): Promise<void>;
export declare function getIndexFields(baseType: GraphQLObjectType): IndexSpec[];
export declare function getCustomIndex(field: GraphQLField<any, any>): IndexSpec;
//# sourceMappingURL=createIndexes.d.ts.map