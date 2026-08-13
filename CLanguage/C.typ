#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()
// Disable line numbers globally
#codly(number-format: none)

#set document(
  author: "Ignacio Sammartino",
  description: 
    "22.07 - Programacion I",
  keywords: "Resumen", 
  date: auto
)

#set text(lang: "es")


//Seteo el formato del texto
#set text(
  font: "Linux Biolinum O",
  size: 12pt,
  tracking: 0pt, // (Default = 0pt2)
  spacing: 100%,
  fractions: false /* Se rompe por algun motivo con true*/
)

//Formato del titulo
#show title: set text(size: 20pt)
#show title: set align(center)
#show title: set block(below: 4em)

#align(center)[#text(size: 24pt)[Instituto Tecnológico de Buenos Aires (ITBA)]] 

#figure(
  image("/images/itbaSVG_black.svg", width: 80%)
) <fig:indice>

#title[
22.07 - Programacion I

Resumen de C
]

Ignacio Sammartino
#set page(
  header: context [
    #grid(
      columns: (1fr, auto),
      align: center,
      [#align(left)[22.07 - Programacion I ]],
      [#align(right)[#image("/images/itbaSVG.svg", width: 33%)]]
    )
  ],
  numbering: "1 of 1",
  columns: 1,
)

#set page(
  margin: (
  top: 3cm,
  bottom: 2cm,
  x: 0.8cm,
))

#set page(numbering: "1 of 1")
//#set heading(numbering: "1. 1. 1 -")

#pagebreak()
#set page(columns: 2)
#outline()
#set page(columns: 1)

#codly(
  languages: (
    rust: (name: "C", icon: "A", color: rgb("#CE412B")),
  )
)

= Names in C

En el lenguaje C, los identificadores (nombres de variables, funciones, etc.) deben seguir reglas específicas:

- Son *case sensitive* (distinguen entre mayúsculas y minúsculas).
- Deben comenzar con una *letra* o un *guion bajo* ("\_").
- Solo pueden contener *guiones bajos, letras o números*.

```c
int variableValida;
int _contador;
int valor2;
// int 2valor; // Esto causaría un error de compilació
```

= Function that exits a program - exit()

`exit()` La función `exit()` permite terminar la ejecución de un programa de forma inmediata desde cualquier punto. Se encuentra definida en la librería `<stdlib.h>`. Comúnmente se utiliza el valor 0 para una terminación exitosa y valores distintos para indicar errores.


```C
#include <stdlib.h>

int main(void){
    // Exit successfully. The program terminates at this point.
    exit(0);

    // Exit with error.
    exit(-1);
}
```

= printf and scanf

Estas son las funciones fundamentales para la entrada y salida de datos en consola, incluidas en la librería `<stdio.h>`.
- `printf()`: Se utiliza para imprimir texto y variables con formato.
- `scanf()`: Se utiliza para leer datos del usuario desde el teclado.

```C
#include <stdlib.h>

int main() {
    int edad;
    printf("Ingrese su edad: ");
    scanf("%d", &edad); // El símbolo & es necesario para obtener la dirección
    printf("Su edad es: %d años\n", edad);
    return 0;
}
```
#box(
  stroke: 1pt,
  inset: 10pt,
)[
De querer escanear otro tipo de input para `scanf()`, tengo las siguientes opciones:

  - `%d` :   integer
  - `%f` :   floating point
  - `%c` :   char
  - `%s` :   `NULL` or '\0' terminated string
  - `%x` :   Hexadecimal number
  - `%o` :   Octal number
]

= Scaler types
Los tipos escalares en C representan valores individuales y se dividen en varias categorías según las fuentes:

- *Tipos primitivos*: Incluyen los tipos básicos como `int`, `char`, `float` y `double`.
- *Notación científica*: C permite representar números reales usando notación científica (ej. `1.2e3`).
- *C99 - bool*: A partir del estándar C99, se incluye el tipo booleano mediante la librería `<stdbool.h>`.
- *Enums*: Permiten definir tipos de enumeración para manejar constantes relacionadas.

```c
#include <stdio.h>
#include <stdbool.h>

enum dia_semana {LUNES, MARTES, MIERCOLES};

int main() {
    int entero = 10;
    float pi = 3.14159;
    double cientifica = 1.2e-3;
    bool esVerdad = true;
    enum dia_semana hoy = LUNES;
    
    return 0;
}
```


== Primitivos - Enteros

#table(
columns: (auto,auto,auto),
[*type*],[*size (bits/bytes)*],[*Range*],
[`unsigned char`],[8 / 1],[0 to 255],
[`char`],[8 / 1],[-128 to 127],
[`unsigned int`],[16 / 2],[0 to 63535],
[`short int` ],[16 / 2],[-32768 to 32767],
[`int`],[16 / 2],[-32768 to 32768 ],
[`unsigned long`],[32 / 4],[0 to 4294967295],
[`long`],[32 / 4],[-2147483648 to 2147483647],
)

== Primitivos - Punto Flotante

