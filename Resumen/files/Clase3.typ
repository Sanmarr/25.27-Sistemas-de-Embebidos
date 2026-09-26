// ==========================================
// FUNCIONES DE CUADROS DIDÁCTICOS (CALLOUTS)
// ==========================================

#let cuadro-concepto(titulo:[Concepto Clave], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#e8f4f8"), stroke: (left: 4pt + rgb("#1b6ec2")),
[
    #text(weight: "bold", fill: rgb("#104e8b"), size: 10.5pt)[💡 #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-ejemplo(titulo:[Ejemplo Práctico], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#eafaf1"), stroke: (left: 4pt + rgb("#2ecc71")),
[
    #text(weight: "bold", fill: rgb("#1e8449"), size: 10.5pt)[🛠️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-atencion(titulo:[¡Atención / Cuidado!], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#fdf2e9"), stroke: (left: 4pt + rgb("#e67e22")),
[
    #text(weight: "bold", fill: rgb("#a04000"), size: 10.5pt)[⚠️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-registro(titulo:[Detalle Técnico / Registro], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#f4ecf7"), stroke: (left: 4pt + rgb("#8e44ad")),
[
    #text(weight: "bold", fill: rgb("#5b2c6f"), size: 10.5pt)[⚙️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

= Mecanismos Avanzados de Gestión de Prioridades en Cortex-M4

La arquitectura *ARM Cortex-M4* incluye optimizaciones por hardware diseñadas para minimizar la latencia de interrupción y el sobrecosto (*overhead*) del apilado y desapilado de registros en la memoria Stack.

== 1.1. Tail-Chaining (Encadenamiento al Final)
En procesadores convencionales, al finalizar la ejecución de una ISR, la CPU realiza la restauración completa de registros (*POP*) hacia el programa principal, para luego realizar inmediatamente un guardado de registros (*PUSH*) si existe otra interrupción pendiente.

#cuadro-concepto(titulo:[Mecanismo de Tail-Chaining])[
  - *Funcionamiento:* Si al terminar una ISR existe otra interrupción pendiente con la prioridad necesaria para ser atendida, el hardware *omite la secuencia completa de POP y PUSH*.
  - *Ahorro de Ciclos:* En lugar de gastar más de 20 ciclos restaurando y volviendo a salvar el contexto, la CPU salta directamente a la segunda ISR realizando una transición administrativa de solo *6 ciclos de reloj*.
  - *Beneficio:* Reduce drásticamente la latencia para atender interrupciones consecutivas acumuladas.
]

#figure(
  image("/images/tail.png", width: 80%),
  caption: "Interrupt Latency - Tail Chaining"
)

== 1.2. Pre-Emption (Anidamiento y Desalojo de Interrupciones)
El NVIC permite el anidamiento de interrupciones basado en niveles de prioridad.

- *Regla de Desalojo:* Una interrupción entrante solo desaloja (*preempts*) a la ISR que se está ejecutando actualmente si su *nivel de prioridad es strictly mayor* (es decir, posee un número numérico menor en la configuración de prioridad).
- *Prioridad Igual o Menor:* Si la interrupción entrante tiene prioridad igual o más baja que la activa, permanece retenida en estado pendiente (*Pending*) hasta que finalice la ISR en curso, momento en el cual se atiende mediante *Tail-Chaining*.

#cuadro-atencion(titulo:[Guardado Automático de Contexto])[
  Cuando ocurre el desalojo por mayor prioridad, el hardware apila automáticamente el bloque de registros básicos en la pila (*MSP/PSP*) para permitir la ejecución de la nueva ISR y reanudar la ISR anterior al finalizar la más urgente.
]

#figure(
  image("/images/pre.png", width: 80%),
  caption: "Interrupt Latency - Pre-Emption"
)

== 1.3. Late Arrival (Llegada Tardía)
Ocurre cuando una interrupción de *alta prioridad* se dispara justo mientras el procesador está realizando la fase de apilado automático de registros (*PUSH*) para una interrupción previa de *menor prioridad*.

#cuadro-concepto(titulo:[Optimizador de Llegada Tardía])[
  1. El procesador *no interrumpe ni descarta* el proceso de apilado en curso, ya que la información del contexto que debe guardarse en el Stack es idéntica independientemente de qué ISR se ejecute primero.
  2. En paralelo a la finalización del apilado, la CPU cambia el vector buscado en la tabla IVT y *salta a ejecutar primero la ISR de mayor prioridad* (la que llegó tarde).
  3. Al terminar la ISR de alta prioridad, el procesador atiende a la de menor prioridad mediante *Tail-Chaining* (6 ciclos).
]

