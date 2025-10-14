import { render, screen } from '@testing-library/react';
import App from './App';

test('renders GCP Landing Zone Deployment header', () => {
  render(<App />);
  const headerElement = screen.getByText(/GCP Landing Zone Deployment/i);
  expect(headerElement).toBeInTheDocument();
});
