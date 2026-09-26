
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

= Clase 5

== Fundamentos de Comunicación Serial vs. Paralela

La transmisión de datos en sistemas embebidos entre el microcontrolador y periféricos externos (sensores, módulos de comunicación, PCs o pantallas) se clasifica en dos arquitecturas fundamentales:

#table(
  columns: (1.2fr, 2fr, 2fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#0f2b48") } else if calc.odd(y) { rgb("#f9f9f9") },
  align: (left, left, left),
  table.header(
    [*Parámetro*], [*Comunicación Paralela*], [*Comunicación Serial*]
  ),
  [*Líneas Físicas*], [Múltiples líneas de datos (8, 16, 32 bits simultáneos).], [Líneas reducidas (1 línea TX, 1 línea RX + GND).],
  [*Costo y Pines*], [Alto número de pines de I/O y cables voluminosos.], [Mínimo uso de pines; conectores y cables económicos.],
  [*Distancia y Ruido*], [Limitado a distancias muy cortas por *skew* de reloj y acoplamiento capacitivo.], [Alta inmunidad al ruido; ideal para distancias cortas y largas.],
  [*Ancho de Banda*], [Elevado en distancias muy cortas.], [Muy alto a altas frecuencias con transceptores adecuados.]
)

=== Comunicación Sincrónica vs. Asincrónica

- *Sincrónica (SPI, I2C):* Existe una línea física explícita de reloj (*Clock*) provista por un máster para sincronizar la lectura de los bits en emisor y receptor.
- *Asincrónica (UART):* No existe línea física de reloj. Emisor y receptor acuerdan previamente una velocidad fija (*Baud Rate*) y sincronizan sus relojes locales mediante el formato de una trama estructurada (*Start/Stop bits*).

#cuadro-concepto(titulo: [Bit Banging vs. Periférico Hardware])[
  - *Bit Banging:* Simular la transmisión serie por software conmutando manualmente pines GPIO mediante delays o timers. Consume valiosos ciclos de CPU y es propenso a fluctuaciones de tiempo (*jitter*).
  - *Periférico Dedicado (UART):* Módulo de hardware integrado que realiza la conversión paralelo-serie y serie-paralelo de forma autónoma mediante registros de desplazamiento y buffers, liberando a la CPU.
]

== 2. Anatomía Completa de la Trama UART (Protocolo 8N1)

En reposo, la línea de transmisión se mantiene en nivel lógico ALTO ($1$). La trama estándar *8N1* (8 bits de datos, sin paridad, 1 bit de stop) se compone secuencialmente de:

#cuadro-registro(titulo: [Campos Secuenciales de la Trama UART])[
  1. *Línea en Reposo (Idle):* Permanece en nivel lógico *ALTO (1 / $V_"DD"$)*.
  2. *Bit de Start:* Un pulso de nivel *BAJO (0 / GND)* de duración exacta de 1 tiempo de bit ($T_"bit"$) que avisa al receptor del inicio de datos.
  3. *Carga Útil (Payload / Data Bits):* Se transmiten de 5 a 8 bits de datos, enviando siempre el *bit menos significativo (LSB) primero*.
  4. *Bit de Paridad (Opcional - Par/Impar/Ninguna):* Bit de control para detección de errores simples de bit.
  5. *Bit(s) de Stop:* Uno o dos bits en nivel *ALTO (1 / $V_"DD"$)* que marcan el cierre de la trama y retornan la línea a reposo.
]

=== Eficiencia de Canal y Muestreo por Sobremuestreo

En una trama estándar 8N1 se envían 10 bits totales para transmitir 8 bits útiles de información:

$ "Eficiencia" = (8 "bits útiles") / (10 "bits totales") = 80 "%" $

$ T_"bit" = 1 / "Baud Rate" quad ==> quad "A 9600 bps: " T_"bit" = 1 / 9600 approx 104.16 mu "s" $

#cuadro-atencion(titulo: [Sobremuestreo 16x y Tolerancia de Sincronismo])[
  El receptor detecta el flanco descendente del bit de Start y sobremuestrea la línea *$16 times$* más rápido que el Baud Rate. Muestrea el nivel de tensión en el *centro teórico de cada bit ($0.5 times T_"bit"$)* para maximizar el margen de ruido.
  
  *Tolerancia Máxima:* Dado que emisor y receptor poseen cristales independientes, un desfasaje acumulado mayor al *$2.5 "%"$* entre ambos relojes provoca la lectura incorrecta del bit de Stop, generando un error de trama (*Framing Error - FE*).
]

