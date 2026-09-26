= Clase 1: Buses de Datos, Decodificación y Control de GPIO

== Buses de Datos y de Direcciones

Con una instrucción como `LDAA $1000`, la CPU solicita el contenido de la dirección de memoria `$1000` y lo carga en el acumulador A.

- *Address Bus (Bus de Direcciones):* Unidireccional. La CPU indica *con qué dispositivo o posición de memoria* desea comunicarse.
- *Data Bus (Bus de Datos):* Bidireccional. Transporta *el valor* leído o escrito entre la CPU y el destino.

#figure(
  image("/images/dataBus.png", width: 95%),
  caption: [Interconexión de la CPU con la memoria y periféricos mediante el bus de direcciones y datos.],
) <fig:addressDecode>

#block(
  fill: rgb("#e8f0fe"),
  stroke: (left: 4pt + rgb("#1a73e8")),
  inset: 10pt,
  radius: (right: 4pt),
  width: 100%,
)[
  *Concepto Clave: Buffers Tri-State y Control de Bus* \
  Para evitar colisiones cuando múltiples periféricos comparten el *Data Bus*, se emplean buffers *Tri-State*. La lógica de control administra el acceso mediante:
  - *R/W (Read/Write):* Controla el sentido del flujo de datos (Lectura = 1, Escritura = 0).
  - *CS (Chip Select):* Habilita únicamente al periférico cuya dirección fue decodificada por la Lógica de Decodificación (LC).
  - *Alta Impedancia (Z):* Los periféricos no seleccionados desconectan eléctricamente sus salidas para no interferir en el bus.
]

=== Ejemplo del TP1: Mapeo en Memoria de Registros GPIO (MCAL)
En el microcontrolador FRDM-K64F, los periféricos están mapeados en memoria (*Memory-Mapped I/O*). Cada acceso a los registros del puerto viaja por el *Address Bus* hacia la dirección del periférico GPIO.

```c
// Proveniente de: MCAL_layer/gpio.c
static GPIO_Type * const gpio_ptrs[] = {PTA, PTB, PTC, PTD, PTE};

void gpioWrite (pin_t pin, bool value) {
    uint8_t portId = PIN2PORT(pin); // Extrae puerto (0..4 -> PA..PE)
    uint8_t pinNum = PIN2NUM(pin);   // Extrae número de pin (0..31)

    if (value) {
        gpio_ptrs[portId]->PSOR = (1 << pinNum); // Escribe en Port Set Output Register
    } else {
        gpio_ptrs[portId]->PCOR = (1 << pinNum); // Escribe en Port Clear Output Register
    }
}
```

== GPIO: Entradas y Salidas Digitales

#figure(
  image("/images/gpioIn.png", width: 70%),
  caption: [Mapeo de registros de entrada y salida digital en un microcontrolador.],
) <fig:gpioIn>

Los pines de un GPIO (*General Purpose Input/Output*) se controlan mediante registros mapeados en memoria. Cada registro tiene su propia dirección física.

#figure(
  image("/images/gpio.png", width: 70%),
  caption: [Ejemplo genérico de la estructura interna de un puerto GPIO.],
) <fig:gpio>

En este esquema genérico, el registro `P1DIR` define el sentido de cada pin:
- *Bit en `0`:* Configura el pin como *Entrada* (alta impedancia).
- *Bit en `1`:* Configura el pin como *Salida* (baja impedancia).

=== Readback: Leer el Estado de una Salida

#figure(
  image("/images/readBack.png", width: 70%),
  caption: [Esquema de verificación mediante Readback.],
) <fig:readBack>

El *readback* permite verificar el estado real de una señal de salida:
- Se configura un pin como `OUTPUT` para generar la señal y otro pin (o el propio registro de entrada `PDIR`) como `INPUT` para observarla.
- Permite detectar fallas en el circuito externo, como cortocircuitos a masa (GND) o a alimentación (VCC).
- *Regla de seguridad:* Nunca se deben conectar dos salidas con valores opuestos sobre el mismo conductor.

=== Active-Low y Active-High

#figure(
  image("/images/active.png", width: 70%),
  caption: [Configuraciones de carga en esquemas Active-High y Active-Low.],
) <fig:active>

