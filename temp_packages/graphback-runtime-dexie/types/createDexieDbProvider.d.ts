import { GraphbackDataProvider } from '@graphback/core';
import Dexie from 'dexie';
/**
 * Creates a new KnexDBDataProvider
 *
 * @param {Db} db - Dexie db not opened instance
 */
export declare function createDexieDbProvider(db: Dexie): (...args: any[]) => GraphbackDataProvider;
//# sourceMappingURL=createDexieDbProvider.d.ts.map