
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

// =====================================================================
// CLASE 6: GPIO AVANZADO Y PROTOCOLOS SERIE (SPI, I2C, CAN)
// =====================================================================

= Clase 6

== Protocolo SPI (Serial Peripheral Interface)

#figure(image("/images/spi.png", width: 60%), caption: "Protocolo SPI")

=== Arquitectura y Señales Físicas

SPI es un protocolo serie síncrono diseñado para comunicaciones de corta distancia entre periféricos y microcontroladores. Opera bajo una arquitectura estricta de maestro-esclavo, donde el dispositivo maestro siempre inicia la transferencia y genera la señal de reloj para sincronizar los datos.

Físicamente, un enlace SPI utiliza cuatro señales:
 - *SCK (Serial Clock):* Reloj generado exclusivamente por el maestro.
 - *MOSI (Master Out Slave In):* Línea de datos desde el maestro hacia el esclavo.
 - *MISO (Master In Slave Out):* Línea de datos desde el esclavo hacia el maestro.
 - *SS (Slave Select):* Señal de habilitación, típicamente activa en bajo, con la que el maestro selecciona específicamente el esclavo activo.

#figure(image("/images/spi2.png", width: 60%))

#cuadro-registro(titulo: [Mecanismo de Shift Registers])[
Internamente, la comunicación SPI funciona como un gran anillo de registros de desplazamiento (*shift registers*). Tanto el maestro como el esclavo poseen un registro de desplazamiento; durante cada ciclo de reloj, el maestro empuja un bit por MOSI hacia el esclavo, y simultáneamente el esclavo empuja un bit por MISO hacia el maestro. Toda transmisión de datos implica inherentemente una recepción paralela.
]

=== Topologías de Red

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  [
    #cuadro-concepto(titulo: [*Topología en Bus:*])[
      Todos los esclavos comparten en paralelo las líneas SCK, MISO y MOSI. El maestro utiliza múltiples pines de SS (uno dedicado de forma individual por cada esclavo). Las salidas MISO de los esclavos deshabilitados deben permanecer obligatoriamente en estado de alta impedancia ($"Hi"-Z$).
    ]
  ],
  [
    #cuadro-concepto(titulo: [*Topología en Cascada (Daisy Chain):*])[
      Se utiliza un único pin SS compartido para todos los esclavos. La línea MOSI del maestro entra al primer esclavo, la salida MISO del primero se conecta a la entrada MOSI del segundo, y así sucesivamente, hasta que el MISO del último esclavo retorna al maestro. 
    ]
  ]
)


== Protocolo I2C (Inter-Integrated Circuit)

#figure(image("/images/i2c.png", width: 60%))

=== Arquitectura Eléctrica y Wired-AND

I2C es un bus serie síncrono, multimaestro y multiesclavo de baja velocidad (típicamente entre 100 kbps y 400 kbps) que utiliza únicamente dos hilos bidireccionales y una referencia de masa compartida ($"GND"$):


#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
[
    #cuadro-registro(titulo:[SDA (Serial Data)])[
      Línea de datos  \ bidireccional.
    ]
  ],
[
    #cuadro-registro(titulo:[SCL (Serial Clock)])[
      Línea de reloj bidireccional controlada por el máster activo.
    ]
  ]
)

Todos los pines de los dispositivos están configurados en drenador o colector abierto (*Open-Drain*) y comparten resistencias de *Pull-Up* externas conectadas a $V_"DD"$ (típicamente $1.8 "k"Omega$ a $10 "k"Omega$). Esta configuración forma una compuerta *Wired-AND* de hardware: la línea solo sube a ALTO si todos los dispositivos dejan su salida en alta impedancia ($"Hi"-Z$), lo que previene cortocircuitos si dos equipos transmiten simultáneamente.

En el Kinetis K64F, es necesario activar el bit `ODE` escribiendo un "1" en el registro `PORTx_PCRn` correspondiente.

=== Formas de Onda y Reglas del Protocolo I2C


#table(
  columns: (1.5fr, 2.5fr, 2fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#1a5fb4") } else if calc.odd(y) { rgb("#f4f7fa") },
  align: (left, left, left),
  table.header(
    [*Condición / Fase*],
    [*Comportamiento de Señal (SDA / SCL)*],
    [*Función en la Trama*]
  ),
  [*START (S)*], [Flanco descendente de SDA mientras SCL está en ALTO.], [Inicia la transferencia y toma el control del bus.],
  [*STOP (P)*], [Flanco ascendente de SDA mientras SCL está en ALTO.], [Finaliza la transferencia y libera el bus ($"Idle"$).],
  [*REPEATED START (Sr)*], [Condición START generada sin emitir un STOP previo.], [Permite cambiar de dirección TX/RX sin perder el control del bus ni reiniciar la máquina de estados del esclavo.],
  [*Transferencia Datos*], [SDA solo puede cambiar cuando SCL está en BAJO. Se lee en el nivel ALTO de SCL.], [Transmite 8 bits (*MSB primero*).],
  [*ACK / NACK*], [El receptor fuerza SDA a BAJO (ACK = 0) o lo deja libre (NACK = 1) en el 9º pulso de SCL.], [Confirmación de recepción del byte por parte del receptor.]
)

