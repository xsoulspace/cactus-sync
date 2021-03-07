// import { IResolvers } from 'apollo-server-express'
// import { QueryFilter } from 'graphback'
// import { GraphQLResolveInfo } from 'graphql'
// import { GraphQLContext } from '../customContext'
// import { NoteFilter } from '../generated-types'

// export const noteResolvers: IResolvers = {
//   Query: {
//     getDraftNotes: async (
//       parent: any,
//       args: any,
//       context: GraphQLContext,
//       info: GraphQLResolveInfo
//     ) => {
//       const filter: QueryFilter<NoteFilter> = {
//         title: {
//           startsWith: '[DRAFT]',
//         },
//       }

//       const results = await context.graphback.Note.findBy(
//         { filter },
//         context,
//         info
//       )

//       return results.items
//     },
//   },
// }
