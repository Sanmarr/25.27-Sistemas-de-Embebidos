// ==========================================
// FUNCIONES DE CUADROS DIDÁCTICOS (CALLOUTS)
// ==========================================

#let cuadro-concepto(titulo: [Concepto Clave], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#e8f4f8"), stroke: (left: 4pt + rgb("#1b6ec2")),
  [
    #text(weight: "bold", fill: rgb("#104e8b"), size: 10.5pt)[💡 #titulo]     #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-ejemplo(titulo: [Ejemplo Práctico], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#eafaf1"), stroke: (left: 4pt + rgb("#2ecc71")),
  [
    #text(weight: "bold", fill: rgb("#1e8449"), size: 10.5pt)[🛠️ #titulo]     #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-atencion(titulo: [¡Atención / Cuidado!], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#fdf2e9"), stroke: (left: 4pt + rgb("#e67e22")),
  [
    #text(weight: "bold", fill: rgb("#a04000"), size: 10.5pt)[⚠️ #titulo]     #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-registro(titulo: [Detalle Técnico / Registro], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#f4ecf7"), stroke: (left: 4pt + rgb("#8e44ad")),
  [
    #text(weight: "bold", fill: rgb("#5b2c6f"), size: 10.5pt)[⚙️ #titulo]     #v(0.4em)
    #cuerpo
  ]
)

// ==========================================
// ENCABEZADO PRINCIPAL DEL RESUMEN
// ==========================================

= Arquitectura Interna y Funciones Avanzadas de GPIO

El módulo GPIO (*General Purpose Input/Output*) es el periférico más elemental de un microcontrolador. Sin embargo, su arquitectura interna incluye mecanismos clave para la integridad de señal y el control eléctrico.

== Instrumentación de Firmware (Debug por Hardware)
Además de controlar actuadores o leer sensores, los pines GPIO son la herramienta principal de depuración en tiempo real:
- *Técnica:* Conmutar un pin GPIO al ingresar y salir de una ISR o función crítica.
- *Medición:* Conectando un osciloscopio o analizador lógico al pin, se mide de forma exacta la *latencia de interrupción*, el *tiempo de ejecución de la tarea* y el *porcentaje de uso de CPU*.

== Configuración Eléctrica de Salida: Push-Pull vs. Open-Drain

#table(
  columns: (1.5fr, 2.5fr, 2fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#0f2b48") } else if calc.odd(y) { rgb("#f9f9f9") },
  align: (left, left, left),
  table.header(
    [ *Configuración* ], [ *Estructura MOSFET Interna* ], [ *Aplicación Principal* ]
  ),
  [ *Push-Pull* ], [Par PMOS (superior) y NMOS (inferior). Conecta activamente a $V_"DD"$ o $"GND"$.], [LEDs, cargas simples, buses punto a punto (SPI, UART TX).],
  [ *Open-Drain* ], [Deshabilita el PMOS. El pin solo puede forzar $"GND"$ o quedar en Alta Impedancia ($"Hi-Z"$).], [Buses compartidos bidireccionales (I2C), lógica *Wired-AND* y adaptación de niveles.]
)

== Sincronización y Prevención de Metaestabilidad
Cuando una señal digital externa cambia de estado de forma asincrónica, existe el riesgo de que el cambio ocurra exactamente durante el pulso de muestreo del reloj interno del microcontrolador.

#cuadro-atencion(titulo: [Riesgo de Metaestabilidad])[  Un evento asincrónico no sincronizado con el reloj del sistema puede provocar que los flip-flops internos entren en un estado indeterminado (*metaestable*), corrompiendo la lógica digital interna.
  
  *Solución de Hardware:* La etapa de entrada de los microcontroladores Kinetis incluye un *sincronizador con doble flip-flop en cascada*, el cual estabiliza la señal antes de presentarla en el registro de entrada `PDIR`.
]

= Mapeo de Registros PORT y GPIO en Kinetis K64F

En el K64F, el control de pines se divide formalmente en dos módulos de hardware:
1. *Módulo PORT (`PORTx_PCRn`):* Controla las propiedades eléctricas y la multiplexación de cada pin individual.
2. *Módulo GPIO (`GPIOx`):* Controla la dirección de datos y los niveles lógicos de salida y entrada.

== Registros Clave de Control y Datos

#cuadro-registro(titulo: [Registro Control de Pin (PORTx_PCRn)])[  - *`MUX` (Bits [10:8]):* Selecciona la función del pin (`001` = ALT1 para GPIO).
  - *`IRQC` (Bits [19:16]):* Configura la generación de interrupción o DMA (flancos o niveles).
  - *`ODE` (Bit 5):* Habilita modo Open-Drain ($1 =$ Habilitado).
  - *`PE` / `PS` (Bits 1:0):* Pull Enable ($"PE"=1$) y Pull Select ($"PS"=1$ para Pull-Up, $"PS"=0$ para Pull-Down).
  - *`DSE` (Bit 6):* Drive Strength Enable ($1 =$ Alta capacidad de corriente).
  - *`SRE` (Bit 2):* Slew Rate Enable ($1 =$ Velocidad de conmutación lenta para reducir EMI).
  - *`LK` (Bit 15):* Lock Register ($1 =$ Bloquea la configuración del PCR hasta el próximo Reset).
]