#figure(image("/images/i2c-prot.png", width: 100%), 
caption: "Protocolo de Escritura")

=== Mecanismos Avanzados

#cuadro-registro(titulo: [Clock Stretching y Arbitraje])[
*Clock Stretching:* Si un esclavo necesita tiempo adicional para procesar un byte recibido, puede mantener forzosamente SCL en nivel bajo. El maestro detecta este estado de espera (*wait state*) y pausa la transmisión hasta que el esclavo libera SCL.

*Arbitraje de Bus:* Si dos maestros emiten un START simultáneamente, ambos monitorean la línea SDA mientras transmiten. Si un maestro impone un '1' (recesivo) pero lee un '0' (dominante forzado por otro nodo), detecta una colisión, pierde el arbitraje y aborta su transmisión inmediatamente sin corromper el mensaje.

#figure(image("/images/i2c-blando.png", width: 100%), 
caption: "lógica Wired-AND (1 Blando y 0 Dominante).")
]
=== Driver I2C en Kinetis K64F

El microcontrolador K64F cuenta con los módulos `I2C0`, `I2C1` e `I2C2`.
Registros principales:
 - `I2Cx->A1`: Dirección propia de esclavo (7 bits).
 - `I2Cx->F`: Divisor de frecuencia para SCL a partir del Bus Clock.
 - `I2Cx->C1`: Control principal (`IICEN`, `IICIE`, `MST`, `TX`, `TXAK`, `RSTA`).
 - `I2Cx->S`: Estado (`TCF`, `BUSY`, `ARBL`, `IICIF` *w1c*, `RXAK`).
 - `I2Cx->D`: Registro de datos de entrada/salida.

*Código C: Driver I2C Máster (Inicialización, Escritura y Lectura)*
```c
#include "MK64F12.h"
#include <stdbool.h>

// 1. Inicialización del Módulo I2C0
void I2C0_Init(void) {
    // A) Clock Gating para I2C0 y PORTE
    SIM->SCGC4 |= SIM_SCGC4_I2C0_MASK;
    SIM->SCGC5 |= SIM_SCGC5_PORTE_MASK;

    // B) Configurar MUX = ALT5 (I2C) y activar Open-Drain (ODE=1) en PTE24 (SCL) y PTE25 (SDA)
    PORTE->PCR[24] = PORT_PCR_MUX(5) | PORT_PCR_ODE_MASK;
    PORTE->PCR[25] = PORT_PCR_MUX(5) | PORT_PCR_ODE_MASK;

    // C) Configurar Frecuencia de SCL ~ 100 kHz (con Bus Clock de 50 MHz)
    I2C0->F = 0x14;

    // D) Habilitar el Módulo I2C
    I2C0->C1 = I2C_C1_IICEN_MASK;
}

// 2. Transmisión Máster (Escritura de un Byte a un Esclavo)
bool I2C0_WriteByte(uint8_t slave_addr, uint8_t reg_addr, uint8_t data) {
    while (I2C0->S & I2C_S_BUSY_MASK);

    I2C0->C1 |= I2C_C1_MST_MASK | I2C_C1_TX_MASK;
    I2C0->D = (slave_addr << 1) | 0;
    while (!(I2C0->S & I2C_S_IICIF_MASK));
    I2C0->S |= I2C_S_IICIF_MASK;

    if (I2C0->S & I2C_S_RXAK_MASK) {
        I2C0->C1 &= ~I2C_C1_MST_MASK; // Generar STOP
        return false;
    }

    I2C0->D = reg_addr;
    while (!(I2C0->S & I2C_S_IICIF_MASK));
    I2C0->S |= I2C_S_IICIF_MASK;

    I2C0->D = data;
    while (!(I2C0->S & I2C_S_IICIF_MASK));
    I2C0->S |= I2C_S_IICIF_MASK;

    I2C0->C1 &= ~(I2C_C1_MST_MASK | I2C_C1_TX_MASK);
    return true;
}

// 3. Recepción Máster (Lectura de un Byte desde un Esclavo)
uint8_t I2C0_ReadByte(uint8_t slave_addr, uint8_t reg_addr) {
    uint8_t dummy, data;

    I2C0->C1 |= I2C_C1_MST_MASK | I2C_C1_TX_MASK;
    I2C0->D = (slave_addr << 1) | 0;
    while (!(I2C0->S & I2C_S_IICIF_MASK));
    I2C0->S |= I2C_S_IICIF_MASK;

    I2C0->D = reg_addr;
    while (!(I2C0->S & I2C_S_IICIF_MASK));
    I2C0->S |= I2C_S_IICIF_MASK;

    // Repeated Start
    I2C0->C1 |= I2C_C1_RSTA_MASK;
    I2C0->D = (slave_addr << 1) | 1; // R/W = 1
    while (!(I2C0->S & I2C_S_IICIF_MASK));
    I2C0->S |= I2C_S_IICIF_MASK;

    I2C0->C1 &= ~I2C_C1_TX_MASK;
    I2C0->C1 |= I2C_C1_TXAK_MASK; // Responder con NACK

    dummy = I2C0->D; // Lectura dummy
    while (!(I2C0->S & I2C_S_IICIF_MASK));
    I2C0->S |= I2C_S_IICIF_MASK;

    I2C0->C1 &= ~(I2C_C1_MST_MASK | I2C_C1_TXAK_MASK);
    data = I2C0->D; // Lectura real

    return data;
}
```

