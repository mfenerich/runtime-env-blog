---
layout: post
title: 'Understanding Dependency Injection in NestJS: A Practical Guide - Part 2'
description: "Dive deeper into sharing services across modules in NestJS as we implement CPU and Disk modules that depend on a common Power service. Master the three-step process for cross-module dependencies and understand how NestJS resolves the dependency tree."
date: 2025-03-06 13:31 +0100
categories: code nestjs
author: "Marcel Fenerich"
tags: [NestJS, CrossModuleServices, TypeScript, ModuleHierarchy, DependencyInjection, BackendDevelopment, NodeJS, IntermediateTutorial, ServiceInjection, ApplicationDesign]
comments: true
---

In the previous article, we set up our project and learned about the fundamentals of Dependency Injection in NestJS. Now, let's continue by implementing modules that depend on each other, focusing on how to properly inject services across module boundaries.

## Implementing the CPU Module

Our CPU module needs access to the Power module's services. Let's implement this relationship:

### Step 1: Import the Power Module

First, we need to import the Power module into our CPU module:

```typescript
// cpu/cpu.module.ts
import { Module } from '@nestjs/common';
import { CpuService } from './cpu.service';
import { PowerModule } from '../power/power.module';

@Module({
  imports: [PowerModule], // This gives access to exported providers from PowerModule
  providers: [CpuService],
  exports: [CpuService]  // Making CpuService available to other modules
})
export class CpuModule {}
```

### Step 2: Inject the Power Service into CPU Service

Now, we can use the PowerService in our CpuService:

```typescript
// cpu/cpu.service.ts
import { Injectable } from '@nestjs/common';
import { PowerService } from '../power/power.service';

@Injectable()
export class CpuService {
  constructor(private powerService: PowerService) {}

  compute(a: number, b: number) {
    console.log('Drawing 10 watts of power from PowerService');
    this.powerService.supplyPower(10);
    return a + b;
  }
}
```

Note how we've injected the PowerService through the constructor. NestJS's Dependency Injection system will automatically create an instance of PowerService and provide it to our CpuService.

## Implementing the Disk Module

Similarly, our Disk module also needs power. Let's implement it following the same pattern:

### Step 1: Import the Power Module into Disk Module

```typescript
// disk/disk.module.ts
import { Module } from '@nestjs/common';
import { DiskService } from './disk.service';
import { PowerModule } from '../power/power.module';

@Module({
  imports: [PowerModule],
  providers: [DiskService],
  exports: [DiskService]
})
export class DiskModule {}
```

### Step 2: Inject the Power Service into Disk Service

```typescript
// disk/disk.service.ts
import { Injectable } from '@nestjs/common';
import { PowerService } from '../power/power.service';

@Injectable()
export class DiskService {
  constructor(private powerService: PowerService) {}

  getData() {
    console.log('Drawing 20 watts of power from PowerService');
    this.powerService.supplyPower(20);
    return 'data';
  }
}
```

## Implementing the Computer Module

Now that we have our CPU and Disk modules set up, we need to connect them to our Computer module:

### Step 1: Import the CPU and Disk Modules

```typescript
// computer/computer.module.ts
import { Module } from '@nestjs/common';
import { ComputerController } from './computer.controller';
import { CpuModule } from '../cpu/cpu.module';
import { DiskModule } from '../disk/disk.module';

@Module({
  imports: [CpuModule, DiskModule],
  controllers: [ComputerController]
})
export class ComputerModule {}
```

### Step 2: Inject the CPU and Disk Services into the Computer Controller

```typescript
// computer/computer.controller.ts
import { Controller, Get } from '@nestjs/common';
import { CpuService } from '../cpu/cpu.service';
import { DiskService } from '../disk/disk.service';

@Controller('computer')
export class ComputerController {
  constructor(
    private cpuService: CpuService,
    private diskService: DiskService
  ) {}

  @Get()
  run() {
    return [
      this.cpuService.compute(1, 2),
      this.diskService.getData()
    ];
  }
}
```

## Important Note on Module Dependencies

An important point to understand: The Computer module does not need to directly import the Power module. Since both CPU and Disk modules already import the Power module, the Computer module inherits these dependencies.

This demonstrates the hierarchical nature of dependency injection in NestJS - dependencies are resolved through the module tree.

