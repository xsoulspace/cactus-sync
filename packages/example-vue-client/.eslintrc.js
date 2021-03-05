module.exports = {
  root: true,
  env: {
    browser: true,
    es2021: true,
    node: true,
  },
  extends: [
    "../../.eslintrc",
    "@vue/typescript/recommended",
    // 他のルールの下に追加
    "@vue/prettier",
    "@vue/prettier/@typescript-eslint",
    "plugin:vue/vue3-recommended",
  ],
  parserOptions: {},
  plugins: [],
  rules: {},
};
