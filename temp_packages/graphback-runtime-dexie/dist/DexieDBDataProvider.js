"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DexieDBDataProvider = void 0;
const tslib_1 = require("tslib");
const core_1 = require("@graphback/core");
const dexieQueryBuilder_1 = require("./dexieQueryBuilder");
const createDexieIndexes_1 = require("./utils/createDexieIndexes");
const isNotNull_1 = require("./utils/isNotNull");
const objectId_1 = require("./utils/objectId");
/**
 * Graphback provider that connnects to the Dexie database
 */
class DexieDBDataProvider {
    constructor(model, db) {
        this.verifyDBPrimaryKey(model.graphqlType.name, model.primaryKey);
        this.db = db;
        this.tableMap = core_1.buildModelTableMap(model.graphqlType);
        this.tableName = this.tableMap.tableName;
        this.fieldSet = new Set(Object.keys(model.fields));
        // FIXME: what is it and why it needed?
        this.fieldTransformMap = core_1.getFieldTransformations(model.graphqlType);
        createDexieIndexes_1.findAndCreateIndexes({
            baseType: model.graphqlType,
            db,
            tableName: this.tableName,
        }).catch((e) => {
            throw e;
        });
    }
    create(data) {
        return tslib_1.__awaiter(this, void 0, void 0, function* () {
            const { data: createData, idField } = core_1.getDatabaseArguments(this.tableMap, data);
            if (idField == null)
                throw Error('no idField found');
            this.addObjectId(createData, idField);
            const table = this.getTable();
            const maybeId = yield table.add(createData);
            if (maybeId) {
                const createdType = yield table.get(maybeId);
                if (createdType)
                    return createdType;
            }
            throw new core_1.NoDataError(`Cannot create ${this.tableName}`);
        });
    }
    update(data, selectedFields) {
        return tslib_1.__awaiter(this, void 0, void 0, function* () {
            const { idField, data: updateData } = core_1.getDatabaseArguments(this.tableMap, data);
            const castUpdatedData = updateData;
            if ((idField === null || idField === void 0 ? void 0 : idField.value) == null)
                throw new core_1.NoDataError(`Cannot update ${this.tableName} - missing ID field`);
            if (castUpdatedData == null)
                throw new core_1.NoDataError(`Cannot update ${this.tableName} - missing updating data`);
            const table = this.getTable();
            const maybeId = yield (() => tslib_1.__awaiter(this, void 0, void 0, function* () {
                if (this.verifyTypeIntegrity(castUpdatedData)) {
                    return yield table.put(castUpdatedData);
                }
                else {
                    yield table.update(idField.value, castUpdatedData);
                    return idField.value;
                }
            }))();
            if (maybeId) {
                const result = yield (() => tslib_1.__awaiter(this, void 0, void 0, function* () {
                    const updated = yield table.get(maybeId);
                    if (updated) {
                        if (selectedFields) {
                            return this.getSelectedFieldsFromType(selectedFields, updated);
                        }
                        else {
                            return updated;
                        }
                    }
                    return null;
                }))();
                if (result)
                    return result;
            }
            throw new core_1.NoDataError(`Cannot update ${this.tableName}`);
        });
    }
    delete(data, selectedFields) {
        return tslib_1.__awaiter(this, void 0, void 0, function* () {
            const { idField } = core_1.getDatabaseArguments(this.tableMap, data);
            if ((idField === null || idField === void 0 ? void 0 : idField.value) == null)
                throw new core_1.NoDataError(`Cannot delete ${this.tableName} - missing ID field`);
            try {
                const table = this.getTable();
                const id = data[idField.name];
                const dbObj = yield table.get(id);
                const dbType = yield (() => tslib_1.__awaiter(this, void 0, void 0, function* () {
                    if (selectedFields && dbObj) {
                        return this.getSelectedFieldsFromType(selectedFields, dbObj);
                    }
                    return dbObj;
                }))();
                yield table.delete(id);
                if (dbType)
                    return dbType;
                throw Error();
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
                return selectedFields
                    ? this.getSelectedFieldsFromType(selectedFields, data)
                    : data;
            }
            throw new core_1.NoDataError(`Cannot find a result for ${this.tableName} with filter: ${JSON.stringify(filter)}`);
        });
    }
    findBy(args, selectedFields) {
        return tslib_1.__awaiter(this, void 0, void 0, function* () {
            /**
             * How it should work:
             * - If the search in indexed field, then
             * it uses Dexie WhereCause
             * - If the search in non indexed field, then
             * it uses Dexie Filter
             *
             * For now it uses only Filter
             *
             */
            const { idField } = core_1.getDatabaseArguments(this.tableMap);
            if (idField == null)
                throw Error('cannot find idField');
            const isQuery = (maybeQuery) => {
                if (maybeQuery == null)
                    return false;
                for (const key of Object.keys(maybeQuery)) {
                    if (this.fieldSet.has(key))
                        return true;
                    if (dexieQueryBuilder_1.RootQueryOperatorSet.has(key))
                        return true;
                }
                return false;
            };
            const getQuery = () => {
                if (args === null || args === void 0 ? void 0 : args.filter)
                    return args === null || args === void 0 ? void 0 : args.filter;
                return isQuery(args) ? args : null;
            };
            const filterQuery = dexieQueryBuilder_1.buildQuery({
                filter: getQuery(),
                idField,
                provider: this,
            });
            const result = yield (() => tslib_1.__awaiter(this, void 0, void 0, function* () {
                if (filterQuery == null || Object.keys(filterQuery).length == 0) {
                    return this.getTable().toArray();
                }
                return yield dexieQueryBuilder_1.runQuery({
                    provider: this,
                    query: filterQuery,
                }).toArray();
            }))();
            const data = this.usePage(this.sortQuery(result, args === null || args === void 0 ? void 0 : args.orderBy), args === null || args === void 0 ? void 0 : args.page);
            if (data)
                return selectedFields ? this.getSelectedData(data, selectedFields) : data;
            throw new core_1.NoDataError(`Cannot find all results for ${this.tableName} with filter: ${JSON.stringify(args === null || args === void 0 ? void 0 : args.filter)}`);
        });
    }
    count(filter) {
        return tslib_1.__awaiter(this, void 0, void 0, function* () {
            const { idField } = core_1.getDatabaseArguments(this.tableMap);
            if (idField == null)
                throw Error('cannot find idField');
            const filterQuery = dexieQueryBuilder_1.buildQuery({
                filter: filter,
                idField,
                provider: this,
            });
            if (filterQuery == null || Object.keys(filterQuery).length == 0) {
                return yield this.getTable().count();
            }
            const result = dexieQueryBuilder_1.runQuery({
                provider: this,
                query: filterQuery,
            });
            return yield result.count();
        });
    }
    batchRead(relationField, ids, filter, selectedFields) {
        var _a;
        return tslib_1.__awaiter(this, void 0, void 0, function* () {
            filter = filter || {};
            filter[relationField] = { in: ids };
            const { idField } = core_1.getDatabaseArguments(this.tableMap);
            if (idField == null)
                throw Error('cannot find idField');
            const filterQuery = dexieQueryBuilder_1.buildQuery({
                filter: filter,
                idField,
                provider: this,
            });
            let result = yield (() => tslib_1.__awaiter(this, void 0, void 0, function* () {
                if (filterQuery == null || Object.keys(filterQuery).length == 0) {
                    return yield this.getTable().toArray();
                }
                return yield dexieQueryBuilder_1.runQuery({
                    provider: this,
                    query: filterQuery,
                }).toArray();
            }))();
            const toUseSelectedFields = selectedFields != null &&
                selectedFields.length != Object.keys((_a = result[0]) !== null && _a !== void 0 ? _a : {}).length;
            if (result) {
                // result = this.validateForObjectId(result)
                // To not force check for every loop
                // we divide mothod into two - with selected fields and without
                const prepareResults = (pushFn) => {
                    return ids.map((objId) => {
                        const objectsForId = [];
                        for (const data of result) {
                            if (data[relationField].toString() === objId.toString()) {
                                pushFn(data, objectsForId);
                            }
                        }
                        return objectsForId;
                    });
                };
                const resultsById = (() => {
                    const pushRawFn = (data, objectsForId) => {
                        if (selectedFields == null)
                            throw Error('You used wrong method. Please use pushWithSelectedFieldsFn to get results');
                        const cuttedType = this.getSelectedFieldsFromType(selectedFields, data);
                        objectsForId.push(cuttedType);
                    };
                    const pushWithSelectedFieldsFn = (data, objectsForId) => {
                        objectsForId.push(data);
                    };
                    return toUseSelectedFields
                        ? prepareResults(pushWithSelectedFieldsFn)
                        : prepareResults(pushRawFn);
                })();
                return resultsById;
            }
            throw new core_1.NoDataError(`No results for ${this.tableName} query and batch read with filter: ${JSON.stringify(filter)}`);
        });
    }
    getTable() {
        return this.db.table(this.tableName);
    }
    getSelectedFields(selectedFields) {
        return (selectedFields === null || selectedFields === void 0 ? void 0 : selectedFields.length) ? selectedFields : '*';
    }
    addObjectId(data, idField) {
        // getting id field name
        if (idField.value == null) {
            // if id is empty generate new one, as Dexie will no generate it
            // and auto increment is too simple. But IndexedDb not supported
            // ObjectId as primary key, so we will use id of IndexedDb
            // see more https://bugzilla.mozilla.org/show_bug.cgi?id=1357636
            const newObjectId = objectId_1.parseObjectID(null);
            idField.value = newObjectId.toHexString();
            data[idField.name] = idField.value;
        }
        else {
            // handle case if id already an objectId
            const isValid = objectId_1.isObjectID(idField.value);
            if (isValid) {
                switch (typeof idField.value) {
                    case 'string':
                        // nothing to change
                        break;
                    case 'object':
                        idField.value = idField.value.toHexString();
                        data[idField.name] = idField.value;
                }
            }
        }
    }
    /**
     * in case if we request all properties then just return all
     * @param data
     * @param selectedFields
     * @returns
     */
    getSelectedData(data, selectedFields) {
        const obj = data[0];
        if (obj == null)
            return [];
        if (Object.keys(obj).length == selectedFields.length) {
            return data.filter(isNotNull_1.isNotNull);
        }
        return data.reduce((acc, el) => {
            if (el)
                acc.push(this.getSelectedFieldsFromType(selectedFields, el));
            return acc;
        }, []);
    }
    getSelectedFieldsFromType(selectedFields, type) {
        const obj = {};
        for (const field of this.getSelectedFields(selectedFields)) {
            obj[field] = type[field];
        }
        return obj;
    }
    verifyDBPrimaryKey(modelName, primaryKey) {
        if (primaryKey.name === '_id' && primaryKey.type === 'GraphbackObjectID') {
            throw Error(`Model "${modelName}" must contain a "id: ID!" primary key instead of _id: GraphbackObjectID!. 
      If you use are using MongoDb - it not supported.
      Visit https://graphback.dev/docs/model/datamodel#postgres to see how to 
      set up one for your Postgres model.`);
        }
        if (primaryKey.name === 'id' && primaryKey.type === 'ID') {
            return;
        }
        throw Error(`Model "${modelName}" must contain a "id: ID!" primary key. Visit https://graphback.dev/docs/model/datamodel#postgres to see how to set up one for your Postgres model.`);
    }
    verifyTypeIntegrity(data) {
        const fields = Object.keys(data);
        for (const field of fields) {
            if (!this.fieldSet.has(field))
                return false;
        }
        if (this.fieldSet.size != fields.length)
            return false;
        return true;
    }
    get indexedFieldsSet() {
        const isOpen = this.db.isOpen();
        if (isOpen) {
            const table = this.getTable();
            const indexesSet = new Set(table.schema.indexes.map((el) => el.name));
            indexesSet.add(table.schema.primKey.name);
            return indexesSet;
        }
        return new Set();
    }
    isFieldIndexed(fieldName) {
        return this.indexedFieldsSet.has(fieldName);
    }
    sortQuery(query, orderBy) {
        var _a;
        if (orderBy == null)
            return query;
        if (orderBy.field && orderBy.field.length > 0) {
            query = query.sort((a, b) => {
                const fieldA = a[orderBy.field];
                const fieldB = b[orderBy.field];
                if (fieldA < fieldB)
                    return -1;
                if (fieldA > fieldB)
                    return 1;
                return 0;
            });
        }
        if (((_a = orderBy === null || orderBy === void 0 ? void 0 : orderBy.order) === null || _a === void 0 ? void 0 : _a.toLowerCase()) === 'desc')
            return query.reverse();
        return query;
    }
    usePage(query, page) {
        if (page == null)
            return query;
        const { offset, limit } = page;
        if (offset != null && offset < 0)
            throw new Error('Invalid offset value. Please use an offset of greater than or equal to 0 in queries');
        if (limit != null && limit < 1)
            throw new Error('Invalid limit value. Please use a limit of greater than 1 in queries');
        // emulating correct limits and offsets
        if (offset && limit == null) {
            query = query.slice(offset);
        }
        else if (offset && limit) {
            query = query.slice(offset, limit + offset);
        }
        else if ((offset == null || offset == 0) && limit != null) {
            query.length = limit;
        }
        return query;
    }
}
exports.DexieDBDataProvider = DexieDBDataProvider;
//# sourceMappingURL=DexieDBDataProvider.js.map