- *Active-High:* La función se considera activa cuando la señal está en nivel alto (`1` / 3.3V).
- *Active-Low:* La función se considera activa cuando la señal está en nivel bajo (`0` / GND). Suele denotarse con `_n`, `_b` o barra superior (\\(\overline{\text{SIGNAL}}\\)).

#block(
  fill: rgb("#fff8e1"),
  stroke: (left: 4pt + rgb("#f57f17")),
  inset: 10pt,
  radius: (right: 4pt),
  width: 100%,
)[
  *Ejemplo del TP1: Lector Magnético con Señales Active-Low* \
  En `lector.c`, las líneas de datos y reloj de la tarjeta magnética operan en *Active-Low*. Al capturar los bits en la ISR de reloj, se invierte el estado lógico con `!`:

  ```c
  // Proveniente de: HAL_layer/lector.c (IRQ_CardClk)
  void IRQ_CardClk(void) {
      // El dato ingresa invertido por ser una línea ACTIVO BAJO
      bitarray[currbit++] = !gpioRead(PIN_CARD_DATA); 
      ...
  }
  ```
]

=== Propiedades Eléctricas de un Pin

#figure(
  image("/images/prot.png", width: 50%),
  caption: [Estructura de protección diódica y resistencias internas de un pin I/O.],
) <fig:prot>

- *Diodos de protección:* Protegen contra descargas electrostáticas (ESD). Conducen cuando la tensión supera \\(V_{\text{DD}}\\) o cae por debajo de \\(V_{\text{SS}}\\). No deben usarse para regular tensión de forma permanente.
- *Pull-Up / Pull-Down:* Resistencias internas configurables que fijan un nivel lógico conocido cuando el pin de entrada está desconectado o en alta impedancia.
- *Drive Strength (`DSE`):* Define la capacidad de entrega de corriente de la salida. Un valor alto permite manejar cargas más exigentes (como un buzzer), pero puede incrementar el ruido electromagnético (EMI).

#block(
  fill: rgb("#e6f4ea"),
  stroke: (left: 4pt + rgb("#137333")),
  inset: 10pt,
  radius: (right: 4pt),
  width: 100%,
)[
  *Ejemplo del TP1: Configuración de Pull-Ups Internos* \
  Tanto el encoder rotativo como el lector magnético requieren resistencias de Pull-Up para evitar estados flotantes:

  ```c
  // Proveniente de: HAL_layer/encoder.c (inicializarEncoder)
  gpioMode(PIN_ENC_A,  INPUT_PULLUP);
  gpioMode(PIN_ENC_B,  INPUT_PULLUP);
  gpioMode(PIN_ENC_SW, INPUT_PULLUP);
  ```
]

=== Configuraciones de Pines con MOSFETs

#figure(
  image("/images/logica.png", width: 100%),
  caption: [Implementación de lógica digital con MOSFET y elevación de tensión de salida.],
) <fig:logica>

Las salidas de *Colector Abierto / Drenador Abierto (Open-Collector / Open-Drain)* permiten:
- Conectar múltiples salidas en paralelo sobre una misma línea (*Wired-OR* / *Wired-AND*).
- Adaptar diferentes niveles de tensión lógica (por ejemplo, elevar de 3.3V a 5V) mediante una resistencia de Pull-Up externa.

== GPIO del Kinetis K64F

El microcontrolador K64F posee cinco puertos GPIO de 32 bits cada uno (`PORTA` a `PORTE`).

#figure(
  image("/images/pcrMap.png", width: 80%),
  caption: [Kinetis K64 - Reference Manual - Capítulo 4 (Mapa de memoria PORT/GPIO).],
) <fig:pcrMap>

Registros principales de datos de cada puerto (donde `X` representa el puerto A, B, C, D o E):
- `GPIOX_PDOR` (*Port Data Output Register*): Contiene el valor enviado a los pines de salida.
- `GPIOX_PSOR` (*Port Set Output Register*): Pone en `1` de forma atómica los bits indicados.
- `GPIOX_PCOR` (*Port Clear Output Register*): Pone en `0` de forma atómica los bits indicados.
- `GPIOX_PTOR` (*Port Toggle Output Register*): Invierte el estado lógico de los bits indicados.
- `GPIOX_PDIR` (*Port Data Input Register*): Permite leer el nivel físico de las entradas.
- `GPIOX_PDDR` (*Port Data Direction Register*): Configura la dirección (`0` = Entrada, `1` = Salida).

