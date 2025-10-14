import React, { useState } from 'react';
import { Stepper, Step, StepLabel, Button, Typography, Box, TextField, Switch, FormControlLabel, Tooltip } from '@mui/material';

const steps = ['Organization Setup', 'Resource Management', 'Networking'];

function OrgSetupForm({ config, handleChange, showAdvanced, toggleAdvanced }) {
  return (
    <Box>
      <Tooltip title="The billing account ID for the new project.">
        <TextField
          label="Billing Account"
          value={config.billing_account}
          onChange={(e) => handleChange('billing_account', e.target.value)}
          fullWidth
          margin="normal"
        />
      </Tooltip>
      <Tooltip title="The ID of the GCP organization.">
        <TextField
          label="Organization ID"
          value={config.organization_id}
          onChange={(e) => handleChange('organization_id', e.target.value)}
          fullWidth
          margin="normal"
        />
      </Tooltip>
      <FormControlLabel
        control={<Switch checked={showAdvanced} onChange={toggleAdvanced} />}
        label="Show Advanced Options"
      />
      {showAdvanced && (
        <Tooltip title="An optional prefix for all created resources.">
          <TextField
            label="Prefix"
            value={config.prefix}
            onChange={(e) => handleChange('prefix', e.target.value)}
            fullWidth
            margin="normal"
          />
        </Tooltip>
      )}
    </Box>
  );
}

function ResmanForm({ config, handleChange }) {
    return (
        <Box>
            <Tooltip title="The ID of the folder where resources will be created.">
                <TextField
                    label="Folder ID"
                    value={config.folder_id}
                    onChange={(e) => handleChange('folder_id', e.target.value)}
                    fullWidth
                    margin="normal"
                />
            </Tooltip>
        </Box>
    );
}

function NetworkingForm({ config, handleChange }) {
    return (
        <Box>
            <Tooltip title="The name of the VPC network to be created.">
                <TextField
                    label="VPC Name"
                    value={config.vpc_name}
                    onChange={(e) => handleChange('vpc_name', e.target.value)}
                    fullWidth
                    margin="normal"
                />
            </Tooltip>
        </Box>
    );
}

function getStepContent(step, config, handleChange, showAdvanced, toggleAdvanced) {
  switch (step) {
    case 0:
      return <OrgSetupForm config={config} handleChange={handleChange} showAdvanced={showAdvanced} toggleAdvanced={toggleAdvanced} />;
    case 1:
      return <ResmanForm config={config} handleChange={handleChange} />;
    case 2:
      return <NetworkingForm config={config} handleChange={handleChange} />;
    default:
      return 'Unknown step';
  }
}

function DeploymentWizard({ setDeploymentOutput }) {
  const [activeStep, setActiveStep] = useState(0);
  const [config, setConfig] = useState({
    "Organization Setup": { billing_account: "", organization_id: "", prefix: "" },
    "Resource Management": { folder_id: "" },
    "Networking": { vpc_name: "" }
  });
  const [showAdvanced, setShowAdvanced] = useState(false);

  const handleNext = () => setActiveStep((prev) => prev + 1);
  const handleBack = () => setActiveStep((prev) => prev - 1);
  const handleReset = () => {
    setActiveStep(0);
    setConfig({
      "Organization Setup": { billing_account: "", organization_id: "", prefix: "" },
      "Resource Management": { folder_id: "" },
      "Networking": { vpc_name: "" }
    });
  };

  const handleChange = (stage, key, value) => {
    setConfig(prev => ({
      ...prev,
      [stage]: { ...prev[stage], [key]: value }
    }));
  };

  const toggleAdvanced = () => setShowAdvanced(prev => !prev);

  const handleDeploy = async () => {
    setDeploymentOutput('');
    try {
      const response = await fetch('/deploy', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ config: config }),
      });

      if (!response.body) return;

      const reader = response.body.getReader();
      const decoder = new TextDecoder();

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        const chunk = decoder.decode(value, { stream: true });
        setDeploymentOutput(prev => prev + chunk);
      }
    } catch (error) {
      setDeploymentOutput(`An error occurred: ${error.message}`);
    }
  };

  return (
    <Box sx={{ width: '100%' }}>
      <Stepper activeStep={activeStep}>
        {steps.map((label) => (
          <Step key={label}>
            <StepLabel>{label}</StepLabel>
          </Step>
        ))}
      </Stepper>
      {activeStep === steps.length ? (
        <React.Fragment>
          <Typography sx={{ mt: 2, mb: 1 }}>All steps completed - you're ready to deploy.</Typography>
          <Box sx={{ display: 'flex', flexDirection: 'row', pt: 2 }}>
            <Button color="inherit" onClick={handleReset} sx={{ mr: 1 }}>Reset</Button>
            <Box sx={{ flex: '1 1 auto' }} />
            <Button onClick={handleDeploy}>Deploy</Button>
          </Box>
        </React.Fragment>
      ) : (
        <React.Fragment>
          <Box sx={{ mt: 2, mb: 1 }}>
            {getStepContent(activeStep, config[steps[activeStep]], (key, value) => handleChange(steps[activeStep], key, value), showAdvanced, toggleAdvanced)}
          </Box>
          <Box sx={{ display: 'flex', flexDirection: 'row', pt: 2 }}>
            <Button color="inherit" disabled={activeStep === 0} onClick={handleBack} sx={{ mr: 1 }}>Back</Button>
            <Box sx={{ flex: '1 1 auto' }} />
            <Button onClick={handleNext}>{activeStep === steps.length - 1 ? 'Finish' : 'Next'}</Button>
          </Box>
        </React.Fragment>
      )}
    </Box>
  );
}

export default DeploymentWizard;