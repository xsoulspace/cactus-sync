"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateTableEntry = exports.convertFieldQueryToStringCondition = exports.runQuery = exports.buildQuery = exports.queryBuilder = exports.DexieFilterTypes = exports.GraphbackQueryOperator = exports.RootQueryOperatorSet = exports.RootQueryOperator = void 0;
const escapeRegex = require("escape-string-regexp");
var RootQueryOperator;
(function (RootQueryOperator) {
    RootQueryOperator["and"] = "and";
    RootQueryOperator["or"] = "or";
    RootQueryOperator["not"] = "not";
})(RootQueryOperator = exports.RootQueryOperator || (exports.RootQueryOperator = {}));
exports.RootQueryOperatorSet = new Set(Object.keys(RootQueryOperator));
// A map to transform Graphql operators to typescript
const tsRootQueryOperator = {
    and: '&&',
    not: '!=',
    or: '||',
};
const isRootOperator = (key) => exports.RootQueryOperatorSet.has(key);
var GraphbackQueryOperator;
(function (GraphbackQueryOperator) {
    GraphbackQueryOperator["eq"] = "eq";
    GraphbackQueryOperator["ne"] = "ne";
    GraphbackQueryOperator["lt"] = "lt";
    GraphbackQueryOperator["le"] = "le";
    GraphbackQueryOperator["gt"] = "gt";
    GraphbackQueryOperator["ge"] = "ge";
    GraphbackQueryOperator["between"] = "between";
    GraphbackQueryOperator["in"] = "in";
    GraphbackQueryOperator["contains"] = "contains";
    GraphbackQueryOperator["startsWith"] = "startsWith";
    GraphbackQueryOperator["endsWith"] = "endsWith";
})(GraphbackQueryOperator = exports.GraphbackQueryOperator || (exports.GraphbackQueryOperator = {}));
// A map to transform Graphql operators to typescript
const tsGraphbackQueryOperator = {
    eq: '==',
    ne: '!=',
    lt: '<',
    le: '<=',
    gt: '>',
    ge: '>=',
    between: 'between',
    in: 'in',
    contains: 'contains',
    startsWith: 'startsWith',
    endsWith: 'endsWith',
};
const GraphbackQueryOperatorSet = new Set(Object.keys(GraphbackQueryOperator));
const isGraphbackQueryOperator = (key) => GraphbackQueryOperatorSet.has(key);
const isPrimitive = (test) => test instanceof RegExp || test !== Object(test);
var DexieFilterTypes;
(function (DexieFilterTypes) {
    DexieFilterTypes["Filter"] = "Filter";
    DexieFilterTypes["WhereClause"] = "WhereClause";
})(DexieFilterTypes = exports.DexieFilterTypes || (exports.DexieFilterTypes = {}));
/**
 * Work principle:
 * 1. Flat filter to DexieQueryMap (QueryBuilder)
 * 2. Execute DexieQueryMap (QueryRunner)
 * @param filter
 */
const queryBuilder = ({ filter, idField, provider, }) => {
    if (filter == null)
        return undefined;
    const dexieQueryMap = {};
    const fillField = (fieldName, fieldState) => {
        if (isRootOperator(fieldName)) {
            return Object.assign(Object.assign({}, fieldState), { rootOperator: fieldName });
        }
        if (isGraphbackQueryOperator(fieldName)) {
            return Object.assign(Object.assign({}, fieldState), { queryOperator: fieldName });
        }
        // suppose that field is table.field name
        // then we need to:
        return Object.assign(Object.assign({}, fieldState), { filterType: DexieFilterTypes.Filter, fieldName });
    };
    const flatifyValues = (filterValue, fieldState) => {
        var _a, _b;
        if (isPrimitive(filterValue)) {
            const fieldName = (_a = fieldState === null || fieldState === void 0 ? void 0 : fieldState.fieldName) !== null && _a !== void 0 ? _a : idField.name;
            const isFieldIndexed = provider['isFieldIndexed'](fieldName);
            const arr = (_b = dexieQueryMap[fieldName]) !== null && _b !== void 0 ? _b : [];
            arr.push(Object.assign(Object.assign({}, fieldState), { 
                // FIXME: when WhereClause will be ready replace to
                // isFieldIndexed ? DexieFilterTypes.WhereClause : DexieFilterTypes.Filter
                filterType: DexieFilterTypes.Filter, isIndexed: isFieldIndexed, value: filterValue, fieldName }));
            dexieQueryMap[fieldName] = arr;
        }
        else {
            for (const [fieldName, value] of Object.entries(filterValue)) {
                if (Array.isArray(value)) {
                    const arrFieldState = fillField(fieldName, fieldState);
                    // TODO: implement between and array conditions
                    if (arrFieldState.queryOperator == GraphbackQueryOperator.between) {
                        const [first, second] = value;
                        flatifyValues(first, Object.assign(Object.assign({}, arrFieldState), { queryOperator: GraphbackQueryOperator.ge }));
                        flatifyValues(second, Object.assign(Object.assign({}, arrFieldState), { queryOperator: GraphbackQueryOperator.le }));
                    }
                    else {
                        for (const val of value) {
                            flatifyValues(val, arrFieldState);
                        }
                    }
                    continue;
                }
                const updatedState = fillField(fieldName, fieldState);
                // suppose that field is table.field name
                // then we need to:
                if (value)
                    flatifyValues(value, updatedState);
            }
        }
    };
    flatifyValues(filter);
    return dexieQueryMap;
};
exports.queryBuilder = queryBuilder;
/**
 * Build a Dexie query from a Graphback filter.
 * To run query use runQuery
 *
 * @param {QueryFilter} filter
 */