/*
== Protocolo CAN (Controller Area Network)

=== Capa Física y Señal Diferencial

#figure(image("/images/CAN.png", width: 80%))

CAN es un estándar automotriz de bus serie asíncrono y multimaestro altamente robusto. A nivel físico, emplea un par de cables trenzados (*twisted pair*) por donde viaja una señal diferencial (*CANH* y *CANL*). Esta topología requiere resistencias terminadoras de $120 Omega$ en ambos extremos del bus para evitar reflexiones de señal.

El bus opera con dos estados eléctricos que implementan la lógica *Wired-AND*:
 - *Recesivo (1 lógico):* Transceptores apagados. Ambas líneas descansan pasivamente en $2.5 "V"$ ($V_"diff" = 0 "V"$).
 - *Dominante (0 lógico):* Transceptores activos ($"CANH" = 3.5 "V"$, $"CANL" = 1.5 "V"$, $V_"diff" = 2 "V"$). Si un nodo intenta transmitir un nivel dominante y otro uno recesivo, el dominante sobrescribe al recesivo en el bus.

=== Trama, Arbitraje y Bit Stuffing

A diferencia de protocolos direccionales por nodo, en CAN cada mensaje posee un Identificador (*ID*, de 11 bits en el *Standard Data Frame*) que define tanto el contenido de los datos como la prioridad del mensaje.


 - *Arbitraje*: Si el bus está en reposo (idle), cualquier nodo puede iniciar un mensaje enviando un bit dominante de Start of Frame (SOF), seguido de su ID. Todos los nodos escuchan el bus mientras transmiten. Si un nodo envía un bit recesivo de su ID pero lee el bus en estado dominante, pierde el arbitraje de manera no destructiva y pasa inmediatamente a modo de solo escucha (listening only). El mensaje con el ID de valor numérico más bajo posee la prioridad más alta.

 - *Bit Stuffing*: Debido a la naturaleza asíncrona del bus, los nodos receptores necesitan flancos (transiciones) para resincronizar sus relojes internos. Si el hardware de transmisión detecta 5 bits consecutivos con idéntica polaridad, inserta automáticamente un bit de relleno (stuff bit) de valor opuesto. El receptor descarta este bit para recuperar los datos originales. Esta regla detiene su aplicación antes de llegar al campo CRC delimiter.

 - *Estructura de Trama*: Una trama de datos (Data Frame) estándar contiene el SOF, el ID, el bit RTR, los bits de control y código de longitud (DLC), entre 0 y 8 bytes de datos útiles, un campo CRC de 15 bits para validación, un delimitador, una ranura de Acknowledge (ACK) donde todos los receptores imponen un bit dominante si validaron el CRC, y finaliza con un End of Frame (EOF) compuesto por 7 bits recesivos.

=== Filtrado de Mensajes por Hardware

El controlador CAN utiliza lógica de hardware dedicada para aceptar o descartar tramas de la red sin cargar la CPU:
#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  [
    #cuadro-concepto(titulo: [*Filtro (Filter)*])[
      Registro que guarda el valor hexadecimal del ID específico que el nodo está programado para aceptar.
    ]
  ],
  [
    #cuadro-concepto(titulo: [*Máscara (Mask):*])[
      Especifica qué bits del filtro deben coincidir estrictamente con el ID entrante. Un bit en "1" en la máscara exige verificación estricta de esa posición; un bit en "0" ordena ignorar (*don't care*) esa posición. Configurar la máscara en cero lógico acepta todos los mensajes del bus.. 
    ]
  ]
)
*/