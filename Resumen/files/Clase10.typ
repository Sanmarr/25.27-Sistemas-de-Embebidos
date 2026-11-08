// ==========================================
// FUNCIONES DE CUADROS DIDÁCTICOS (CALLOUTS)
// ==========================================

#let cuadro-concepto(titulo: [Concepto Clave], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#e8f4f8"), stroke: (left: 4pt + rgb("#1b6ec2")),
  [
    #text(weight: "bold", fill: rgb("#104e8b"), size: 10.5pt)[💡 #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-ejemplo(titulo: [Ejemplo Práctico], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#eafaf1"), stroke: (left: 4pt + rgb("#2ecc71")),
  [
    #text(weight: "bold", fill: rgb("#1e8449"), size: 10.5pt)[🛠️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-atencion(titulo: [¡Atención / Cuidado!], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#fdf2e9"), stroke: (left: 4pt + rgb("#e67e22")),
  [
    #text(weight: "bold", fill: rgb("#a04000"), size: 10.5pt)[⚠️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-registro(titulo: [Detalle Técnico / Registro], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#f4ecf7"), stroke: (left: 4pt + rgb("#8e44ad")),
  [
    #text(weight: "bold", fill: rgb("#5b2c6f"), size: 10.5pt)[⚙️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let imagen(desc) = figure(
  rect(width: 100%, height: 6cm, fill: rgb("#f0f0f0"), stroke: 1pt + gray)[
    #align(center + horizon)[#text(fill: gray)[🖼️ #desc]]
  ]
)

// ==========================================
// CLASE 10
// ==========================================

= Clase 10

== Introducción a ARM Cortex-M4: Startup y Toolchain

#cuadro-concepto(titulo: [Objetivo de la clase])[
El microcontrolador *no arranca directamente en `main()`*. Antes hay que dejar listo el *stack*, la *vector table* y la memoria (`.data` y `.bss`). En esta clase vemos (1) qué define la arquitectura ARM y cómo se organiza el Cortex-M4, (2) dónde vive cada variable en memoria, (3) qué hace la CPU después del reset y (4) cómo la *toolchain* genera el binario que se graba en la Flash.
]

=== CPU vs. microcontrolador

- El *ARM Cortex-M4* es una *CPU* (un núcleo).
- El *Kinetis MK64FN1M0VLL12* (NXP) es un *microcontrolador (MCU)*: la CPU más Flash, RAM, periféricos, reloj, lógica de reset, etc.

Esta distinción importa más adelante: *el reset lo maneja el MCU, no la CPU*.

=== Qué es ARM y qué define una arquitectura

- *ARM* (Advanced RISC Machine) es una *arquitectura de CPU*, no un fabricante.
- *Arm Holdings* es la empresa que *licencia* esa arquitectura a otras (NXP, ST, Microchip, Apple, etc.).
- La arquitectura es el *"contrato" entre hardware y software*: describe *qué* funcionalidad debe proveer el hardware al software, pero *no cómo* la implementa.

#align(center)[
#table(
  columns: (auto, auto),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Elemento*], [*Qué define*]),
  [*Instruction set (ISA)*], [Instrucciones disponibles, función de cada una (y qué excepciones puede disparar) y cómo se codifica en memoria.],
  [*Register set*], [Registros disponibles, su tamaño, su función y su comportamiento en el reset.],
  [*Exception model*], [Niveles de privilegio, tipos de excepciones y qué las dispara, y qué pasa al entrar o volver de una excepción.],
  [*Memory model*], [Orden de los accesos a memoria, comportamiento de las cachés y cuándo el software debe hacer mantenimiento explícito.],
  [*Debug, trace y profiling*], [Cómo se ponen y disparan los breakpoints, y qué información capturan las herramientas de trace y en qué formato.],
)]

==== Familias de procesadores ARM

ARM ofrece tres grandes perfiles, según el mercado al que apuntan:

#table(
  columns: (1fr, 1.6fr, 1.6fr, 1.6fr),
  inset: 7pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([], [*Cortex-A* (Application)], [*Cortex-R* (Real-time)], [*Cortex-M* (Microcontroller)]),
  [*Diseño*], [Alta frecuencia, pipeline largo, alta performance, soporte multimedia (NEON).], [Pipeline corto a medio, determinístico (baja latencia de interrupción).], [Pipeline corto, ultra bajo consumo, determinístico.],
  [*Features*], [MMU, caché, seguridad TrustZone, corre Linux/OS móviles.], [MPU, caché, memoria TCM (Tightly Coupled Memory).], [MPU, *NVIC* (controlador de interrupciones), WIC (wakeup).],
  [*Mercado*], [Smartphones, servidores, microprocesadores de alta gama.], [Microcontroladores industriales, automotriz, discos rígidos, módems.], [Sensores, MEMS, IoT, sistemas embebidos de bajo consumo.],
)

