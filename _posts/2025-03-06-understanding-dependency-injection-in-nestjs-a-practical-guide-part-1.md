---
layout: post
title: 'Understanding Dependency Injection in NestJS: A Practical Guide - Part 1'
description: "Learn the fundamentals of Dependency Injection in NestJS through a practical example modeling computer components. This introductory guide covers what DI is, why it matters, and how to implement your first module with proper dependency management."
date: 2025-03-06 13:25 +0100
categories: code nestjs
author: "Marcel Fenerich"
tags: [NestJS, DependencyInjection, WebDevelopment, TypeScript, Modules, Backend, NodeJS, BeginnerTutorial, SoftwareArchitecture, ModularDesign]
comments: true
---

Dependency Injection (DI) is a fundamental concept in NestJS that can greatly improve your application's architecture. In this article, I'll walk you through what DI is, why it matters, and how to implement it effectively using a practical example.

<!-- markdownlint-disable MD033 -->
{::nomarkdown}
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 400">
  <!-- Background -->
  <rect width="600" height="400" fill="#f8f9fa" rx="10" ry="10" />

  <!-- Title -->
  <text x="300" y="40" font-family="Arial" font-size="20" text-anchor="middle" font-weight="bold">NestJS Dependency Injection - Computer Example</text>

  <!-- Computer Module -->
  <rect x="150" y="70" width="300" height="70" fill="#e9ecef" stroke="#6c757d" stroke-width="2" rx="5" ry="5" />
  <text x="300" y="105" font-family="Arial" font-size="16" text-anchor="middle" font-weight="bold">Computer Module</text>
  <text x="300" y="125" font-family="Arial" font-size="12" text-anchor="middle">ComputerController</text>

  <!-- CPU and Disk Modules -->
  <rect x="100" y="170" width="180" height="70" fill="#e9ecef" stroke="#6c757d" stroke-width="2" rx="5" ry="5" />
  <text x="190" y="205" font-family="Arial" font-size="16" text-anchor="middle" font-weight="bold">CPU Module</text>
  <text x="190" y="225" font-family="Arial" font-size="12" text-anchor="middle">CPUService</text>

  <rect x="320" y="170" width="180" height="70" fill="#e9ecef" stroke="#6c757d" stroke-width="2" rx="5" ry="5" />
  <text x="410" y="205" font-family="Arial" font-size="16" text-anchor="middle" font-weight="bold">Disk Module</text>
  <text x="410" y="225" font-family="Arial" font-size="12" text-anchor="middle">DiskService</text>

  <!-- Power Module -->
  <rect x="210" y="270" width="180" height="70" fill="#e9ecef" stroke="#6c757d" stroke-width="2" rx="5" ry="5" />
  <text x="300" y="305" font-family="Arial" font-size="16" text-anchor="middle" font-weight="bold">Power Module</text>
  <text x="300" y="325" font-family="Arial" font-size="12" text-anchor="middle">PowerService</text>

  <!-- Arrows -->
  <!-- Computer -> CPU -->
  <line x1="230" y1="140" x2="190" y2="170" stroke="#495057" stroke-width="2" marker-end="url(#arrowhead)" />
  <!-- Computer -> Disk -->
  <line x1="370" y1="140" x2="410" y2="170" stroke="#495057" stroke-width="2" marker-end="url(#arrowhead)" />
  <!-- CPU -> Power -->
  <line x1="190" y1="240" x2="260" y2="270" stroke="#495057" stroke-width="2" marker-end="url(#arrowhead)" />
  <!-- Disk -> Power -->
  <line x1="410" y1="240" x2="340" y2="270" stroke="#495057" stroke-width="2" marker-end="url(#arrowhead)" />

  <!-- Arrow definition -->
  <defs>
    <marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
      <polygon points="0 0, 10 3.5, 0 7" fill="#495057" />
    </marker>
  </defs>
