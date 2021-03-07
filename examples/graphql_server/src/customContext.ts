import { GraphbackContext } from 'graphback'

/**
 * Overriding context to add GraphQL-Code-Generator typings to Graphback services
 */
export interface GraphQLContext extends GraphbackContext {
  graphback: {}
}
