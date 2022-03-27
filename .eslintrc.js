module.exports = {
    env: {
        commonjs: true,
        es2020: true,
        node: true,
    },
    extends: ['eslint:recommended', 'plugin:prettier/recommended'],
    plugins: ['eslint-plugin-prettier'],
    parserOptions: {
        ecmaVersion: 11,
    },
    rules: {
        'prettier/prettier': [
            'error',
            {
                printWidth: 120,
                tabWidth: 4,
                singleQuote: true,
                trailingComma: 'es5',
            },
        ],
    },
};
