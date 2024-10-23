---
layout: post
title: K8s Project - Understanding and Creating a Service - Part V
date: 2024-10-23 13:13 +0200
categories: Kubernetes
comments: true
author: "Marcel Fenerich"
---

👉 If you missed the previous part, check out [Part IV]({% post_url 2024-10-22-k8s-project-creating-a-deployment-with-kubernetes-part-iv %}).

## 🚀 K8s Project - Understanding and Creating a Service - Part V

So, you’ve got your pods running in Kubernetes, your application is alive, and everything seems great! But, let’s face it—port forwarding into your cluster every time you want to access the app isn’t the most user-friendly solution, right? That’s where **Kubernetes services** come in to save the day! In this post, we’ll walk through the concept of services in Kubernetes, why they’re awesome, and how to create one for your app. Ready? Let’s dive in!

### 🧐 What Is a Service in Kubernetes?

A **service** in Kubernetes is like your app’s personal receptionist—it makes sure that your users (and other apps) can access your pods without needing to know exactly where they are. Think of it as a single point of entry that balances traffic across all your app’s pods. It’s like Kubernetes saying, “Don’t worry about finding the pods, I got this!”

But wait, there’s more! A service also assigns a stable **IP address** and **DNS name** to your app, so even if your pods change, the service remains the same. Pretty neat, right?

### 🧑‍💻 Step 1: Let’s Create a Service

Now, instead of making your users struggle with port forwarding, let’s create a service that will act as a single point of entry for your app. The service will handle distributing requests between your pods, and users can access your app easily.

In Kubernetes, there are different types of services, but for now, we’ll focus on the most common one: the **ClusterIP** service. This type of service provides an internal, stable IP address that other services and pods within your Kubernetes cluster can use to find your app.

So, here’s how we create it:

1. **Create the Service YAML file**:
    We’ll use `kubectl` to generate a basic service YAML file, similar to how we created the deployment:

    ```bash
    kubectl create service clusterip myks8project --tcp=80:80 --dry-run=client -o yaml > service.yaml
    ```

    This command creates a service that exposes port **80** from the pods (since our app runs on port 80 inside the container) and maps it to port **80** of the service itself. The `--dry-run=client` flag ensures we just create the YAML without applying it yet. Let’s open this file and take a look at what we’ve got.

---

### 📜 Understanding the Service Manifest

Just like with the deployment, the service also has a manifest that describes its configuration. Here’s what the generated YAML might look like:

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: myks8project
  name: myks8project
spec:
  ports:
  - name: 80-80
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: myks8project
  type: ClusterIP
status:
  loadBalancer: {}
```

Here’s a breakdown of the important parts:

- **apiVersion**: This specifies the API version used to define the service. In this case, it’s `v1` because we’re creating a basic service.
- **kind**: It tells Kubernetes what resource we’re dealing with, which is a **Service**.
- **metadata**: The **name** of the service is `myks8project`.
- **selector**: This is where the magic happens! The selector links the service to the correct set of pods using the `app=myks8project` label. This way, the service knows which pods to route traffic to.
- **ports**: We specify that traffic will come through **port 80** and will be routed to **port 80** on the pods.
- **type**: We’re using a **ClusterIP** service, which exposes the service only within the cluster.

---

### 🔧 Step 2: Apply the Service

Now that our service manifest is ready, let’s apply it and create the service in Kubernetes.

1. **Apply the service**:

    ```bash
    kubectl apply -f service.yaml
    ```

    If everything goes well, you’ll see a message like:

    ```bash
    service/myks8project created
    ```

2. **Verify the service** by running:

    ```bash
    kubectl get services
    ```

    You should see your service listed with its own **ClusterIP** (the internal IP address Kubernetes has assigned to it).

---

### 🎯 Step 3: Testing the Service

Alright, our service is now live and should be routing traffic to our pods. But let’s confirm that everything is working as expected. Instead of using the deployment name for port forwarding like we did earlier, we’ll now use the service name:

1. **Forward the port using the service**:

    ```bash
    kubectl port-forward service/myks8project 8080:80
    ```

    This command forwards traffic from **localhost:8080** to the service’s port **80**, which in turn forwards it to the pods.

2. **Test the service**:

    Head to your browser and open:

    ```bash
    http://localhost:8080
    ```

    You should see your **Hello World!!!** website running smoothly! 🎉

---

### 🧠 Quick Recap on What We Just Did

We just created a **Kubernetes service**—a stable, single point of entry for your application inside the Kubernetes cluster. By using the **ClusterIP** type of service, we made sure that traffic can flow seamlessly between your users and the right pods, all without having to deal with port forwarding directly into the cluster every time.

- **Services** provide stable IP addresses and DNS names, making your app accessible to other services and users.
- The **selector** tells the service which pods to route traffic to based on labels.
- The service acts like a smart load balancer for your pods.

Here’s an improved version of the new section, adding more explanations:

---

#### 🔍 Let's Check All We Have Got So Far

At this point, it’s important to see what resources Kubernetes has created for your app. To do that, we can list all the Kubernetes resources associated with our app using the **label selector** (`-l`). Labels are key in Kubernetes because they allow you to group and filter resources by custom tags (like `app=myks8project`), which is super handy when you want to see everything related to a specific app.

To check all the resources we've created for our app, run the following command:

```bash
kubectl get all -l app=myks8project
```

This command will return all resources (pods, services, deployments, etc.) that have the label `app=myks8project`. You should see something like this:

```bash
NAME                                READY   STATUS    RESTARTS   AGE
pod/myks8project-79cd67c7cc-5rfnf   1/1     Running   0          23h

NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/myks8project   ClusterIP   10.96.46.222   <none>        80/TCP    10m

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/myks8project   1/1     1            1           23h

NAME                                      DESIRED   CURRENT   READY   AGE
replicaset.apps/myks8project-79cd67c7cc   1         1         1       23h
```

Let’s break down what we’re seeing:

1. **Pods**:
   - The pod `myks8project-79cd67c7cc-5rfnf` is listed under the `pod/` section, indicating that one replica of our app is currently running (`1/1` under **READY**). This means our app is successfully running inside the Kubernetes cluster.

2. **Service**:
   - The `service/myks8project` entry shows the **ClusterIP** service we created earlier. This service is accessible internally within the cluster through the IP `10.96.46.222` and is exposing port **80**. There’s no **EXTERNAL-IP** here because we haven’t set it up for external access yet, which is fine for now.

3. **Deployment**:
   - The deployment `deployment.apps/myks8project` shows that it’s running 1 pod (1/1 under **READY**) and that everything is up-to-date with no issues.

4. **ReplicaSets**:
   - ReplicaSets manage the pods. Here we see 1 ReplicaSet: (`myks8project-79cd67c7cc`) which has 1 pod running, indicating it’s the current active ReplicaSet.

Using the `-l app=myks8project` filter is not only useful for viewing all related resources but also helpful for ensuring that your setup is running as expected after applying the manifests. It’s a great way to troubleshoot if anything looks off.

---

### 🧑‍💻 Wrapping Up

Congrats! You’ve now leveled up your Kubernetes game by creating a service that manages traffic routing within your cluster. No more manual port forwarding—now you’ve got a scalable, maintainable way to access your app. 🙌

But there’s more! In the next part, we’ll dive deeper into **ingress controllers**, which take this a step further by exposing your services to the outside world with real domain names. Ready to learn how to make your app publicly accessible? Stay tuned for more Kubernetes adventures!

See you in the [Part VI]({% post_url 2024-10-23-k8s-project-setting-up-an-ingress-part-vi %}).
