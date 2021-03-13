<template>
  <img alt="Vue logo" src="./assets/logo.png" />
  <HelloWorld msg="Hello Vue 3 + TypeScript + Vite" />
  <button @click="addTodo">Add to original state</button>
  <button @click="addTodoModel">Add via standalone model</button>
  <div>
    <span>List Original</span>
    <div v-for="todo in todoList" :key="todo.id">
      <div>
        <p>{{ todo.title }}</p>
        <p><button @click="removeTodo(todo)">x</button></p>
      </div>
    </div>
  </div>
  <div>
    <span>List Duplicates</span>
    <div v-for="todo in todoDuplicateList" :key="todo.id">
      <div>{{ todo.title }}</div>
      <p><button @click="removeTodo(todo)">x</button></p>
    </div>
  </div>
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
      const todoDubplicateState = useTodoState()
      const counter = ref(1)
      onMounted(async () => {
        const isReplicating = await todoModel.startReplication()
        console.log({ isReplicating })

        todoState.find()
      })
      const addTodo = async (arg?: { standalone?: boolean }) => {
        const todo: CreateTodoInput = {
          _version: 1,
          _lastUpdatedAt: Date.now().toString(),
          title: `New todo ${counter.value}`,
        }
        counter.value++
        if (arg?.standalone) {
          await todoModel.add({
            input: todo,
          })
        } else {
          await todoState.add({
            input: todo,
          })
        }
      }
      const addTodoModel = () => addTodo({ standalone: true })
      const removeTodo = async (todo: Todo) => {
        await todoState.remove({
          input: {
            id: todo.id,
          },
        })
      }

      return {
        addTodo,
        addTodoModel,
        removeTodo,
        todoList: todoState.list,
        todoDuplicateList: todoDubplicateState.list,
      }
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
