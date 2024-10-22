---
layout: post
title: K8s Project - Creating a Deployment with Kubernetes - Part IV
date: 2024-10-22 12:14 +0200
categories: Kubernetes
comments: true
author: "Marcel Fenerich"
---

👉 If you missed the previous part, check out [Part III]({% post_url 2024-10-21-k8s-project-creating-a-local-docker-registry-part-iii %}).

## 🚀 K8s Project - Creating a Deployment with Kubernetes - Part IV

Now that we’ve set up our Kind cluster and Docker registry, it’s time to get to the exciting part: **creating a deployment**. In this post, we’ll walk through how to deploy your Dockerized application to Kubernetes using a local cluster and test it out. Ready? Let’s go!

### 🏗️ Step 1: Push Your Docker Image to the Registry

First up, we need to make sure that our Docker image is pushed to the local registry.

Here’s how to do it:

1. **Tag the Docker image**:

    ```bash
    docker tag my-static-website localhost:5000/my-static-website
    ```

2. **Push the tagged image to your local registry**:

    ```bash
    docker push localhost:5000/my-static-website
    ```

    If it works, you should see something like:

    ```bash
    Using default tag: latest
    The push refers to repository [localhost:5000/my-static-website]
    fc3d5e2745da: Layer already exists
    af19c9fda5c9: Layer already exists
    9c748015f5b4: Layer already exists
    347076dd9c82: Layer already exists
    031c892f6794: Layer already exists
    baca49726296: Layer already exists
    98591063c9e4: Layer already exists
    86aa2ad58202: Layer already exists
    16113d51b718: Layer already exists
    latest: digest: sha256:a8a257ac5996ebbba7cc7893233fec86137cb3168a037eee9358731de4a96be8 size: 2196
    ```

Now, your image is safely tucked away in your local Docker registry, and Kubernetes will be able to use it in our deployment. 🎉

---

### 📜 Understanding Kubernetes Manifests

Before we dive into creating our deployment, let’s take a moment to understand **Kubernetes manifests**. Kubernetes uses YAML files, known as manifests, to define and manage resources like deployments, services, and more. These manifests act as the blueprint for the resources you want to create.

When you define a manifest, you’re essentially describing the configuration of a resource. In this case, we’re creating a **deployment** manifest that will ensure the right number of pods (which run our application containers) stay up and running.

Let’s create a blank manifest for the deployment using `kubectl`. This command will generate the YAML we need:

```bash
kubectl create deployment myks8project --image=localhost:5000/my-static-website --dry-run=client --output=yaml > deployment.yaml
```

This command generates a deployment manifest in YAML format but doesn’t apply it yet (thanks to the `--dry-run=client` flag). It outputs the YAML to a file called `deployment.yaml`. Let’s open that file and take a look.

---

### 📦 Step 2: Create the Kubernetes Deployment Manifest

Now that we’ve generated the basic manifest, we can take a closer look at its structure. The deployment manifest contains several important components:

- **apiVersion**: Specifies the API version (`apps/v1`) that defines the deployment object.
- **kind**: Tells Kubernetes the type of resource we’re creating—in this case, a **Deployment**.
- **metadata**: Includes fields like the **name** and **labels** for the deployment, helping Kubernetes identify it.
- **spec**: Defines the desired state of the Deployment, such as the number of replicas and the container configuration.

The manifest also includes labels that act as selectors to associate pods with the deployment. This allows us to find the pods easily using label selectors.

Here’s what the `deployment.yaml` file might look like:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: myks8project
  name: myks8project
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myks8project
  strategy: {}
  template:
    metadata:
      labels:
        app: myks8project
    spec:
      containers:
      - image: localhost:5000/my-static-website
        name: my-static-website
        resources: {}
status: {}

```

This is a basic deployment manifest. As we go further, you can customize it by adding more fields, such as environment variables or resource limits.

---

### 🌐 Step 3: Apply the Deployment Manifest

With our deployment manifest ready, it’s time to apply it and create the actual deployment in our Kubernetes cluster.

1. **Apply the deployment**:

    ```bash
    kubectl apply -f deployment.yaml
    ```

2. **Verify the deployment** by listing the pods associated with it:

    ```bash
    kubectl get pods -l app=myks8project
    ```

    The `-l` flag filters the pods by their label, specifically those associated with our `myks8project` deployment. If you see a running pod, that’s it! Your deployment is live and well.

    You should see something like this:

    ```bash
    NAME                            READY   STATUS    RESTARTS   AGE
    myks8project-79cd67c7cc-zd9h7   1/1     Running   0          26m
    ```

    Make sure the status is **Running**, otherwise something is wrong.

---

### 🔄 Understanding Key Parts of the Manifest

Now that our deployment is live, let's revisit some key concepts:

- **Replicas**: Defines the number of identical pods you want Kubernetes to maintain. Our deployment creates one replica by default, but you can scale this up or down.

- **Selectors**: Allow you to target and identify resources by their labels. We used the label `app=myks8project` to find all pods associated with this deployment.

- **Template**: Under `spec.template`, we define the pod template, including the container image, name, and ports.

---

### 🌐 Step 4: Forward Ports to Access the Application

Now that our app is up and running in a pod, we need a way to access it. We can do this using `kubectl port-forward`, which works similarly to Docker’s `-p` or `--publish` option. This will map a port from our local machine to a port inside the pod running our application.

Run the following command to forward the port:

```bash
kubectl port-forward deployment/myks8project 8080:80
```

Let’s break that down:

- We’re forwarding the port from our **deployment** named `myks8project`.
- `8080:80` means we’re forwarding port **8080** on our local machine to port **80** inside the pod (since port 80 is where the website runs inside the container).

If you see messages like this:

```shell
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

it means the forwarding has started successfully.

---

### 🎉 Step 5: Access the Application Locally

Finally, let’s test the deployment! Open your browser and head to:

```bash
http://localhost:8080
```

You should now see your **Hello World!!!** website running locally, courtesy of Kubernetes! 🎉

---

## 🌟 Final Thoughts

And there you have it! You’ve successfully deployed your Dockerized application into a Kubernetes cluster, verified that it’s running, and accessed it locally. This setup not only gets your app up and running quickly but also prepares you for larger-scale deployments down the road.

Stay tuned for more as we continue to build out our Kubernetes project and explore the endless possibilities of cloud-native development!

👉 *Part V comming soon...*
