# BigQuery ML and Vertex AI Pipeline Demo

This demo shows how to combine BigQuery ML (BQML) and Vertex AI to create a ML pipeline leveraging the infrastructure created in the blueprint.

More in details, this tutorial will focus on the following three steps:

- define a Vertex AI pipeline to create features, train and evaluate BQML models
- serve a BQ model through an API powered by Vertex AI Endpoint
- create batch prediction via BigQuery

In this tutorial we will also see how to make explainable predictions, in order to understand what are the most important features that most influence the algorithm outputs.

# Dataset

This tutorial uses a fictitious e-commerce dataset collecting programmatically generated data from the fictitious e-commerce store called The Look. The dataset is publicly available on BigQuery at this location `bigquery-public-data.thelook_ecommerce`.

# Goal

The goal of this tutorial is to train a classification ML model using BigQuery ML and predict if a new web session is going to convert.

The tutorial focuses more on how to combine Vertex AI and BigQuery ML to create a model that can be used both for near-real time and batch predictions rather than the design of the model itself.

# Main components

In this tutorial we will make use of the following main components:
- Big Query:
	- standard: to create a view which contains the model features and the target variable
	- ML: to train, evaluate and make batch predictions
- Vertex AI:
	- Pipeline: to define a configurable and re-usable set of steps to train and evaluate a BQML model
	- Experiment: to keep track of all the trainings done via the Pipeline
	- Model Registry: to keep track of the trained versions of a specific model
	- Endpoint: to serve the model via API
	- Workbench: to run this demo

# How to get started

1. Access the Vertex AI Workbench
2. clone this repository
2. run the [`bmql_pipeline.ipynb`](bmql_pipeline.ipynb) Jupyter Notebook