//#imagen([Familias de procesadores ARM (clásicos vs. Cortex; diapositiva 5)])

#figure(
  image("/images/2P/familia.png", width: 90%)
  )

Dentro de la familia Cortex-M:

#table(
  columns: (0.8fr, 4fr),
  inset: 7pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Núcleo*], [*Característica principal*]),
  [*M0 / M0+*], [Muy chicos, bajo costo y ultra bajo consumo. El M0+ agrega I/O de ciclo único y relocación de vector table.],
  [*M1*], [Diseñado para FPGAs (implementación con bloques de memoria de la FPGA). Mismo set de instrucciones que el M0.],
  [*M3*], [Más potente: set de instrucciones rico, divisor por hardware, MAC, debug y trace completos.],
  [*M4*], [Lo del M3 *más instrucciones DSP* (SIMD, MAC de ciclo único) y una *FPU opcional* de precisión simple (IEEE 754).],
  [*M7*], [Alto rendimiento: FPU de doble precisión opcional, cachés y TCM.],
)

//#imagen([Soporte del Instruction Set en los distintos Cortex-M: M0/M0+, M3, M4/M7, DSP, FPU (diapositiva 8)])

#figure(
  image("/images/2P/soporte.png", width: 80%),
  caption: [Soporte del Instruction Set en los distintos Cortex-M: M0/M0+, M3, M4/M7, DSP, FPU ]
  )

=== Mapa de registros del Cortex-M4

El Cortex-M tiene registros de *32 bits*:

- *16 registros de propósito general* (`R0` a `R15`; tres de ellos tienen función especial: `SP`, `LR` y `PC`).
- *5 registros especiales*.
- *32 registros de punto flotante* (`S0`–`S31`, solo en variantes con FPU).

//#imagen([Mapa de registros del Cortex-M (R0–R15, registros especiales y registros de FPU; diapositiva 9)])

#figure(
  image("/images/2P/CortexM.png", width: 45%),
  caption: [Mapa de registros del Cortex-M (R0–R15, registros especiales y registros de FPU ]
  )

#table(
  columns: (1.1fr, 3.5fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Registro*], [*Función*]),
  [`R0`–`R12`], [Propósito general.],
  [`R13` (`SP`)], [*Stack Pointer*: puntero al stack. Existen dos copias, `MSP` (Main) y `PSP` (Process).],
  [`R14` (`LR`)], [*Link Register*: dirección de retorno de subrutina.],
  [`R15` (`PC`)], [*Program Counter*: instrucción que se está ejecutando.],
  [`PSR`], [Flags de la ALU, información de interrupciones y estado de ejecución.],
  [`PRIMASK` (1 bit)], [Bloquea *todas* las excepciones (incluidas las interrupciones), excepto `NMI` y `HardFault`.],
  [`FAULTMASK` (1 bit)], [Bloquea todas las excepciones, *incluso* `HardFault` (queda solo la `NMI`).],
  [`BASEPRI` (8 bits)], [Bloquea las excepciones con prioridad "mayor o igual a su valor" (numéricamente: valor de prioridad ≥ `BASEPRI`, o sea las menos urgentes).],
  [`CONTROL`], [Selecciona qué stack pointer se usa (`MSP` o `PSP`) y otras opciones de control.],
)

#cuadro-atencion(titulo: [Prioridades en ARM])[
En Cortex-M, *número menor = prioridad más alta*. Por eso `BASEPRI` enmascara las excepciones cuyo número de prioridad es *igual o mayor* al configurado (las menos urgentes) y deja pasar las más urgentes.
]

==== El Stack Pointer en acción

El stack se usa para guardar temporalmente registros y direcciones de retorno. Ejemplo típico: una subrutina que preserva `R4` y `R5` del llamador.

```asm
        ; Programa principal
        ; R4 = A, R5 = B
        BL   func1          ; salta a func1 y guarda en LR la dirección de retorno
        ; al volver: R4 = A, R5 = B

func1:
        PUSH {R4-R5}        ; guardar R4 y R5 en el stack
        ; ... tareas de la subrutina (puede usar R4 y R5 libremente) ...
        POP  {R4-R5}        ; restaurar R4 y R5
        BX   LR             ; retornar a main
```

