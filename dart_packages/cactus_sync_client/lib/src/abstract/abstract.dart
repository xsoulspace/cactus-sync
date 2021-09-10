library cactus_client_abstract;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:gql/language.dart' as gql_lang;
import 'package:gql_http_link/gql_http_link.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:riverpod/riverpod.dart';
import 'package:simple_logger/simple_logger.dart';

import '../graphql/graphql.dart';
import '../utils/utils.dart';

part 'cactus_events.dart';
part 'cactus_model.dart';
part 'cactus_model_state.dart';
part 'cactus_sync.dart';
part 'graphback_result_list.dart';
part 'graphql_runner.dart';
part 'recorded_model.dart';
