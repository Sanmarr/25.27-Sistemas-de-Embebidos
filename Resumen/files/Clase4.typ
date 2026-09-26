
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

= Clase 4

== Arquitectura de Firmware en Capas

En el desarrollo de sistemas embebidos profesionales, la complejidad crece rápidamente al integrar múltiples periféricos (displays multiplexados, teclados, sensores, comunicaciones). Para evitar que el código se vuelva inmanejable ("código espagueti") y garantizar su mantenibilidad, portabilidad y testeabilidad, se utiliza una *arquitectura modular estructurada en capas de abstracción bien definidas*.

#cuadro-concepto(titulo:[Principio de Diseño en Capas])[
  Cada capa del sistema satisface un rol específico y se comunica *exclusivamente con la capa inmediata superior o inferior* mediante interfaces estándar. La regla fundamental es el *aislamiento de hardware*: la capa de aplicación debe desconocer por completo qué microcontrolador o circuito integrado físico está ejecutando el código.
]

=== Jerarquía de Abstracción del Sistema

#grid(
  columns: (1fr,),
  gutter: 10pt,
[
    #table(
      columns: (1.2fr, 2.5fr, 2.5fr),
      inset: 6pt,
      stroke: 0.5pt + luma(180),
      fill: (_, y) => if y == 0 { rgb("#0f2b48") } else if calc.odd(y) { rgb("#f4f7fa") },
      align: (left, left, left),
      table.header(
      [ *Capa* ],[ *Responsabilidad y Función* ],[ *Impacto ante Cambios* ]
      ),
    [ *Aplicación (APP)* ],[Contiene la lógica de negocio (FSM, reglas del producto). Es independiente del tiempo real y *nunca accede directamente a registros*.],[Totalmente portable. No cambia si se reemplaza el procesador o los componentes externos.],
    [ *Hardware \ Abstraction \ Layer (HAL)* ],[Abstrae los componentes de hardware externos (display de 7 segmentos, shift-registers 74HC595, lector de tarjetas, encoder).],[Si cambia un componente exterior (ej. nuevo display), *solo se modifica esta capa*.],
    [ *Microcontroller \ Abstraction  \ Layer  (MCAL)* ],[Librería de más bajo nivel. Modifica los registros del microcontrolador (PORT, GPIO, SysTick, ADC, PIT, UART).],[Si se cambia de microcontrolador (ej. K64F $arrow$ STM32), *solo se modifica esta capa*.],
    [ *Complex Drivers* ],[Módulos especiales que unifican MCAL y HAL para aplicaciones de tiempo crítico estricto o máxima velocidad.],[Usados solo cuando el paso por capas intermedias introduce latencia inaceptable.]
    )
  ]
)

#v(0.5em)

#cuadro-atencion(titulo:[Regla Inviolable de Arquitectura])[
  *La Capa de Aplicación (APP) jamás debe incluir `MK64F12.h` ni acceder a registros como `PORTB->PCR` o `PTB->PSOR`.* Toda interacción con el mundo físico debe realizarse a través de las funciones de servicio de la capa HAL/MCAL.
]

#figure(
  image("/images/arqui.png", width: 90%),
  caption: "Ejemplo de Arquitectura de Firmware: Controlador de temperatura"
)

== Estructura Estándar de un Driver en C

Todos los drivers de periféricos (DRV) deben seguir una estructura interna uniforme dividida en 4 partes funcionales:

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
[
    #cuadro-registro(titulo:[1. Inicialización (`DRV_Init`)])[
      - Configura los registros iniciales del periférico e inicializa variables locales en RAM.
      - Se ejecuta *una sola vez* al arrancar el programa (invocada desde `App_Init`).
    ]
  ],
[
    #cuadro-registro(titulo:[2. Servicios de API (`DRV_SrvN`)])[
      - Funciones públicas de interfaz con la capa superior (ej. `HAL_Display_SetText`).
      - Invocables con cualquier frecuencia desde la APP. Ocultan los registros.
    ]
  ]
)

#v(0.3em)

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
[
    #cuadro-registro(titulo:[3. Rutina Periódica (`DRV_PISR`)])[
      - Tarea ejecutada a frecuencia fija (ej. cada 1 ms vía callback del SysTick).
      - Diseñada para *eventos lentos* (antirrebote de botones, multiplexado de display).
    ]
  ],
[
    #cuadro-registro(titulo:[4. Interrupción Dedicada (`DRV_ISR`)])[
      - Atiende eventos físicos instantáneos disparados por hardware.
      - Diseñada para *eventos rápidos / críticos* (flancos de reloj de banda magnética).
    ]
  ]
)

== Análisis Temporal de Modelos de Ejecución

Para gestionar la interacción entre la Aplicación, el Driver y el Hardware, existen 4 estrategias temporales con eficiencias drásticamente distintas:

=== 1. Código Bloqueante (*Blocking Code*)
La Aplicación llama al Driver para iniciar una tarea y el Driver congela la CPU en un bucle cerrado hasta que el Hardware responda.
- *Rendimiento:* *0% de eficiencia de CPU.* Desperdicia millones de ciclos de reloj esperando eventos externos.
- *Uso:* Totalmente *prohibido* en sistemas profesionales y de tiempo real.

#figure(
  image("/images/bloq.png", width: 70%)
)

