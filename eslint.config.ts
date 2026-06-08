import type { Plugin } from '@eslint/core';
import eslint from '@eslint/js';
import prettierRecommended from 'eslint-plugin-prettier/recommended';
import react from 'eslint-plugin-react';
import reactHooks from 'eslint-plugin-react-hooks';
import { defineConfig } from 'eslint/config';
import globals from 'globals';
import tseslint from 'typescript-eslint';

export default defineConfig([
  eslint.configs.recommended,
  tseslint.configs.recommended,
  prettierRecommended,
  {
    rules: {
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-unused-vars': 'error'
    }
  },
  {
    files: ['app/javascript/components/**/*.{ts,tsx,js,jsx}'],
    ...react.configs.flat.recommended,
    ...react.configs.flat['jsx-runtime']
  },
  {
    files: ['app/javascript/components/**/*.{ts,tsx,js,jsx}'],
    // eslint-plugin-react-hooks v7 types its self-referential `configs.flat`
    // in a way that isn't assignable to ESLint's `Plugin` interface; cast to
    // satisfy defineConfig's stricter type checking.
    plugins: { 'react-hooks': reactHooks as unknown as Plugin },
    rules: {
      ...reactHooks.configs.recommended.rules,
      'react/prop-types': 'off',
      'react-hooks/exhaustive-deps': 'error'
    }
  },
  {
    files: ['app/javascript/**/*.{ts,tsx,js,jsx}'],
    languageOptions: { globals: { ...globals.browser } }
  },
  {
    files: ['*.config.{ts,js}'],
    languageOptions: { globals: { ...globals.node } }
  }
]);
