import uuid4 from 'uuid4'
describe('validateUuid', () => {
  test('Expect to be valid check = true', () => {
    const uuid = 'b82f119f-a180-4866-b6ae-91a562232746'
    const result = uuid4.valid(uuid)
    expect(result).toBeTruthy()
  })
  test('Expect to be wrong & null = false', () => {
    const uuid = 'p;a'
    const result = uuid4.valid(uuid)
    expect(result).toBeFalsy()

    const uuidNull = null
    const resultNull = uuid4.valid(uuidNull)
    expect(resultNull).toBeFalsy()
  })
})