=== 2. Polling (*Consulta Continua*)
La Aplicación realiza una secuencia de 3 llamadas no bloqueantes: *comenzar*, *¿está listo?*, y *leer resultado*.
- *Rendimiento:* La APP puede intercalar otras tareas, pero pierde tiempo valioso volviendo a preguntar constantemente `¿listo?` al Driver.
- *Inconveniente:* El Driver actúa de simple pasamanos y la CPU consume energía inútilmente.

#figure(
  image("/images/polling.png", width: 70%)
)

=== 3. Interrupción Periódica (*PISR / Hardware Polling*)
Un temporizador de hardware (como el *SysTick a 1 kHz*) ejecuta automáticamente la función `DRV_PISR()` a intervalos regulares para interrogar al hardware.
- *Rendimiento:* *Excelente.* La APP queda suspendida un tiempo ínfimo durante la interrupción y el evento se captura en RAM inmediatamente.
- *Uso:* Opción preferida para la mayoría de las interfaces humanas (botones, encoders, displays).

#figure(
  image("/images/pisr.png", width: 70%)
)

=== 4. Interrupción Dedicada (*ISR*)
El hardware envía una señal eléctrica (IRQ) a la CPU en el instante exacto en que ocurre el evento, ejecutando `DRV_ISR()`.
- *Rendimiento:* *Respuesta inmediata en tiempo real (mínima latencia).*
- *Uso:* Reservado para eventos ultra-rápidos que se perderían entre muestras periódicas.

#v(0.5em)

#table(
  columns: (1.5fr, 1.2fr, 2fr, 2fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#1a5fb4") } else if calc.odd(y) { rgb("#f4f7fa") },
  align: (left, center, left, left),
  table.header(
  [ *Modelo* ],[ *Latencia* ],[ *Consumo de CPU* ],[ *Caso de Uso Recomendado* ]
  ),
[ *Bloqueante* ],[ Nula (espera dedicada) ],[ 100% de la CPU desperdiciada ],[ Inicializaciones sencillas de hardware al arrancar. ],
[ *Polling* ],[ Variable según el loop ],[ Alto (consultas repetitivas) ],[ Pruebas de laboratorio o microcontroladores sin timers. ],
[ *PISR (Tick)* ],[ Acotada al período (ej. 1 ms) ],[ Mínimo (ejecución rápida en ISR) ],[ Pulsadores, encoders, displays multiplexados, teclados. ],
[ *ISR Dedicada* ],[ Inmediata ($approx$ nanosegundos) ],[ Solo durante la ráfaga del evento ],[ Lectores de banda magnética, recepción UART, encoders de motor. ]
)

== Integración Segura con Callbacks y Reglas de Diseño

#cuadro-atencion(titulo:[REGLA ABSOLUTA DE DISEÑO: Jamás Lanzar Callbacks desde ISR / PISR])[
  *"Never ever launch a callback from inside an ISR or PISR."* \
  Si un driver ejecuta un *callback* inyectado por el usuario directamente dentro del contexto de una interrupción y dicho código contiene un error (bucle infinito, retardo o sección bloqueante), *todo el microcontrolador se congelará irreversiblemente*.

   #figure(
  image("/images/isrCal.png", width: 80%)
)
]

=== Arquitectura Correcta de Despacho de Eventos

Para comunicar eventos desde el hardware hacia la aplicación sin correr riesgos:
1. *La ISR / PISR solo captura los datos crudos y enciende un *Flag* en RAM.*
2. *El bucle principal (`App_Run`) consulta el estado del driver mediante funciones de servicio (`DRV_Srv`).*
3. *Al detectar el flag activo, la APP invoca la función de usuario o callback de manera segura fuera de la interrupción.*

#v(0.5em)

#cuadro-ejemplo(titulo:[Código Didáctico: Arquitectura Completa de Capas y Timer PISR en C])[
```c
// ====================================================================
// CAPA MCAL / HAL: driver_timer.c (Gestión del SysTick y PISR)
// ====================================================================
#include "MK64F12.h"
#include <stdbool.h>

static volatile bool flag_evento_10ms = false;
static uint32_t contador_milis = 0;

// PISR: Ejecutada periódicamente a 1 kHz por la ISR del SysTick
void DRV_PISR_TimerTick(void) {
    contador_milis++;
    if ((contador_milis % 10) == 0) {
        flag_evento_10ms = true; // SOLO SE PONE EL FLAG, NO SE LLAMA AL CALLBACK
    }
}

// Servicio público para consultar estado desde la APP (Servicio No Bloqueante)
bool DRV_Srv_CheckEvent10ms(void) {
    if (flag_evento_10ms) {
        flag_evento_10ms = false; // Write-1-to-Clear lógico
        return true;
    }
    return false;
}

// ====================================================================
// CAPA APLICACIÓN: App.c (Súper-Loop y FSM)
// ====================================================================
void App_Run(void) {
    // Consulta no bloqueante de eventos del driver
    if (DRV_Srv_CheckEvent10ms()) {
        // Ejecución segura de la lógica de usuario / Callback
        FSM_Update(EV_TICK_10MS);
    }
    
    // El Súper-Loop continúa ejecutando otras tareas sin bloquearse
}
```
]

#v(0.8em)

#cuadro-concepto(titulo:[Resumen de la Estrategia del Proyecto])[
  - *SysTick (1 kHz):* Se utiliza como la base de tiempo central (Scheduler) que dispara la `PISR` para refrescar el display y procesar el antirrebote del encoder.
  - *Lector Magnético (ISR Dedicada):* Captura cada bit en tiempo real por flanco en la ISR de `PORTB`. La decodificación del paquete (operación costosa) se delega a `App_Run()` fuera de la interrupción.
]
