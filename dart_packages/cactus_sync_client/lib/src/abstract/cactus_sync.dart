import 'package:graphql/client.dart';
import 'package:simple_logger/simple_logger.dart';

import 'cactus_model.dart';
import 'graphql_runner.dart';

class CactusSync {
  CactusSync._({this.graphqlRunner});

  static CactusSync init<TCacheShape>({
    required final GraphqlRunner graphqlRunner,
    final Level loggerLevel = Level.OFF,
    final bool loggerIncludeCallerInfo = false,
  }) {
    l.setLevel(
      loggerLevel,
      includeCallerInfo: loggerIncludeCallerInfo,
    );
    final db = CactusSync._(graphqlRunner: graphqlRunner);
    if (CactusSync.db != null) {
      l.info('CactusSync is already intialized');
    } else {
      CactusSync.db = db;
    }
    return db;
  }

  static CactusSync? db;
  static bool get isInitialized => db != null;
  static void setRunner({GraphqlRunner? graphqlRunner}) {
    if (graphqlRunner == null) return;
    db?.graphqlRunner = graphqlRunner;
  }

  GraphqlRunner? graphqlRunner;

  static final l = SimpleLogger();

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
      TGetResult,
      TFindInput,
      TFindResult> attachModel<
          TModel,
          TCreateInput extends JsonSerializable,
          TCreateResult,
          TUpdateInput extends JsonSerializable,
          TUpdateResult,
          TDeleteInput extends JsonSerializable,
          TDeleteResult,
          TGetResult,
          TFindInput extends JsonSerializable,
          TFindResult>(
      CactusModelBuilder<
              TModel,
              TCreateInput,
              TCreateResult,
              TUpdateInput,
              TUpdateResult,
              TDeleteInput,
              TDeleteResult,
              TGetResult,
              TFindInput,
              TFindResult>
          modelBuilder) {
    final db = CactusSync.db;
    if (db == null) {
      throw Exception(
        '''
        You don't have CactusSync db instance! Be aware: 
        CactusSync.init(...) should be called before attachModel!
        ''',
      );
    }
    final model = modelBuilder(db: db);
    db.models.addAll({model.graphqlModelName: model});
    return model;
  }

  /// ============== Replication section ================
  Map<String, CactusModel> models = {};
}