</svg>
{:/}
<!-- markdownlint-enable MD033 -->

## What is Dependency Injection?

Dependency Injection is a design pattern where a class receives its dependencies from external sources rather than creating them itself. In simpler terms, instead of a class creating the objects it needs, those objects are "injected" from outside.

Benefits of using DI include:

- **Decoupling**: Classes are less dependent on specific implementations
- **Testability**: Dependencies can be easily mocked during testing
- **Reusability**: Services can be shared across different parts of your application
- **Maintainability**: Changes to one part of your application affect fewer other parts

## Our Example Project: Modeling a Computer

To understand how dependency injection works in NestJS, we'll build a simple project that models a computer with different components:

1. **Power Module**: Supplies power to other components
2. **CPU Module**: Processes data, requires power to work
3. **Disk Module**: Stores data, also requires power
4. **Computer Module**: The main module that uses both CPU and disk

Each component is represented by its own module with corresponding services (or controllers). The dependencies flow as shown in the diagram above.

## Getting Started

Let's begin by setting up our project:

```bash
# Create a new NestJS project
nest new di-example

# Generate the modules
nest g module computer
nest g module cpu
nest g module disk
nest g module power

# Generate services and controller
nest g service cpu
nest g service disk
nest g service power
nest g controller computer
```

After generating these files, we need to update our `main.ts` to use our Computer module as the root:

```typescript
import { NestFactory } from '@nestjs/core';
import { ComputerModule } from './computer/computer.module';

async function bootstrap() {
  const app = await NestFactory.create(ComputerModule);
  await app.listen(3000);
}
bootstrap();
```

## Understanding NestJS Modules

Before diving into dependency injection across modules, let's clarify what NestJS modules are:

A module in NestJS is a class annotated with the `@Module()` decorator. This decorator provides metadata that NestJS uses to organize the application structure.

Each module has several properties:

- `providers`: Services that will be instantiated by the NestJS injector
- `controllers`: Controllers that need to be instantiated
- `imports`: List of imported modules that export providers needed in this module
- `exports`: Providers that should be available for modules that import this module

By default, providers created within a module are **private** - they can only be used within that module unless explicitly exported.

## Implementing the Power Module

Let's start with our "bottom-up" approach by implementing the foundational Power module:

```typescript
// power/power.service.ts
import { Injectable } from '@nestjs/common';

@Injectable()
export class PowerService {
  supplyPower(watts: number) {
    console.log(`Supplying ${watts} watts of power`);
    return watts;
  }
}
```

Now, we need to make this service available to other modules by modifying the Power module:

```typescript
// power/power.module.ts
import { Module } from '@nestjs/common';
import { PowerService } from './power.service';

@Module({
  providers: [PowerService],
  exports: [PowerService] // This makes PowerService available to other modules
})
export class PowerModule {}
```

The `exports` array is crucial here - it explicitly tells NestJS which providers from this module should be available for injection in other modules that import this one.

## Dependency Injection Between Modules: The Three-Step Process

When sharing services between different modules in NestJS, you need to follow these three steps:

1. **Export the service from its module**: Add the service to the `exports` array in its module
2. **Import the module in the target module**: Add the source module to the `imports` array in the target module
3. **Inject the service**: Use constructor injection in the target service/controller

Let's see this in action by connecting our modules together.

## Part 1: Conclusion

In this first part of our series on Dependency Injection in NestJS, we've covered:

- The concept of Dependency Injection and its benefits
- Project setup and module generation
- How NestJS modules work
- Building our first module and understanding exports

In the next article, we'll implement the CPU and Disk modules that depend on the Power module, and see how Dependency Injection works across modules in practice.

**GitHub Repository**: [https://github.com/mfenerich/nest-di](https://github.com/mfenerich/nest-di)

See you in the [Part II]({% post_url 2025-03-06-understanding-dependency-injection-in-nestjs-a-practical-guide-part-2 %}).
