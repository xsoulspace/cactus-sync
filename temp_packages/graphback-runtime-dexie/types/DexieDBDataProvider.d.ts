import { FieldTransformMap, FindByArgs, GraphbackDataProvider, ModelDefinition, ModelTableMap, QueryFilter } from '@graphback/core';
import Dexie from 'dexie';
/**
 * Graphback provider that connnects to the Dexie database
 */
export declare class DexieDBDataProvider<Type = any> implements GraphbackDataProvider<Type> {
    protected db: Dexie;
    protected tableName: string;
    protected tableMap: ModelTableMap;
    protected fieldTransformMap: FieldTransformMap;
    constructor(model: ModelDefinition, db: Dexie);
    create(data: Type): Promise<Type>;
    update(data: Partial<Type>, selectedFields?: string[]): Promise<Type>;
    delete(data: Partial<Type>, selectedFields?: string[]): Promise<Type>;
    findOne(filter: Partial<Type>, selectedFields?: string[]): Promise<Type>;
    findBy(_args?: FindByArgs, _selectedFields?: string[]): Promise<Type[]>;
    count(_filter?: QueryFilter): Promise<number>;
    batchRead(_relationField: string, _ids: string[], _filter?: QueryFilter, _selectedFields?: string[]): Promise<Type[][]>;
    protected getTable(): import("dexie").Table<Type, string>;
    protected getSelectedFields(selectedFields: string[]): string[] | "*";
    protected getSelectedFieldsFromType(selectedFields: string[], type: Type): Type;
    private verifyMongoDBPrimaryKey;
}
//# sourceMappingURL=DexieDBDataProvider.d.ts.map