import 'dart:async';

import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:gql/language.dart' as gql_lang;
import "package:gql/schema.dart" as gql_schema;
import 'package:indent/indent.dart';

import '../utils/utils.dart';

class ModelBuilder implements Builder {
  String _getModelProvider({
    required String camelModelName,
    required String properModelType,
  }) {
    return '''
        final use${camelModelName}State = Provider<$properModelType>((_)=>
          CactusStateModel<$properModelType>()
        );
      ''';
  }

  StringBuffer _getModelProviders({
    required Iterable<gql_schema.TypeDefinition?> operationTypes,
  }) {
    final strBuffer = StringBuffer();
    for (final type in operationTypes) {
      if (type == null) continue;
      final typeName = type.name;
      // print(gql_lang.printNode());

      if (typeName == null || isSystemType(typeName: typeName)) continue;
      final strModelsBuffer = _generateCactusModels(
        properModelType: typeName,
      );
      strBuffer.writeln(strModelsBuffer);
    }
    return strBuffer;
  }

  /// Use it to generate inputs for mutations
  /// and queries
  StringBuffer _getInputClasses({
    required List<gql_schema.InputObjectTypeDefinition> inputObjectTypes,
  }) {
    final finalClasses = StringBuffer();
    for (final item in inputObjectTypes) {
      final List<Field> fieldsDiefinitions = [];
      final List<Parameter> defaultConstructorInitializers = [];
      for (final gqlField in item.fields) {
        final gqlFieldName = gqlField.name;
        if (gqlFieldName == null) continue;

        final typeName = gqlField.type?.baseTypeName;
        if (typeName == null) continue;

        fieldsDiefinitions.add(
          Field(
            (f) {
              f
                ..name = gqlFieldName
                ..type = refer(typeName)
                ..docs.add(gqlField.description ?? '');
            },
          ),
        );
        defaultConstructorInitializers.add(
          Parameter(
            (p) => p
              ..toThis = true
              ..named = true
              ..required = true
              ..name = gqlFieldName,
          ),
        );
      }

      final defaultConstructor = Constructor(
        (c) => c
          ..name = item.name
          ..constant = true
          ..requiredParameters.addAll(
            defaultConstructorInitializers,
          ),
      );

      final inputClass = Class(
        (b) => b
          ..name = item.name
          ..abstract = true
          ..fields.addAll(fieldsDiefinitions)
          ..constructors.addAll([defaultConstructor])
        // ..methods.add(Method.returnsVoid((b) => b
        //   ..name = 'eat'
        //   ..body = const Code("print('Yum');")))
        ,
      );
      final emitter = DartEmitter();
      final strigifiedInputClass = DartFormatter().format(
        inputClass.accept(emitter).toString(),
      );
      finalClasses.writeln(strigifiedInputClass);
    }

    return finalClasses;
  }

  StringBuffer _generateCactusModels({
    required String properModelType,
  }) {
    final pluralProperModelName = properModelType.toPluralName();
    final strBuffer = StringBuffer();
    final properModelName = '${properModelType}Model';

    final camelModelName = '${properModelType.toCamelCase()}Model';

    final defaultFragmentName = '${properModelType}Fragment';

    final mutationCreateArgs = 'MutationCreate${properModelType}Args';
    final mutationCreateResult =
        '{ create$properModelType: Maybe<$properModelType> }';

    final mutationUpdateArgs = 'MutationUpdate${properModelType}Args';
    final mutationUpdateResult =
        '{ update$properModelType: Maybe<$properModelType> }';

    final mutationDeleteArgs = 'MutationDelete${properModelType}Args';
    final mutationDeleteResult =
        '{ delete$properModelType: Maybe<$properModelType> }';

    final queryGetArgs = 'QueryGet${properModelType}Args';
    final queryGetResult = '{ get$properModelType: Maybe<$properModelType> }';

    final queryFindArgs = 'QueryFind${pluralProperModelName}Args';
    final queryFindResult = '${properModelType}ResultList';
    final queryFindResultI = '{ find$pluralProperModelName: $queryFindResult}';
    const defaultFragment = '';
    final modelStr = '''
        final $properModelName = CactusSync.attachModel(
          CactusModel.init<
            $properModelType,
            $mutationCreateArgs,
            $mutationCreateResult,
            $mutationUpdateArgs,
            $mutationUpdateResult,
            $mutationDeleteArgs,
            $mutationDeleteResult,
            $queryGetArgs,
            $queryGetResult,
            $queryFindArgs,
            $queryFindResultI
          >(graphqlModelType: $defaultFragment)б
        );
      ''';
    final providerStr = _getModelProvider(
        camelModelName: camelModelName, properModelType: properModelType);
    strBuffer.writeAll([providerStr, modelStr], "\n");
    return strBuffer;
  }

  bool isSystemType({required String typeName}) =>
      typeName.contains('_') || typeName.toLowerCase() == 'query';
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    // Retrieve the currently matched asset
    final inputId = buildStep.inputId;

    /// Create new target
    final copyAssetId = inputId.changeExtension('.dart');
    final originContentStr = await buildStep.readAsString(inputId);
    final schemaDocument = gql_lang.parseString(originContentStr);
    final schema = gql_schema.buildSchema(schemaDocument);
    final operationTypes = schema.typeMap;
    final finalModels = StringBuffer();