#figure(
  image("/images/late.png", width: 80%),
  caption: "Interrupt Latency - Late Arrival"
)

#v(2em)

#table(
  columns: (1.5fr, 2fr, 2fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#0f2b48") } else if calc.odd(y) { rgb("#f9f9f9") },
  align: (left, left, left),
  table.header(
  [ *Mecanismo de HW* ],[ *Condición de Disparo* ],[ *Impacto en Latencia / Ciclos* ]
  ),
[ *Tail-Chaining* ],[ISR finaliza y hay otra interrupción pendiente.],[Transición directa en *6 ciclos* (omite POP + PUSH completo).],
[ *Pre-Emption* ],[Entra IRQ con prioridad estrictamente mayor.],[Desaloja ISR actual; se anida mediante nuevo PUSH de contexto.],
[ *Late Arrival* ],[Entra IRQ de alta prioridad durante el PUSH de una menor.],[Aprovecha el PUSH en curso y redirige el salto a la ISR más urgente.]
)

= El Temporizador de Sistema: SysTick

El *SysTick* (*System Tick Timer*) es un temporizador regresivo de 24 bits integrado internamente dentro del núcleo ARM Cortex-M4 (Excepción N° 15 de la tabla IVT).

== 2.1. Propósito y Arquitectura
- *Heartbeat del Sistema:* Proporciona una base de tiempo fija y confiable (típicamente a *1 kHz / 1 ms*) utilizada por el sistema operativo o scheduler para medir retrasos, marcas de tiempo y coordinar tareas periódicas.
- *Contador Regresivo de 24 Bits:* Módulo decrementador independiente que cuenta desde el valor cargado en `LOAD` hasta `0`.
- *Excepción del Núcleo:* Al llegar a cero, se activa el flag `COUNTFLAG` y, si está habilitado, dispara la excepción nativa `SysTick_Handler()`.

#cuadro-atencion(titulo:[Limpieza Automática de Flag por Hardware])[
  A diferencia de los periféricos externos de los puertos (como `PORTA` o `PORTB`), *la ISR del SysTick NO requiere limpiar un flag mediante software (w1c)*. El hardware borra automáticamente la solicitud de interrupción al ingresar a la rutina `SysTick_Handler()`.
]

== 2.2. Estructura de Registros (`SysTick_Type` en CMSIS)

El módulo se programa mediante cuatro registros principales agrupados en la estructura `SysTick`:

#cuadro-registro(titulo:[Registros del Módulo SysTick])[
  - *`SysTick->CTRL` (Control and Status Register):*
    - Bit 0 (`ENABLE`): Activa o pausa el contador ($1 =$ Encendido).
    - Bit 1 (`TICKINT`): Habilita la excepción de interrupción ($1 =$ Genera IRQ al llegar a 0).
    - Bit 2 (`CLKSOURCE`): Selecciona la fuente de reloj ($1 =$ Core Clock / 100 MHz; $0 =$ Clock externo).
    - Bit 16 (`COUNTFLAG`): Retorna $1$ si el contador llegó a 0 desde la última lectura.
  - *`SysTick->LOAD` (Reload Value Register):* Registro de 24 bits (valor máx: $2^24 - 1$). Define el valor inicial cargado al llegar a cero.
  - *`SysTick->VAL` (Current Value Register):* Valor actual del contador de 24 bits. Escribir cualquier valor borra el contador y limpia `COUNTFLAG`.
  - *`SysTick->CALIB` (Calibration Value Register):* Registro de lectura con la calibración de fábrica para 10 ms.
]

=== Cálculo del Valor de Recarga (`LOAD`)
Para obtener un intervalo de tiempo $T$ con una frecuencia de reloj $f_"core"$:

$ "LOAD" = (f_"core" times T) - 1 $

#cuadro-ejemplo(titulo:[Ejemplos de Cálculo de Reload para K64F ($f_"core" = 100 "MHz"$)])[
  - *Para Tick de 1 ms ($1 "kHz" $): *
    $ "LOAD" = (100.000.000 "Hz" times 0,001 "s") - 1 = 100.000 - 1 = 99.999 "0x1869F" $
  - *Para Tick de 125 ms ($8 "Hz"$):*
    $ "LOAD" = (100.000.000 "Hz" times 0,125 "s") - 1 = 12.500.000 - 1 = 12.499.999 "0xBEBC1F" $
]

== 2.3. Código C de Inicialización y Controlador Nativo

