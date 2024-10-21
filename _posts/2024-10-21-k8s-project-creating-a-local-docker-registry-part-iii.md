---
layout: post
title: "k8s Project - Mastering Local Docker Registries with Kind: A Step-by-Step Guide - Part III"
date: 2024-10-21 13:37 +0200
categories: Kubernetes
comments: true
author: "Marcel Fenerich"
---

👉 If you missed the previous part, check out [Part II]({% post_url 2024-10-19-k8s-project-installing-and-setting-up-kind-part-ii %}).

## 🏗️ Setting Up a Local Docker Registry for Your Kubernetes Cluster

Ever feel like Kubernetes is that friend who just *doesn’t get it* when it comes to your local environment? You’ve got everything set up just right on your machine, but Kubernetes? Nope. It wants your Docker images all nicely packaged and stored in a registry like it’s too fancy to acknowledge what you’ve built locally. Fear not! You can actually create your own local Docker registry, and in this post, I’ll walk you through it—step by step—while hopefully making you chuckle at least once.

### 🧐 Why Bother with a Local Docker Registry?

Before you start thinking, *Why do I even need a local registry? I’ve got Docker Hub!*, let me give you a couple of solid reasons:

1. **Privacy First**: Sure, Docker Hub is great… until it isn’t. If you’re working on something top-secret (like the next big thing, or just a cool project you’d rather not share with the world), you don’t want that image floating around in public, right?
2. **Rate Limits**: Ah, Docker Hub’s famous rate limits. Because nothing says “let’s have a productive day” like hitting a pull limit just when you’re in the groove. Nobody has time for that.

So, what’s the solution? A local Docker registry. It’s like having your own personal cloud—but, you know, on the ground.

### 🚀 Let’s Set Up That Local Docker Registry

Enough chit-chat. Let’s dive into how you can get your local Docker registry up and running.

1. **Start the Local Docker Registry**:

   Open up your terminal and type the following magic words:

   ```bash
   docker run --name local-registry -d --restart=always -p 5000:5000 registry:2
   ```

   Now, let me break that down for you in human terms:

   - **docker run**: You're starting a new Docker container. Simple, right?
   - **--name local-registry**: You're calling this container “local-registry” because naming things is important, even containers. You wouldn’t just call your cat “cat,” right?
   - **-d**: This runs the container in detached mode, which is fancy talk for “I don’t need to watch you work.”
   - **--restart=always**: If it breaks, Docker will put it back together. This container is practically self-healing!
   - **-p 5000:5000**: This maps port 5000 on your machine to port 5000 in the container. Think of it like creating a little door that Docker can go through.
   - **registry:2**: This tells Docker to use version 2 of the registry image. Why? Because we're cool like that.

2. **Check if It’s Alive**:

   Now that you’ve got your local registry container running, it’s time to see if it’s alive and kicking. Run:

   ```bash
   curl --location http://localhost:5000/v2
   ```

   If everything’s in order, you should get a response like:

   ```json
   {}
   ```

   If you’re thinking, *Oh great, a blank JSON object,* congratulations! It’s working! That empty object is your registry’s way of saying, “Yep, I’m here, but I don’t have any images yet.”

---

### 🔗 Connecting Your Docker Registry to the Kind Cluster

Alright, now that we’ve got our Docker registry up and running (and looking pretty snazzy if I do say so myself), it’s time to get Kubernetes on the same page. Think of this like introducing two best friends who should have met ages ago. Kubernetes, meet Docker registry. Docker registry, Kubernetes. Now play nice, okay?

#### 📝 Creating a Kind Cluster Configuration File

To make sure Kubernetes knows where to find our local registry, we’ll need to create a configuration file for our **Kind cluster**. **Kind cluster** configuration files are like the blueprints that tell **Kubernetes** how to set things up. It’s where we say, “Hey, Kubernetes, there’s this cool registry over here at localhost:5000 that you should totally know about.”

So, let’s go ahead and create a file called `kind_config.yaml` and open it up in your favorite editor. (Personally, I’m a fan of any editor that doesn’t crash on me when I accidentally try to open a 2GB log file, but you do you.)

