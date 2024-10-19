---

layout: post  
title: "K8s Project - Installing and Setting Up Kind - Part II"  
date: 2024-10-19 18:04 +0200  
categories: Kubernetes  
comments: true  

---

# 🚀 Introduction

For this project, we will be using **Kind**, not **Minikube**. Both tools are excellent, but Kind is simpler, lighter, and perfectly suited for our needs. You can compare both in more detail in my previous blog post: [Kind Vs Minikube]({% post_url 2024-10-19-kind-vs-minikube %}).

# 🔧 What You’ll Need

- `curl` installed on your machine

# 📥 Installing Kind

You could follow the [official documentation](https://kind.sigs.k8s.io/docs/user/quick-start/#installation), but it requires Golang to be installed on your machine, which might take some time. If you'd still like to go that route, follow the instructions [here](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).

Alternatively, you can use the method below for a quicker setup:

## 🧑‍💻 Getting the Source Code

1. Go to the [Kind GitHub Releases page](https://github.com/kubernetes-sigs/kind/releases) and download the appropriate version for your OS.  
   In my case, I’m using **macOS** with an **arm64** architecture, so I’ll right-click on the correct package and copy the link.

2. Download the file using `curl` (you can save it in the root of your project):

    ```bash
    curl -L -o ./kind https://github.com/kubernetes-sigs/kind/releases/download/v0.24.0/kind-darwin-arm64
    ```

3. Make it executable by giving the appropriate permissions:

    ```bash
    sudo chmod +x ./kind
    ```

4. Verify the installation by checking the version:

    ```bash
    ./kind --version
    ```

   You should see something like:

    ```bash
    kind version 0.24.0
    ```

# 🏗️ Creating Your K8s Cluster

Now comes the fun part—creating your Kubernetes cluster with Kind! To do this, run the following command:

```bash
./kind create cluster --name myks8project
```

If everything goes well, you’ll see output similar to this:

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

# 🌟 Final Thoughts

That’s it! You’ve successfully set up a Kubernetes cluster with Kind. 🎉 Great job!

👉 If you missed the first part, check out [Part I]({% post_url 2024-10-19-k8s-project-creating-docker-container-part-i %}).