    // final modelProviders = _getModelProviders(
    //   operationTypes: operationTypes.values,
    // );

    final inputClasses = _getInputClasses(
      inputObjectTypes: schema.inputObjectTypes,
    );

    // finalModels.writeln(modelProviders);

    finalModels.writeln(inputClasses);

    final finalContent = """
      import 'package:cactus_sync_client/cactus_sync_client.dart';
      import 'package:riverpod/riverpod.dart';

      /// !------------ CAUTION ------------!
      /// Autogenerated file. Please do not edit it manually!
      /// Updated: ${DateTime.now()}
      /// !---------- END CAUTION ----------!

      $finalModels
    """;

    await buildStep.writeAsString(copyAssetId, finalContent.unindent());
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '.graphql': [".dart"]
      };
}

// interface PluginConfig {
//   withVueState?: boolean
//   schemaTypesPath?: string
//   useDefaultFragments?: boolean
//   defaultFragmentsPath?: string
//   modelsGraphqlSchemaPath?: string
//   cactusSyncConfigPath?: string
//   cactusSyncConfigHookName?: string
// }

// const toCamelCase = (str: string) => {
//   const first = str[0].toLowerCase()
//   const rest = str.substring(1)
//   return `${first}${rest}`
// }
// async (schema: GraphQLSchema, _documents, config: PluginConfig) {
//     // ============== Config settings ======================

//     const {
//       withVueState,
//       schemaTypesPath,
//       useDefaultFragments,
//       defaultFragmentsPath,
//       modelsGraphqlSchemaPath,
//       cactusSyncConfigPath,
//       cactusSyncConfigHookName,
//     } = config
//     const importVueStateModel = withVueState ? ', VueStateModel' : ''
//     const typesPath = schemaTypesPath ?? './generatedTypes'
//     const fragmentsPath = defaultFragmentsPath ?? '../gql'
//     const graphqlSchemaPath = modelsGraphqlSchemaPath ?? './models.graphql?raw'
//     const configPath = cactusSyncConfigPath ?? './config'
//     const configHookName = cactusSyncConfigHookName ?? 'useCactusSyncInit'
//     // ============ Filtering types only ====================

//     const types = Object.values(schema.getTypeMap()).filter((el) =>
//       isObjectType(el)
//     )
//     const exportModelStrings: string[] = []
//     const typesModels: string[] = []
//     const fragments: string[] = []
//     for (const type of types) {

//       const args = [
//         mutationCreateArgs,
//         mutationUpdateArgs,
//         mutationDeleteArgs,
//         queryGetArgs,
//         queryFindArgs,
//         queryFindResult,
//       ]
//       typesModels.push(...args, name)

//       const modelName = `${camelName}Model`

//       // ============ Model generation ====================
//       const defaultFragmentName = `${name}Fragment`
//       const defaultFragment = (() => {
//         if (useDefaultFragments) {
//           fragments.push(defaultFragmentName)
//           return `, defaultModelFragment: ${defaultFragmentName}`
//         } else {
//           return ''
//         }
//       })()
//       let modelStr = endent`
//       export const ${modelName}= CactusSync.attachModel(
//         CactusModel.init<
//           ${name},
//           ${mutationCreateArgs},
//           ${mutationCreateResult},
//           ${mutationUpdateArgs},
//           ${mutationUpdateResult},
//           ${mutationDeleteArgs},
//           ${mutationDeleteResult},
//           ${queryGetArgs},
//           ${queryGetResult},
//           ${queryFindArgs},
//           ${queryFindResultI}
//         >({ graphqlModelType: schema.getType('${name}') as Maybe<GraphQLObjectType> ${defaultFragment}})
//       )
//       `
//       if (withVueState) {
//         modelStr = endent`
//           ${modelStr}
//           export const use${name}State = () => new VueStateModel({ cactusModel: ${modelName} })
//           export type ${name}State = VueStateModel<
//               ${name},
//               ${mutationCreateArgs},
//               ${mutationCreateResult},
//               ${mutationUpdateArgs},
//               ${mutationUpdateResult},
//               ${mutationDeleteArgs},
//               ${mutationDeleteResult},
//               ${queryGetArgs},
//               ${queryGetResult},
//               ${queryFindArgs},
//               ${queryFindResultI}
//             >
//         `
//       }
//       exportModelStrings.push(modelStr)
//     }

//     const modelsExportStr = exportModelStrings.join('\n')
//     const fragmentsImportStr = useDefaultFragments
//       ? endent`import {${fragments.join(',\n')}} from '${fragmentsPath}'`
//       : ''
//     return endent`
    
//       /* eslint-disable */
//       import { GraphQLObjectType, buildSchema } from 'graphql'
//       ${fragmentsImportStr}
//       import { ${typesModels.join(' ,\n ')} } from '${typesPath}'
//       import { CactusSync, CactusModel ${importVueStateModel}, Maybe } from '@xsoulspace/cactus-sync-client'
//       import strSchema from '${graphqlSchemaPath}'
//       import {${configHookName}} from '${configPath}'
      
//       ${configHookName}()

//       const schema = buildSchema(strSchema)

//       ${modelsExportStr}
      
//       console.log('Cactus Sync hooks initialized')

//     `
// }

