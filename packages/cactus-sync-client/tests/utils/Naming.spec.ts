import { toPluralName } from '../../lib'

describe('Naming', () => {
  describe('toPluralName', () => {
    test('can turn *h to *hies', () => {
      const match = 'matcH'
      const matches = toPluralName(match)
      expect(matches).toEqual('matcHes')
    })
    test('can turn *y to *ies', () => {
      const supply = 'supply'
      const supplies = toPluralName(supply)
      expect(supplies).toEqual('supplies')
    })
    test('can simply add s', () => {
      const size = 'size'
      const sizes = toPluralName(size)
      expect(sizes).toEqual('sizes')
    })
  })
})