#v(0.5em)

#cuadro-concepto(titulo: [Ventaja de Registros de Escritura Atómica (PSOR / PCOR / PTOR)])[  - *`PDDR`:* Dirección de datos ($0 =$ Entrada, $1 =$ Salida).
  - *`PDIR`:* Lectura del estado real de los pines.
  - *`PSOR` (Port Set Output):* Escribir `1` fuerza el pin a ALTO.
  - *`PCOR` (Port Clear Output):* Escribir `1` fuerza el pin a BAJO.
  - *`PTOR` (Port Toggle Output):* Escribir `1` conmuta el estado del pin.
  
  *Escribir en `PSOR`/`PCOR`/`PTOR` ejecuta la modificación en *1 solo ciclo de bus*, garantizando operaciones atómicas sin requerir la secuencia susceptible a carreras Read-Modify-Write (`PDOR |= (1<<n)`).*
]

= Protocolo de Comunicación I2C (Inter-Integrated Circuit)

I2C es un bus serial síncrono, multimaestro y multiesclavo desarrollado por Philips que utiliza solo *2 hilos bidireccionales*:
- *SDA (Serial Data):* Línea de datos bidireccional.
- *SCL (Serial Clock):* Línea de reloj bidireccional controlada por el máster activo.

== Topología Eléctrica Open-Drain y Lógica Wired-AND
Todas las salidas SDA y SCL de los dispositivos en el bus son de drenador abierto (*Open-Drain*) y comparten resistencias de *Pull-Up* externas conectadas a $V_"DD"$ (típicamente $1.8 "k" Omega$ a $10 "k" Omega$).

#cuadro-concepto(titulo: [Lógica Wired-AND])[  Cualquier dispositivo en el bus puede tirar la línea a $"GND"$ (0V), pero ninguno puede forzar activamente un ALTO (3.3V). La línea solo sube a ALTO si *todos* los dispositivos dejan su salida en alta impedancia ($"Hi"-Z$). Esto previene cortocircuitos si dos equipos transmiten simultáneamente.
]

== Formas de Onda y Reglas del Protocolo I2C

#table(
  columns: (1.5fr, 2.5fr, 2fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#1a5fb4") } else if calc.odd(y) { rgb("#f4f7fa") },
  align: (left, left, left),
  table.header(
    [ *Condición / Fase* ], [ *Comportamiento de Señal (SDA / SCL)* ], [ *Función en la Trama* ]
  ),
  [ *START (S)* ], [Flanco descendente de SDA mientras SCL está en ALTO.], [Inicia la transferencia y toma el control del bus.],
  [ *STOP (P)* ], [Flanco ascendente de SDA mientras SCL está en ALTO.], [Finaliza la transferencia y libera el bus ($"Idle"$).],
  [ *REPEATED START (Sr)* ], [Condición START generada sin emitir un STOP previo.], [Permite cambiar de dirección TX/RX sin perder el control del bus.],
  [ *Transferencia Datos* ], [SDA solo puede cambiar cuando SCL está en BAJO. Se lee en el nivel ALTO de SCL.], [Transmite 8 bits (MSB primero).],
  [ *ACK / NACK* ], [El receptor fuerza SDA a BAJO (ACK = 0) o lo deja libre (NACK = 1) en el 9º pulso de SCL.], [Confirmación de recepción del byte por parte del receptor.]
)

== Mecanismos Avanzados: Clock Stretching y Arbitraje
1. *Clock Stretching (Estiramiento de Reloj):* Si un esclavo lento necesita tiempo para procesar datos, puede forzar la línea SCL a BAJO de forma continua. El máster detecta esto y detiene el reloj hasta que el esclavo libera SCL.
2. *Arbitraje Multi-Master:* Si dos másters inician una transmisión simultánea, ambos monitorean la línea SDA. Si un máster intenta enviar un `'1'` pero lee un `'0'` (porque otro máster tiró la línea a masa), pierde inmediatamente el arbitraje y se retira sin corromper la trama en curso.

= Implementación del Driver I2C en Kinetis K64F

El microcontrolador K64F cuenta con módulos `I2C0`, `I2C1` e `I2C2`.

== Registros Principales del Periférico `I2Cx`
- *`I2Cx->A1`:* Dirección propia de esclavo (7 bits).
- *`I2Cx->F`:* Divisor de frecuencia para generar la velocidad de SCL a partir del Bus Clock.
- *`I2Cx->C1`:* Registro de control principal (`IICEN` habilita módulo, `IICIE` habilita interrupción, `MST` selecciona Master/Slave, `TX` selecciona Transmisor/Receptor, `TXAK` habilita NACK, `RSTA` genera Repeated Start).
- *`I2Cx->S`:* Registro de estado (`TCF` transferencia completa, `BUSY` bus ocupado, `ARBL` pérdida de arbitraje, `IICIF` flag de interrupción *w1c*, `RXAK` estado del ACK recibido).
- *`I2Cx->D`:* Registro de datos de entrada/salida.

