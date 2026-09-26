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

= Clase 2

== 1. Bit-Banding: Operaciones Atómicas de BITS

En los microcontroladores estándar de 32 bits, la CPU *no puede modificar bits individuales directamente en memoria o en un registro*. Los accesos a memoria se realizan siempre por bytes (8 bits), half-words (16 bits) o words completos (32 bits).

=== El Problema de la Condición de Carrera (Race Condition)
Cuando intentamos cambiar un solo bit mediante la secuencia tradicional *Read-Modify-Write (RMW)*:
1. *Read:* La CPU lee el registro completo de 32 bits a un registro interno de la CPU.
2. *Modify:* Realiza una operación lógica (`OR`, `AND`) para alterar el bit deseado.
3. *Write:* Escribe el valor modificado de regreso al registro.

#cuadro-atencion(titulo: [Riesgo de Concurrencia con Interrupciones])[
  Si una interrupción (ISR) ocurre justo entre el paso de *Lectura* y el de *Escritura*, la ISR puede modificar otro bit del mismo registro. Al retornar de la interrupción, el programa principal ejecutará el paso de *Escritura*, **sobrescribiendo y perdiendo completamente el cambio realizado por la ISR**.
]

=== La Solución: Mapeo Bit-Band
La arquitectura ARM Cortex-M4 introduce el mecanismo de **Bit-Banding**, el cual convierte un acceso a un *bit individual* en una operación de escritura o lectura *atómica* (indivisible e ininterrumpible) mediante el uso de un **alias de memoria**.

#grid(
  columns: (1fr, 1fr),
  gutter: 12pt,
  [
    #cuadro-concepto(titulo: [Región Bit-Band])[
      - Corresponde a la región de memoria real (SRAM o Periféricos).
      - Cada bit en esta región se mapea a una palabra de 32 bits en la región alias.
      - Tamaño: 1 MB de memoria real.
    ]
  ],
  [
    #cuadro-concepto(titulo: [Región Alias Bit-Band])[
      - Dirección especial de memoria de 32 MB.
      - Escribir `0x01` o `0x00` en una dirección alias modifica **solamente el bit objetivo** de manera atómica por hardware.
    ]
  ]
)

#v(0.5em)

==== Fórmula de Mapeo de Direcciones
Para calcular la dirección en la región alias correspondiente a un bit específico de un byte/registro:

$ "Alias_Addr" = "Alias_Base" + ("Byte_Offset" times 32) + ("Bit_Number" times 4) $

#table(
  columns: (1.5fr, 2fr, 2fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#0f2b48") } else if calc.odd(y) { rgb("#f9f9f9") },
  align: (left, center, center),
  table.header(
    [ *Zona de Memoria* ], [ *Dirección Base Real (Bit-Band)* ], [ *Dirección Base Alias* ]
  ),
  [ *SRAM (RAM)* ], [`0x2000_0000`], [`0x2200_0000`],
  [ *Periféricos (GPIO, TIM, etc.)* ], [`0x4000_0000`], [`0x4200_0000`]
)

#cuadro-ejemplo(titulo: [Lectura / Escritura en Alias])[
  - **Escritura:** Escribir cualquier número con LSB=1 (como `0x01`) en la dirección alias pone el bit real en `1`. Escribir un número con LSB=0 (como `0x00`) pone el bit real en `0`.
  - **Lectura:** Leer la dirección alias retorna `0x01` si el bit real está en `1`, y `0x00` si está en `0`.
]

== 2. Fundamentos de Interrupciones

Una **interrupción** es un evento generado por el hardware que suspende temporalmente la ejecución secuencial del programa principal (*Main Loop*) para atender una tarea urgente mediante una rutina llamada **ISR** (*Interrupt Service Routine*). Una vez finalizada la ISR, el procesador retoma la ejecución del programa exactamente en la instrucción donde fue suspendido.

=== Conceptos Fundamentales
- **IRQ (Interrupt Request):** Solicitud asincrónica de interrupción enviada por un periférico al procesador.
- **ISR (Interrupt Service Routine / Handler):** Función ejecutada en respuesta a una IRQ específica.
- **IVT (Interrupt Vector Table):** Tabla ubicada al inicio de la memoria que almacena punteros a función (*vectores*) con las direcciones de inicio de cada ISR.

=== Comparativa de Estrategias de Control

#table(
  columns: (1.2fr, 2fr, 2fr, 2fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#1a5fb4") } else if calc.odd(y) { rgb("#f4f7fa") },
  align: (left, left, left, left),
  table.header(
    [ *Mecanismo* ], [ *Funcionamiento* ], [ *Ventajas* ], [ *Desventajas* ]
  ),
  [ *Polling (Consulta)* ], [El bucle principal consulta continuamente el estado del periférico en un `while(1)`.], [Fácil de programar, sin sobrecosto de contexto.], [Desperdicia tiempo de CPU y energía; no determinístico.],
  [ *Interrupción Periódica (Tick)* ], [Un timer (SysTick) interrumpe a intervalos regulares para muestrear eventos (p. ej. botones).], [Consumo controlado, excelente para debouncing de pulsadores.], [Retardo de respuesta acotado por el período del tick.],
  [ *Interrupción Dedicada* ], [El evento de hardware exterior (flanco en pin) dispara la ISR en tiempo real.], [Respuesta inmediata (mínima latencia), ultra eficiente.], [Puede saturar la CPU si ocurren eventos indeseados a muy alta frecuencia.]
)