#figure(
  image("/images/gen.png", width: 100%),
  caption: [Arquitectura interna de registros de un puerto GPIO en el K64F.],
) <fig:gen>

=== PDDR (Port Data Direction Register)
#figure(
  image("/images/PDDR.png", width: 80%),
  caption: [Configuración de dirección mediante PDDR (`0` = Entrada, `1` = Salida).],
) <fig:PDDR>

=== PSOR (Port Set Output Register)
#figure(
  image("/images/PSOR.png", width: 80%),
  caption: [Escritura atómica en nivel alto mediante PSOR.],
) <fig:PSOR>

=== PCOR (Port Clear Output Register)
#figure(
  image("/images/PCOR.png", width: 80%),
  caption: [Escritura atómica en nivel bajo mediante PCOR.],
) <fig:PCOR>

=== PTOR (Port Toggle Output Register)
#figure(
  image("/images/PTOR.png", width: 80%),
  caption: [Conmutación / Toggle atómico mediante PTOR.],
) <fig:PTOR>

=== PDIR (Port Data Input Register)
#figure(
  image("/images/PDIR.png", width: 80%),
  caption: [Lectura del estado de las entradas a través de PDIR.],
) <fig:PDIR>

== PCR: Configuración Individual de Cada Pin

Cada pin dispone de un registro individual de 32 bits denominado *Pin Control Register* (`PORTX_PCRn`).

#figure(
  image("/images/pcr.png", width: 100%),
  caption: [Estructura de bits del registro Pin Control Register (PCR). Los campos en gris no son accesibles.],
) <fig:pcr>

#table(
  columns: (1.2fr, 2.8fr, 2fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (x, y) => if y == 0 { rgb("#1a3a6b") } else if calc.odd(y) { rgb("#f8f9fa") },
  table.header(
    [text(fill: white)[*Campo PCR*]], [text(fill: white)[*Descripción / Función*]], [text(fill: white)[*Uso en TP1*]]
  ),
  [*MUX*], [Selecciona la función del pin (GPIO = `ALT1`, I2C, SPI, UART, etc.).], [`PORT_PCR_MUX(1)` en `gpio.c`],
  [*IRQC*], [Configura interrupciones / DMA por flanco o nivel.], [`gpioIRQ()` en `gpio.c`],
  [*PE / PS*], [*PE:* Habilita resistencia interna. \ *PS:* Selecciona Pull-Up (`1`) o Pull-Down (`0`).], [`INPUT_PULLUP` en drivers],
  [*DSE*], [*Drive Strength Enable:* Incrementa corriente de salida.], [`OUTPUT_HIGH_DRIVE` para Buzzer],
  [*SRE*], [*Slew Rate Enable:* Modula la velocidad de transición.], [Ver @fig:sre]
)

#figure(
  image("/images/sre.png", width: 45%),
  caption: [Efecto del Slew Rate (SRE) en la transición de la señal de salida.],
) <fig:sre>

=== PCR - MUX

#figure(
  image("/images/mux2.png", width: 100%),
  caption: [Multiplexación de funciones mediante el campo MUX del PCR.],
) <fig:mux2>

#figure(
  image("/images/k64f.png", width: 100%),
  caption: [Tabla de alternativas de multiplexado del Kinetis K64F.],
) <fig:k64f>

=== Secuencia para Configurar un Pin como GPIO

1. *Clock Gating:* Activar el reloj del puerto en `SIM->SCGC5`.
2. *Configuración PORT:* Asignar `MUX(1)` (`ALT1`) y propiedades eléctricas en `PORTX_PCRn`.
3. *Dirección GPIO:* Configurar `GPIOX_PDDR` (`0` para entrada, `1` para salida).
4. *Operación:* Leer o escribir los pines mediante `PDOR`, `PSOR`, `PCOR`, `PTOR` o `PDIR`.

== PCR - Global

#figure(
  image("/images/glob.png", width: 90%),
  caption: [Control global de pines para modificar múltiples registros PCR simultáneamente.],
) <fig:glob>

