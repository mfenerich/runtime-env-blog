---
layout: post
title: 'K8s-citus-patroni Project - Deploying Patroni and Citus on Kubernetes: From Zero to Cluster Hero - Part II'
date: 2025-01-04 17:22 +0100
categories:
  - Kubernetes
  - Patroni
  - Citus
tags:
  - Kubernetes
  - Databases
  - PostgreSQL
  - High Availability
  - Scalability
comments: true
author: "Marcel Fenerich"
---

### **Deploying Patroni and Citus on Kubernetes: From Zero to Cluster Hero 🚀**

Welcome back, fearless database wranglers! In this post, we’ll dive deeper into the *how* and *why* of running **Patroni** and **Citus** on **Kubernetes**, specifically focusing on best practices and actionable steps. If you're looking to build a highly-available, horizontally scalable PostgreSQL cluster with some serious data superpowers, buckle up (and maybe grab a 🍕 for the road). We’ve got you covered. This post will also explain how to run the project using Kind (Kubernetes in Docker) on your local environment for quick (and hopefully painless) prototyping. 💻

All the code shown in this post can be found in the [**GitHub repository**](https://github.com/mfenerich/patroni-citus-demo). Feel free to clone it and follow along — but please, no pushing suspiciously large binary files into the repo! 🤭

---

## **1. Understanding the Tools 🛠️**

Before we jump into the Kubernetes manifests, let’s revisit our cast of characters. Think of them as the Avengers of the database world, only with fewer spandex suits:

1. **PostgreSQL**
   The reliable, open-source relational database that powers countless applications. Loved by developers worldwide for its robustness and feature set, it’s basically the 🍰 of databases — everybody wants a slice.

2. **Citus**
   A PostgreSQL extension that transforms a single-node database into a distributed system by sharding and replicating data across multiple worker nodes. Perfect for multi-tenant SaaS and real-time analytics. This is your friendly neighborhood sidekick that makes scaling horizontally look easy. 🕹️

3. **Patroni**
   A battle-tested high-availability solution for PostgreSQL. Patroni manages leader election, automatic failover, and replication setup. Think of it as your cluster’s personal bodyguard — always on alert, ready to take action at a moment’s notice. 🛡️

### **How They Work Together**

- **Patroni** ensures there is always one active PostgreSQL leader and manages replicas that continuously receive WAL logs for replication.
- **Citus** adds the ability to scale horizontally by delegating queries from a *coordinator* node to multiple *worker* nodes.
- **Kubernetes** orchestrates containers and handles aspects like scaling, networking, storage, and more.

By combining these three technologies, you can build a distributed PostgreSQL cluster that can withstand failures (thanks to Patroni) and scale out to accommodate large workloads (thanks to Citus), all managed seamlessly by Kubernetes. It’s like having an army of well-trained pizza chefs who never burn the crust! 🍕

---

## **2. Why Use StatefulSets Instead of Deployments? 🤔**

Databases are stateful workloads, and in Kubernetes, the **StatefulSet** resource is specifically designed for these scenarios. Here are four key reasons why **StatefulSets** are preferred over **Deployments** for database clusters:

1. **Stateful Workloads Need Persistent Storage**
   - **StatefulSet**: Each pod gets its own **persistent volume** (PV). Even if a pod is rescheduled, its storage persists and can be reattached, preserving data like precious leftover pizza in the fridge.
   - **Deployment**: Better suited for stateless applications, where ephemeral storage or losing a pod doesn’t impact persistent data.

2. **Stable Network Identity**
   - **StatefulSet**: Pods have predictable DNS names (e.g., `citus-worker-0`, `citus-worker-1`), which is crucial for a distributed system like Citus.
   - **Deployment**: Pods get randomly generated names, making it harder to maintain consistent connections between a coordinator and its workers.

3. **Ordered, Graceful Updates and Scaling**
   - **StatefulSet**: Updates pods **sequentially**, ensuring the cluster remains consistent. This is essential for rolling updates in a database environment (no “pizza topping missing” surprises).
   - **Deployment**: Updates and scales pods in parallel, which can be disruptive to a stateful system if not carefully managed.

4. **Leader Election and Failover**
   - Patroni uses a Distributed Configuration Store (like Etcd) to elect a PostgreSQL leader. Having each node consistently identified and updated ensures failovers happen smoothly and the correct replica becomes the new leader. 🍀

---

## **3. Patroni Configuration: `config.yml`**

Patroni’s configuration file (`config.yml`) defines how the cluster behaves, which DCS (e.g., Etcd) it relies on, and how it manages PostgreSQL settings. An example configuration might look like this:

```yaml
scope: postgres-cluster
namespace: default
name: citus-coordinator

restapi:
  listen: 0.0.0.0:8008
  connect_address: citus-coordinator:8008

etcd:
  host: etcd.default.svc.cluster.local:2379

bootstrap:
  dcs:
    postgresql:
      use_pg_rewind: true
      parameters:
        max_connections: 100
        shared_buffers: 512MB
        wal_level: logical
        synchronous_commit: "on"
        max_wal_senders: 10
        max_replication_slots: 10
  initdb:
    - encoding: UTF8
    - locale: en_US.UTF-8
  users:
    admin:
      password: admin_pass
      options:
        - createrole
        - createdb

postgresql:
  listen: 0.0.0.0:5432
  connect_address: citus-coordinator:5432
  authentication:
    replication:
      username: replicator
      password: replicate_pass
    superuser:
      username: postgres
      password: postgres_pass
  data_dir: /var/lib/postgresql/data
```

**Key Sections**:

- **scope** & **namespace**: Logical grouping of cluster nodes.
- **restapi**: Patroni’s management API, used for cluster-level operations.
- **etcd**: Points Patroni to the Etcd endpoint for leader election data.
- **bootstrap**: Defines the initial PostgreSQL configuration and default credentials (like that secret sauce recipe).
- **postgresql**: Contains the main database settings, including the data directory and authentication.

---

## **4. Citus Configuration**

> **Note**: In this project, we’re not actually running the following Citus commands as part of the deployment steps. They’re here for explanation and clarity on how you might set up Citus once the cluster is running. Use them as references if you need to manually configure a coordinator to recognize new workers or enable the Citus extension within PostgreSQL. Think of it like reading the instructions on how to assemble furniture before diving in — wise, but optional until you're really setting things up. 🪑🔧

### **Coordinator Node**

The coordinator node manages metadata and query distribution. Typically, you would:

1. **Enable the Extension**

   ```sql
   CREATE EXTENSION IF NOT EXISTS citus;
   ```

2. **Add Worker Nodes**

   ```sql
   SELECT master_add_node('citus-worker-1', 5432);
   SELECT master_add_node('citus-worker-2', 5432);
   ```

### **Worker Nodes**

Workers handle actual data storage and query execution. Minimal setup is needed beyond enabling the extension:

```sql
CREATE EXTENSION IF NOT EXISTS citus;
```

---

## **5. Kubernetes StatefulSet: Putting It All Together 🏗️**

Below is a high-level example of a **StatefulSet** YAML for a single coordinator node (Patroni + Citus). In practice, you’d also define a set of worker nodes, each with its own StatefulSet (or a single StatefulSet with multiple replicas, depending on your topology).

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: citus-coordinator
spec:
  replicas: 1
  selector:
    matchLabels:
      app: citus-coordinator
  serviceName: citus-coordinator-svc
  template:
    metadata:
      labels:
        app: citus-coordinator
    spec:
      containers:
      - name: citus
        image: my-citus-image:latest
        ports:
        - containerPort: 5432
        env:
        - name: PATRONI_SCOPE
          value: postgres-cluster
        - name: PATRONI_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: ETCD_HOST
          value: etcd.default.svc.cluster.local:2379
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

**Important Details**:

1. **`serviceName`**: The `serviceName` (`citus-coordinator-svc`) matches the headless service for internal DNS resolution.
2. **`volumeClaimTemplates`**: Each pod automatically receives its own persistent volume claim (PVC), providing data durability (like an infinite pizza box with your name on it).
3. **`env`**: Environment variables feed into Patroni’s config, pointing to Etcd, the cluster scope, etc.

---

## **6. Sharding & Table Distribution 🍕🔪**

So, how exactly does **Citus** slice and dice your data so that it can be spread across multiple worker nodes? Let’s dive into the delicious details:

### **Hash-Sharding & Reference Tables**

1. **Hash-Sharded Tables**:
   - **What It Is**: Citus assigns rows to shards based on a hash of a distribution column (e.g., `customer_id`). This aims for an even distribution of data across worker nodes.
   - **Why It’s Awesome**: Perfect for multi-tenant use cases or scenarios where you need your data to be uniformly spread out for balanced load. No single worker becomes “the chosen one” that does all the work.
   - **How to Use It**:

     ```sql
     -- On the coordinator node
     CREATE TABLE orders (
       order_id bigserial,
       customer_id bigint,
       amount numeric,
       ...
     );

     -- Convert it to a distributed table based on the chosen column:
     SELECT create_distributed_table('orders', 'customer_id', 'hash');
     ```

2. **Reference Tables**:

   - **What It Is**: Smaller, often-joined “dimension” tables that need to be copied in full to every worker node.
   - **Why It’s Awesome**: Handy when you have lookup data (like country codes or currency types) that’s repeatedly used across different shards. Minimizes cross-node chatter.
   - **How to Use It**:

     ```sql
     -- On the coordinator node
     CREATE TABLE countries (
       country_id serial PRIMARY KEY,
       country_name text
     );

     -- Mark it as a reference table
     SELECT create_reference_table('countries');
     ```

### **Range-Sharding (Time-Series or Sequential Data)**

1. **When to Use**:

   If your data is time-based (e.g., logs, events) or you often query by date ranges, you can shard using a **range** distribution strategy (though you might have to customize the approach slightly with Citus).
2. **Benefits**:

   - Keep data from the same time intervals together, making range queries more efficient.
   - Great for partition-like behavior on top of distributed tables.
3. **Potential Gotchas**:

   - **Hot Shards**: If all recent data goes to one shard, you might have an imbalance. Sometimes a hybrid approach (range + hash) is used in advanced setups.

### **Data Movement & Scaling**

- **Adding More Workers**: When you add new workers, you can rebalance shards to distribute existing data across the new nodes. Citus provides commands like `rebalance_table_shards()`.
- **Shard Resizing**: In certain advanced cases, you might want more granular shards or fewer shards if the cluster changes in size significantly.

### **Real-World Considerations**

1. **Selecting a Distribution Column**

   - Ensure it’s something that’s part of frequent joins or filters (e.g., `customer_id`).
   - Avoid columns with very few distinct values (leading to fewer shards).
   - Avoid columns with extremely high skew (where one value appears way more often than others).

2. **Multi-Tenant Patterns**

   - **One Tenant Per Shard**: Great for strict data isolation. Also easy to drop shards for offboarded tenants.
   - **Shared Tenant Shards**: More flexible. Tenants are hashed across shards, but you lose guaranteed isolation.

3. **Coordinator Resources**

   - Make sure your coordinator node has enough CPU and memory to handle metadata and routing queries. It’s the brains behind the operation; don’t starve it!

Overall, effectively distributing your tables in Citus is the linchpin of a well-performing, scalable cluster. Choose the right distribution strategy, keep an eye on data skew, and watch your queries fly! 🚀

---

## **7. Best Practices 🌟**

1. **Use Kubernetes Secrets**: Store usernames, passwords, and sensitive config in Secrets rather than in plain YAML. Nobody likes leaving the secret sauce recipe out in the open!
2. **High-Availability DCS**: Patroni needs a robust Distributed Configuration Store (Etcd, Consul, Zookeeper). Make sure it’s also deployed in an HA fashion; you don’t want your HA solution to be single-point-of-failure. That’s like having an umbrella made of paper. ☂️
3. **Monitoring**: Hook up Prometheus or another monitoring stack. Both Patroni and Citus export vital metrics that can help you keep tabs on performance and catch issues early.
4. **Automate with CI/CD**: Use GitOps or similar approaches to automatically deploy changes to your cluster. This ensures consistent environments from dev to prod, which is particularly handy when your boss asks for “just one more node” at 5 PM on a Friday. 😅

---

## **8. Running the Project Locally with Kind 🏠**

To try this setup locally without impacting existing Kubernetes clusters, you can use **Kind** (Kubernetes in Docker). The [**GitHub repository**](https://github.com/mfenerich/patroni-citus-demo) contains everything you need.

### **Prerequisites**

- [Docker](https://www.docker.com/)
- [Kind](https://kind.sigs.k8s.io/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/)

### **Setup Instructions**

1. **Clone the Repository**

   ```bash
   git clone https://github.com/mfenerich/patroni-citus-demo.git
   cd patroni-citus-demo
   ```

2. **Create a Kind Cluster**

   ```bash
   kind create cluster --name patroni-citus-demo
   ```

   It’s kind of a cluster, but in a good way! 🤪

3. **Build and Load Docker Image**

   Build the Docker image using the provided `Dockerfile`:

   ```bash
   docker build -f Dockerfile -t patroni-citus-k8s .
   ```

   Then load it into your Kind cluster:

   ```bash
   kind load docker-image patroni-citus-k8s --name patroni-citus-demo
   ```

4. **Deploy on Kubernetes**

   Apply the Kubernetes configuration:

   ```bash
   kubectl apply -f citus_k8s.yaml
   ```

   This will create the necessary StatefulSets, Services, and other resources. **Voila!** You’re halfway to being a cluster hero. 🦸

5. **Verify the Deployment**

   - Check the StatefulSets:

     ```bash
     kubectl get sts
     ```

   - Check the pods and their roles:

     ```bash
     kubectl get pods -l cluster-name=citusdemo -L role
     ```

   Grab another slice of pizza while it all spins up. 🍕

### **Repository Files**

- **Dockerfile**: Defines the container environment for running Patroni and Citus.
- **citus_k8s.yaml**: Main Kubernetes manifest for deploying coordinator and worker nodes.
- **entrypoint.sh**: Entrypoint script that initializes Patroni and sets up Citus.

---

**Got questions or feedback?** Feel free to drop a comment below or open an issue in the [GitHub repository](https://github.com/mfenerich/patroni-citus-demo). Until next time, happy clustering!
