"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createDexieDbProvider = void 0;
const DexieDBDataProvider_1 = require("./DexieDBDataProvider");
/**
 * Creates a new KnexDBDataProvider
 *
 * @param {Db} db - Dexie db not opened instance
 */
function createDexieDbProvider(db) {
    return (model) => {
        return new DexieDBDataProvider_1.DexieDBDataProvider(model, db);
    };
}
exports.createDexieDbProvider = createDexieDbProvider;
//# sourceMappingURL=createDexieDbProvider.js.map