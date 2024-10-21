---

layout: post
title: "K8s Project - Installing and Setting Up Kind - Part II"
date: 2024-10-19 18:04 +0200
categories: Kubernetes
comments: true

---

## 🚀 Introduction

For this project, we will be using **Kind**, not **Minikube**. Both tools are excellent, but Kind is simpler, lighter, and perfectly suited for our needs. You can compare both in more detail in my previous blog post: [Kind Vs Minikube]({% post_url 2024-10-19-kind-vs-minikube %}).

## 🔧 What You’ll Need

- `curl` installed on your machine

## 📥 Installing Kind

You could follow the [official documentation](https://kind.sigs.k8s.io/docs/user/quick-start/#installation), but it requires Golang to be installed on your machine, which might take some time. If you'd still like to go that route, follow the instructions [here](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).

Alternatively, you can use the method below for a quicker setup:

### 🧑‍💻 Getting the Source Code

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

## 🏗️ Creating Your K8s Cluster

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

Waaaiittt... have you notice the command `kubectl cluster-info --context kind-myks8project` on the `Kind` output?

## 🧑‍💻 What is `kubectl`?

Once you've set up your Kubernetes cluster using `Kind`, you will often interact with it using **kubectl**. But what exactly is `kubectl`?

### 🛠️ Understanding `kubectl`

`kubectl` is the command-line tool that allows you to communicate with your Kubernetes clusters. Think of it as the bridge between you and the Kubernetes API, enabling you to:

- Inspect the state of your cluster (view nodes, pods, services, etc.)
- Deploy applications
- Manage cluster resources
- Perform debugging tasks

Without `kubectl`, managing Kubernetes would be much more difficult, as you’d have to work directly with the Kubernetes API or use a UI. In essence, `kubectl` is essential for day-to-day operations when working with Kubernetes.

### 🖥️ Installing `kubectl`

Let’s look at how to install `kubectl` on different platforms: **macOS**, **Ubuntu**, and **Windows**.

#### MacOS Installation

For macOS, you can use `brew`:

1. Open your terminal and run:

    ```bash
    brew install kubectl
    ```

2. Verify the installation:

    ```bash
    kubectl version --client
    ```

#### Ubuntu Installation

On Ubuntu, you can install `kubectl` using the following commands:

1. Install `kubectl`:

    ```bash
    sudo apt-get update
    # apt-transport-https may be a dummy package; if so, you can skip that package
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
    ```

    ```bash
    # If the folder `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
    # sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring
    ```

    ```bash
    # This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly
    ```

    ```bash
    sudo apt-get update
    sudo apt-get install -y kubectl
    ```

2. Verify the installation:

    ```bash
    kubectl version --client
    ```

#### Windows Installation

On Windows, you can install `kubectl` using **chocolatey**:

1. Open **PowerShell** as an Administrator and run:

    ```bash
    choco install kubernetes-cli
    ```

2. Verify the installation:

    ```bash
    kubectl version --client
    ```

For more detailed instructions, refer to the [official Kubernetes documentation](https://kubernetes.io/docs/tasks/tools/).

### 🖥️ Checking Your Cluster Nodes

Once you have `kubectl` installed, you can check the nodes in your Kubernetes cluster by running the following command:

```bash
kubectl get nodes
```

This will display all the nodes (machines) in your cluster, giving you an overview of its current state. You should see something like this:

```shell
NAME                         STATUS   ROLES           AGE   VERSION
myks8project-control-plane   Ready    control-plane   17m   v1.31.0
```

## 🌟 Final Thoughts

That’s it! You’ve successfully set up a Kubernetes cluster with Kind. 🎉 Great job!

👉 If you missed the first part, check out [Part I]({% post_url 2024-10-19-k8s-project-creating-docker-container-part-i %}).