- `PUSH` *decrementa* `SP` y escribe los registros: el stack *crece hacia direcciones bajas*.
- `POP` lee los valores y *incrementa* `SP`.

//#imagen([Operaciones Push y Pop sobre el stack (diapositivas 12 y 13)])

#figure(
  image("/images/2P/PUSH.png", width: 110%),
  caption: [Operaciones Push y Pop sobre el stack ]
)

=== Arquitectura del Cortex-M4 y mapa de memoria

La arquitectura del Cortex-M4 es un *híbrido entre Harvard y Von Neumann*:

- Tiene *buses separados* para código y datos (como Harvard).
- Pero tiene un *único mapa de memoria unificado* (como Von Neumann).

Además, tiene componentes opcionales (FPU, MPU, ETM, watchpoints), el *NVIC* (que unifica el controlador de interrupciones entre los distintos fabricantes) y el *Debug Access Port*.

//#imagen([Diagrama de bloques de la implementación del Cortex-M4 (diapositiva 20)])

#figure(
  image("/images/2P/imple.png", width: 50%),
  caption: [Diagrama de bloques de la implementación del Cortex-M4 ]
)

#cuadro-concepto(titulo: [Todos los Cortex-M4 comparten el mapa de memoria])[
El *mapa de memoria* (qué rango de direcciones corresponde a código, SRAM, periféricos, etc.) es *el mismo para todas las implementaciones* del Cortex-M4. Lo que *sí depende del fabricante/producto* es *qué hay realmente* en cada región: cuánta Flash y RAM tiene, qué periféricos incluye y en qué direcciones están sus registros.
]

#table(
  columns: (1.7fr, 1.5fr, 2.5fr),
  inset: 7pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Región*], [*Tamaño*], [*Rango de direcciones*]),
  [Code (Flash)], [0.5 GB], [`0x0000_0000` – `0x1FFF_FFFF`],
  [SRAM], [0.5 GB], [`0x2000_0000` – `0x3FFF_FFFF`],
  [Peripheral], [0.5 GB], [`0x4000_0000` – `0x5FFF_FFFF`],
  [External RAM], [1 GB], [`0x6000_0000` – `0x9FFF_FFFF`],
  [External device], [1 GB], [`0xA000_0000` – `0xDFFF_FFFF`],
  [Private peripheral bus], [—], [`0xE000_0000` – `0xE00F_FFFF`],
  [System], [—], [`0xE010_0000` – `0xFFFF_FFFF`],
)

Las regiones SRAM y Peripheral incluyen una *bit-band region* de 1 MB (con su *bit-band alias* de 32 MB) que permite acceder a bits individuales con una sola operación de lectura/escritura.

//#imagen([Mapa de memoria del sistema del Cortex-M4 (diapositiva 21)])

#figure(
  image("/images/2P/mem.png", width: 70%),
  caption: [Mapa de memoria del sistema del Cortex-M4 ]
)

=== ¿Dónde se guarda cada variable?

Al compilar, el programa se divide en *secciones*. Cada tipo de variable o función cae en una sección distinta, y cada sección va a un tipo de memoria distinto.

#table(
  columns: (1fr, 1.4fr, 2.6fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Sección*], [*Memoria*], [*Qué contiene*]),
  [`.text`], [Flash], [Código (instrucciones).],
  [`.rodata`], [Flash], [Constantes (read-only).],
  [`.data`], [RAM (valores iniciales en Flash)], [Variables globales/estáticas inicializadas con valor distinto de 0.],
  [`.bss`], [RAM], [Variables globales/estáticas inicializadas en 0 (o no inicializadas).],
  [*heap*], [RAM], [Memoria reservada dinámicamente (`malloc`).],
  [*stack*], [RAM], [Variables locales y contexto de las llamadas a función.],
)

//#imagen([Layout de memoria: text, rodata, data, bss, heap y stack (diapositivas 24 a 31)])

#figure(
  image("/images/2P/DondeSeGuarda.png", width: 110%),
  caption: [Layout de memoria: text, rodata, data, bss, heap y stack ]
)

==== Ejemplos de la clase

```c
const int const_int = 42;
const char * const const_string = "Hola";
int global_uninit;
int global_init = 5;

int main(void) {
    return 0;
}
```

