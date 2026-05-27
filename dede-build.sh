#!/bin/bash

usage() {
    echo "Usage: $0 <cluster> <component-name>"
    echo "Example: $0 dexter-rtp-dev-01 app-alpha.yaml"
    exit 1
}

if [ "$#" -ne 2 ]; then
    usage
fi

# Repo root (absolute path) – dede requires kustomizej2 to be under current working dir
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

cluster="$1"
comp_name="$2"
template="../gitops-${comp_name}"
comp_file="${SCRIPT_DIR}/${cluster}/components/${comp_name}.yaml"
cluster_file="${SCRIPT_DIR}/${cluster}/cluster.yaml"
output_dir="${SCRIPT_DIR}/output"

echo "Repo root: ${SCRIPT_DIR}"
echo "Starting dede release for component: ${comp_file}"

if [ ! -f "$comp_file" ]; then
    echo "Error: Component file $comp_file does not exist."
    echo "Please ensure the component name is correct and the file exists."
    exit 1
fi

if [ ! -d "${template}" ]; then
    echo "Error: Directory ${template} does not exist."
    echo "Please clone the template project repository."
    exit 1
fi

rm -rf kustomizej2 helm kustomize gitops output/*

# check if directory exists before copying
if [ -d "${template}/kustomizej2" ]; then
    echo "Copying ${template}/kustomizej2 to current directory."
    cp -rf "${template}/kustomizej2" .
fi
if [ -d "${template}/helm" ]; then
    echo "Copying ${template}/helm to current directory."
    cp -rf "${template}/helm" .
fi
if [ -d "${template}/kustomize" ]; then
    echo "Copying ${template}/kustomize to current directory."
    cp -rf "${template}/kustomize" .
fi
if [ -d "${template}/gitops" ]; then
    echo "Copying ${template}/gitops to current directory."
    cp -rf "${template}/gitops" .
fi

# Run dede with CWD explicitly set to repo root (required for kustomizej2 path check)
if ! (cd "$SCRIPT_DIR" && dede -vvv release manifests "$output_dir" "$cluster_file" "$comp_file"); then
    echo "*** dede release failed ***"
    exit 1
fi
echo "*** dede release completed. Output available in output/ ***"

rm -rf kustomizej2 helm kustomize gitops