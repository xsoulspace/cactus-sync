part of cactus_abstract;

/// Using notifyListeners mostly to reset states
class CactusSync {
  CactusSync._({final this.graphqlRunner});
  final emitter = CactusEmitter();
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

  /// Sets new graphql runner (for example in case of http endpoint change)
  /// Will notify all states to reset their state.
  static void setRunner({final GraphqlRunner? graphqlRunner}) =>
      db?._setRunner(graphqlRunner);

  GraphqlRunner? graphqlRunner;
  void _setRunner(final GraphqlRunner? _graphqlRunner) {
    if (graphqlRunner == null) return;
    graphqlRunner = _graphqlRunner;
    emitter.add(const CactusResetStateEvent());
  }

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
          TFindResult>
      attachModel<
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
    final CactusModelBuilder<
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
        modelBuilder,
  ) {
    final db = CactusSync.db;
    if (db == null) {
      throw ArgumentError.notNull(
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