#table(
columns: (auto,auto,auto,auto),
[*type*],[*size (bits/bytes)*],[*Exponente*],[*Mantissa*],
[`float`],[32 / 4],[8],[23],
[`double`],[64 / 8],[11],[52]
)


== Casteo (Implicitos)
Esto ocurre cuando se le asigna un valor a una variable, y el tipo de la constante no coincide con el de la variable. En dicho caso, el tipo de la constante es casteado (promovido truncado) al tipo de la variable

```c
float		      x = 3;		  //almacena el 3.0
int		        i = 8.452	  //almacena el número 8
char		      a = 200	    //(número negativo)
unsigned char b = -12		  //(número positivo)
int		        c = -12.89	//(almacena el -12)
int		        e = ‘5’		  //(almacena el ASCII del 5)

```

== Notación Cientifica
```c
// Notacion Cientifica
float num_2  = 5e-5;
double num_3 = 3.7e12;
```

== Define
La directiva `#define `que nos permite asignarle a un símbolo un valor
```c
# define NUM_A    5.5     /* Double constant       */
# define NUM_B    5.5f    /* Float constant        */
# define NUM_C    5.5e6L  /* Long double constant  */
# define ADDRESS    0x20004000UL  /* Unsigned Long constant  */
```

== Enumeradores
Por default, `LUNES` arranca en 0
```c
enum dias { LUNES, MARTES, MIÉRCOLES, JUEVES, VIERNES, SÁBADO, DOMINGO }
```
De queres forzar a que arranque desde otro numero.
```c
enum dias { LUNES = 1, MARTES, MIÉRCOLES, JUEVES, VIERNES, SÁBADO, DOMINGO }
```

== Logica Booleana

```c
#include <stdbool.h>
bool flag = false;
flag = true;
if (flag){ print("Flag is true!\n");}
```

= TypeDef's
La palabra clave `typedef` se utiliza para crear un alias o un nuevo nombre para un tipo de dato ya existente, lo que mejora la legibilidad del código.
```c
typedef unsigned long ulong;
typedef int entero;

int main() {
    ulong numeroGrande = 1000000;
    entero edad = 20;
    return 0;
}
```

= Multidimensional arrays
C permite la creación de arreglos de múltiples dimensiones (matrices). Al pasarlos a funciones, es importante recordar que se deben especificar las dimensiones *excepto la primera*.

```c
void imprimirMatriz(int matriz[2][1]) {
    for(int i = 0; i < 2; i++) {
        for(int j = 0; j < 3; j++) {
            printf("%d ", matriz[i][j]);
        }
    }
}

int main() {
    // Inicialización
    int miMatriz[2][1] = {
        {1, 2, 3},
        {4, 5, 6}
    };
    imprimirMatriz(miMatriz);
    return 0;
}
```

#pagebreak()
= Pointers
Los punteros son variables que almacenan la dirección de memoria de otro objeto. Las fuentes destacan los siguientes puntos:

- *Dirección e inicialización*: Se usa `&` (_adress of_) para obtener la dirección y `*` para declarar un puntero.
- *Desreferenciación*: Acceder al valor almacenado en la dirección que apunta el puntero.
- *Aritmética de punteros*: Es posible sumar o restar valores a un puntero para navegar por la memoria (común en arrays).

- *Puntero `NULL`*: Indica que el puntero no apunta a ninguna dirección válida.

```c
int main() {
    int variable = 42;
    int *ptr = &variable; // Inicialización con la dirección de variable

    printf("Valor: %d\n", *ptr); // Desreferenciación
    
    int *pNull = NULL; // Puntero nulo
    
    int arr[1] = {10, 20, 30};
    int *pArr = arr;
    printf("Segundo elemento: %d\n", *(pArr + 1)); // Aritmética
    
    return 0;
}
```

== Punteros y arreglos
Los punteros son muy comdos a la hora de trabajar con matrices. Supongamos que tenemos el siguiente arreglo.
```c
int arr[ ] = {10, 20, 30}; // indices: 0,1,2
int *p;
```
Si quiero inicializar el puntero al primer elemento del arreglo, puedo hacer:
```c
p= array[0];
p = arr;          // Cualquiera de las 2 manera esta bien
```
Si quiero acceder a otro elemento del array, puedo ir incrementando el indice
```c
int e0 = *p;      //accedo al 10
int e1 = *(p+1);  //accedo al 20
int e3 = *(p+2);  //accedo al 30
```
== Aritmetica de punteros
```c
// Pointer arithmetic.
char * pC_1 = (char *) 0x02UL;
char * pC_2;


pC_2 = pC_1 + 1;   // Address: 0x03
pC_2 = pC_1 + 2;   // Address: 0x04
pC_2 = pC_1 - 1;   // Address: 0x01
```
En la aritmética de punteros, cuando sumas o restas un número entero a un puntero, no se suman bytes individuales, sino *unidades del tipo de dato al que apunta el puntero*.

```c
int *pI_1 = (int *) 8UL;  //                                    0x08
int *pI_2, *pI_3, *pI_4;  // Cada int ocupa 4 bytes

pI_3 = pI_1 + 1;   // Address: 12  Step 4 addresses bytes:      0x0C
pI_4 = pI_1 + 2;   // Address: 16  Step 4 * 2 addresses bytes.  0x10
pI_2 = pI_1 - 1;   // Address: 4  Step 4 addresses bytes.       0x04    
```