== Capa Física, Estándares Eléctricos y Control de Flujo

La salida nativa del microcontrolador opera en niveles *TTL/CMOS (0V a 3.3V)*. Para comunicarse con computadoras o equipos industriales se requieren adaptadores de capa física:

#table(
  columns: (1.2fr, 2fr, 2fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#1a5fb4") } else if calc.odd(y) { rgb("#f4f7fa") },
  align: (left, left, left),
  table.header(
    [*Estándar*], [*Niveles de Tensión*], [*Características / Uso*]
  ),
  [*TTL / CMOS*], [$0 "V" = 0$, $3.3 "V" / 5 "V" = 1$], [Conexiones punto a punto dentro de la misma placa a corta distancia.],
  [*RS-232*], [$+3 "V" " a " +15 "V" = 0$ (Space), \ $-3 "V" " a " -15 "V" = 1$ (Mark)], [Lógica invertida de alta tensión. Requiere transceptor como MAX232. Inmunidad a interferencias.],
  [*USB-Serial (OpenSDA)*], [Conversión USB CDC Virtual COM], [Integrado en FRDM-K64F. Permite ver la UART en la PC mediante terminales (PuTTY, TeraTerm).],
  [*Comandos AT*], [Lógica de texto sobre UART (`AT`, `AT+CSQ`)], [Estándar de configuración para módulos Bluetooth (HC-05), GSM (SIM800) y GPS.]
)

=== Control de Flujo por Software (XON / XOFF)

Cuando el receptor no puede procesar los datos a la velocidad que los recibe, utiliza *Control de Flujo por Software*:
- *XOFF (`0x13` / Ctrl+S):* Enviado por el receptor para ordenar al emisor pausar la transmisión.
- *XON (`0x11` / Ctrl+Q):* Enviado por el receptor cuando vuelve a tener espacio disponible en el buffer para reanudar la transmisión.

== Colas Circulares (Ring Buffers) e Interrupciones

Existe una clara *asimetría temporal* entre la transmisión y la recepción:
- *Recepción (RX):* Es crítica e impredecible. Si no se lee el dato de inmediato cuando llega, el siguiente byte entrante lo sobrescribirá, causando un error de sobreescritura (*Overrun Error - OR*).
- *Transmisión (TX):* No es crítica. Si se demora el envío, únicamente se pierde velocidad de transmisión.

#cuadro-concepto(titulo: [Solución: Colas Circulares Orientadas a Interrupción])[
  Para evitar código bloqueante, la ISR de recepción guarda los bytes inmediatamente en una *Cola Circular (Ring Buffer)* en memoria RAM. El programa principal (*Main Loop*) consume los datos de la cola a su propio ritmo.
]

=== Código C Didáctico de una Cola Circular (`RingBuffer`)

```c
#define RING_BUFFER_SIZE 64

typedef struct {
    uint8_t buffer[RING_BUFFER_SIZE];
    uint16_t in;    // Puntero de entrada (escritura ISR)
    uint16_t out;   // Puntero de salida (lectura APP)
    uint16_t count; // Cantidad de elementos almacenados
} RingBuffer_t;

void RingBuffer_Init(RingBuffer_t *rb) {
    rb->in = 0;
    rb->out = 0;
    rb->count = 0;
}

bool RingBuffer_Push(RingBuffer_t *rb, uint8_t data) {
    if (rb->count >= RING_BUFFER_SIZE) return false; // Buffer Lleno
    rb->buffer[rb->in] = data;
    rb->in = (rb->in + 1) % RING_BUFFER_SIZE;
    rb->count++;
    return true;
}

bool RingBuffer_Pull(RingBuffer_t *rb, uint8_t *data) {
    if (rb->count == 0) return false; // Buffer Vacío
    *data = rb->buffer[rb->out];
    rb->out = (rb->out + 1) % RING_BUFFER_SIZE;
    rb->count--;
    return true;
}
```

== Mapeo de Registros y Cálculo Fraccional de Baud Rate en Kinetis K64F

El Kinetis K64F cuenta con 6 módulos UART (`UART0` a `UART5`):
- `UART0` y `UART1`: Alimentados desde el *System Clock* ($f_"core"$ hasta 100 MHz).
- `UART2` a `UART5`: Alimentados desde el *Bus Clock* ($f_"bus"$ hasta 50 MHz).

