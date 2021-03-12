<template>
  <img alt="Vue logo" src="./assets/logo.png" />
  <HelloWorld msg="Hello Vue 3 + TypeScript + Vite" />
  <button @click="findTodos">Find</button>
  {{ foundTodo.title }}
</template>

<script lang="ts">
  import { defineComponent, onMounted, ref } from 'vue'
  import { CreateTodoInput, Todo } from '../../../resources/generatedTypes'
  import HelloWorld from './components/HelloWorld.vue'
  import { todoModel, useTodoState } from './sync/hooks'

  export default defineComponent({
    name: 'App',
    components: {
      HelloWorld,
    },
    setup() {
      const todoState = useTodoState()
      onMounted(async () => {
        const todos: CreateTodoInput[] = [
          {
            _version: 1,
            _lastUpdatedAt: Date.now().toString(),
            title: 'Hello World!',
          },
          {
            _version: 1,
            _lastUpdatedAt: Date.now().toString(),
            title: 'Hello Mars!',
          },
        ]
        for (const todo of todos) {
          await todoModel.add({
            input: todo,
          })
        }
        todoState.find()
      })
      const foundTodo = ref<Partial<Todo>>({})
      const findTodos = async () => {
        const result = (
          await todoModel.find({
            filter: { title: { contains: 'Mars' } },
          })
        ).data?.items[0]
        if (result) foundTodo.value = result
      }
      return { findTodos, foundTodo }
    },
  })
</script>

<style>
  #app {
    font-family: Avenir, Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-align: center;
    color: #2c3e50;
    margin-top: 60px;
  }
</style>