Asignar e incrementar *despues* el valor del elemento apuntado por el puntero.
```c
*p++    =  6;	
*(p++)  =  6;     // Cualquiera de las 2 manera esta bien
```

== Equivalencias
```c
*(arr + i)    //accedo al elemento del indice i
arr[i]

*(p + i)      //accedo al elemento del indice i
pi[i]
```


== Strings
```c
#include <stdio.h>
#include <string.h>

int main(){
    char *c = "Hello World!";
    int n = strlen(c); int i = 0;
    while(i++ <= n){
        printf("%c", *c++);// Iterate until NULL pointer.
    }
    return 0;}
```
== Passing Pointers to functions arguments

```c
void clear(int * p){
    *p = 0;
}

int main(void){
    int ar_vars[2] = { 1, 2 };
    clear(&ar_vars[1]);       // Result ar_vars[2] = { 1, 0 }

    clear(ar_vars);           // that is the same of clear(&ar_vars[0]); 
                              //Result ar_vars[2] = { 0, 0 }
}
```
== Array of pointers
```c
#include <stdio.h>

int main(){
    int i = 1; int j = 1; int k = 1;
    int *p[3];         // Si o si tengo que determinar el tamaño del array

    p[0] = &i; p[1] = &j; p[2] = &k;

    int z = *p[0] + *p[1] + *p[2];    // Result z = 3
    return 0;
}
```
== Punteros de Punteros
```c
#include <stdio.h>

int main(){
    int   j    = 6;
    int  *p_A  = &j;
    int **p_B  = &p_A;

    printf("%d %d",*p_A,**p_B + 1);  // 6 7
    return 0;
}
```

= True vs False
Se pueden hacer en una linea con operadores ternarios.
```c
char *txt  = (2 > 1) ? "true" : "false";; //
```
= Logical operators

- `&&` : AND
- `||` : OR
- `!` : NOT

= Switch
```c
int i = 20; int j;

switch(i){
    case 0:
        j = 0;
        break;
    case 1:
        j = 1;
        break;
    case 2:
        j = 2;
        break;
    default:
        printf("test");
        break;
}
```
= While Block

== While 
Si la condición es falsa, saltea el bloque. 
Si la condición es verdadera, se ejecutan las excepciones del bloque y se reevalua
```c
#include <stdio.h>

int main(){
  int n = 0;
  while (n < 10){
	  printf("%d ",n++);
  }                     //Cuenta de 0-9
  return 0;
}
```

== do while
Ejecuta el bloque.
Si la condición es falsa, saltea el bloque. 
Si la condición es verdadera, se ejecutan las excepciones del bloque y se reevalua

```c
#include <stdio.h>

int main(){
  n=0;
  do{
    printf("%d ",n++);
  }
  while (n<10); // Cuenta de 0-9

  return 0;
}
```

= For Block
Dentro del parentisis del `for`, la primera expresion indica la inicializacion de la variable de iteracion. La segunda expresion indica la condicion a evaluar, donde si es `FALSE`, termina el bloque. La expresion 3 se realiza luego de que termine de ejecutarse la iteracion del contenido del bloque.


```c
#include <stdio.h>
  int main(){
  int i,n,rta;
  //  Expresion 1: i=1, rta=1, n=10
  //  Expresion 2: i<=n;
  //  Expresion 3: i++
  for(i=1, rta=1, n=10; i<=n; i++){
    printf("%d ",rta++);
  }
  return 0;
}
```

== Break
Rompe el ciclo y sale del `for`
#figure(
  image("images/Break3.png", width: 70%)
) <fig:Break>

== Continue
Salta directamente a la proxima iteracion del `for`
#figure(
  image("images/cont3.png", width: 70%)
) <fig:cont3>


= Comparing floating point values

```c
float x = 2.0;

if ( (x > 2.0 - 0.0001) && (x < 2.0 + 0.0001){
    // Inside the tolerance interval.
    // Always compare with interval, never with exact values, 
    // because floating point representation may not have exact values. 
}
```
= Bit operators

#table(
columns: (0.5fr,1fr),
[*Operator*],[*Name*],
[`>>`],[Right shift],
[`<<`],[Left Shift],
[`&`],[Bitwise AND],
[`|`],[Bitwise OR],
[`^`],[Bitwise XOR],
[`~ `],[Bitwise Compliment]
)

= sizeof operator


= Structures
= Structure operators
= Unions
= Dynamic memory allocation on the Heap
= Types of includes
= Keyword static
= Same ways of defining strings
= Functions for manipulating strings and general functions
= Functions for manipulating files
= Function pointers
= C99 - stdint.h - Primitive fixed size types
= Preprocessor Macros
= Technique for defining more than one statement in a preprocessor Macro.
= C for Embedded Systems
= Keyword const and volatile
= Sizes for 32 bit microController
= Two ways of making a Menu with strings - char \* - and send it to UART.

