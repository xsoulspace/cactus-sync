"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.findDexieTableFieldIndex = exports.getRelationIndex = exports.getCustomIndex = exports.getIndexFields = exports.applyIndexes = exports.getIndexedFieldsString = exports.findAndCreateIndexes = void 0;
const tslib_1 = require("tslib");
const core_1 = require("@graphback/core");
const graphql_metadata_1 = require("graphql-metadata");
const lodash_1 = require("lodash");
function findAndCreateIndexes({ baseType, db, tableName, }) {
    return tslib_1.__awaiter(this, void 0, void 0, function* () {
        const indexes = getIndexFields(baseType);
        yield applyIndexes({ indexes, db, tableName });
    });
}
exports.findAndCreateIndexes = findAndCreateIndexes;
/**
 * Should get correct indexes for filds based on
 * IndexSpec. See more at https://dexie.org/docs/Version/Version.stores()
 * @param indexes
 * @returns {string}
 */
const getIndexedFieldsString = (indexes) => {
    const strArr = indexes.reduce((indexesArr, indexSpec) => {
        if (indexSpec.compound) {
            const arr = indexSpec.keyPath != null && Array.isArray(indexSpec.keyPath)
                ? indexSpec.keyPath
                : [indexSpec.keyPath];
            const finalStr = `[${arr.join('+')}]`;
            indexesArr.push(finalStr);
            return indexesArr;
        }
        // see more at https://dexie.org/docs/Version/Version.stores()
        const getSymbol = (field) => {
            switch (field) {
                case 'auto':
                    return '++';
                case 'compound':
                    return '';
                case 'keyPath':
                    return '';
                case 'multi':
                    return '*';
                case 'name':
                    return '';
                case 'src':
                    return '';
                case 'unique':
                    return '&';
            }
        };
        const getFieldSymbol = () => {
            for (const [field, value] of Object.entries(indexSpec)) {
                if (field != 'name' && value != null) {
                    const sym = getSymbol(field);
                    return sym;
                }
            }
            return '';
        };
        const indexName = indexSpec.name;
        const sym = getFieldSymbol();
        const finalIndex = `${sym}${indexName}`;
        indexesArr.push(finalIndex);
        return indexesArr;
    }, []);
    const strIndexes = strArr
        .filter((el) => {
        if (el == null || el.length == 0)
            return false;
        return true;
    })
        .join(',');
    return strIndexes;
};
exports.getIndexedFieldsString = getIndexedFieldsString;
function applyIndexes({ tableName, db, indexes }) {
    return tslib_1.__awaiter(this, void 0, void 0, function* () {
        try {
            const strIndexedFields = exports.getIndexedFieldsString(indexes);
            if (strIndexedFields.length === 0)
                throw Error('At least one primary key must bew defined.');
            db.version(db.verno == null || db.verno < 1 ? 1 : db.verno).stores({
                [tableName]: strIndexedFields,
            });
        }
        catch (error) {
            // let message: string;
            // if (error.codeName === 'IndexOptionsConflict') {
            //   // This Index exists but with a different name
            //   message = `${error.errmsg}, try dropping the existing index or using the same name.`;
            // }
            // if (error.codeName === 'IndexKeySpecsConflict') {
            //   // Another Index with same name exists
            //   message = `${error.errmsg}, try manually dropping the existing index or using a different name.`;
            // }
            // if (error.codeName === 'InvalidIndexSpecificationOption') {
            //   // Invalid options passed to @index
            //   message = `${error.errmsg}, try double checking what you are passing to @index.`;
            // }
            // if (message == undefined) {
            //   message = `Graphback was unable to create the specified indexes: ${error.message}.`;
            // }
            // TODO: implement erorrs
            // eslint-disable-next-line no-console
            console.error(`${error} If all else fails, try recreating the index manually.`);
        }
    });
}
exports.applyIndexes = applyIndexes;
function getIndexFields(baseType) {
    const res = [];
    const reserveFieldPrimaryKeys = [];
    const fields = baseType.getFields();
    for (const field of Object.values(fields)) {
        // Add Index on relation fields
        const relationIndex = getRelationIndex(field);
        if (relationIndex != null) {
            res.push(relationIndex);
            continue;
        }
        // Add custom Index if found e.g. @index
        const customIndex = getCustomIndex(field);
        if (customIndex != null) {
            res.push(customIndex);
            continue;
        }
        const fieldType = lodash_1.toString(JSON.parse(JSON.stringify(field.type)));
        if (fieldType == 'GraphbackObjectID!') {
            const maybeId = { name: field.name, unique: true };
            if (field.name === '_id' || field.name === 'id') {
                res.push(maybeId);
            }
            else {
                reserveFieldPrimaryKeys.push(maybeId);
            }
        }
        else if (fieldType.includes('GraphbackObjectID')) {
            throw Error('Model has id but it not pointed as required. Use GraphbackObjectID! instead of GraphbackObjectID');
        }
    }
    if (res.length == 0) {
        if (reserveFieldPrimaryKeys.length == 0)
            throw Error('Model must have at least one primary key!');
        // push if any keys were reserved
        res.push(reserveFieldPrimaryKeys[0]);
    }
    return res;
}
exports.getIndexFields = getIndexFields;
function getCustomIndex(field) {
    const indexMetadata = field.description
        ? graphql_metadata_1.parseMetadata('index', field.description)
        : null;
    if (indexMetadata) {
        const indexSpec = {
            name: field.name,
        };
        if (typeof indexMetadata === 'object') {
            // unwrappinng case of proxy
            const obj = JSON.parse(JSON.stringify(indexMetadata));
            if (obj.hasOwnProperty('key')) {
                const key = obj['key'];
                if (key != null) {
                    indexSpec.keyPath = Object.keys(key);
                    switch (indexSpec.keyPath.length) {
                        case 2:
                            indexSpec.compound = true;
                            break;
                        case 0:
                            // nothing
                            break;
                        default:
                            console.error(`Custom index for field: ${field.name} have ${indexSpec.keyPath.length} keys but can have only 2`);
                    }
                }
            }
        }
        return indexSpec;
    }
    else {
        return null;
    }
}
exports.getCustomIndex = getCustomIndex;
function getRelationIndex(field) {
    const relationshipData = field.description
        ? core_1.parseRelationshipAnnotation(field.description)
        : null;
    if ((relationshipData === null || relationshipData === void 0 ? void 0 : relationshipData.kind) &&
        ['manyToOne', 'manyToMany'].includes(relationshipData.kind)) {
        return {
            name: relationshipData.key,
        };
    }
    else {
        return null;
    }
}
exports.getRelationIndex = getRelationIndex;
const findDexieTableFieldIndex = ({ indexName, table, }) => {
    const indexes = table.schema.indexes;
    const foundIndex = indexes.find((index) => index.name == indexName);
    if (foundIndex)
        return foundIndex;
    // check primary key as it will be indexed, but not included in indexes
    const primaryKey = table.schema.primKey;
    if (primaryKey.name === indexName)
        return primaryKey;
    return null;
};
exports.findDexieTableFieldIndex = findDexieTableFieldIndex;
//# sourceMappingURL=createDexieIndexes.js.map