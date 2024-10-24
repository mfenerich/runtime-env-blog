---
layout: post
title: K8s Project - Simplifying Kubernetes with Helm - Part VII
date: 2024-10-24 14:58 +0200
categories: Kubernetes
comments: true
author: "Marcel Fenerich"
---

👉 If you missed the previous part, check out [Part VI]({% post_url 2024-10-23-k8s-project-setting-up-an-ingress-part-vi %}).

## 🚀 K8s Project - Simplifying Kubernetes with Helm - Part VII

Ah, Kubernetes manifests… YAML files as far as the eye can see. While they’re powerful and descriptive, managing an app with tens or hundreds of these resources can feel like a balancing act. You know that feeling when you just want to change one little thing and then you realize you need to delete and reapply everything? Yeah, we’ve all been there.

But fear not, friends! [Helm](https://helm.sh/) is here to save the day and make managing Kubernetes apps a breeze. In this post, we’ll dive into what Helm is, how it works, and how to use it to manage your Kubernetes resources like a pro.

### 🧐 What Is Helm?

Helm is like the package manager of Kubernetes—think of it as Kubernetes’ version of apt or yum. Instead of manually applying your Kubernetes manifests (and deleting and reapplying them when something changes), Helm packages all those YAML files into a neat little artifact called a **Helm Chart**. With Helm, you can install, upgrade, or uninstall your entire app with a single command. 

Imagine running `helm install my-app` and having your whole app—deployments, services, ingress—spun up without breaking a sweat. If you need to change something, just update the Helm template, and then run `helm upgrade`. It’s as simple as that!

Helm consists of three key parts:

1. **Metadata**: Describes the chart’s properties—things like the name, version, and description.
2. **Values**: Variables (or “values” in Helm-speak) that are used in the chart to customize things like the number of replicas, image versions, and more.
3. **Templates**: These are your Kubernetes manifests, but with Helm magic. Instead of hardcoded values, you can use variables that can be filled in dynamically when you install or upgrade the chart.

So, enough talk—let’s get Helm installed and set up!

---

### 🧑‍💻 Step 1: Installing Helm

Helm is pretty easy to install, especially if you’re on a Mac. Just run this command:

```bash
brew install helm
```

For Windows users, you can use:

```bash
choco install helm
```

[You can find more detailed informations on the official Helm's docs.](https://helm.sh/docs/intro/install/)

Once it’s installed, let’s create a directory to store our Helm chart and get things rolling. By convention, Helm charts are stored in a directory called `chart`, so let’s stick with that:

```bash
mkdir chart
```

Now that we have our chart directory, let’s create our first Helm file: **Chart.yaml**.

---

### 📜 Step 2: Creating Chart Metadata

Inside your `chart` directory, create a file called `Chart.yaml`. This file is where we define the metadata for our Helm chart, like its name, version, and a few other properties. Here’s an example of what our `Chart.yaml` might look like:

```yaml
apiVersion: v2
name: myks8project-website
version: 1.0.0
deprecated: false
appVersion: 1.0.0
```

Let’s break that down:

- **apiVersion**: This defines the schema version for our Helm chart. Most charts use version 2 (`v2`).
- **name**: The name of the chart—this is what you’ll reference when you install or upgrade the chart.
- **version**: This is the version of the Helm chart itself (not the app). It uses **semantic versioning** (think `1.0.0`).
- **appVersion**: The version of the app that the chart installs—also using semantic versioning.
- **deprecated**: If your chart is no longer maintained, set this to `true`. For now, we’ll keep it `false` since we’re still cool with it.

Easy enough, right? Now that we’ve got the metadata set up, let’s move on to the good stuff—chart values.

---

### ⚙️ Step 3: Creating Chart Values

Next, we’ll define some values that will be used to customize our Kubernetes manifests. These are like variables that can be used inside our templates to dynamically set values like the app name, image name, and replica count.

Create a new file inside the `chart` directory called `values.yaml`. Here’s what it might look like:

```yaml
appName: myks8project
imageName: localhost:5000/myks8project
serviceName: myks8project
serviceAddress: myks8project
servicePort: 8080
replicas: 2
```

- **appName**: The name of the app, which will be used throughout our Kubernetes manifests.
- **imageName**: The Docker image that Kubernetes will pull when creating the pods.
- **replicas**: The number of pod replicas to run in the deployment.

You’ll see why these values are so handy in just a minute when we templatize our Kubernetes manifests!

To make sure everything is all right you can run

```bash
helm show all ./chart
```

You should see something like:

```bash
apiVersion: v2
appVersion: 1.0.0
name: myks8project-website
version: 1.0.0

---
appName: myks8project
imageName: localhost:5000/myks8project
serviceName: myks8project
serviceAddress: myks8project
servicePort: 8080
```
---

### 🏗️ Step 4: Templatizing Kubernetes Manifests

Now comes the fun part—turning our Kubernetes manifests into Helm templates. We’ll create a new directory inside `chart` called `templates` to store our manifest files:

```bash
mkdir chart/templates
```

Let’s start by creating and templatizing a few essential files: the `deployment.yaml`, `ingress.yaml`, and `service.yaml`.

#### **deployment.yaml**

Open your `deployment.yaml` file and replace the static values with Helm variables. For example:

```yaml
{% raw %}
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: {{ .Values.appName }}
  name: {{ .Values.appName }}
spec:
  replicas: {{ .Values.replicas }}
  selector:
    matchLabels:
      app: {{ .Values.appName }}
  strategy: {}
  template:
    metadata:
      labels:
        app: {{ .Values.appName }}
    spec:
      imagePullSecrets:
        - name: {{ .Values.imagePullSecretName }}
      containers:
      - image: {{ .Values.imageName }}
        name: {{ .Values.appName }}-{{ randAlpha 10 | lower }}
        ports:
          - containerPort: 80
        resources: {}
{% endraw %}
```

This template allows you to change the app name, replicas, and image by simply updating the `values.yaml` file. Managing multiple environments or versions becomes a breeze with this level of flexibility!

#### **service.yaml**

Next, let’s templatize the service file. This file ensures that your app gets a stable internal IP and exposes the right ports:

```yaml
{% raw %}
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: {{ .Values.appName }}
  name: {{ .Values.serviceName }}
spec:
  ports:
  - name: http
    port: {{ .Values.servicePort }}
    protocol: TCP
    targetPort: 80
  selector:
    app: {{ .Values.appName }}
  type: ClusterIP
status:
  loadBalancer: {}
{% endraw %}
```

Here, we’re using Helm variables for the app name, service name, and port. This keeps things flexible and easy to manage, especially if you need to deploy different versions of your app in the future.

#### **ingress.yaml**

Finally, let’s templatize the ingress file. This will allow external traffic to route into your app via Kubernetes’ ingress controller:

```yaml
{% raw %}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  creationTimestamp: null
  name: {{ .Values.appName }}
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: {{ .Values.serviceName }}
            port:
              number: {{ .Values.servicePort }}
        path: /
        pathType: Prefix
{% endraw %}
```

This file sets up a simple ingress for your application. It uses Helm variables for the service name and port, making it easy to update when needed. The `pathType: Prefix` ensures that all traffic hitting the root ("/") gets routed to your service.

Now that everything’s set up, let’s test the chart!

---

### 🧹 Cleaning Up Existing Resources

Before deploying our app with Helm, we need to clean up any existing Kubernetes resources that we’ve manually created for the app. This is important because Helm needs to manage all resources related to our app from scratch. If we leave the manually created resources in place, Helm won’t be able to take control of them, which could lead to conflicts during future upgrades.

Let’s delete all the resources associated with the app:

1. **Delete all resources** (Pods, Services, etc.) created earlier using the following command:
   ```bash
   kubectl delete all -l app=myks8project
   ```

2. **Delete the Ingress** resource specifically:
   ```bash
   kubectl delete ingress myks8project
   ```

This ensures that Helm can start with a clean slate and manage everything from here on out.

---

### 🧪 Step 5: Testing the Helm Chart

Now that we’ve templatized everything, it’s time to test our Helm chart. Run the following command to see if the chart renders correctly:

```bash
helm template ./chart
```

This will output your Kubernetes manifests with the values from `values.yaml` substituted in. Check to make sure everything looks good!

Once you’re happy with the output, let’s deploy it:

### Installation Command:

```bash
helm upgrade --atomic --install myks8project-website ./chart
```

This command is performing two key actions using Helm:

1. **`helm upgrade --install`**:
   - **`upgrade`**: Helm tries to upgrade an existing release. If a release with the name `myks8project-website` already exists, Helm will update it with any changes you’ve made to the chart.
   - **`install`**: If the release `myks8project-website` does not exist, Helm will install it for the first time.
   - **`myks8project-website`**: This is the release name. A Helm release is a specific deployment of a chart. In this case, the release is named `myks8project-website`, which will deploy your app using the `chart` directory.
   - **`./chart`**: This specifies the local path to the chart directory where your Helm chart files (like `Chart.yaml`, `values.yaml`, and the `templates` directory) are located.

2. **`--atomic`**:
   - This flag ensures that the installation or upgrade process is **atomic**. If anything goes wrong during the installation (e.g., if a resource fails to create), Helm will automatically roll back to the previous state.
   - It makes the process safer by preventing partial or broken deployments. If all resources don’t become healthy within Helm’s default timeout (usually 5 minutes), the release will be rolled back.

If everything went well you will see something like this:

```bash
Release "myks8project-website" does not exist. Installing it now.
NAME: myks8project-website
LAST DEPLOYED: Thu Oct 24 16:25:40 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

This command removes all the Kubernetes resources (like Pods, Services, Ingress, etc.) created by the Helm release `myks8project-website`. It essentially "undoes" the installation, cleaning up everything related to the app.

---

### 🚀 Step 6: Uninstalling the Helm Chart

Helm will apply the changes without the need to delete and recreate everything—nice, right?

And when you’re done with the app, you can clean it up with:

```bash
helm uninstall myks8project-website
```

If everything went well you will see something like this:

```bash
release "myks8project-website" uninstalled
```

It’s like having Kubernetes on easy mode.

---

## 🌟 Final Thoughts

Helm takes the pain out of managing Kubernetes apps by packaging all your YAML manifests into a single chart. With Helm, you can install, upgrade, and uninstall your app with just a few simple commands. It also makes managing multiple environments, versions, or configurations a breeze thanks to its use of templates and values.

👉 *Part VIII coming soon...*