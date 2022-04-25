#!/bin/bash

export TF_CLI_ARGS_plan='-var-file=bluegreen.tfvars'
export TF_CLI_ARGS_apply='-var-file=bluegreen.tfvars'
export TF_CLI_ARGS_destroy='-var-file=bluegreen.tfvars'