// Example TypeScript file

interface Person {
  name: string;
  age: number;
}

function greet(person: Person): string {
  return `Hello, ${person.name}! You are ${person.age} years old.`;
}

const user: Person = {
  name: "TypeScript User",
  age: 30
};

console.log(greet(user));

// Class example
class Animal {
  public name: string;
  constructor(name: string) {
    this.name = name;
  }
  move(distanceInMeters: number = 0): void {
    console.log(`${this.name} moved ${distanceInMeters}m.`);
  }
}

class Dog extends Animal {
  bark(): void {
    console.log('Woof! Woof!');
  }
}

const dog = new Dog('Buddy');
dog.bark();
dog.move(10);

// Enum example
enum Color {
  Red,
  Green,
  Blue
}

let c: Color = Color.Green;
console.log(`Color is: ${Color[c]}`);

// Async/Await example
async function delayedHello(): Promise<string> {
  await new Promise(resolve => setTimeout(resolve, 1000));
  return "Hello after delay";
}

async function runAsync() {
  const message = await delayedHello();
  console.log(message);
}

runAsync();

// Template literal with expression
const a = 5;
const b = 10;
console.log(`Fifteen is ${a + b} and
not ${2 * a + b}.`);

/* Multi-line
   comment
*/

let hex: number = 0xf00d;
let binary: number = 0b1010;
let octal: number = 0o744;

// --- Added Examples ---

// Decorator
function sealed(constructor: Function) {
  Object.seal(constructor);
  Object.seal(constructor.prototype);
}

@sealed
class Greeter {
  greeting: string;
  constructor(message: string) {
    this.greeting = message;
  }
  greet() {
    return "Hello, " + this.greeting;
  }
}

// JSX/TSX (conceptual - needs React/JSX setup to run)
const element = <h1>Hello, world!</h1>;
function MyComponent(props: { name: string }) {
  return <div>{props.name}</div>;
}

// Generics
function identity<T>(arg: T): T {
  return arg;
}
let output = identity<string>("myString");
let numOutput = identity(123); // Type inferred
type StringArray = Array<string>;

// Type Assertions
let someValue: any = "this is a string";
let strLength: number = (someValue as string).length;
let strLength2: number = (<string>someValue).length;

// Advanced Types (Union, Intersection, Mapped, Conditional, keyof, typeof)
type StringOrNumber = string | number;
type HasName = { name: string };
type HasAge = { age: number };
type PersonDetails = HasName & HasAge; // Intersection

type OptionsFlags<Type> = {
  [Property in keyof Type]: boolean; // Mapped Type
};

interface ExampleType {
  a: number;
  b: string;
}
type FeatureFlags = OptionsFlags<ExampleType>;

type MessageOf<T> = T extends { message: unknown } ? T["message"] : never; // Conditional Type
interface Email { message: string; }
type EmailMessageContents = MessageOf<Email>; // string

const myCar = { make: "Toyota", model: "Corolla", year: 2021 };
function getProperty<T, K extends keyof T>(obj: T, key: K) { // keyof
  return obj[key];
}
let carMake = getProperty(myCar, "make");
let carType = typeof myCar; // typeof

// Modules (more complex import/export)
import { Dog as Canine } from './dog'; // Renaming import
export default class Utility { /* ... */ } // Default export

// Optional Chaining & Nullish Coalescing
const adventurer = {
  name: 'Alice',
  cat: {
    name: 'Dinah'
  }
};
const dogName = adventurer.dog?.name; // Optional Chaining
console.log(dogName); // undefined
const displayName = adventurer.name ?? 'Anonymous'; // Nullish Coalescing
console.log(displayName); // Alice

// Regular Expression Literal
let numberRegex = /^[0-9]+$/g;
console.log(numberRegex.test("12345")); // true