#cuadro-registro(titulo: [Fórmula Exacta del Baud Rate Fraccional])[
  El generador de Baud Rate utiliza un divisor grueso de 13 bits (`SBR` dividido entre los registros `BDH` y `BDL`) y un ajuste fino fraccional de 5 bits (`BRFA` en el registro `C4`):

  $ "Baud Rate" = "UART_CLK" / (16 times ("SBR" + "BRFA" / 32)) $

  - *Cálculo de SBR:* $"SBR" = "floor"("UART_CLK" / (16 times "Baud Rate"))$
  - *Cálculo de BRFA:* "BRFA" = "round"((("UART_CLK" / (16 times "Baud Rate")) - SBR) times 32)
]

== Control de Registros, FIFOs y Driver UART Completo en C

=== Registros de Control y Estado
- *`UARTx_C1`:* Configura formato de trama (8/9 bits, paridad).
- *`UARTx_C2`:* Habilita transmisor (`TE`), receptor (`RE`), interrupción por transmisión libre (`TIE`) e interrupción por recepción llena (`RIE`).
- *`UARTx_S1`:* Almacena los flags de estado principales (`TDRE`, `TC`, `RDRF`, `IDLE`, `OR`, `NF`, `FE`, `PF`).
- *`UARTx_D`:* Registro de datos de entrada/salida.

#cuadro-atencion(titulo: [Secuencia de Doble Lectura para Limpiar Banderas])[
  En los módulos UART de Kinetis, la bandera `RDRF` (o `TDRE`) *no se limpia escribiendo un 1*. Se limpia ejecutando la secuencia estricta por hardware:
  1. *Primero:* Leer el registro de estado `UARTx_S1`.
  2. *Segundo:* Leer (o escribir) el registro de datos `UARTx_D`.
]

=== Configuración de FIFOs de Hardware
Las UARTs disponen de FIFOs de hardware (`PFIFO`, `TWFIFO`, `RWFIFO`) que permiten configurar marcas de agua (*watermarks*). Por ejemplo, `RWFIFO = 1` genera la interrupción `RDRF` en cuanto ingresa al menos 1 byte en la FIFO de recepción.

=== Código C Completo del Driver UART0 Orientado a Interrupciones

```c
#include "MK64F12.h"
#include <stdbool.h>

static RingBuffer_t rx_buffer;

void UART0_Init(uint32_t baud_rate) {
    // 1. Clock Gating para UART0 y PORTB
    SIM->SCGC4 |= SIM_SCGC4_UART0_MASK;
    SIM->SCGC5 |= SIM_SCGC5_PORTB_MASK;

    // 2. Multiplexación de pines PTB16 (RX) y PTB17 (TX) en ALT3
    PORTB->PCR[16] = PORT_PCR_MUX(3);
    PORTB->PCR[17] = PORT_PCR_MUX(3);

    // 3. Deshabilitar Transmisor y Receptor antes de configurar
    UART0->C2 &= ~(UART_C2_TE_MASK | UART_C2_RE_MASK);

    // 4. Configurar Baud Rate (Ejemplo simplificado para 9600 bps a 100 MHz)
    uint16_t sbr = (uint16_t)(100000000 / (16 * baud_rate));
    UART0->BDH = (sbr >> 8) & UART_BDH_SBR_MASK;
    UART0->BDL = sbr & UART_BDL_SBR_MASK;
    UART0->C4 = (UART0->C4 & ~UART_C4_BRFA_MASK) | UART_C4_BRFA(16); // BRFA ajustado

    // 5. Inicializar Buffer Circular y Habilitar Interrupciones en C2 y NVIC
    RingBuffer_Init(&rx_buffer);
    UART0->C2 |= UART_C2_RIE_MASK;                  // Habilitar IRQ por Recepción
    UART0->C2 |= UART_C2_TE_MASK | UART_C2_RE_MASK; // Habilitar TX y RX

    NVIC_SetPriority(UART0_RX_TX_IRQn, 2);
    NVIC_EnableIRQ(UART0_RX_TX_IRQn);
}

// Rutina de Servicio de Interrupción (ISR Compartida)
void UART0_RX_TX_IRQHandler(void) {
    uint8_t status = UART0->S1;
    
    // Si hay un dato recibido en el registro D
    if (status & UART_S1_RDRF_MASK) {
        uint8_t data = UART0->D; // La lectura de S1 + D limpia RDRF automáticamente
        RingBuffer_Push(&rx_buffer, data);
    }
}

// Servicio de lectura no bloqueante para la Aplicación
bool UART0_ReadByte(uint8_t *data) {
    return RingBuffer_Pull(&rx_buffer, data);
}
```
