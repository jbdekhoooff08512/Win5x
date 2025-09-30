import '@testing-library/jest-dom';
import { vi } from 'vitest';

// Mock framer-motion globally
vi.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }: any) => {
      const React = require('react');
      return React.createElement('div', props, children);
    },
  },
}));

// Mock environment variables
Object.defineProperty(import.meta, 'env', {
  value: {
    DEV: true,
  },
  writable: true,
});
