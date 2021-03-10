import endent from 'endent'
import { GraphQLSchema, isObjectType } from 'graphql-compose/lib/graphql'
// NOTE: Do not change this function directly. First change it in utils/Naming, run tests
// and only then apply here
const toPluralName = (str: string) => {
  const lastLetter = str.substr(str.length - 1).toLowerCase()
  let newStr = str.toString()
  switch (lastLetter) {
    case 'h':
      newStr = `${newStr}es`
      return newStr
    case 'y':
      newStr = newStr.substr(0, newStr.length - 1)
      newStr = `${newStr}ies`
      return newStr

    default:
      return `${str}s`
  }
}

interface PluginConfig {
  withVueState?: boolean
  schemaTypesPath?: string
  useDefaultFragments?: boolean
  defaultFragmentsPath?: string
}

const toCamelCase = (str: string) => {
  const first = str[0].toLowerCase()
  const rest = str.substring(1)
  return `${first}${rest}`
}
module.exports = {
  plugin: async (schema: GraphQLSchema, _documents, config: PluginConfig) => {
    // ============== Config settings ======================

    const {
      withVueState,
      schemaTypesPath,
      useDefaultFragments,
      defaultFragmentsPath,
    } = config
    const importVueStateModel = withVueState ? ', VueStateModel' : ''
    const typesPath = schemaTypesPath ?? './generatedTypes'
    const fragmentsPath = defaultFragmentsPath ?? '../gql'
    // ============ Filtering types only ====================

    const types = Object.values(schema.getTypeMap()).filter((el) =>
      isObjectType(el)
    )
    const exportModelStrings: string[] = []
    const typesModels: string[] = []
    const fragments: string[] = []
    for (const type of types) {
      const name = type.name
      const isSystemType = name.includes('_') || name.toLowerCase() == 'query'
      if (isSystemType) continue
      const camelName = toCamelCase(name)
      const pluralName = toPluralName(name)
      // ============ Generic generation =================

      const mutationCreateArgs = `MutationCreate${name}Args`
      const mutationCreateResult = `{ create${name}: Maybe<${name}> }`

      const mutationUpdateArgs = `MutationUpdate${name}Args`
      const mutationUpdateResult = `{ update${name}: Maybe<${name}> }`

      const mutationDeleteArgs = `MutationDelete${name}Args`
      const mutationDeleteResult = `{ delete${name}: Maybe<${name}> }`

      const queryGetArgs = `QueryGet${name}Args`
      const queryGetResult = `{ get${name}: Maybe<${name}> }`

      const queryFindArgs = `QueryFind${pluralName}Args`
      const queryFindResult = `${name}ResultList`

      const args = [
        mutationCreateArgs,
        mutationUpdateArgs,
        mutationDeleteArgs,
        queryGetArgs,
        queryFindArgs,
        queryFindResult,
      ]
      typesModels.push(...args, name)

      const modelName = `${camelName}Model`

      // ============ Model generation ====================
      const defaultFragmentName = `${name}Fragment`
      const defaultFragment = (() => {
        if (useDefaultFragments) {
          fragments.push(defaultFragmentName)
          return `, defaultModelFragment: ${defaultFragmentName}`
        } else {
          return ''
        }
      })()
      let modelStr = endent`
      export const ${modelName}= CactusSync.attachModel(
        CactusModel.init<
          ${name},
          ${mutationCreateArgs},
          ${mutationCreateResult},
          ${mutationUpdateArgs},
          ${mutationUpdateResult},
          ${mutationDeleteArgs},
          ${mutationDeleteResult},
          ${queryGetArgs},
          ${queryGetResult},
          ${queryFindArgs},
          ${queryFindResult},
          PageRequest, 
          OrderByInput
        >({ graphqlModelType: schema.getType('${name}') as Maybe<GraphQLObjectType> ${defaultFragment}})
      )
      `
      if (withVueState) {
        modelStr = endent`
          ${modelStr}
          export const use${name}State = new VueStateModel({ cactusModel: ${modelName} })
        `
      }
      exportModelStrings.push(modelStr)
    }

    const modelsExportStr = exportModelStrings.join('\n')
    const fragmentsImportStr = useDefaultFragments
      ? endent`import {${fragments.join(',\n')}} from '${fragmentsPath}'`
      : ''
    return endent`
    
      /* eslint-disable */
      import { ${typesModels.join(
        ' ,\n '
      )}, PageRequest, OrderByInput} from '${typesPath}'
      ${fragmentsImportStr}
      import path from 'path'
      import { CactusSync, CactusModel ${importVueStateModel} } from '@xsoulspace/cactus-sync-client'
      import { GraphQLFileLoader, loadSchemaSync, Maybe } from 'graphql-tools'
      import { GraphQLObjectType } from 'graphql'
      
      const schemaPath = path.resolve(
        __dirname,
        './schema.graphql'
      )
      const schema = loadSchemaSync(schemaPath, {
        loaders: [new GraphQLFileLoader()],
      })

      ${modelsExportStr}

    `
  },
}