Permiten modificar las propiedades de varios pines del mismo puerto en una sola operación de escritura:
- *Global Pin Control Low Register (`PORTx_GPCLR`):* Aplica cambios a los pines `[15:0]`.
- *Global Pin Control High Register (`PORTx_GPCHR`):* Aplica cambios a los pines `[31:16]`.

#figure(
  image("/images/low.png", width: 50%),
  caption: [Campos del registro PORTx_GPCLR (máscara GPWE y datos GPWD).],
) <fig:low>

#figure(
  image("/images/high.png", width: 50%),
  caption: [Campos del registro PORTx_GPCHR para la mitad superior del puerto.],
) <fig:high>

#block(
  fill: rgb("#f3e5f5"),
  stroke: (left: 4pt + rgb("#7b1fa2")),
  inset: 10pt,
  radius: (right: 4pt),
  width: 100%,
)[
  *Ejemplo del TP1 / Clase Teórica: Configuración Simultánea de LEDs* \
  Uso de `GPCHR` para configurar los pines de los LEDs en el Puerto B (pines PTB21 y PTB22) en una sola instrucción:

  ```c
  // Proveniente de: App.c / Ejemplos Teóricos de Clase
  uint32_t temp = PORT_GPCHR_GPWE((1 << (21 - 16)) | (1 << (22 - 16))); 
  temp |= PORT_GPCHR_GPWD(PORT_PCR_MUX(1) | PORT_PCR_DSE(1));
  PORTB->GPCHR = temp; // Configura MUX y DSE en ambos pines simultáneamente
  ```
]

=== Interrupt Status Flag Register (`PORTx_ISFR`)
Permite identificar qué pin de un puerto generó una interrupción consultando un único registro de 32 bits. Los flags se limpian escribiendo un `1` lógico (*w1c*).

=== Programación del Módulo PORT y GPIO

#figure(
  image("/images/gate.png", width: 70%),
  caption: [Habilitación del reloj (Clock Gating) mediante el registro SIM_SCGC5.],
) <fig:gate>

Estructura de la capa de acceso a registros en `MK64F12.h`:

```c
// Proveniente de: MCAL_layer/MK64F12.h
#define __I  volatile const
#define __O  volatile
#define __IO volatile

typedef struct {
  __IO uint32_t PDOR; /**< Port Data Output Register, offset: 0x0 */
  __O  uint32_t PSOR; /**< Port Set Output Register, offset: 0x4 */
  __O  uint32_t PCOR; /**< Port Clear Output Register, offset: 0x8 */
  __O  uint32_t PTOR; /**< Port Toggle Output Register, offset: 0xC */
  __I  uint32_t PDIR; /**< Port Data Input Register, offset: 0x10 */
  __IO uint32_t PDDR; /**< Port Data Direction Register, offset: 0x14 */
} GPIO_Type;
```

Ejemplo práctico de inicialización bare-metal:

```c
// 1. Habilita el reloj para el Puerto B
SIM->SCGC5 |= SIM_SCGC5_PORTB_MASK;

// 2. Operaciones directas sobre el puerto
PTB->PCOR = (1<<21) | (1<<22);                        // Limpia pines 21 y 22
PTB->PSOR = (1<<21) | (1<<22);                        // Pone en 1 pines 21 y 22
PTB->PDDR = (1<<21) | (1<<22);                        // Configura pines como Salidas
PTB->PTOR = (1<<21) | (1<<22);                        // Invierte estado de los pines 21 y 22

if (PTA->PDIR & (1<<4)) {                             // Testea pin 4 (Entrada)
    Do_something();
}
```

Estructura del módulo `PORT` en `MK64F12.h`:

```c
// Proveniente de: MCAL_layer/MK64F12.h
typedef struct {
  __IO uint32_t PCR;  /**< Pin Control Register array, offset: 0x0 */
  __O  uint32_t GPCLR;    /**< Global Pin Control Low Register, offset: 0x80 */
  __O  uint32_t GPCHR;    /**< Global Pin Control High Register, offset: 0x84 */
       uint8_t  RESERVED_0;
  __IO uint32_t ISFR;     /**< Interrupt Status Flag Register, offset: 0xA0 */
} PORT_Type;
```
