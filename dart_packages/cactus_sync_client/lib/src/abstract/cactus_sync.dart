import 'package:simple_logger/simple_logger.dart';

import 'cactus_model.dart';
import 'graphql_runner.dart';
import 'serializable_model.dart';

// import 'package:';
class CactusSync {
  static CactusSync? db;

  GraphqlRunner graphqlRunner;
  static final l = SimpleLogger();
  CactusSync({required this.graphqlRunner});
  static void init<TCacheShape>({
    required GraphqlRunner graphqlRunner,
    Level loggerLevel = Level.OFF,
    bool loggerIncludeCallerInfo = false,
  }) {
    l.setLevel(
      loggerLevel,
      includeCallerInfo: loggerIncludeCallerInfo,
    );
    CactusSync.db = CactusSync(graphqlRunner: graphqlRunner);
  }

  ///
  /// Start point to include Model into db
  /// Model must be created from GraphQl schema
  ///
  ///
  static CactusModel<
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
      TFindResult> attachModel<
          TModel,
          TCreateInput extends SerializableModel,
          TCreateResult,
          TUpdateInput extends SerializableModel,
          TUpdateResult,
          TDeleteInput extends SerializableModel,
          TDeleteResult,
          TGetInput extends SerializableModel,
          TGetResult,
          TFindInput extends SerializableModel,
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