<!-- markdownlint-disable MD033 -->
{::nomarkdown}
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 280">
  <!-- Background -->
  <rect width="600" height="280" fill="#f8f9fa" rx="10" ry="10" />

  <!-- Title -->
  <text x="300" y="30" font-family="Arial" font-size="18" text-anchor="middle" font-weight="bold">The 3-Step Process for Cross-Module Dependency Injection</text>

  <!-- Step 1 -->
  <rect x="30" y="60" width="160" height="180" fill="#e9ecef" stroke="#6c757d" stroke-width="2" rx="5" ry="5" />
  <text x="110" y="85" font-family="Arial" font-size="16" text-anchor="middle" font-weight="bold">Step 1</text>
  <text x="110" y="110" font-family="Arial" font-size="14" text-anchor="middle">Export the Service</text>

  <rect x="50" y="125" width="120" height="100" fill="white" stroke="#495057" rx="3" ry="3" />
  <text x="60" y="145" font-family="monospace" font-size="11">@Module({</text>
  <text x="60" y="165" font-family="monospace" font-size="11">  providers: [</text>
  <text x="60" y="185" font-family="monospace" font-size="11">    PowerService</text>
  <text x="60" y="205" font-family="monospace" font-size="11">  ],</text>
  <text x="60" y="225" font-family="monospace" font-size="11" fill="#d63384">  exports: [</text>
  <text x="60" y="245" font-family="monospace" font-size="11" fill="#d63384">    PowerService</text>
  <text x="60" y="265" font-family="monospace" font-size="11">  ]</text>
  <text x="60" y="285" font-family="monospace" font-size="11">})</text>

  <!-- Step 2 -->
  <rect x="220" y="60" width="160" height="180" fill="#e9ecef" stroke="#6c757d" stroke-width="2" rx="5" ry="5" />
  <text x="300" y="85" font-family="Arial" font-size="16" text-anchor="middle" font-weight="bold">Step 2</text>
  <text x="300" y="110" font-family="Arial" font-size="14" text-anchor="middle">Import the Module</text>

  <rect x="240" y="125" width="120" height="100" fill="white" stroke="#495057" rx="3" ry="3" />
  <text x="250" y="145" font-family="monospace" font-size="11">@Module({</text>
  <text x="250" y="165" font-family="monospace" font-size="11" fill="#d63384">  imports: [</text>
  <text x="250" y="185" font-family="monospace" font-size="11" fill="#d63384">    PowerModule</text>
  <text x="250" y="205" font-family="monospace" font-size="11">  ],</text>
  <text x="250" y="225" font-family="monospace" font-size="11">  providers: [</text>
  <text x="250" y="245" font-family="monospace" font-size="11">    CpuService</text>
  <text x="250" y="265" font-family="monospace" font-size="11">  ]</text>
  <text x="250" y="285" font-family="monospace" font-size="11">})</text>

  <!-- Step 3 -->
  <rect x="410" y="60" width="160" height="180" fill="#e9ecef" stroke="#6c757d" stroke-width="2" rx="5" ry="5" />
  <text x="490" y="85" font-family="Arial" font-size="16" text-anchor="middle" font-weight="bold">Step 3</text>
  <text x="490" y="110" font-family="Arial" font-size="14" text-anchor="middle">Inject the Service</text>

  <rect x="430" y="125" width="120" height="100" fill="white" stroke="#495057" rx="3" ry="3" />
  <text x="440" y="145" font-family="monospace" font-size="11">@Injectable()</text>
  <text x="440" y="165" font-family="monospace" font-size="11">export class </text>
  <text x="440" y="185" font-family="monospace" font-size="11">CpuService {</text>
  <text x="440" y="205" font-family="monospace" font-size="11" fill="#d63384">  constructor(</text>
  <text x="440" y="225" font-family="monospace" font-size="11" fill="#d63384">    private power</text>
  <text x="440" y="245" font-family="monospace" font-size="11" fill="#d63384">      :PowerService</text>
  <text x="440" y="265" font-family="monospace" font-size="11">  ) {}</text>
  <text x="440" y="285" font-family="monospace" font-size="11">}</text>

  <!-- Arrows -->
  <line x1="190" y1="150" x2="220" y2="150" stroke="#495057" stroke-width="2" marker-end="url(#arrowhead)" />
  <line x1="380" y1="150" x2="410" y2="150" stroke="#495057" stroke-width="2" marker-end="url(#arrowhead)" />

  <!-- Arrow definition -->
  <defs>
    <marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
      <polygon points="0 0, 10 3.5, 0 7" fill="#495057" />
    </marker>
  </defs>
</svg>
{:/}
<!-- markdownlint-enable MD033 -->

## Understanding How NestJS Resolves Dependencies

Behind the scenes, NestJS creates a dependency graph to track which services depend on which other services. When a module imports another module, NestJS makes all the exported providers from the imported module available to the importing module.

When our application starts, NestJS:

1. Creates a dependency injection container
2. Resolves all dependencies in the correct order
3. Instantiates all the services as needed
4. Injects dependencies in the right places

This means that our PowerService is instantiated only once, and the same instance is injected into both the CpuService and DiskService.

## Testing Our Implementation

Let's test our implementation by running the application:

```bash
# Start the application
npm run start:dev
```

Now, if we navigate to [http://localhost:3000/computer](http://localhost:3000/computer) in our browser, we should see:

```json
[3, "data"]
```

And in our console, we should see:

```bash
Drawing 10 watts of power from PowerService
Supplying 10 watts of power
Drawing 20 watts of power from PowerService
Supplying 20 watts of power
```

This confirms that our dependency injection is working correctly! The ComputerController successfully calls methods on both CpuService and DiskService, which in turn use the PowerService.

## Best Practices for Dependency Injection in NestJS

Based on our example, here are some best practices to follow:

1. **Keep modules focused**: Each module should have a clear, single responsibility.

2. **Export only what's needed**: Only add services to the exports array if they need to be used outside the module.

3. **Follow the three-step process**:
   - Export the service from its module
   - Import the module where needed
   - Inject the service via constructor

4. **Leverage the module hierarchy**: Don't import modules unnecessarily if they're already available through the module tree.

5. **Use private class properties**: When injecting services, use the `private` keyword in the constructor to automatically assign the dependency to a class property.

## Common Pitfalls

1. **Forgetting to export a service**: If you're trying to inject a service but getting an error, check if the service is exported from its module.

2. **Circular dependencies**: Be careful not to create circular dependencies between modules. NestJS can handle them in certain cases, but they should generally be avoided.

3. **Overusing providers**: Not everything needs to be a provider. Consider using simple utility functions for operations that don't require state or other dependencies.

## Conclusion

Dependency Injection in NestJS provides a powerful way to structure your application with clear separation of concerns and maintainable code. By understanding how modules, providers, and the dependency injection system work together, you can create applications that are:

- Easy to test
- Easy to maintain
- Highly modular
- Well-organized

The three-step process for sharing services between modules is straightforward once you understand it, and it forms the backbone of how NestJS applications are structured.

In the next article, we'll dive deeper into more advanced Dependency Injection concepts in NestJS, including custom providers, dynamic modules, and scoped providers.
