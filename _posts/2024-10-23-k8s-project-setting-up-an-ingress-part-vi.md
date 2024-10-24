---
layout: post
title: K8s Project - Setting Up an Ingress - Part VI
date: 2024-10-23 13:49 +0200
categories: Kubernetes
comments: true
author: "Marcel Fenerich"
---

👉 If you missed the previous part, check out [Part V]({% post_url 2024-10-23-k8s-project-understanding-and-creating-a-service-part-v %}).

## 🚀 K8s Project - Setting Up an Ingress - Part VI

Alright, friends, it’s time to open the gates and let the world (or at least your local machine) access your Kubernetes services! In this part, we’ll be talking about **Ingress** and how it works as a reverse proxy to provide external access to your Kubernetes resources. Let’s dive in and explore how we can make your app accessible in a more "production-ready" way.

### 🧐 What Is an Ingress in Kubernetes?

Picture an Ingress as a sort of fancy bouncer for your Kubernetes cluster. It sits at the door, allowing external traffic to enter your services through a well-defined set of rules. Without an Ingress, you’d need to expose each service individually or rely on port forwarding—which is a bit like having everyone knock directly on your pod’s door. Not exactly scalable, right?

If you’ve ever dealt with load balancers (like AWS’s Application Load Balancer or Azure’s API Gateway), Ingress will feel quite familiar. But if you haven’t, don’t worry! It’s simply a way to route external traffic (like HTTP requests) to your internal Kubernetes services.

Here’s the magic: Ingress handles routing traffic based on **rules**—which URL path should go to which service. So, instead of creating complicated routing configurations for each pod or service, Ingress makes it easy to direct traffic across multiple resources. It even allows for advanced rules like regex or prefix matching, but we’ll keep things simple for now. Let's get going!

---

### 🧑‍💻 Step 1: Creating an Ingress

Now that we know what an Ingress is, let’s create one for our application. We’ll define a basic rule to forward all traffic hitting the root of `myks8project` to our `myks8project` service.

1. **Generate the Ingress YAML**:
    Just like we did with the deployment and service manifests, we’ll use `kubectl` to generate the Ingress YAML file:

    ```bash
    kubectl create ingress myks8project --rule="myks8project/*=myks8project:80" --dry-run=client -o yaml > ingress.yaml
    ```

    This command generates an Ingress rule that forwards all traffic from `myks8project` to the service `myks8project` on port **80**.

---

### 📜 Understanding the Ingress Manifest

Let’s open up the generated `ingress.yaml` file and see what we’ve got:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  creationTimestamp: null
  name: myks8project
spec:
  rules:
  - host: myks8project
    http:
      paths:
      - backend:
          service:
            name: myks8project
            port:
              number: 80
        path: /
        pathType: Prefix
status:
  loadBalancer: {}
