#!/bin/bash

gcloud config unset universe_domain
gcloud config configurations activate default
gcloud auth login --update-adc