#table(
  columns: (1.4fr, 1fr, 2.4fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Símbolo*], [*Sección*], [*Por qué*]),
  [`main()`], [`.text`], [Es código.],
  [`const_int`], [`.rodata`], [Constante: solo lectura, queda en Flash.],
  [`const_string`], [`.rodata`], [Puntero constante a una cadena constante; ambos en Flash.],
  [`global_init`], [`.data`], [Inicializada en 5: vive en RAM, pero su valor inicial se guarda en Flash.],
  [`global_uninit`], [`.bss`], [Sin inicializar: vive en RAM y debe ponerse en 0.],
)

*Memoria dinámica* (heap):

```c
#include <stdlib.h>

int main(void) {
    int *arr = (int*)malloc(5*sizeof(int));
    arr[0] = 123;
    free(arr);
    return 0;
}
```

- El bloque de 5 enteros que devuelve `malloc` está en el *heap*.
- El puntero `arr` en sí es una variable local y está en el *stack*.

*Variables locales* (stack):

```c
void func2(void) {
    int local2;
}

void func1(void) {
    int local1 = 10;
    func2();
}

int main(void) {
    func1();
    return 0;
}
```

`local1` y `local2` están en el *stack*. Cada llamada a función apila un nuevo marco, por eso `local2` queda "encima" de `local1` y desaparece al retornar `func2`.

*Variables `static` locales*:

```c
void counter(void) {
    static int static_count = 0;
    static_count++;

    int local_count = 1;
}

int main(void) {
    counter();
    counter();
    return 0;
}
```

- `local_count` está en el *stack*: se crea y se destruye en cada llamada.
- `static_count` *no está en el stack*: es una variable global con alcance local a la función, por eso *conserva su valor entre llamadas* (después de dos llamadas vale 2).

#cuadro-atencion(titulo: [`static` inicializada en 0])[
En la diapositiva `static_count` se muestra en `.data`. En la práctica, GCC suele ubicar en `.bss` las variables inicializadas explícitamente en 0. En cualquier caso, lo importante es que *vive en RAM, fuera del stack*.
]

=== Booteo del ARM Cortex-M4

Supongamos el programa mínimo:

```c
void main(void) {
    while (1) {
    }
}
```

La pregunta es: *¿cuál es la secuencia exacta desde que se energiza el micro hasta que ejecuta la primera instrucción de `main`? ¿Hay algo antes?*

==== Del power-on al reset

Al energizar el micro, la tensión empieza a subir. Mientras tanto, el MCU mantiene la CPU en reset. *El reset lo maneja la implementación del fabricante (el MCU), no la CPU Cortex-M4.*

- En el K64, el *Power-On Reset (POR)* se dispara cuando se aplica alimentación (o cuando cae por debajo de cierto umbral), y el circuito *LVD* (Low-Voltage Detect) mantiene el MCU en reset hasta que la tensión supera el umbral.
- Los valores concretos (tensión de POR, umbral de LVD) están en el *K64 Sub-Family Reference Manual* (sección Power-On Reset) y en el *Kinetis K64F Data Sheet* (requisitos de LVD y POR).

==== Qué hace la CPU después del reset

Después del reset (Power-On Reset u otro), la CPU:

1. Carga en `MSP` el *valor guardado en la dirección* `0x0000_0000`.
2. Carga en `LR` el valor `0xFFFF_FFFF`.
3. Carga en `PC` el *valor guardado en la dirección* `0x0000_0004`.

#cuadro-atencion(titulo: [Es el contenido, no la dirección])[
`MSP` y `PC` se cargan con *lo que hay almacenado* en las direcciones 0 y 4, no con los números 0 y 4. La primera palabra de la memoria es el *valor inicial del stack pointer* y la segunda es la *dirección del handler de reset*.
]

Para bootear un Cortex-M4 hay que poner entonces en la Flash:

- Un valor en la dirección `0x0` para cargar en `MSP` (¿cuál?).
- Un valor en la dirección `0x4` para cargar en `PC` (¿cuál?).
- Los valores iniciales de las variables globales y las constantes.
- ¡Un programa!

Y además, *antes de ejecutar `main`*, el programa debe:

- cargar el valor *0* en las variables no inicializadas (`.bss`);
- *copiar de Flash a RAM* los valores iniciales de las variables inicializadas (`.data`).

#cuadro-concepto(titulo: [Secuencia de arranque])[
*Reset* (hardware del MCU) → la CPU carga `MSP` y `PC` desde la *vector table* → se ejecuta el *reset handler* (startup) → se inicializan `.bss` y `.data` → se llama a `main()` → bucle infinito.
]

