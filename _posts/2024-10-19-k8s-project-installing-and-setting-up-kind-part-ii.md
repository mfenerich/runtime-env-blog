---
layout: post
title: k8s Project - Installing And Setting Up Kind - Part II
date: 2024-10-19 18:04 +0200
categories: Kubernetes  
comments: true
---

# Introduction

For this project we are going to use **Kind**, and not **Minikube**. Both are great but Kind is simplier, lightier and perfectly fit this project. You can check a bit of both here in the blog [Kind Vs Kubernetes]({% post_url 2024-10-19-k8s-project-installing-and-setting-up-kind-part-ii %}).

# 🔧 What You’ll Need to Accomplish This Step

- Having `curl` installed on your machine

# Installing

For instaling the Kind you could follow the official documentation, but it could requires Golang installed on your machine and also it would take a while. But if you still wishe to use their instructions follow the instructions [here](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).

Otherwise you can just follow the tips as follow:

## Getting the source code

Just go to their [Github releases page](https://github.com/kubernetes-sigs/kind/releases) and download the most suitable version for your OS. In my case I am using a macOs with a *arm64* architeture. So I right click in the right package and copy the link. Now just download it using `curl`.

You can download it in the root of your project.

```bash
curl -L -o ./kind  https://github.com/kubernetes-sigs/kind/releases/download/v0.24.0/kind-darwin-arm64
```

Than just give the proper permissions to execute it.

```bash
sudo chmod +x ./kind
```

And check the version:

```bash
./kind --version
```

If everything is right you should see something like this:

```
kind version 0.24.0
```

## Creating our k8s cluster

Now we start with the best part. Creating our k8s cluster using Kind. In other to do this just enter this command line:

```bash
./kind create cluster --name myks8project
```

If everything is good you should see something like this:

```bash
    Creating cluster "myks8project" ...
    ✓ Ensuring node image (kindest/node:v1.31.0) 🖼 
    ✓ Preparing nodes 📦  
    ✓ Writing configuration 📜 
    ✓ Starting control-plane 🕹️ 
    ✓ Installing CNI 🔌 
    ✓ Installing StorageClass 💾 
    Set kubectl context to "kind-myks8project"
    You can now use your cluster with:

    kubectl cluster-info --context kind-myks8project

    Have a nice day! 👋
```

If you want, check the [Part I]({% post_url 2024-10-19-k8s-project-creating-docker-container-part-i %})

This is it.

Great Job.

