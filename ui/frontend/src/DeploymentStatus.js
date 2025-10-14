import React, { useState, useEffect } from 'react';
import { Box, Typography, LinearProgress, Paper } from '@mui/material';

const STAGES = [
  "0-org-setup",
  "1-resman",
  "2-networking",
  "3-project-factory",
];

function DeploymentStatus({ deploymentOutput }) {
  const [activeStage, setActiveStage] = useState('');
  const [stageStatus, setStageStatus] = useState({});
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const lines = deploymentOutput.split('\n');
    let currentStatus = {};
    let currentStage = '';

    lines.forEach(line => {
      if (line.includes('--- Starting stage:')) {
        const stage = line.split('--- Starting stage: ')[1].split(' ---')[0];
        currentStage = stage;
        currentStatus[stage] = 'in_progress';
      } else if (line.includes('--- Stage')) {
        const stage = line.split('--- Stage ')[1].split(' completed successfully ---')[0];
        if (stage) {
            currentStatus[stage] = 'success';
        }
      } else if (line.includes('--- Error in stage')) {
        const stage = line.split('--- Error in stage ')[1].split(':')[0];
        currentStatus[stage] = 'error';
      }
    });

    setActiveStage(currentStage);
    setStageStatus(currentStatus);

    const completedStages = Object.values(currentStatus).filter(s => s === 'success').length;
    setProgress((completedStages / STAGES.length) * 100);

  }, [deploymentOutput]);

  return (
    <Paper sx={{ p: 3, height: '100%' }}>
        <Typography variant="h3" component="h3" gutterBottom>
            Deployment Status
        </Typography>
        <Box sx={{ width: '100%', mb: 2 }}>
            <LinearProgress variant="determinate" value={progress} />
        </Box>
        {STAGES.map(stage => (
            <Typography key={stage} variant="body1" color={stageStatus[stage] === 'error' ? 'error' : 'inherit'}>
                {stage}: {stageStatus[stage] || 'pending'}
            </Typography>
        ))}
        <Typography variant="h5" component="h5" gutterBottom sx={{mt: 2}}>
            Logs
        </Typography>
        <pre style={{ whiteSpace: 'pre-wrap', wordWrap: 'break-word', background: '#222', padding: '1rem', borderRadius: '4px', height: 'calc(100% - 240px)', overflowY: 'auto' }}>
            {deploymentOutput}
        </pre>
    </Paper>
  );
}

export default DeploymentStatus;