=== Máscaras y Flags de Interrupción
Para que una interrupción sea atendida, se requieren **dos llaves en serie**:

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  [
    #cuadro-concepto(titulo: [1. Máscara Global])[
      - Controlada por el procesador (*Global Interrupt Enable* / bit `I` en `PRIMASK`).
      - Permite habilitar o deshabilitar todas las interrupciones enmascarables de forma centralizada (funciones `hw_EnableInterrupts()` / `hw_DisableInterrupts()`).
    ]
  ],
  [
    #cuadro-concepto(titulo: [2. Máscaras Individuales])[
      - **Nivel Periférico:** Bit `IRQC` en el `PCR` del pin.
      - **Nivel NVIC:** Registros `ISER` / `ICER` del controlador de interrupciones del ARM Cortex-M4.
    ]
  ]
)

#v(0.5em)

#cuadro-atencion(titulo: [Flags de Interrupción y Lectura/Limpieza (w1c)])[
  Cuando ocurre el evento, el hardware activa un bit de estado llamado **Interrupt Status Flag** (ej. en `ISFR`). 
  
  **Regla de Oro:** En la mayoría de las ISRs de periféricos (como los puertos GPIO), es **obligatorio limpiar el flag dentro de la rutina escribiendo un `1` (Write-1-to-Clear / `w1c`)**. Si no se limpia el flag, al salir de la ISR el procesador verá el flag encendido y volverá a entrar a la interrupción en un **bucle infinito**.
]

== 3. El Controlador de Interrupciones del K64: NVIC

El **NVIC** (*Nested Vectored Interrupt Controller*) es el módulo integrado en el núcleo ARM Cortex-M4 que administra todas las excepciones e interrupciones del microcontrolador.

#cuadro-concepto(titulo: [Características del NVIC])[
  1. **Vectoreado:** Determina la dirección de la ISR directamente mediante la tabla IVT.
  2. **Anidado (Nested):** Si se dispara una interrupción de *mayor prioridad* mientras se ejecuta otra ISR de menor prioridad, la primera es suspendida para atender a la más urgente.
  3. **Tail-Chaining:** Optimización por hardware que reduce el tiempo de cambio entre dos interrupciones consecutivas a solo **6 ciclos de reloj** (evita desapilar y volver a apilar registros innecesariamente).
]

=== Mapa de Excepciones e Interrupciones
Las excepciones se dividen en internas (del núcleo ARM Cortex) y externas (periféricos del fabricante NXP):

#table(
  columns: (1fr, 1.5fr, 1.2fr, 3fr),
  inset: 5pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#0f2b48") } else if y <= 4 { rgb("#eef4f8") } else { rgb("#ffffff") },
  align: (center, left, center, left),
  table.header(
    [ *Nº Excepción* ], [ *Nombre* ], [ *Prioridad* ], [ *Descripción* ]
  ),
  [ 1 ], [ Reset ], [ -3 (Máxima) ], [ Reinicio del sistema por hardware o software. ],
  [ 2 ], [ NMI ], [ -2 ], [ Interrupción No Enmascarable (urgencias graves). ],
  [ 3 ], [ HardFault ], [ -1 ], [ Falla grave de hardware (ej. acceso no permitido a memoria). ],
  [ 15 ], [ SysTick ], [ Configurable ], [ Timer de sistema periódico propio del núcleo ARM. ],
  [ 16 (IRQ0) ], [ DMA / UART / PORTA... ], [ Configurable ], [ Interrupciones externas de periféricos del K64F. ]
)

=== Estructura de Registros del NVIC (`NVIC_Type` en CMSIS)
El NVIC se programa mediante una estructura de registros mapeados en memoria:

#cuadro-registro(titulo: [Registros Principales del NVIC])[
  - **`ISER[8]` (Interrupt Set-Enable):** Escribir `1` habilita la línea de interrupción individual.
  - **`ICER[8]` (Interrupt Clear-Enable):** Escribir `1` deshabilita la línea de interrupción.
  - **`ISPR[8]` (Interrupt Set-Pending):** Fuerza la interrupción a estado pendiente por software.
  - **`ICPR[8]` (Interrupt Clear-Pending):** Limpia el estado pendiente.
  - **`IABR[8]` (Interrupt Active Bit):** Indica si una ISR está actualmente en ejecución.
  - **`IP[240]` (Interrupt Priority):** Array de bytes para configurar la prioridad. En el K64F se utilizan solo los **4 bits más significativos** de cada byte ($2^4 = 16$ niveles de prioridad, donde **0 es la máxima prioridad** y **15 la mínima**).
]