```c
#include "MK64F12.h"

#define SYSTICK_CORE_HZ  100000000UL // 100 MHz
#define SYSTICK_FREQ_HZ  1000U       // 1 kHz (1 ms)

// 1. Inicialización del SysTick a 1 kHz
void SysTick_Init(void) {
    // Deshabilitar el temporizador antes de configurar
    SysTick->CTRL = 0x00;
    
    // Configurar valor de recarga para 1 ms
    SysTick->LOAD = (SYSTICK_CORE_HZ / SYSTICK_FREQ_HZ) - 1UL;
    
    // Limpiar el contador actual
    SysTick->VAL = 0x00;
    
    // Seleccionar Core Clock, habilitar interrupción y activar SysTick
    SysTick->CTRL = SysTick_CTRL_CLKSOURCE_Msk |
                    SysTick_CTRL_TICKINT_Msk   |
                    SysTick_CTRL_ENABLE_Msk;
}

// 2. Manejador de la Interrupción (ISR nativa del núcleo)
void SysTick_Handler(void) {
    // No requiere limpiar flags por software.
    // Tareas periódicas o incremento de contador de ms:
    milisegundos_transcurridos++;
}
```

= 3. Patrón de Arquitectura: Despachador de Tareas Periódicas

Para evitar configurar múltiples timers de hardware para cada tarea ligera, el SysTick actúa como una *base de tiempo compartida* mediante el registro de callbacks (*Scheduler* / Fachada HAL).

#cuadro-concepto(titulo:[Ventajas del Despachador Periódico (SysTick Multi-Callback)])[
  1. *Consolidación:* Múltiples módulos de software (refresco de display multiplexado, lectura de encoder con antirrebote, temporizadores de software) se enganchan al mismo tick de 1 kHz.
  2. *Desacoplamiento:* La ISR del SysTick no conoce la lógica interna de los drivers; simplemente recorre un vector de punteros a función y los ejecuta en orden secuencial.
]

== Ejemplo de Despachador Genérico en C

```c
#define MAX_CALLBACKS 4

typedef void (*systick_callback_t)(void);

static systick_callback_t callbacks_list[MAX_CALLBACKS] = {0};
static uint8_t callback_count = 0;

// Registrar una tarea periódica
bool SysTick_AddCallback(systick_callback_t callback) {
    if (callback_count < MAX_CALLBACKS && callback != NULL) {
        callbacks_list[callback_count++] = callback;
        return true;
    }
    return false;
}

// ISR del SysTick: desparrama la ejecución a todos los callbacks
void SysTick_Handler(void) {
    for (uint8_t i = 0; i < callback_count; i++) {
        if (callbacks_list[i] != NULL) {
            callbacks_list[i](); // Ejecuta HAL_Refresh_Task, actualizarEncoder, etc.
        }
    }
}
```

= Análisis Práctico de Timing y Prioridades

En sistemas embebidos reales con múltiples interrupciones concurrentes, asignar la misma prioridad a todas las ISRs puede provocar la pérdida de eventos críticos.

#cuadro-ejemplo(titulo:[Caso de Estudio: Lector de Banda Magnética vs. Refresco de Display])[
  - *Conflicto:* La ISR de refresco de display (que hace *bit-banging* por shift-registers en SysTick) es la tarea más larga del sistema.
  - *Problema:* Si el SysTick tuviera la misma prioridad que la interrupción de puerto `PORTB` del Lector de Tarjetas (ambos en prioridad 0 por defecto), la ejecución del SysTick retrasaría la captura del flanco del reloj de la tarjeta, perdiendo bits del *swipe*.
  - *Solución:* Ajustar las prioridades mediante el NVIC bajándole la prioridad al SysTick:
]

```c
// Asignación de Prioridades en App_Init()
void App_Init(void) {
    HAL_Scheduler_GlobalIRQDisable();

    // Configurar SysTick con prioridad 1 (más baja que la prioridad 0 por defecto de PORTB)
    NVIC_SetPriority(SysTick_IRQn, 1);
    
    // Inicializar el lector de tarjetas (queda en prioridad 0 por defecto)
    inicializarLector();

    HAL_Scheduler_GlobalIRQEnable();
}
```

#v(0.8em)

#cuadro-concepto(titulo:[Verificación con Osciloscopio (Pin de Testeo TP)])[
  Mediante el uso de un pin de prueba GPIO (`PIN_TEST_ISR`), se conmuta a nivel `HIGH` al ingresar a una ISR y a `LOW` al salir. Un osciloscopio permite medir con precisión absoluta:
  - *Duración de la ISR ($T_"exec"$):* Porcentaje del período del tick consumido por el firmware.
  - *Latencia de Interrupción:* Tiempo exacto entre el flanco físico del periférico externo y la entrada efectiva del procesador a la rutina de servicio.
]