===  La toolchain ARM

Queremos generar, sin IDE ni templates (solo un editor de texto), el *contenido binario que va en la Flash*. Eso lo hace la *toolchain*.

==== ARM Toolchain: Flujo genérico

//#imagen([Flujo genérico de la toolchain ARM: compilador, ensamblador, linker, objcopy y flash programmer (diapositiva 38)])

#figure(
  image("/images/2P/oaa.png", width: 100%),
  caption: [Flujo genérico de la toolchain ARM: compilador, ensamblador, linker, objcopy y flash programmer ]
)

- El *compilador* (C) y el *ensamblador* (assembly) generan *archivos objeto* (`.o`) de los codigos fuentes(c o assmebler).
- El *linker* combina los archivos objeto, según un *linker script* (la especificación del mapa de memoria), y genera la *imagen ejecutable* (`.elf`).
- Utilidades como `objcopy` convierten el ELF a formatos como `.bin` o `.hex`, y `objdump` genera un listado desensamblado.
- El *flash programmer* o el *debugger* graba esa imagen en la Flash del MCU real.

Nosotros usamos la toolchain *GNU* para ARM (`arm-none-eabi-*`, donde `none-eabi` indica programación *bare-metal*, sin sistema operativo).

#table(
  columns: (1.5fr, 3fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Herramienta*], [*Rol*]),
  [`arm-none-eabi-gcc`], [Compila C y ensambla assembly; también invoca al linker (`ld`) para generar el ELF.],
  [`arm-none-eabi-ld`], [Linker: asigna direcciones finales a las secciones y genera el ELF.],
  [`arm-none-eabi-objdump`], [Muestra el desensamblado y las tablas de símbolos y secciones.],
  [`arm-none-eabi-objcopy`], [Convierte el ELF a binario o hex para grabar en Flash.],
)

==== Compilar: el archivo objeto

```bash
$ arm-none-eabi-gcc -mcpu=cortex-m4 -O1 -c ej0.c -o ej0.o
$ arm-none-eabi-objdump -d ej0.o
```

```text
ej0.o:     file format elf32-littlearm

Disassembly of section .text:

00000000 <main>:
   0:   e7fe             b.n    0 <main>
```

`b.n 0 <main>` es el `while (1)`: un salto de `main` a sí misma. La dirección es `0` porque un archivo objeto *todavía no fue linkeado*: las direcciones son relativas al inicio de su sección.

==== Linkear sin indicarle dónde va el código

```bash
$ arm-none-eabi-gcc -mcpu=cortex-m4 -nostartfiles ej0.o -o ej0.elf
warning: cannot find entry symbol _start; defaulting to 0000000000008000
$ arm-none-eabi-objdump -d ej0.elf
```

```text
00008000 <main>:
    8000:       e7fe               b.n       8000 <main>
```

Ahora `main` quedó en `0x8000`: es la dirección por defecto del linker. *No es "incorrecto", pero no es lo que queremos*: el Cortex-M4 espera su vector table en la dirección 0 de la Flash.

#cuadro-concepto(titulo: [¿A quién le decimos dónde poner el código?])[
*Al linker*, no al compilador. El compilador solo *asigna secciones* a cada pedazo del programa; el *linker asigna direcciones* a esas secciones, guiado por el *linker script* (`-T script.ld`).
]

=== Secciones y linker script

Programa de ejemplo:

```c
static int p = 100;
int q;
static const int r = 9;

void main(void) {
    while (p-- > r) {
        q++;
    }
}
```

```bash
$ arm-none-eabi-objdump -td ej1.elf
SYMBOL TABLE:
00008000 l  d .text      00000000 .text
00008030 l  d .rodata    00000000 .rodata
00018034 l  d .data      00000000 .data
00018038 l  d .bss       00000000 .bss
00018034 l  O .data      00000004 p
00008030 l  O .rodata    00000004 r
0001803c g    .bss       00000000 _bss_end__
00018038 g    .bss       00000000 __bss_start__
0001803c g    .bss       00000000 __bss_end__
00018038 g    .bss       00000000 __bss_start
00008000 g  F .text      00000030 main
0001803c g    .bss       00000000 __end__
00018038 g    .data      00000000 _edata
0001803c g    .bss       00000000 _end
00018038 g  O .bss       00000004 q
00018034 g    .data      00000000 __data_start
```

El compilador reparte cada elemento en su sección estándar:

