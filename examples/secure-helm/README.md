# Secure Helm Install Guide

This guide walks through an example of how to setup and configure a secure Helm installation on your Kubernetes
cluster. This guide will utilize the helm installer script provided in the [install-helm-server module](../modules/install-helm-server).

This guide requires a Kubernetes instance. You can either use
[minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/), [Kubernetes on Docker for
Mac](https://docs.docker.com/docker-for-mac/kubernetes/), or the [eks-cluster example](../eks-cluster) to provision a
working Kubernetes cluster.
