import { FieldTransformMap, FindByArgs, GraphbackDataProvider, ModelDefinition, ModelTableMap, QueryFilter, TableID } from '@graphback/core';
import Dexie from 'dexie';
import { Maybe } from 'graphql/jsutils/Maybe';
/**
 * Graphback provider that connnects to the Dexie database
 */
export declare class DexieDBDataProvider<Type = any> implements GraphbackDataProvider<Type> {
    protected db: Dexie;
    protected tableName: string;
    protected tableMap: ModelTableMap;
    protected fieldTransformMap: FieldTransformMap;
    protected fieldSet: Set<keyof Type | string>;
    constructor(model: ModelDefinition, db: Dexie);
    create(data: Type): Promise<Type>;
    update(data: Partial<Type>, selectedFields?: string[]): Promise<Type>;
    delete(data: Partial<Type>, selectedFields?: string[]): Promise<Type>;
    findOne(filter: Partial<Type>, selectedFields?: string[]): Promise<Type>;
    findBy(args?: FindByArgs, selectedFields?: string[]): Promise<Type[]>;
    count(filter?: QueryFilter): Promise<number>;
    batchRead(relationField: string, ids: string[], filter?: QueryFilter, selectedFields?: string[]): Promise<Type[][]>;
    protected getTable(): import("dexie").Table<Type, string>;
    protected getSelectedFields(selectedFields: string[]): string[] | "*";
    protected fixObjectIdForDexie(data: Partial<Type>, idField: TableID): void;
    protected validateForObjectId(data: Type): Type;
    protected validateForObjectId(data: Type[]): Type[];
    /**
     * in case if we request all properties then just return all
     * @param data
     * @param selectedFields
     * @returns
     */
    protected getSelectedData(data: Maybe<Type>[], selectedFields: string[]): Type[];
    protected getSelectedFieldsFromType(selectedFields: string[], type: Type): Type;
    private verifyMongoDBPrimaryKey;
    protected verifyTypeIntegrity(data: Partial<Type>): data is Type;
    protected get indexedFieldsSet(): Set<unknown>;
    protected isFieldIndexed(fieldName: string): boolean;
    private sortQuery;
    private usePage;
}
//# sourceMappingURL=DexieDBDataProvider.d.ts.map