#table(
  columns: (1fr, 2.4fr, 1.4fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Sección*], [*Contenido*], [*En el ejemplo*]),
  [`.text`], [Código.], [`main`],
  [`.rodata`], [Datos inicializados != 0, solo lectura (RO).], [`r`],
  [`.data`], [Datos inicializados != 0, lectura/escritura (RW).], [`p`],
  [`.bss`], [Datos inicializados en 0.], [`q`],
)

Sin linker script, el linker usa direcciones por defecto: `.text` en `0x8000`, `.rodata` en `0x8030`, y `.data` y `.bss` pegadas más arriba (`0x18034`, `0x18038`). *Ninguna de esas direcciones es útil para nuestro micro*, así que hace falta un script propio.

==== El linker script

```bash
MEMORY
{
    flash : ORIGIN = 0x00000000, LENGTH = 1024k
    ram   : ORIGIN = 0x20000000, LENGTH = 256K
}

SECTIONS
{
    .text :
    {
        . = ALIGN(4);
        *(.text*)
        *(.rodata*)
    } > flash

    .data :
    {
        . = ALIGN(4);
        _data_start = .;
        *(.data*)
        . = ALIGN(4);
        _data_end = .;
    } > ram AT > flash

    _data_init_values = LOADADDR(.data);

    .bss (NOLOAD) :
    {
        . = ALIGN(4);
        _bss_start = . ;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = . ;
    } > ram
}
```

- `MEMORY` define las regiones físicas: `flash` (código y constantes) y `ram` (datos, stack).
- `.text` junta código y `.rodata` en Flash.
- `.data` se coloca en `ram` (*VMA*: dirección de ejecución) pero su contenido inicial se guarda en `flash` (*LMA*: dirección de carga), por eso `> ram AT > flash`. `LOADADDR(.data)` devuelve dónde quedaron esos valores iniciales en Flash.
- `.bss` es `NOLOAD`: ocupa RAM pero *no ocupa espacio en la Flash* (solo hay que ponerla en 0).
- El linker *define símbolos* (`_data_start`, `_data_end`, `_data_init_values`, `_bss_start`, `_bss_end`) que el código de inicio puede usar.

#cuadro-registro(titulo: [Nota sobre la RAM del K64])[
En los ejemplos de la clase la RAM arranca en `0x2000_0000` por simplicidad. En el K64 real, el reference manual reparte la SRAM a ambos lados de esa dirección (una parte arranca en `0x1FFF_0000`). Para un proyecto real hay que usar los valores del manual del MCU.
]

==== Compilar con el script



```bash
$ arm-none-eabi-gcc -mcpu=cortex-m4 -nostartfiles -T ej1.ld ej1.c -o ej1.elf
$ arm-none-eabi-objdump -td ej1.elf
SYMBOL TABLE:
00000000 l    d .text     00000000 .text
20000000 l    d .data     00000000 .data
20000004 l    d .bss      00000000 .bss
20000000 l    O .data     00000004 p
00000030 l    O .text     00000004 r
20000004 g    O .bss      00000004 q
00000000 g    F .text     00000030 main
20000000 g      .data     00000000 _data_start
20000004 g      .data     00000000 _data_end
20000004 g      .bss      00000000 _bss_start
20000008 g      .bss      00000000 _bss_end
00000034 g      *ABS*     00000000 _data_init_values
```

Ahora `main` está en `0x0`, `r` quedó en Flash (`0x30`), `p` y `q` en RAM (`0x2000_0000` y `0x2000_0004`), y los valores iniciales de `.data` están en Flash a partir de `0x34`.

==== El binario que va a la Flash

```bash
$ arm-none-eabi-objcopy -O binary ej1.elf ej1.bin
```

```bash
Offset    0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
00000000  80  B4  00  AF  04  E0  08  4B  1B  68  01  33  06  4A  13  60
00000010  06  4B  1B  68  5A  1E  05  49  0A  60  09  22  93  42  F2  DC
00000020  00  BF  BD  46  80  BC  70  47  04  00  00  20  00  00  00  20
00000030  09  00  00  00  64  00  00  00
```

- Desde `0x00` hasta `0x2F`: el código de `main`.
- `0x30`: `09 00 00 00` = `r` = 9 (little endian).
- `0x34`: `64 00 00 00` = valor inicial de `p` = 100 (`0x64`), que alguien tendrá que *copiar a RAM*.

#figure(
  image("/images/2P/compilar.png", width: 100%),
  caption: [Ejemplo anterior.]
)