```

Here’s a breakdown of the important bits:

- **apiVersion**: Specifies the API version for the Ingress object. We’re using `networking.k8s.io/v1`.
- **kind**: Tells Kubernetes that we’re creating an **Ingress** resource.
- **rules**: This is where the magic happens! We’re saying that any HTTP request hitting `myks8project/` should be routed to the `myks8project` service on port **80**.
- **pathType**: We’ve set this to `Prefix`, meaning any traffic to `myks8project/` or subpaths (like `/images`) will be sent to the service.

Pretty neat, right?

---

### ⚙️ Step 2: Configuring the Ingress Controller

But wait—there’s one more thing! Before we can actually use the Ingress, we need an **Ingress controller**. This controller is responsible for watching the Ingress rules and directing traffic accordingly. Think of it as the brains behind the Ingress.

1. **Install the NGINX Ingress Controller**:
    Since we’re using Kind, we’ll follow the official documentation to install the NGINX Ingress controller. Kind makes this easy by providing a one-liner to get it up and running:

    ```bash
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    ```

    This command applies a pre-configured NGINX Ingress controller manifest from GitHub. It creates everything we need to handle the Ingress routing.

2. **Verify the Installation**:
    After the installation, let’s check if everything’s running smoothly. We’ll look at all resources in the `ingress-nginx` namespace:

    ```bash
    kubectl get all -n ingress-nginx
    ```

    If you see a pod for the **Ingress controller** in the running state, we’re good to go!

    You should see something like this:

    ```bash
    NAME                                            READY   STATUS      RESTARTS   AGE
    pod/ingress-nginx-admission-create-2h297        0/1     Completed   0          18s
    pod/ingress-nginx-admission-patch-6qbpj         0/1     Completed   1          18s
    pod/ingress-nginx-controller-7bf576957f-vnf6z   0/1     Running     0          18s

    NAME                                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    service/ingress-nginx-controller             NodePort    10.96.250.186   <none>        80:32066/TCP,443:31049/TCP   18s
    service/ingress-nginx-controller-admission   ClusterIP   10.96.98.21     <none>        443/TCP                      18s

    NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/ingress-nginx-controller   0/1     1            0           18s

    NAME                                                  DESIRED   CURRENT   READY   AGE
    replicaset.apps/ingress-nginx-controller-7bf576957f   1         1         0       18s

    NAME                                       COMPLETIONS   DURATION   AGE
    job.batch/ingress-nginx-admission-create   1/1           5s         18s
    job.batch/ingress-nginx-admission-patch    1/1           6s         18s
    ```

---

### 🏗️ Step 3: Apply the Ingress Manifest

Now that the NGINX Ingress controller is in place, it’s time to apply our `ingress.yaml` file:

```bash
kubectl apply -f ingress.yaml
```

This will create the Ingress resource and make it active. But there’s one last step to make sure we can actually access it.

---

### 🌐 Step 4: Map Your Ingress to Localhost

Your Ingress is now live, but we need to make sure `myks8project` actually points to your local machine. Since we don’t have a real DNS entry for `myks8project`, we’ll simulate one using the `/etc/hosts` file on your computer.

1. **Edit your `/etc/hosts` file** (you’ll need admin or sudo permissions):

    ```bash
    sudo vim /etc/hosts
    ```

2. **Add this line** to map `myks8project` to `localhost`:

    ```bash
    127.0.0.1 myks8project
    ```

This tells your computer that any traffic to `myks8project` should go to `localhost`, which is where your Kubernetes cluster is running.

---

### 🎉 Step 5: Test the Ingress

Moment of truth—let’s see if everything’s working! Open up your browser and go to:

```bash
http://myks8project
```

If everything is set up correctly, you should see your app running! The Ingress is now handling the routing and directing traffic to your `myks8project` service. 🎉

---

### 🔍 Let’s Check What We Have So Far

Before we wrap things up, let’s review all the resources related to our app. We can use a simple `kubectl` command to list all resources associated with `myks8project`:

```bash
kubectl get all -l app=myks8project
```

This will show the pods, services, deployments, and now the Ingress we’ve just created. You should see something like this:

```bash
NAME                                READY   STATUS    RESTARTS   AGE
pod/myks8project-79cd67c7cc-5rfnf   1/1     Running   0          23h

NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/myks8project   ClusterIP   10.96.46.222   <none>        80/TCP    40m

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/myks8project   1/1     1            1           23h

NAME                                      DESIRED   CURRENT   READY   AGE
replicaset.apps/myks8project-79cd67c7cc   1         1         1       23h
```

Looks like everything is up and running smoothly!

---

## 🌟 Final Thoughts

And there you have it! We’ve successfully set up an Ingress in Kubernetes, created routing rules, and even faked a DNS entry to make it all work on your local machine. You’re one step closer to having a fully operational Kubernetes setup!

Next up, we’ll dive into scaling and monitoring your services to make sure your app is ready to handle traffic like a pro. Stay tuned!

See you in the [Part VII]({% post_url 2024-10-24-k8s-project-simplifying-kubernetes-with-helm-part-vii %}).
