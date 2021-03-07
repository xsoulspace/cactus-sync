"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DexieDBDataProvider = void 0;
const tslib_1 = require("tslib");
const core_1 = require("@graphback/core");
// interface SortOrder {
//   [fieldName: string]: 1 | -1;
// }
/**
 * Graphback provider that connnects to the Dexie database
 */
class DexieDBDataProvider {
    constructor(model, db) {
        this.verifyMongoDBPrimaryKey(model.graphqlType.name, model.primaryKey);
        this.db = db;
        this.tableMap = core_1.buildModelTableMap(model.graphqlType);
        this.tableName = this.tableMap.tableName;
        // FIXME: what is it and why it needed?
        this.fieldTransformMap = core_1.getFieldTransformations(model.graphqlType);
        // findAndCreateIndexes(model.graphqlType, this.db, this.tableName).catch(
        //   (e: Error) => {
        //     throw e;
        //   },
        // );
    }
    create(data) {
        return tslib_1.__awaiter(this, void 0, void 0, function* () {
            // getting id field name
            const { data: createData } = core_1.getDatabaseArguments(this.tableMap, data);
            const table = this.db.table(this.tableName);
            const maybeId = yield table.add(createData);
            if (maybeId)
                return yield table.get(maybeId);
            throw new core_1.NoDataError(`Cannot create ${this.tableName}`);
        });
    }
    update(data, selectedFields) {
        return tslib_1.__awaiter(this, void 0, void 0, function* () {
            const { idField, data: updateData } = core_1.getDatabaseArguments(this.tableMap, data);
            if (!idField.value) {
                throw new core_1.NoDataError(`Cannot update ${this.tableName} - missing ID field`);
            }
            const table = this.getTable();
            const maybeId = yield table.put(updateData);
            if (maybeId) {
                const result = yield table.get(maybeId, (value) => this.getSelectedFieldsFromType(selectedFields, value));
                return result;
            }
            throw new core_1.NoDataError(`Cannot update ${this.tableName}`);
        });
    }
    delete(data, selectedFields) {
        return tslib_1.__awaiter(this, void 0, void 0, function* () {
            const { idField } = core_1.getDatabaseArguments(this.tableMap, data);
            if (!idField.value) {
                throw new core_1.NoDataError(`Cannot delete ${this.tableName} - missing ID field`);
            }
            try {
                const table = this.getTable();
                const id = data[idField.value];
                const dbType = yield (() => tslib_1.__awaiter(this, void 0, void 0, function* () {
                    const dbObj = yield table.get(id);
                    return this.getSelectedFieldsFromType(selectedFields, dbObj);
                }))();
                yield table.delete(id);
                return dbType;
            }
            catch (error) {
                throw new core_1.NoDataError(`Cannot delete ${this.tableName} with ${JSON.stringify(data)}`);
            }
        });
    }
    findOne(filter, selectedFields) {
        return tslib_1.__awaiter(this, void 0, void 0, function* () {
            const table = this.getTable();
            const data = yield table.where(filter).first();
            if (data) {
                return this.getSelectedFieldsFromType(selectedFields, data);
            }
            throw new core_1.NoDataError(`Cannot find a result for ${this.tableName} with filter: ${JSON.stringify(filter)}`);
        });
    }
    findBy(_args, _selectedFields) {
        return tslib_1.__awaiter(this, void 0, void 0, function* () {
            // const filterQuery = buildQuery(args?.filter);
            // const compare = (arg: Partial<Type>) => {
            //   const objToCompare = {};
            //   for (const field of Object.keys(filter)) {
            //     objToCompare[field] = arg[field];
            //   }
            //   return _.isEqual(objToCompare, filter);
            // };
            // TODO: implement query builder
            // const query = this.getTable().find(filterQuery, { projection });
            // const data = await this.usePage(
            //   this.sortQuery(query, args?.orderBy),
            //   args?.page,
            // );
            // if (data) {
            //   return data.map((el) =>
            //     this.getSelectedFieldsFromType(selectedFields, el),
            //   );
            // }
            // throw new NoDataError(
            //   `Cannot find all results for ${
            //     this.tableName
            //   } with filter: ${JSON.stringify(args?.filter)}`,
            // );
            return [];
        });
    }
    count(_filter) {
        return tslib_1.__awaiter(this, void 0, void 0, function* () {
            // return await this.getTable().where(buildQuery(filter)).count();
            return yield this.getTable().count();
        });
    }
    batchRead(_relationField, _ids, _filter, _selectedFields) {
        return tslib_1.__awaiter(this, void 0, void 0, function* () {
            // filter = filter || {};
            // filter[relationField] = { in: ids };
            // const result = await this.db
            //   .collection(this.tableName)
            //   .find(buildQuery(filter), { projection })
            //   .toArray();
            // if (result) {
            //   const resultsById = ids.map((objId: string) => {
            //     const objectsForId: any = [];
            //     for (const data of result) {
            //       if (data[relationField].toString() === objId.toString()) {
            //         objectsForId.push(data);
            //       }
            //     }
            //     return objectsForId;
            //   });
            //   return resultsById as [Type[]];
            // }
            // throw new NoDataError(
            //   `No results for ${
            //     this.tableName
            //   } query and batch read with filter: ${JSON.stringify(filter)}`,
            // );
            return [];
        });
    }
    getTable() {
        return this.db.table(this.tableName);
    }
    getSelectedFields(selectedFields) {
        return (selectedFields === null || selectedFields === void 0 ? void 0 : selectedFields.length) ? selectedFields : '*';
    }
    getSelectedFieldsFromType(selectedFields, type) {
        const obj = {};
        for (const field of this.getSelectedFields(selectedFields)) {
            obj[field] = type[field];
        }
        return obj;
    }
    verifyMongoDBPrimaryKey(modelName, primaryKey) {
        if (primaryKey.name === '_id' && primaryKey.type === 'GraphbackObjectID') {
            return;
        }
        throw Error(`Model "${modelName}" must contain a "_id: GraphbackObjectID" primary key. Visit https://graphback.dev/docs/model/datamodel#mongodb to see how to set up one for your MongoDB model.`);
    }
}
exports.DexieDBDataProvider = DexieDBDataProvider;
//# sourceMappingURL=DexieDBDataProvider.js.map