#cuadro-atencion(titulo: [¿Qué falta configurar?])[
Hasta acá el linker ordenó todo, pero *nadie usa los símbolos que generó*: no hay código que ponga `.bss` en 0 ni que copie `.data` a RAM. Y tampoco hay nada en las direcciones 0 y 4 que le diga al micro con qué `MSP` y `PC` arrancar. Falta el *código de startup*.
]

===  Código de startup

==== Inicialización pre-main (`init.c`)

```c
#include <string.h>

void init(void) {
    extern char _bss_start[];
    extern char _bss_end[];

    extern char _data_start[];
    extern char _data_end[];
    extern char _data_init_values[];

    // Poner .bss en 0
    memset(_bss_start, 0, (_bss_end - _bss_start));

    // Copiar los valores iniciales de .data desde Flash a RAM
    memcpy(_data_start, _data_init_values, (_data_end - _data_start));
}
```

Usa exactamente los símbolos que definió el linker script.

==== Vector table y reset handler (`startup.S`)

```asm
    .cpu cortex-m4
    .global _reset_vector

/* sección ".vectors", allocatable */
.section .vectors, "a"
    .word _sp_init_value      @ dirección 0x0: valor inicial de MSP
    .word _reset_vector       @ dirección 0x4: valor inicial de PC

.section .text
_reset_vector:
    bl init                   @ inicializar .bss y .data
    bl main                   @ ejecutar el programa de usuario
    b .                       @ si main retorna, quedarse acá
```

Las dos primeras palabras de la Flash son justo lo que la CPU lee después del reset: el stack inicial y la dirección del reset handler.

==== Linker script completo (`ej2.ld`)

```text
MEMORY
{
    flash : org = 0, len = 1024k
    ram   : org = 0x20000000, len = 256K
}

ENTRY(_reset_vector)

SECTIONS
{
    .vectors :
    {
        *(.vectors*)
    } > flash

    ... (.text, .data y .bss como antes) ...

    _sp_init_value = org(ram) + len(ram);
}
```

- `.vectors` va *primero* en la Flash, para quedar en la dirección 0.
- `ENTRY(_reset_vector)` indica el punto de entrada.
- `_sp_init_value = org(ram) + len(ram)` coloca el stack al *final de la RAM*, y como el stack crece hacia abajo, tiene toda la RAM disponible.

==== Compilar y linkear todo junto

```bash
$ arm-none-eabi-gcc -mcpu=cortex-m4 -O0 -c startup.S -o startup.o
$ arm-none-eabi-gcc -mcpu=cortex-m4 -O0 -c init.c -o init.o
$ arm-none-eabi-gcc -mcpu=cortex-m4 -O0 -c ej2.c -o ej2.o
$ arm-none-eabi-gcc -mcpu=cortex-m4 -nostartfiles -T ej2.ld startup.o init.o ej2.o -o ej2.elf
$ arm-none-eabi-objdump -td ej2.elf > ej2.dump.txt
$ arm-none-eabi-objcopy -O binary ej2.elf ej2.bin
```



Al inspeccionar el binario, el primer dato es `00 00 04 20`, que en little endian es `0x2004_0000`: el valor inicial de `MSP`, es decir *`0x2000_0000` + 256 KB* (el tope de la RAM). La segunda palabra es la dirección del reset handler, y a continuación está el código de `startup`, `init` y `main`.

#cuadro-ejemplo(titulo: [Flujo completo de nuestro ejemplo])[
+ Reset del MCU.
+ La CPU lee la dirección `0x0` y carga `MSP = 0x2004_0000`.
+ La CPU lee la dirección `0x4` y carga `PC = _reset_vector`.
+ `_reset_vector` llama a `init` (`.bss` en 0, `.data` copiada de Flash a RAM).
+ Se llama a `main`.
+ Si `main` retorna, `b .` deja la CPU en un bucle infinito.
]

=== Startup real del Kinetis (`startup_mk64f12.c`)

El SDK de Kinetis hace lo mismo pero en C y con la *vector table completa*.

*Vector table.* Es un arreglo de punteros a función que el linker script ubica al inicio de la Flash:

#align(center)[
#table(
  columns: (auto,auto, auto),
  inset: 7pt,
  stroke: 0.5pt + luma(180),
  align: (left,center,left), 
  table.header([*Dirección*], [*Vector*], [*Contenido*]),
  [`0x0000_0000`], [0], [Valor inicial del stack pointer.],
  [`0x0000_0004`], [1], [`ResetISR` (reset handler).],
  [`0x0000_0008`], [2], [`NMI_Handler`.],
  [`0x0000_000C`], [3], [`HardFault_Handler`.],
  [`0x0000_0010`], [4], [`MemManage_Handler` (MPU fault).],
  [`0x0000_0014`], [5], [`BusFault_Handler`.],
  [`0x0000_0018`], [6], [`UsageFault_Handler`.],
  [`0x0000_002C`], [11], [`SVC_Handler` (supervisor call).],
  [`0x0000_0030`], [12], [`DebugMon_Handler`.],
  [`0x0000_0038`], [14], [`PendSV_Handler`.],
  [`0x0000_003C`], [15], [`SysTick_Handler`.],
  [`0x0000_0040`], [16 (IRQ 0)], [Primera interrupción de periférico del chip (DMA canal 0).],
)]

Las posiciones reservadas se rellenan con `0`. Los primeros 16 vectores son *del núcleo ARM*; desde el vector 16 en adelante son *específicos del chip* (los periféricos del K64).

//#imagen([Vector table del K64 (`g_pfnVectors`) y tabla de asignación de vectores de interrupción (diapositiva 50)])

#figure(
  image("/images/2P/vecTable.png", width: 100%),
  caption: [Vector table del K64 (`g_pfnVectors`) y tabla de asignación de vectores de interrupción  ]
)


*Inicialización de RAM.* Las funciones `data_init` y `bss_init` hacen lo mismo que nuestro `init.c`, pero copian/limpian palabra por palabra (de a 4 bytes):

```c
__attribute__ ((section(".after_vectors.init_data")))
void data_init(unsigned int romstart, unsigned int start, unsigned int len) {
    unsigned int *pulDest = (unsigned int*) start;
    unsigned int *pulSrc  = (unsigned int*) romstart;
    unsigned int loop;
    for (loop = 0; loop < len; loop = loop + 4)
        *pulDest++ = *pulSrc++;
}

__attribute__ ((section(".after_vectors.init_bss")))
void bss_init(unsigned int start, unsigned int len) {
    unsigned int *pulDest = (unsigned int*) start;
    unsigned int loop;
    for (loop = 0; loop < len; loop = loop + 4)
        *pulDest++ = 0;
}
```

*Reset handler.* `ResetISR` recorre unas *tablas de secciones* (`__data_section_table` y `__bss_section_table`) para inicializar cada banco de RAM, y finalmente llama a `main()`. Se usan tablas porque algunos MCUs tienen *varias regiones de RAM*, y así el mismo `ResetISR` sirve para todos. Si `main` retorna, queda en un `while (1)`.

//#imagen([`ResetISR`: copia de `.data` desde Flash a SRAM, puesta en cero de `.bss` y salto a `main` (diapositivas 51 y 52)])

#figure(
  image("/images/2P/codeLoop.png", width: 115%),
  caption: [`ResetISR`: copia de `.data` desde Flash a SRAM, puesta en cero de `.bss` y salto a `main`]
)

===  Resumen final

#cuadro-concepto(titulo: [Ideas clave])[
+ *ARM define una arquitectura* (ISA, registros, excepciones, memoria, debug); el Cortex-M4 es una CPU, y el MCU (ej. Kinetis K64) es lo que la rodea.
+ *Todos los Cortex-M4 tienen el mismo mapa de memoria*; lo que cambia entre fabricantes es qué hay en cada región.
+ Cada variable va a una sección según su tipo: `.text`, `.rodata`, `.data`, `.bss`, *heap* y *stack*.
+ Tras el reset, la CPU carga `MSP` con el contenido de la dirección `0x0` y `PC` con el contenido de la dirección `0x4`: esa es la *vector table*.
+ El compilador asigna *secciones*; el *linker*, guiado por el *linker script*, asigna *direcciones*.
+ Antes de `main`, el startup debe poner `.bss` en 0 y copiar `.data` de Flash a RAM.
]

#cuadro-ejemplo(titulo: [Flujo típico])[
*reset → vector table (MSP y PC) → startup → inicialización de `.bss` y `.data` → `main()` → bucle infinito*
]

/*
==== Referencias

- Cortex-M4 Devices Generic User Guide.
- K64 Sub-Family Reference Manual.
- Kinetis K64F Sub-Family Data Sheet.
- _The Definitive Guide to the ARM Cortex-M3/M4_.
- ARM Developer Documentation.
- Manuales de GCC, LD, etc.
*/