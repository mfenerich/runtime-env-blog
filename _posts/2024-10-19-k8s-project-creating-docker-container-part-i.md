---

layout: post  
title: "K8s Project - Creating a Docker Container - Part I"
date: 2024-10-19 13:09 +0200  
categories: Kubernetes  

---

# 🚀 Introduction

Before we dive into creating a Kubernetes (K8s) cluster, it's essential to first create the Docker container we'll orchestrate, right? Yes! So let's create a very simple Docker container. Of course, we know that if you have only one or two containers, you don’t need K8s. But we’re doing this for learning purposes. 😊

Before we begin, I'd like to emphasize that Docker is not the only container runtime K8s can run. [Here’s a link](https://kubernetes.io/docs/setup/production-environment/container-runtimes/) to the supported ones. However, we’re sticking with Docker since it’s probably the most widely used.

We’ll create an Nginx container to serve a static webpage. It’s perfect for our purpose: keeping a container running indefinitely, having something visual to check (the webpage), and later on using Kubernetes Service, Ingress Controllers, Load Balancers, and other cool K8s features to make our amazing website available to the world. 🌍

# 🔧 What You’ll Need to Accomplish This First Step

- Docker installation. Here’s the [official link](https://docs.docker.com/engine/install/) on how to install Docker on your machine.
- A text editor.

# 🛠️ Create Our Docker Container

Let’s get started by creating our simple static website and “dockerizing” it.

First, create a file called `index.html` and add the following content:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Static Website</title>
</head>
<body>
    <h1>My Static Website</h1>
    <h2>Hello World!!!</h2>
    <p>If you can see me, I'm working :)</p>
</body>
</html>
```

Awesome job! 🎉

Next, we need to “dockerize” our website. Create a file called `Dockerfile` and paste the following content:

```bash
FROM nginx:alpine

LABEL maintainer="Your Name <name@email.com>"
LABEL version="1.0"
LABEL description="A simple project to serve a static page with Nginx in Docker."

COPY index.html /usr/share/nginx/html/

EXPOSE 80
```

Perfect! Now, all we have to do is run our Docker container and check if it's properly running. Open your terminal, build, and run your Docker container:

```bash
docker build -t my-static-website .
docker run --rm -p 8080:80 my-static-website
```

If everything went well, you can open your browser and visit:

```
http://localhost:8080/
```

You should see something like this:

![alt text](/assets/images/running-ngix-docker-project-creating-docker-container.part-i.png)

Great job.

See you in the next post.

Enjoy ;)