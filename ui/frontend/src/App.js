import React, { useState } from 'react';
import { ThemeProvider, CssBaseline, Container, Grid, Typography, Paper } from '@mui/material';
import theme from './theme';
import DeploymentWizard from './DeploymentWizard';
import DeploymentStatus from './DeploymentStatus';

function App() {
  const [deploymentOutput, setDeploymentOutput] = useState('');

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <Typography variant="h1" component="h1" gutterBottom>
              GCP Landing Zone Deployment
            </Typography>
          </Grid>
          <Grid item xs={12} md={8}>
            <Paper sx={{ p: 3 }}>
              <DeploymentWizard setDeploymentOutput={setDeploymentOutput} />
            </Paper>
          </Grid>
          <Grid item xs={12} md={4}>
             <DeploymentStatus deploymentOutput={deploymentOutput} />
          </Grid>
        </Grid>
      </Container>
    </ThemeProvider>
  );
}

export default App;