Here’s what the configuration file looks like:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:5000"]
    endpoint = ["http://local-registry:5000"]
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
```

Let’s break this down a bit:

1. **kind: Cluster**: This line tells Kubernetes that we’re dealing with a *cluster* object. It’s like saying, “Hey Kubernetes, I’m about to give you some instructions on how to configure a cluster.”
2. **apiVersion**: Kubernetes has a lot of objects (seriously, *a lot*), and they come in different versions. Here, we’re using `v1alpha4` of the `kind.x-k8s.io` API because that’s what our little Kind cluster likes to work with. Basically, it’s saying, “Hey, I’m talking in the language of version `v1alpha4` here—hope you’re fluent!”
3. **containerdConfigPatches**: This section is where the magic happens. It’s like sending a memo to `containerd`, which is the container runtime that Kind uses. We’re essentially telling `containerd`, “By the way, there’s a Docker registry chilling at **localhost:5000**. You might want to use it.”

That’s it! Not too scary, right?

### 📦 Adding a ConfigMap for the Local Registry

Hold on, we’re not done yet! There’s one more little thing to do before Kubernetes can fully appreciate your local Docker registry: the **ConfigMap**.

Think of ConfigMaps like Kubernetes’ way of passing around notes, saying “Hey, here’s some important configuration data for you to know.” In this case, we’ll use a ConfigMap to let Kubernetes know all about our local registry.

Here’s what your `kind_configmap.yaml` file will look like:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
```

This ConfigMap tells Kubernetes, “Hey, there’s a local Docker registry you should know about. Here’s the URL: **localhost:5000**. Oh, and if you’re confused, here’s a helpful link for more info!”

---

### 🖥️ Putting It All Together: Using and Applying the Configuration

Alright, we’ve done all the hard work, and now it’s time to see everything in action! Let’s go through the final steps of creating, managing, and applying your configurations.

1. **Check Existing Clusters**: Before creating a new cluster, it’s always good to check if you have any existing clusters running. Use this command:

   ```bash
   ./kind get clusters
   ```

   This will show a list of any clusters Kind is currently managing.

2. **Deleting a Cluster**: If you have an old cluster hanging around and want to remove it, you can delete it with:

   ```bash
   ./kind delete cluster --name myks8project
   ```

   This command will remove the cluster named `myks8project` so you can start fresh.

3. **Creating the Cluster with Configuration**: Now, let's create our new cluster, using a specific image and the configuration file we’ve just set up:

   ```bash
   ./kind create cluster --image=kindest/node:v1.21.12 --name myks8project --config ./kind_config.yaml
   ```

   **What’s that `kindest/node:v1.21.12`?**

   Glad you asked! The `kindest/node:v1.21.12` image is a specific version of the Kubernetes node that Kind uses to simulate a Kubernetes cluster. Think of it like the operating system for each Kubernetes node. Version `v1.21.12` refers to a stable Kubernetes release that you can use in your local Kind environment. The "kindest" part is just the name that the Kind project uses for its node images. You can swap this version for other versions if you need to test your cluster on different Kubernetes releases, but here we're going with `v1.21.12` for stability and compatibility.

4. **Applying the ConfigMap**: Lastly, we need to apply the ConfigMap to our cluster to complete the setup. Run this command:

   ```bash
   kubectl apply -f ./kind_configmap.yaml
   ```

   This applies the `kind_configmap.yaml` file, making Kubernetes aware of the local registry’s hosting information.

---

### 🗺️ Understanding Kubernetes Manifests

Before we dive into the next section, let me just give a quick shoutout to Kubernetes manifests. These are like the instruction manuals for how Kubernetes should deploy and configure resources in your cluster. Every manifest starts with a couple of key lines (like the `kind` and `apiVersion` we saw earlier) to define *what* Kubernetes is dealing with and *how* to handle it.

Here’s the thing, though: Kubernetes can create and configure *a lot* of different objects, and each one comes with its own unique manifest schema. It’s like learning a hundred different dialects of the same language. But don’t worry, the [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/) is your best friend here. This reference contains all the objects and their manifest schemas, so you can figure out exactly what to write in your YAML files without breaking a sweat.

Now, don’t go grabbing that API reference for this particular cluster object—our Kind cluster is using a custom object created by the Kind authors. But I wanted to introduce the reference here because as you venture deeper into Kubernetes land, you’ll be creating all sorts of custom manifests, and this documentation will save your bacon more than once.

---

## 🌟 Final Thoughts

And that’s a wrap! We’ve set up a local Docker registry, configured it in our Kind cluster, and made Kubernetes aware of it using a ConfigMap. Now, Kubernetes can happily pull your Docker images from localhost:5000 like the good little orchestration tool it is.

As always, keep experimenting, and don’t hesitate to dive deeper into the wild world of Kubernetes. And remember: YAML files may look intimidating, but with a bit of practice (and the occasional Google search), they’ll become your best friend. Happy coding!

👉 *Part IV comming soon...*