== Código C: Driver I2C Máster (Inicialización, Escritura y Lectura)

```c
#include "MK64F12.h"

// 1. Inicialización del Módulo I2C0
void I2C0_Init(void) {
    // A) Clock Gating para I2C0 y PORTE
    SIM->SCGC4 |= SIM_SCGC4_I2C0_MASK;
    SIM->SCGC5 |= SIM_SCGC5_PORTE_MASK;

    // B) Configurar MUX = ALT5 (I2C) y activar Open-Drain (ODE=1) en PTE24 (SCL) y PTE25 (SDA)
    PORTE->PCR[24] = PORT_PCR_MUX(5) | PORT_PCR_ODE_MASK;
    PORTE->PCR[25] = PORT_PCR_MUX(5) | PORT_PCR_ODE_MASK;

    // C) Configurar Frecuencia de SCL ~ 100 kHz (con Bus Clock de 50 MHz)
    I2C0->F = 0x14; // Multiplicador y Divisor de reloj

    // D) Habilitar el Módulo I2C
    I2C0->C1 = I2C_C1_IICEN_MASK;
}

// 2. Transmisión Máster (Escritura de un Byte a un Esclavo)
bool I2C0_WriteByte(uint8_t slave_addr, uint8_t reg_addr, uint8_t data) {
    // Esperar a que el bus esté libre
    while (I2C0->S & I2C_S_BUSY_MASK);

    // Generar START y configurar modo Transmisor (TX)
    I2C0->C1 |= I2C_C1_MST_MASK | I2C_C1_TX_MASK;

    // Enviar Dirección de Esclavo + Bit de Escritura (R/W = 0)
    I2C0->D = (slave_addr << 1) | 0;
    while (!(I2C0->S & I2C_S_IICIF_MASK)); // Esperar fin de byte
    I2C0->S |= I2C_S_IICIF_MASK;          // Limpiar flag w1c

    if (I2C0->S & I2C_S_RXAK_MASK) {      // Si se recibe NACK, abortar
        I2C0->C1 &= ~I2C_C1_MST_MASK;     // Generar STOP
        return false;
    }

    // Enviar Dirección del Registro Interno
    I2C0->D = reg_addr;
    while (!(I2C0->S & I2C_S_IICIF_MASK));
    I2C0->S |= I2C_S_IICIF_MASK;

    // Enviar el Dato
    I2C0->D = data;
    while (!(I2C0->S & I2C_S_IICIF_MASK));
    I2C0->S |= I2C_S_IICIF_MASK;

    // Generar Condición de STOP para liberar el bus
    I2C0->C1 &= ~(I2C_C1_MST_MASK | I2C_C1_TX_MASK);
    return true;
}

// 3. Recepción Máster (Lectura de un Byte desde un Esclavo)
uint8_t I2C0_ReadByte(uint8_t slave_addr, uint8_t reg_addr) {
    uint8_t dummy, data;

    // A) Enviar dirección de registro en modo Escritura
    I2C0->C1 |= I2C_C1_MST_MASK | I2C_C1_TX_MASK;
    I2C0->D = (slave_addr << 1) | 0;
    while (!(I2C0->S & I2C_S_IICIF_MASK));
    I2C0->S |= I2C_S_IICIF_MASK;

    I2C0->D = reg_addr;
    while (!(I2C0->S & I2C_S_IICIF_MASK));
    I2C0->S |= I2C_S_IICIF_MASK;

    // B) Generar REPEATED START para cambiar a modo Lectura
    I2C0->C1 |= I2C_C1_RSTA_MASK;
    I2C0->D = (slave_addr << 1) | 1; // R/W = 1 (Lectura)
    while (!(I2C0->S & I2C_S_IICIF_MASK));
    I2C0->S |= I2C_S_IICIF_MASK;

    // C) Cambiar a modo Receptor (RX) y configurar NACK para el último byte
    I2C0->C1 &= ~I2C_C1_TX_MASK;
    I2C0->C1 |= I2C_C1_TXAK_MASK; // Responder con NACK al recibir el byte

    // D) Lectura Dummy para iniciar la recepción por hardware
    dummy = I2C0->D;
    while (!(I2C0->S & I2C_S_IICIF_MASK));
    I2C0->S |= I2C_S_IICIF_MASK;

    // E) Generar STOP antes de leer el último byte del registro de datos
    I2C0->C1 &= ~(I2C_C1_MST_MASK | I2C_C1_TXAK_MASK);
    data = I2C0->D; // Lectura real del dato recibido

    return data;
}
```