const buildQuery = (arg) => exports.queryBuilder(arg);
exports.buildQuery = buildQuery;
const runQuery = ({ provider, query, }) => {
    const table = provider['getTable']();
    const queryEntires = Object.entries(query);
    const result = table.filter((tableEntry) => {
        const isPass = validateTableEntry({
            queryEntires,
            tableEntry,
        });
        return isPass;
    });
    return result;
};
exports.runQuery = runQuery;
const toString = (anything) => {
    switch (typeof anything) {
        case 'string':
            return anything;
        case 'boolean':
        case 'number':
        case 'symbol':
            return anything.toString();
        default:
            return JSON.stringify(anything);
    }
};
const cleanUpDoubleQuotes = (str) => str.replace(/"([^"]+(?="))"/g, '$1');
function convertFieldQueryToStringCondition({ condition, fieldQuery, tableValue, }) {
    let prePostfix = tsRootQueryOperator.and;
    const compareValue = fieldQuery.value;
    if (compareValue == null)
        return { condition, postfix: prePostfix };
    if (fieldQuery.rootOperator != null) {
        prePostfix = tsRootQueryOperator[fieldQuery.rootOperator];
    }
    let valueComparation = '';
    let isValidValue = false;
    if (fieldQuery.queryOperator != null) {
        const strCompareValue = cleanUpDoubleQuotes(toString(fieldQuery.value));
        const strTableValue = cleanUpDoubleQuotes(toString(tableValue));
        const validateByMatch = (escaptedRegex) => {
            var _a;
            return (((_a = strTableValue.match(new RegExp(escaptedRegex, 'gim'))) !== null && _a !== void 0 ? _a : []).length > 0);
        };
        switch (fieldQuery.queryOperator) {
            case GraphbackQueryOperator.eq:
            case GraphbackQueryOperator.ge:
            case GraphbackQueryOperator.gt:
            case GraphbackQueryOperator.le:
            case GraphbackQueryOperator.lt:
            case GraphbackQueryOperator.ne:
                const operator = tsGraphbackQueryOperator[fieldQuery.queryOperator];
                valueComparation = `"${strTableValue}" ${operator} "${strCompareValue}"`;
                break;
            case GraphbackQueryOperator.in:
                switch (prePostfix) {
                    case tsRootQueryOperator.and:
                    case tsRootQueryOperator.or:
                        isValidValue = strTableValue == strCompareValue;
                        break;
                    default:
                        valueComparation = `"${strTableValue}" ${prePostfix} "${strCompareValue}"`;
                        break;
                }
                break;
            case GraphbackQueryOperator.between:
                // if we here, then something went wrong because beetwen must be divided to le ge...
                // abort
                break;
            case GraphbackQueryOperator.contains:
                isValidValue = validateByMatch(escapeRegex(strCompareValue));
                break;
            case GraphbackQueryOperator.endsWith:
                isValidValue = validateByMatch(`${escapeRegex(strCompareValue)}$`);
                break;
            case GraphbackQueryOperator.startsWith:
                isValidValue = validateByMatch(`^${escapeRegex(strCompareValue)}`);
                break;
            default:
                throw Error(`Operator ${fieldQuery.queryOperator} is not supported!`);
        }
    }
    const finalValueComparation = valueComparation.length
        ? valueComparation
        : isValidValue;
    if (condition.length == 0) {
        condition = `${condition}${finalValueComparation}`;
    }
    else {
        condition = `${condition}${prePostfix}${finalValueComparation}`;
    }
    return { condition, postfix: prePostfix };
}
exports.convertFieldQueryToStringCondition = convertFieldQueryToStringCondition;
function validateTableEntry({ tableEntry, queryEntires, }) {
    var _a;
    const fnConditions = [];
    const queryCount = queryEntires.length;
    let i = 0;
    for (const [fieldName, fieldQueries] of queryEntires) {
        i++;
        let rootPostfix = tsRootQueryOperator.and;
        const isNotLastQuery = i != queryCount;
        if (fieldQueries == null)
            continue;
        const filterType = (_a = fieldQueries[0]) === null || _a === void 0 ? void 0 : _a.filterType;
        switch (filterType) {
            case DexieFilterTypes.WhereClause:
                // TODO:
                break;
            case DexieFilterTypes.Filter:
            default:
                const tableValue = tableEntry[fieldName];
                const fnQueryCondition = fieldQueries.reduce((condition, fieldQuery) => {
                    if (fieldQuery == null)
                        return condition;
                    // depending from condition it can be or post or prefix
                    const result = convertFieldQueryToStringCondition({
                        tableValue,
                        condition,
                        fieldQuery,
                    });
                    rootPostfix = result.postfix;
                    return result.condition;
                }, '');
                fnConditions.push(`( ${fnQueryCondition} )`);
        }
        if (isNotLastQuery) {
            fnConditions.push(rootPostfix);
        }
    }
    const fnBody = `function(){return ${fnConditions.join(` `)};}`;
    const fn = new Function('return ' + fnBody);
    const isValid = fn()();
    return isValid;
}
exports.validateTableEntry = validateTableEntry;
//# sourceMappingURL=dexieQueryBuilder.js.map