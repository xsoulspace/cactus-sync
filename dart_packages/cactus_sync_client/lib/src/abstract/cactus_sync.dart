import 'package:cactus_sync_client/src/abstract/cactus_model.dart';
import 'package:cactus_sync_client/src/abstract/graphql_runner.dart';

class CactusSync {
  static CactusSync? db;

  GraphqlRunner graphqlRunner;
  CactusSync({required this.graphqlRunner});
  static init<TCacheShape>({required GraphqlRunner graphqlRunner}) {
    CactusSync.db = new CactusSync(graphqlRunner: graphqlRunner);
  }

  ///
  /// Start point to include Model into db
  /// Model must be created from GraphQl schema
  ///
  ///
  static attachModel<
          TModel,
          TCreateInput,
          TCreateResult,
          TUpdateInput,
          TUpdateResult,
          TDeleteInput,
          TDeleteResult,
          TGetInput,
          TGetResult,
          TFindInput,
          TFindResult>(
      CactusModelBuilder<
              TModel,
              TCreateInput,
              TCreateResult,
              TUpdateInput,
              TUpdateResult,
              TDeleteInput,
              TDeleteResult,
              TGetInput,
              TGetResult,
              TFindInput,
              TFindResult>
          modelBuilder) {
    var db = CactusSync.db;
    if (db == null) throw Exception('''
        You don't have CactusSync db instance! Be aware: 
        CactusSync.init(...) should be called before attachModel!
      ''');
    var model = modelBuilder(db: db);
    db.models.addAll({model.modelName: model});
    return model;
  }

  /// ============== Replication section ================
  Map<String, CactusModel> models = {};
}
