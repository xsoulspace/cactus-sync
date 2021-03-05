module.exports = {
  roots: ['<rootDir>/lib'],
  transform: {
    '^.+\\.ts$': 'ts-jest',
  },
  testRegex: '(/lib/.*.(test|spec)).(jsx?|tsx?)$',
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json', 'node'],
  collectCoverage: true,
  coveragePathIgnorePatterns: ['(lib/.*.mock).(jsx?|tsx?)$'],
  verbose: true,
}
