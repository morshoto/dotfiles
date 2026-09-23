# Storybook Improvement Patterns

Use these templates as starting points. Adjust names and imports to match the project.

## Meta + Docs Blocks

```tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Title, Description, Primary, Controls, Stories } from '@storybook/blocks';
import { Badge } from './Badge';

const meta: Meta<typeof Badge> = {
  title: 'Components/Badge',
  component: Badge,
  tags: ['autodocs'],
  parameters: {
    layout: 'centered',
    docs: {
      description: {
        component: 'Badges are compact labels for statuses or categories.',
      },
      page: () => (
        <>
          <Title />
          <Description />
          <Primary />
          <Controls />
          <Stories />
        </>
      ),
    },
  },
};

export default meta;
type Story = StoryObj<typeof Badge>;
```

## Args-Driven Stories

```tsx
export const Default: Story = {
  args: {
    children: 'Default',
  },
};

export const Secondary: Story = {
  args: {
    variant: 'secondary',
    children: 'Secondary',
  },
};
```

## Interaction Test (Play Function)

```tsx
import { within, userEvent } from '@storybook/test';

export const Clickable: Story = {
  args: {
    children: 'Click me',
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const badge = await canvas.findByText('Click me');
    await userEvent.click(badge);
  },
};
```

## Global Decorators and Parameters

```tsx
// .storybook/preview.ts
import type { Preview } from '@storybook/react';
import { ThemeProvider } from '../src/theme/ThemeProvider';
import { theme } from '../src/theme/theme';

const preview: Preview = {
  decorators: [
    (Story) => (
      <ThemeProvider theme={theme}>
        <Story />
      </ThemeProvider>
    ),
  ],
  parameters: {
    layout: 'centered',
    controls: { expanded: true },
    backgrounds: { default: 'light' },
  },
};

export default preview;
```

## Addons Configuration

```ts
// .storybook/main.ts
const config = {
  addons: [
    '@storybook/addon-a11y',
    '@storybook/addon-viewport',
    '@storybook/addon-interactions',
  ],
};

export default config;
```
