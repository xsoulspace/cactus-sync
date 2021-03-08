import { CactusSync } from './CactusSync'
CactusSync.dependencies.indexedDB = require('fake-indexeddb')
CactusSync.dependencies.IDBKeyRange = require('fake-indexeddb/lib/FDBKeyRange')
describe('CactusSync', () => {
  test('should init', async () => {
    await CactusSync.init({})
    expect(CactusSync.db).toBeTruthy()
  })
})