=== Funciones Estándar CMSIS para el NVIC

```c
// Habilitar / Deshabilitar interrupción de un periférico
NVIC_EnableIRQ(PORTA_IRQn);
NVIC_DisableIRQ(PORTA_IRQn);

// Configurar prioridad (IRQn_Type IRQn, uint32_t priority [0..15])
NVIC_SetPriority(PORTA_IRQn, 5);

// Limpiar estado pendiente
NVIC_ClearPendingIRQ(PORTA_IRQn);
```

== 4. Guía Paso a Paso: Configuración de Interrupción en C

Para configurar e implementar una interrupción de GPIO externa (por ejemplo, en el pulsador SW3 conectado a `PTA4`), se debe seguir estrictamente la siguiente secuencia de 5 pasos:

#grid(
  columns: (1fr,),
  gutter: 8pt,
  [
    #cuadro-ejemplo(titulo: [Secuencia de Inicialización de una Interrupción (5 Pasos Globales)])[
      1. **Deshabilitar Interrupciones Globales:** Evita que entren interrupciones mientras se configura el microcontrolador (`hw_DisableInterrupts()`).
      2. **Clock Gating:** Activar el reloj del puerto correspondiente (`SIM->SCGC5 |= SIM_SCGC5_PORTA_MASK`).
      3. **Configurar Pin Control Register (PCR):** Configurar MUX como GPIO (ALT1), resistencias de Pull-Up/Down y el modo de disparo por flanco en `IRQC`.
      4. **Habilitar IRQ en el NVIC:** Activar la atención de interrupción del puerto en el controlador del núcleo (`NVIC_EnableIRQ(PORTA_IRQn)`).
      5. **Habilitar Interrupciones Globales:** Permitir la entrada de interrupciones al procesador (`hw_EnableInterrupts()`).
    ]
  ]
)

=== Código de Ejemplo Completo (Pulsador SW3 en `PTA4` e ISR)

```c
#include "MK64F12.h"

// 1. Definición de la Rutina de Servicio de Interrupción (ISR)
void PORTA_IRQHandler(void) {
    // A) Verificar e identificar el pin que interrumpió
    if (PORTA->ISFR & (1 << 4)) {
        
        // B) LIMPIAR EL FLAG DE INTERRUPCIÓN (Write 1 to Clear)
        PORTA->ISFR = (1 << 4); 
        
        // C) Ejecutar la acción deseada (ejemplo: alternar LED)
        PTB->PTOR = (1 << 21); // Toggle LED Azul en PTB21
    }
}

// 2. Función de Inicialización del Sistema
void App_Init(void) {
    // Paso 1: Deshabilitar interrupciones globales durante la configuración
    hw_DisableInterrupts();

    // Paso 2: Activar Clock Gating para los puertos A y B
    SIM->SCGC5 |= SIM_SCGC5_PORTA_MASK | SIM_SCGC5_PORTB_MASK;

    // Configurar LED Azul en PTB21 como salida
    PORTB->PCR[21] = PORT_PCR_MUX(1); // GPIO (ALT1)
    PTB->PDDR |= (1 << 21);            // Dirección: Salida

    // Paso 3: Configurar el Pin Control Register (PCR) del Pulsador PTA4
    PORTA->PCR[4] = 0x0;                                     // Limpiar registro
    PORTA->PCR[4] |= PORT_PCR_MUX(1);                         // MUX = ALT1 (GPIO)
    PORTA->PCR[4] |= PORT_PCR_PE(1) | PORT_PCR_PS(1);         // Habilitar Pull-Up interno
    PORTA->PCR[4] |= PORT_PCR_IRQC(0x09);                     // IRQC = 0x09 (Flanco de Subida / Interrupt on Rising Edge)

    // Configurar PTA4 como entrada
    PTA->PDDR &= ~(1 << 4);

    // Paso 4: Configurar prioridad y habilitar la IRQ del Puerto A en el NVIC
    NVIC_SetPriority(PORTA_IRQn, 3); // Prioridad 3
    NVIC_EnableIRQ(PORTA_IRQn);       // Habilitar en NVIC

    // Paso 5: Re-habilitar interrupciones globales
    hw_EnableInterrupts();
}
```

#v(0.8em)

#cuadro-concepto(titulo: [Resumen Visual de Configuración `IRQC` en PCR])[
  Los bits [19:16] del registro `PORTx_PCRn` determinan el modo de generación de evento de interrupción/DMA:
  - `0000` (0x0): Interrupción deshabilitada.
  - `1000` (0x8): Interrupción lógica `0` (por nivel).
  - `1001` (0x9): Interrupción por **Flanco de Subida (Rising Edge)**.
  - `1010` (0x10 / 0xA): Interrupción por **Flanco de Bajada (Falling Edge)**.
  - `1011` (0x11 / 0xB): Interrupción por **Ambos Flancos (Either Edge)**.
  - `1100` (0x12 / 0xC): Interrupción lógica `1` (por nivel).
]
