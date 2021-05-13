import 'cactus_model.dart';
import 'graphql_runner.dart';

class CactusSync {
  static CactusSync? db;

  GraphqlRunner graphqlRunner;
  CactusSync({required this.graphqlRunner});
  static void init<TCacheShape>({required GraphqlRunner graphqlRunner}) {
    CactusSync.db = CactusSync(graphqlRunner: graphqlRunner);
  }

  ///
  /// Start point to include Model into db
  /// Model must be created from GraphQl schema
  ///
  ///
  static CactusModel attachModel<
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
    final db = CactusSync.db;
    if (db == null) {
      throw Exception('''
        You don't have CactusSync db instance! Be aware: 
        CactusSync.init(...) should be called before attachModel!
      ''');
    }
    final model = modelBuilder(db: db);
    db.models.addAll({model.graphqlModelName: model});
    return model;
  }

  /// ============== Replication section ================
  Map<String, CactusModel> models = {};
}
