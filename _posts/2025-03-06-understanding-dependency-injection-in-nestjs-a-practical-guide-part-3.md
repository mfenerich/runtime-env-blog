---
layout: post
title: 'Understanding Dependency Injection in NestJS: A Practical Guide - Part 3'
description: "Explore advanced Dependency Injection concepts in NestJS including custom providers, scoped instances, dynamic modules, and testing strategies. Learn professional patterns for building flexible, maintainable applications with sophisticated dependency management."
date: 2025-03-06 13:34 +0100
categories: code nestjs
author: "Marcel Fenerich"
tags: [NestJS, AdvancedDependencyInjection, CustomProviders, DynamicModules, Testing, TypeScript, SoftwareArchitecture, EnterprisePatterns, BestPractices, AdvancedTutorial]
comments: true
published: false
---

In our previous articles, we explored the fundamentals of Dependency Injection (DI) in NestJS and how to share services between modules. Now, let's delve into more advanced concepts that will give you greater flexibility and control over your application's architecture.

## Custom Providers

So far, we've seen the standard way of providing services using the `providers` array in the `@Module()` decorator. However, NestJS offers more advanced provider registration options through custom providers.

### Value Providers

Value providers allow you to use a constant value instead of a service instance:

```typescript
@Module({
  providers: [
    {
      provide: 'CONFIG',
      useValue: {
        apiUrl: 'https://api.example.com',
        timeout: 3000
      }
    }
  ]
})
```

You can inject this using the `@Inject()` decorator:

```typescript
@Injectable()
export class AppService {
  constructor(@Inject('CONFIG') private config: any) {}

  getApiUrl() {
    return this.config.apiUrl;
  }
}
```

### Class Providers

Class providers give you more control over which class is instantiated:

```typescript
@Module({
  providers: [
    {
      provide: PowerService,
      useClass: EnhancedPowerService
    }
  ]
})
```

This tells NestJS: "Whenever someone asks for PowerService, give them an instance of EnhancedPowerService instead."

### Factory Providers

Factory providers allow you to create providers dynamically:

```typescript
@Module({
  providers: [
    {
      provide: 'DATABASE_CONNECTION',
      useFactory: (configService: ConfigService) => {
        // Dynamic logic to create a database connection
        const connection = createConnection(configService.getDatabaseConfig());
        return connection;
      },
      inject: [ConfigService] // Dependencies for the factory function
    }
  ]
})
```

## Enhancing Our Computer Example

Let's enhance our computer example to use some of these advanced provider techniques:

### Using a Factory Provider for Power Configuration

Imagine we want to configure our PowerService based on the environment (low power mode vs. high performance):

```typescript
// power/power.module.ts
import { Module } from '@nestjs/common';
import { PowerService } from './power.service';

@Module({
  providers: [
    {
      provide: 'POWER_MODE',
      useValue: process.env.POWER_MODE || 'normal'
    },
    PowerService
  ],
  exports: [PowerService]
})
export class PowerModule {}
```

```typescript
// power/power.service.ts
import { Injectable, Inject } from '@nestjs/common';

@Injectable()
export class PowerService {
  private powerMultiplier: number;

  constructor(@Inject('POWER_MODE') private powerMode: string) {
    switch (powerMode) {
      case 'low':
        this.powerMultiplier = 0.5;
        break;
      case 'high':
        this.powerMultiplier = 2;
        break;
      default:
        this.powerMultiplier = 1;
    }
  }

  supplyPower(watts: number) {
    const actualWatts = watts * this.powerMultiplier;
    console.log(`Supplying ${actualWatts} watts of power (${this.powerMode} mode)`);
    return actualWatts;
  }
}
```

## Scoped Providers

By default, NestJS providers are singletons - one instance is shared across the entire application. However, there are use cases where you might want different scopes:

### Request Scope

A new instance is created for each incoming request:

```typescript
@Injectable({ scope: Scope.REQUEST })
export class UserService {
  // This instance will be created for each request
}
```

### Transient Scope

A new instance is created each time it's injected:

```typescript
@Injectable({ scope: Scope.TRANSIENT })
export class CacheService {
  // A new instance will be created every time this service is injected
}
```

## Dynamic Modules

Dynamic modules allow you to create modules that can be customized when they're imported. This is particularly useful for creating reusable modules that need configuration.

Let's refactor our PowerModule to be dynamic:

```typescript
// power/power.module.ts
import { Module, DynamicModule } from '@nestjs/common';
import { PowerService } from './power.service';

@Module({})
export class PowerModule {
  static register(options: { powerMode: string }): DynamicModule {
    return {
      module: PowerModule,
      providers: [
        {
          provide: 'POWER_OPTIONS',
          useValue: options
        },
        PowerService
      ],
      exports: [PowerService]
    };
  }
}
```

Now, when importing the PowerModule, we can configure it:

```typescript
// cpu/cpu.module.ts
import { Module } from '@nestjs/common';
import { PowerModule } from '../power/power.module';
import { CpuService } from './cpu.service';

@Module({
  imports: [
    PowerModule.register({ powerMode: 'high' })
  ],
  providers: [CpuService],
  exports: [CpuService]
})
export class CpuModule {}
```

```typescript
// disk/disk.module.ts
import { Module } from '@nestjs/common';
import { PowerModule } from '../power/power.module';
import { DiskService } from './disk.service';

@Module({
  imports: [
    PowerModule.register({ powerMode: 'low' }) // Different configuration
  ],
  providers: [DiskService],
  exports: [DiskService]
})
export class DiskModule {}
```

This creates an interesting scenario: The CPU module would receive a PowerService configured for high performance, while the Disk module would receive a PowerService configured for low power consumption.

## Circular Dependencies

Sometimes you might encounter situations where two services depend on each other. NestJS provides a way to handle this:

```typescript
// service-a.service.ts
@Injectable()
export class ServiceA {
  constructor(@Inject(forwardRef(() => ServiceB)) private serviceB: ServiceB) {}
}

// service-b.service.ts
@Injectable()
export class ServiceB {
  constructor(@Inject(forwardRef(() => ServiceA)) private serviceA: ServiceA) {}
}
```

While this works, it's generally a sign that your architecture could be improved. Consider refactoring to avoid circular dependencies.

## Testing with Dependency Injection

One of the greatest benefits of Dependency Injection is testability. NestJS provides excellent tools for testing services with dependencies:

```typescript
describe('CpuService', () => {
  let cpuService: CpuService;
  let powerService: PowerService;

  beforeEach(async () => {
    const moduleRef = await Test.createTestingModule({
      providers: [
        CpuService,
        {
          provide: PowerService,
          useValue: {
            supplyPower: jest.fn().mockReturnValue(10)
          }
        }
      ],
    }).compile();

    cpuService = moduleRef.get<CpuService>(CpuService);
    powerService = moduleRef.get<PowerService>(PowerService);
  });

  describe('compute', () => {
    it('should add two numbers and draw power', () => {
      const result = cpuService.compute(2, 3);

      expect(result).toBe(5);
      expect(powerService.supplyPower).toHaveBeenCalledWith(10);
    });
  });
});
```

## Practical Tips for Effective Dependency Injection

Based on what we've learned, here are some practical tips for using Dependency Injection effectively in NestJS:

1. **Design for testability**: Structure your code so that dependencies can be easily mocked during testing.

2. **Use interfaces for better abstraction**: Create interfaces for your services to clearly define the contract they fulfill.

3. **Prefer composition over inheritance**: Rather than extending classes, use dependency injection to compose functionality.

4. **Keep services focused**: Each service should have a single responsibility to maintain clarity and testability.

5. **Use dependency injection for cross-cutting concerns**: Logging, caching, error handling, and other cross-cutting concerns are perfect candidates for dependency injection.

6. **Be careful with scoped providers**: Non-singleton providers can impact performance, so use them judiciously.

7. **Leverage dynamic modules for reusable components**: If you're creating modules that need configuration, make them dynamic.

## Conclusion

Dependency Injection in NestJS is a powerful tool that goes beyond just wiring components together. It provides a framework for building modular, testable, and maintainable applications.

In this series, we've covered:

1. The fundamentals of Dependency Injection in NestJS
2. How to share services between modules using the three-step process
3. Advanced provider patterns and scopes
4. Dynamic modules and testing strategies

By mastering these concepts, you'll be able to design NestJS applications that are not only functional but also well-structured and easy to maintain as they grow in complexity.

Remember that good architecture isn't just about solving today's problems—it's about creating a foundation that can adapt to tomorrow's challenges. Dependency Injection is a key piece of that foundation in the NestJS ecosystem.
