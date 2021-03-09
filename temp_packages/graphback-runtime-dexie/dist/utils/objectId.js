"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getObjectIDTimestamp = exports.parseObjectID = exports.isObjectID = void 0;
const bson_1 = require("bson");
/* eslint-disable */
function isObjectID(value) {
    const isBsonObjectId = (val) => val instanceof bson_1.ObjectID;
    if (isBsonObjectId(value))
        return true;
    let isBsonExtObjectID = () => false;
    try {
        const BsonExtObjectID = require('bson-ext').ObjectID;
        isBsonExtObjectID = (val) => val instanceof BsonExtObjectID;
        if (isBsonExtObjectID(value))
            return true;
    }
    catch (_a) { }
    try {
        switch (typeof value) {
            case 'string':
                const parsedObjectId = parseObjectID(value);
                if (parsedObjectId.toHexString() == value) {
                    return true;
                }
                break;
        }
    }
    catch (_b) { }
    return false;
}
exports.isObjectID = isObjectID;
function parseObjectID(value) {
    let ObjectID = bson_1.ObjectID;
    try {
        ObjectID = require('bson-ext').ObjectID; // always prefer the native bson extension which is more performant than js-bson
    }
    catch (_a) { }
    return new ObjectID(value);
}
exports.parseObjectID = parseObjectID;
function getObjectIDTimestamp(value) {
    if (typeof value == 'string' && isObjectID(value)) {
        const objectId = parseObjectID(value);
        return objectId.getTimestamp();
    }
    return value.getTimestamp();
}
exports.getObjectIDTimestamp = getObjectIDTimestamp;
/* eslint-enable */
//# sourceMappingURL=objectId.js.map