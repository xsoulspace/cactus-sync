import { CactusSync } from '../../lib'
CactusSync.dependencies.indexedDB = require('fake-indexeddb')
CactusSync.dependencies.IDBKeyRange = require('fake-indexeddb/lib/FDBKeyRange')
describe('CactusSync', () => {
  test('can init db with graphql runtime', async () => {
    await CactusSync.init({})
    expect(CactusSync.db).toBeTruthy()
  })
})
